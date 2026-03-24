from __future__ import annotations

import logging
from collections.abc import Iterable
from typing import TYPE_CHECKING, Any

from django.apps import apps
from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.core.app_service import AppService
from apps.core.utils.logging import log_event

from .models import (
    Channel,
    ContentVariant,
    ShareJob,
    SharePlan,
    ShareTemplate,
    SocialAccount,
)

# Lazy imports for modularity - blog app is optional
if TYPE_CHECKING:
    from apps.blog.models import Post

logger = logging.getLogger(__name__)


def _enabled_channels() -> list[str]:
    try:
        dist_api = AppService.get("distribution")
        settings_obj = (
            dist_api.get_settings()
            if dist_api and hasattr(dist_api, "get_settings")
            else {}
        )
        if not settings_obj.get("distribution_enabled", True):
            return []
        override = settings_obj.get("default_channels") or []
        if override:
            return override
    except Exception:  # noqa: S110
        pass
    return getattr(settings, "DISTRIBUTION_CHANNELS", list(Channel.values))


def _default_template(channel: str) -> ShareTemplate | None:
    tmpl = (
        ShareTemplate.objects.filter(channel=channel, is_default=True).first()
        or ShareTemplate.objects.filter(channel=channel).first()
    )
    return tmpl


def _ensure_variants(post: Post, channels: Iterable[str]) -> dict[str, dict[str, Any]]:
    variants: dict[str, dict[str, Any]] = {}

    # Generate AI content once if possible
    ai_summary = post.summary
    ai_title = post.title
    ai_hashtags = []

    try:
        import json

        from apps.ai.services import test_completion

        prompt = f"""
        Analyze this blog post and provide distribution content.
        Return ONLY a valid JSON object with the following keys:
        - summary: A short, engaging summary for social media (max 280 chars)
        - title: A catchy, click-worthy title
        - hashtags: A list of 5 relevant hashtags (strings, no #)

        Post Title: {post.title}
        Post Summary: {post.summary}
        Post Body (excerpt): {post.body[:1000]}
        """

        resp = test_completion(prompt)
        text = resp.get("text", "")
        if text.startswith("```"):
            text = text.split("```")[1].replace("json", "").strip()

        data = json.loads(text)
        ai_summary = data.get("summary") or post.summary
        ai_title = data.get("title") or post.title
        ai_hashtags = data.get("hashtags") or []

    except Exception as e:
        logger.warning(f"AI distribution content generation failed: {e}")

    for ch in channels:
        variant_payload = {
            "title": ai_title,
            "summary": ai_summary,
            "hashtags": ai_hashtags,
            "url": post.get_absolute_url(),
        }
        variants[ch] = variant_payload
        ContentVariant.objects.update_or_create(
            post=post,
            channel=ch,
            variant_type="summary",
            defaults={"payload": variant_payload},
        )
    return variants


def _absolute_url(url: str) -> str:
    """
    Guarantee an absolute URL for downstream channels (indexing/social).
    """
    if url.startswith("http://") or url.startswith("https://"):
        return url
    base = getattr(settings, "SITE_URL", "").rstrip("/")
    return f"{base}{url}" if base else url


def _build_payload(
    post: Post, channel: str, template: ShareTemplate | None, variants: dict[str, Any]
) -> dict[str, Any]:
    data = variants.get(channel) or {}
    tmpl = template.body_template if template else "{title} {url}"
    url = data.get("url") or post.get_absolute_url()
    body = tmpl.format(
        title=data.get("title") or post.title,
        url=_absolute_url(url),
        summary=data.get("summary") or post.summary,
        hashtags=" ".join(f"#{h}" for h in data.get("hashtags", [])[:6]),
    )
    payload = {"body": body}
    if template and template.media_template:
        payload["media"] = template.media_template
    return payload


@transaction.atomic
def create_plan_for_post(
    post: Post,
    *,
    channels: Iterable[str] | None = None,
    schedule_at=None,
    created_by=None,
) -> SharePlan:
    """Create a distribution plan for a blog post."""
    channels = list(channels or _enabled_channels())
    if not channels:
        return None  # type: ignore[return-value]
    existing = SharePlan.objects.filter(
        post=post, status__in=["pending", "queued", "sent"]
    ).first()
    if existing:
        return existing
    plan = SharePlan.objects.create(
        post=post,
        channels=channels,
        schedule_at=schedule_at,
        status="queued" if schedule_at and schedule_at > timezone.now() else "pending",
        created_by=created_by,
    )
    variants = _ensure_variants(post, channels)
    jobs: list[ShareJob] = []
    for ch in channels:
        template = _default_template(ch)
        payload = _build_payload(post, ch, template, variants)
        account = (
            SocialAccount.objects.filter(channel=ch, is_active=True).first()
            if ch not in {Channel.RSS, Channel.ATOM, Channel.JSON, Channel.WEBSUB}
            else None
        )
        jobs.append(
            ShareJob(
                post=post,
                plan=plan,
                account=account,
                channel=ch,
                payload=payload,
                schedule_at=schedule_at,
                status="pending",
            )
        )
    ShareJob.objects.bulk_create(jobs)
    return plan


def should_fanout(post: Post) -> bool:
    """Check if post should be fanned out - requires blog app."""
    if not apps.is_installed("apps.blog"):
        return False
    try:
        from apps.blog.models import PostStatus

        return (
            post.status == PostStatus.PUBLISHED
            and post.publish_at
            and post.publish_at <= timezone.now()
        )
    except Exception:
        return False


def fanout_post_publish(post: Post, *, created_by=None) -> SharePlan | None:
    """Fan out published post to distribution channels. Requires blog app."""
    if not apps.is_installed("apps.blog"):
        return None
    if not should_fanout(post):
        return None
    try:
        dist_api = AppService.get("distribution")
        settings_obj = (
            dist_api.get_settings()
            if dist_api and hasattr(dist_api, "get_settings")
            else {}
        )
        if not settings_obj.get("distribution_enabled", True):
            return None
        if not settings_obj.get("auto_fanout_on_publish", True):
            return None
    except Exception:  # noqa: S110
        pass
    plan = create_plan_for_post(post, created_by=created_by)
    if not plan:
        logger.info(
            "distribution.plan.skipped",
            extra={"post": post.slug, "reason": "no_channels"},
        )
        return None
    log_event(
        logger,
        "info",
        "distribution.plan.created",
        post=post.slug,
        plan=plan.pk,
        channels=plan.channels,
    )
    return plan


# ══════════════════════════════════════════════════════════════════════════════
# Video Script Generation
# ══════════════════════════════════════════════════════════════════════════════

# Platforms that benefit from video content
VIDEO_CHANNELS: set[str] = {
    Channel.TIKTOK,
    Channel.INSTAGRAM,
    Channel.FACEBOOK,
    Channel.TWITTER,
    Channel.LINKEDIN,
}


def generate_video_script(post: Post, *, channel: str | None = None) -> dict[str, Any]:
    """
    Generate an AI video script for a blog post.

    Returns a dict with keys: title, hook, scenes (list of scene dicts),
    cta (call-to-action), duration_seconds, hashtags.
    Each scene has: narration, visual_description, duration_seconds.
    """
    target_channel = channel or "generic"
    platform_hints: dict[str, str] = {
        Channel.TIKTOK: "Keep it under 60 seconds. Fast-paced, trend-aware, vertical format.",
        Channel.INSTAGRAM: "Reels format, 30-90 seconds. Visual-first with text overlays.",
        Channel.FACEBOOK: "1-3 minutes. Story-driven, emotional hook, landscape or square.",
        Channel.TWITTER: "Under 140 seconds. Punchy, informative, horizontal.",
        Channel.LINKEDIN: "Professional tone, 1-2 minutes. Insight-driven, value-first.",
    }
    platform_hint = platform_hints.get(
        target_channel, "General social media video, 60-90 seconds."
    )

    try:
        import json

        from apps.ai.services import test_completion

        prompt = f"""
Create a video script for a social media post about this blog article.
Platform: {target_channel} — {platform_hint}

Return ONLY a valid JSON object with these keys:
- title: Catchy video title
- hook: Opening 5-second hook text to grab attention
- scenes: Array of 3-5 scene objects, each with:
  - narration: What the narrator says
  - visual_description: What appears on screen
  - duration_seconds: Scene length in seconds
- cta: Call-to-action text for the end
- duration_seconds: Total video duration
- hashtags: Array of 5 relevant hashtags (no # prefix)

Blog Title: {post.title}
Blog Summary: {post.summary or ""}
Blog Body (excerpt): {post.body[:1500] if post.body else ""}
"""
        resp = test_completion(prompt)
        text = resp.get("text", "")
        if text.startswith("```"):
            text = text.split("```")[1].replace("json", "").strip()

        script = json.loads(text)
        # Validate minimal structure
        if not isinstance(script.get("scenes"), list):
            script["scenes"] = []
        return script

    except Exception as e:
        logger.warning("Video script generation failed: %s", e)
        return {
            "title": post.title,
            "hook": f"Did you know about {post.title}?",
            "scenes": [
                {
                    "narration": post.summary or post.title,
                    "visual_description": "Title card with blog post image",
                    "duration_seconds": 10,
                },
                {
                    "narration": "Check out the full article for more details!",
                    "visual_description": "Blog URL and QR code on screen",
                    "duration_seconds": 5,
                },
            ],
            "cta": "Link in bio!",
            "duration_seconds": 15,
            "hashtags": [],
        }


def create_video_variants_for_post(
    post: Post, *, channels: Iterable[str] | None = None, created_by: Any = None
) -> list[ContentVariant]:
    """
    Generate video script variants for a post across video-friendly channels.
    Returns the created/updated ContentVariant objects.
    """
    target_channels = set(channels or VIDEO_CHANNELS) & VIDEO_CHANNELS
    if not target_channels:
        return []

    results: list[ContentVariant] = []
    for ch in target_channels:
        script = generate_video_script(post, channel=ch)
        variant, _created = ContentVariant.objects.update_or_create(
            post=post,
            channel=ch,
            variant_type="video_script",
            defaults={
                "payload": script,
                "generated_by": created_by,
            },
        )
        results.append(variant)
        logger.info(
            "distribution.video_script.generated",
            extra={"post": post.pk, "channel": ch},
        )
    return results
