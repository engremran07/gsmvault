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
# Video Script Generation — Advanced MrBeast-Style Production
# ══════════════════════════════════════════════════════════════════════════════

# Platforms that benefit from video content
VIDEO_CHANNELS: set[str] = {
    Channel.TIKTOK,
    Channel.INSTAGRAM,
    Channel.FACEBOOK,
    Channel.TWITTER,
    Channel.LINKEDIN,
}

# ── Brand identity for intro/outro (loaded once, cached per-call) ───────────


def _get_brand_identity() -> dict[str, str]:
    """Load brand identity from SiteSettings for intro/outro sequences."""
    try:
        from apps.site_settings.models import SiteSettings

        site = SiteSettings.get_solo()
        return {
            "brand_name": getattr(site, "site_name", "") or "GSMFWs",
            "tagline": getattr(site, "site_description", "") or "Your Firmware Source",
            "website": "gsmfws.com",
            "primary_color": getattr(site, "primary_color", "") or "#00d4ff",
        }
    except Exception:
        return {
            "brand_name": "GSMFWs",
            "tagline": "Your Firmware Source",
            "website": "gsmfws.com",
            "primary_color": "#00d4ff",
        }


# ── Platform-specific production configs ────────────────────────────────────

PLATFORM_PRODUCTION_PROFILES: dict[str, dict[str, Any]] = {
    Channel.TIKTOK: {
        "pacing": "rapid",
        "scene_count": (4, 6),
        "max_seconds": 55,
        "tone": "energetic, Gen-Z, trend-aware",
        "text_style": "bold uppercase, emoji-heavy, punchy one-liners",
        "transitions": "glitch, zoom, whip-pan",
        "music_mood": "trap beat, high energy",
        "hook_style": "shock value / impossible claim / 'Wait for it...'",
        "engagement": "reply bait, stitch hooks, green screen prompts",
        "platform_hint": (
            "TikTok vertical (9:16). Under 60s. First 1.5 seconds MUST hook. "
            "Use pattern interrupts every 3-5 seconds. Text overlays are mandatory. "
            "End with a loop-worthy moment or open question."
        ),
    },
    Channel.INSTAGRAM: {
        "pacing": "rhythmic",
        "scene_count": (4, 7),
        "max_seconds": 85,
        "tone": "aesthetic, aspirational, relatable",
        "text_style": "clean sans-serif, minimal but impactful",
        "transitions": "smooth crossfade, morph, slide",
        "music_mood": "lo-fi chill, trending audio",
        "hook_style": "visual wow moment / 'Save this for later' / carousel-style reveals",
        "engagement": "'Save this', 'Share with someone who needs this', 'Follow for more'",
        "platform_hint": (
            "Instagram Reels (9:16). 30-90s sweet spot. Visual-first with text overlays. "
            "Use 3-second hook. Aesthetic color grading. Carousel-style info reveals. "
            "End with 'Follow + Save' CTA. Hashtags in caption, not video."
        ),
    },
    Channel.FACEBOOK: {
        "pacing": "narrative",
        "scene_count": (5, 8),
        "max_seconds": 180,
        "tone": "story-driven, emotional, community-focused",
        "text_style": "readable, warm, sentence case with emphasis",
        "transitions": "cinematic dissolve, Ken Burns zoom",
        "music_mood": "emotional piano, uplifting orchestral",
        "hook_style": "emotional story / surprising fact / 'Nobody talks about this...'",
        "engagement": "share prompt, tag-a-friend, comment question",
        "platform_hint": (
            "Facebook (16:9). 1-3 minutes. Story-driven narrative arc. "
            "Sound-off friendly with burned-in subtitles. Emotional hook in first 3 seconds. "
            "Build tension → reveal → emotional payoff. Community engagement at end."
        ),
    },
    Channel.TWITTER: {
        "pacing": "punchy",
        "scene_count": (3, 5),
        "max_seconds": 130,
        "tone": "witty, informative, slightly provocative",
        "text_style": "Twitter-native, thread-style reveals, quotable one-liners",
        "transitions": "hard cut, zoom snap, typewriter reveal",
        "music_mood": "minimal electronic, news-style urgency",
        "hook_style": "hot take / breaking news format / controversial opinion",
        "engagement": "quote retweet bait, 'What do you think?', ratio-worthy take",
        "platform_hint": (
            "Twitter/X (16:9). Under 140s. Dense information per second. "
            "Thread-style sequential reveals. Punchy, quotable statements. "
            "End with a retweet-worthy conclusion or open debate question."
        ),
    },
    Channel.LINKEDIN: {
        "pacing": "deliberate",
        "scene_count": (5, 8),
        "max_seconds": 120,
        "tone": "professional, insightful, authoritative yet approachable",
        "text_style": "executive-friendly, data callouts, bullet point reveals",
        "transitions": "elegant fade, slide, chart reveal",
        "music_mood": "corporate ambient, subtle confidence",
        "hook_style": (
            "industry insight / data-driven claim / "
            "'After 10 years in tech, here is what I learned...'"
        ),
        "engagement": "'Thoughts?', 'Agree or disagree?', 'Follow for daily insights'",
        "platform_hint": (
            "LinkedIn (16:9). 1-2 minutes. Professional value-first content. "
            "Lead with a bold industry insight or data point. Use numbered lists "
            "and stat callouts. End with a thought-provoking question for comments."
        ),
    },
}

# ── Fallback scene visual effects library ───────────────────────────────────

SCENE_VISUAL_EFFECTS = [
    "zoom_in",
    "zoom_out",
    "pan_left",
    "pan_right",
    "glitch",
    "shake",
    "pulse",
    "split_reveal",
    "typewriter",
    "counter_up",
    "particle_burst",
    "gradient_shift",
    "spotlight",
    "wave",
    # ── Round 3 additions ──
    "neon_glow",  # Neon edge glow on text
    "chromatic_aberration",  # RGB split channel shift
    "film_reel",  # Film strip flicker + vignette
    "matrix_rain",  # Digital rain overlay
    "parallax",  # Depth parallax on content layers
    "lens_flare",  # Anamorphic lens streak
    "dolly_zoom",  # Hitchcock vertigo zoom
    "ink_reveal",  # Ink blot mask reveal
]

SCENE_GRADIENT_PALETTES = [
    ("linear-gradient(135deg, #667eea 0%, #764ba2 100%)", "cosmic"),
    ("linear-gradient(135deg, #f093fb 0%, #f5576c 100%)", "sunset"),
    ("linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)", "ocean"),
    ("linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)", "mint"),
    ("linear-gradient(135deg, #fa709a 0%, #fee140 100%)", "fire"),
    ("linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)", "lavender"),
    ("linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)", "peach"),
    ("linear-gradient(135deg, #ff0844 0%, #ffb199 100%)", "cherry"),
    ("linear-gradient(135deg, #30cfd0 0%, #330867 100%)", "aurora"),
    ("linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)", "pastel"),
    ("linear-gradient(135deg, #d558c8 0%, #24d292 100%)", "neon"),
    ("linear-gradient(135deg, #13547a 0%, #80d0c7 100%)", "teal"),
    # ── Round 3 additions ──
    ("linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%)", "midnight"),
    ("linear-gradient(135deg, #ffe259 0%, #ffa751 100%)", "golden"),
    ("linear-gradient(135deg, #00b09b 0%, #96c93d 100%)", "emerald"),
    ("linear-gradient(135deg, #c94b4b 0%, #4b134f 100%)", "crimson"),
    ("linear-gradient(135deg, #654ea3 0%, #eaafc8 100%)", "royal"),
    ("linear-gradient(135deg, #2c3e50 0%, #4ca1af 100%)", "steel"),
    ("linear-gradient(135deg, #fc466b 0%, #3f5efb 100%)", "electric"),
    ("linear-gradient(135deg, #11998e 0%, #38ef7d 100%)", "matrix"),
]

# ── Scene layout types — determines how content is arranged ────────────────

SCENE_LAYOUT_TYPES = [
    "full_text",  # Centered narration, full width
    "stat_hero",  # Giant stat/number as focal, narration below
    "split_screen",  # Text left, visual hint right
    "quote_style",  # Large quotation marks, italic text, attribution
    "list_reveal",  # Bullet points appearing one by one
    "countdown",  # Big countdown number + text
    "device_showcase",  # Device-frame overlay + firmware text
    # ── Round 3 additions ──
    "timeline",  # Vertical timeline with milestone nodes
    "comparison",  # Before / After side-by-side columns
    "highlight_reel",  # Large keyword cloud with floating emphasis
]

# ── Slide transitions — how one scene replaces the next ────────────────────

SLIDE_TRANSITIONS = [
    "crossfade",  # Simple opacity crossfade (default)
    "wipe_left",  # New slide wipes in from right
    "wipe_right",  # New slide wipes in from left
    "wipe_up",  # New slide wipes in from bottom
    "zoom_through",  # Current slide zooms out, new zooms in
    "glitch_cut",  # Brief glitch then hard cut
    "dissolve",  # Pixel dissolve transition
    "slide_up",  # Current slides up, new comes from bottom
    # ── Round 3 additions ──
    "curtain",  # Theater curtain reveal from center
    "morph",  # Elastic morph with scale + blur
    "spiral_in",  # Clock-spiral clip-path wipe
]

# ── Text animation types per scene ─────────────────────────────────────────

TEXT_ANIMATION_TYPES = [
    "word_by_word",  # Words appear one at a time
    "line_by_line",  # Lines slide in sequentially
    "char_cascade",  # Characters cascade in from top
    "bounce_in",  # Text bounces in from below
    "slide_from_left",  # Text slides in from left side
    "fade_up",  # Default fade + slide up
    "typewrite",  # Typewriter char by char
    "scale_in",  # Text scales from 0 to full size
    # ── Round 3 additions ──
    "glitch_type",  # Glitch distortion reveal per word
    "wave_in",  # Sinusoidal wave entrance per character
]

# ── Background animation styles ────────────────────────────────────────────

BG_ANIMATION_TYPES = [
    "breathing",  # Slow scale pulse (1.0 → 1.05 → 1.0)
    "shifting",  # Gradient position shifts slowly
    "morphing",  # Background color morphs via hue-rotate
    "static",  # No animation
    # ── Round 3 additions ──
    "parallax_shift",  # Multi-layer depth parallax
    "aurora",  # Northern-lights color wave
]

# ── Hook subtypes for variety ──────────────────────────────────────────────

HOOK_SUBTYPES = {
    "countdown_321": {
        "pre_text": ["3", "2", "1"],
        "pre_duration": 0.8,
        "style": "Numbers count down before main hook text",
    },
    "question_hook": {
        "prefix": "Did you know...?",
        "style": "Rhetorical question with dramatic pause",
    },
    "stat_shock": {
        "style": "Giant shocking number/stat with explanation below",
    },
    "challenge_hook": {
        "prefix": "CHALLENGE:",
        "style": "Dare the viewer to watch",
    },
    # ── Round 3 additions ──
    "before_after": {
        "prefix": "BEFORE vs AFTER",
        "style": "Split-reveal comparison with dramatic wipe",
    },
    "myth_buster": {
        "prefix": "MYTH:",
        "suffix": "BUSTED ✕",
        "style": "Present common myth, then smash it with facts",
    },
}

# ── Color grading presets — mapped to color_mood values ────────────────────

COLOR_GRADING_PRESETS: dict[str, dict[str, str]] = {
    "vibrant": {
        "tint": "rgba(255,100,50,0.06)",
        "filter": "saturate(1.2) contrast(1.05)",
    },
    "dark_tech": {
        "tint": "rgba(0,200,255,0.08)",
        "filter": "saturate(0.9) contrast(1.1) brightness(0.95)",
    },
    "warm": {"tint": "rgba(255,180,80,0.07)", "filter": "saturate(1.1) sepia(0.05)"},
    "cool": {
        "tint": "rgba(100,150,255,0.07)",
        "filter": "saturate(0.95) brightness(1.02)",
    },
    "neon": {"tint": "rgba(200,0,255,0.06)", "filter": "saturate(1.4) contrast(1.1)"},
    "cinematic": {
        "tint": "rgba(0,0,0,0.04)",
        "filter": "contrast(1.15) saturate(0.85)",
    },
    "vintage": {
        "tint": "rgba(180,140,80,0.1)",
        "filter": "sepia(0.12) saturate(0.9) contrast(1.05)",
    },
}

# ── Particle color mapping by gradient mood ────────────────────────────────

PARTICLE_COLORS: dict[str, str] = {
    "cosmic": "rgba(102,126,234,0.5)",
    "sunset": "rgba(245,87,108,0.5)",
    "ocean": "rgba(0,242,254,0.5)",
    "mint": "rgba(56,249,215,0.5)",
    "fire": "rgba(254,225,64,0.5)",
    "lavender": "rgba(161,140,209,0.5)",
    "peach": "rgba(252,182,159,0.5)",
    "cherry": "rgba(255,8,68,0.5)",
    "aurora": "rgba(48,207,208,0.5)",
    "pastel": "rgba(254,214,227,0.5)",
    "neon": "rgba(213,88,200,0.5)",
    "teal": "rgba(128,208,199,0.5)",
    "midnight": "rgba(48,43,99,0.5)",
    "golden": "rgba(255,167,81,0.5)",
    "emerald": "rgba(150,201,61,0.5)",
    "crimson": "rgba(201,75,75,0.5)",
    "royal": "rgba(234,175,200,0.5)",
    "steel": "rgba(76,161,175,0.5)",
    "electric": "rgba(63,94,251,0.5)",
    "matrix": "rgba(56,239,125,0.5)",
}


def _extract_content_highlights(post: Post) -> dict[str, Any]:
    """
    Parse post body to extract numbers, brand names, features,
    and other visually compelling content for scenes.
    """
    import re

    body = post.body or ""
    title = post.title or ""

    # Extract numbers/stats
    numbers = re.findall(
        r"\b(\d+(?:\.\d+)?(?:\s*(?:GB|MB|GHz|MP|mAh|mm|g|%|K|M))?)\b", body
    )
    stats = [n for n in numbers if len(n) <= 12][:6]

    # Extract version numbers
    versions = re.findall(r"\b[Vv]?(\d+\.\d+(?:\.\d+)?)\b", body)[:3]

    # Extract sentences as narration candidates (prioritize shorter, punchier ones)
    raw_sentences = [
        s.strip() for s in re.split(r"[.!?]\s+", body) if 15 < len(s.strip()) < 200
    ]
    # Sort by engagement potential (shorter = punchier, questions = engaging)
    narration_candidates = sorted(
        raw_sentences,
        key=lambda s: (0 if "?" in s else 1, len(s)),
    )[:12]

    # Extract brand/model names from title
    brand_model = (
        title.split("—")[0].strip() if "—" in title else title.split("-")[0].strip()
    )

    # Extract keywords from body
    common_fw_words = {
        "firmware",
        "update",
        "download",
        "flash",
        "rom",
        "stock",
        "recovery",
        "bootloader",
        "unlock",
        "root",
        "custom",
        "official",
        "latest",
        "version",
        "build",
        "release",
    }
    body_lower = body.lower()
    found_keywords = [w for w in common_fw_words if w in body_lower]

    return {
        "stats": stats,
        "versions": versions,
        "narration_candidates": narration_candidates,
        "brand_model": brand_model,
        "keywords": found_keywords,
        "has_download_link": "download" in body_lower,
        "has_version_info": bool(versions),
        "word_count": len(body.split()),
    }


def generate_video_script(post: Post, *, channel: str | None = None) -> dict[str, Any]:
    """
    Generate an advanced, production-ready video script for a blog post.

    Returns a rich dict with:
    - intro: branded opening sequence (same across all videos)
    - title, hook, hook_emoji, hook_style
    - scenes[]: narration, visual_description, effect, emoji, stat_callout,
                gradient, text_emphasis, duration_seconds
    - outro: branded closing sequence (same across all videos)
    - cta, cta_sub, cta_emoji
    - duration_seconds, hashtags, music_mood, pacing, transitions
    """
    import random

    target_channel = channel or "generic"
    profile = PLATFORM_PRODUCTION_PROFILES.get(
        target_channel,
        PLATFORM_PRODUCTION_PROFILES[Channel.FACEBOOK],
    )
    brand = _get_brand_identity()

    # ── Intro (branded, universal across all videos) ──
    intro = {
        "brand_name": brand["brand_name"],
        "tagline": brand["tagline"],
        "website": brand["website"],
        "primary_color": brand["primary_color"],
        "duration_seconds": 3,
        "effect": "logo_reveal",
    }

    # ── Outro (branded, universal across all videos) ──
    outro = {
        "brand_name": brand["brand_name"],
        "tagline": brand["tagline"],
        "website": brand["website"],
        "primary_color": brand["primary_color"],
        "subscribe_text": "Subscribe for more!",
        "follow_text": "Follow us everywhere",
        "duration_seconds": 4,
        "effect": "logo_pulse",
    }

    # ── Try AI generation first ──
    try:
        import json

        from apps.ai.services import test_completion

        min_scenes, max_scenes = profile["scene_count"]
        content = _extract_content_highlights(post)

        prompt = f"""You are an elite video producer creating MrBeast / MKBHD-quality content.
Create an ADVANCED cinematic video script for this firmware blog article.

PLATFORM: {target_channel} — {profile["platform_hint"]}
PACING: {profile["pacing"]} | TONE: {profile["tone"]}
TEXT STYLE: {profile["text_style"]}
TRANSITIONS: {profile["transitions"]}
HOOK STYLE EXAMPLES: {profile["hook_style"]}
ENGAGEMENT TECHNIQUES: {profile["engagement"]}

CONTENT INTELLIGENCE (extracted from article):
- Key stats found: {content["stats"][:4]}
- Version numbers: {content["versions"]}
- Brand/model: {content["brand_model"]}
- Keywords: {content["keywords"][:8]}

Return ONLY a valid JSON object with these keys:
- title: Ultra-catchy, clickbait-worthy title (curiosity gap + numbers + superlatives)
- hook: Opening 2-3 second hook text (pattern interrupt, instant curiosity)
- hook_emoji: Single emoji amplifying the hook
- hook_style: "shock" | "question" | "impossible" | "countdown" | "reveal" | "challenge"
- hook_subtype: "countdown_321" | "question_hook" | "stat_shock" | "challenge_hook" | null
- scenes: Array of {min_scenes}-{max_scenes} scene objects, each with:
  - narration: What the narrator says (conversational, NOT robotic)
  - visual_description: Camera/overlay/effect direction
  - effect: "zoom_in" | "zoom_out" | "pan_left" | "pan_right" | "glitch" | "shake" | "pulse" | "split_reveal" | "typewriter" | "counter_up" | "particle_burst" | "gradient_shift" | "spotlight" | "wave" | "neon_glow" | "chromatic_aberration" | "film_reel" | "matrix_rain" | "parallax" | "lens_flare" | "dolly_zoom" | "ink_reveal"
  - layout: "full_text" | "stat_hero" | "split_screen" | "quote_style" | "list_reveal" | "countdown" | "device_showcase" | "timeline" | "comparison" | "highlight_reel"
  - transition: "crossfade" | "wipe_left" | "wipe_up" | "zoom_through" | "glitch_cut" | "dissolve" | "slide_up" | "curtain" | "morph" | "spiral_in"
  - text_anim: "word_by_word" | "line_by_line" | "bounce_in" | "slide_from_left" | "fade_up" | "typewrite" | "scale_in" | "glitch_type" | "wave_in"
  - bg_anim: "breathing" | "shifting" | "morphing" | "static" | "parallax_shift" | "aurora"
  - emoji: Mood emoji for this scene
  - stat_callout: Bold stat/number for prominent display (e.g. "99.9%", "10x", "FREE"), or empty
  - text_emphasis: Key phrase to highlight with glow
  - badge: Corner badge text (e.g. "NEW", "FREE", "🔥 HOT"), or empty
  - duration_seconds: {3 if profile["pacing"] == "rapid" else 5}-{8 if profile["pacing"] == "rapid" else 15}s
- cta: Strong platform-native call-to-action
- cta_sub: Secondary CTA text
- cta_emoji: CTA emoji
- music_mood: "{profile["music_mood"]}"
- pacing: "{profile["pacing"]}"
- transitions: "{profile["transitions"]}"
- duration_seconds: Total video (max {profile["max_seconds"]}s)
- hashtags: Array of 8 platform-optimized hashtags (no # prefix)
- engagement_hook: Final engagement prompt (question/challenge for comments)
- color_mood: "vibrant" | "dark_tech" | "warm" | "cool" | "neon" — overall visual mood

Blog Title: {post.title}
Blog Summary: {post.summary or "N/A"}
Blog Body (excerpt): {post.body[:2000] if post.body else "N/A"}
"""
        resp = test_completion(prompt)
        text = resp.get("text", "")
        # Strip markdown code fences
        if "```" in text:
            parts = text.split("```")
            text = parts[1] if len(parts) > 1 else parts[0]
            text = text.removeprefix("json").strip()

        script = json.loads(text)

        # Validate and enrich
        if not isinstance(script.get("scenes"), list) or len(script["scenes"]) < 2:
            raise ValueError("Insufficient scenes from AI")

        # Inject intro/outro
        script["intro"] = intro
        script["outro"] = outro
        script.setdefault("music_mood", profile["music_mood"])
        script.setdefault("pacing", profile["pacing"])
        script.setdefault("transitions", profile["transitions"])
        script.setdefault("color_mood", "vibrant")

        # Ensure every scene has all required fields
        for i, scene in enumerate(script["scenes"]):
            scene.setdefault("effect", random.choice(SCENE_VISUAL_EFFECTS))  # noqa: S311
            scene.setdefault("layout", "full_text")
            scene.setdefault(
                "transition", SLIDE_TRANSITIONS[i % len(SLIDE_TRANSITIONS)]
            )
            scene.setdefault(
                "text_anim", TEXT_ANIMATION_TYPES[i % len(TEXT_ANIMATION_TYPES)]
            )
            scene.setdefault("bg_anim", BG_ANIMATION_TYPES[i % len(BG_ANIMATION_TYPES)])
            scene.setdefault("emoji", "🔥")
            scene.setdefault("stat_callout", "")
            scene.setdefault("text_emphasis", "")
            scene.setdefault("badge", "")
            gradient_pair = SCENE_GRADIENT_PALETTES[i % len(SCENE_GRADIENT_PALETTES)]
            scene.setdefault("gradient", gradient_pair[0])
            scene.setdefault("duration_seconds", 5)
            # Round 3: color grading + particle tinting
            mood = gradient_pair[1]
            scene.setdefault(
                "particle_color", PARTICLE_COLORS.get(mood, "rgba(255,255,255,0.3)")
            )
        # Apply global color grading from mood
        grading = COLOR_GRADING_PRESETS.get(
            script.get("color_mood", "vibrant"),
            COLOR_GRADING_PRESETS["vibrant"],
        )
        script["color_grading"] = grading

        return script

    except Exception as e:
        logger.warning(
            "AI video script generation failed, using advanced fallback: %s", e
        )
        return _build_advanced_fallback_script(
            post, target_channel, profile, brand, intro, outro
        )


def _build_advanced_fallback_script(
    post: Post,
    channel: str,
    profile: dict[str, Any],
    brand: dict[str, str],
    intro: dict[str, Any],
    outro: dict[str, Any],
) -> dict[str, Any]:
    """
    Build a cinematic, platform-optimized fallback script when AI is unavailable.
    Uses content intelligence to create 5-8 scenes with varied layouts,
    transitions, text animations, and visual effects.
    """
    import random

    title = post.title or "Check This Out"
    summary = post.summary or title
    content = _extract_content_highlights(post)

    # ── Platform-specific hooks with subtypes ──
    hooks: dict[str, tuple[str, str, str, str]] = {
        Channel.TIKTOK: (
            "🤯 You NEED to see this firmware update!",
            "🤯",
            "shock",
            "countdown_321",
        ),
        Channel.INSTAGRAM: (
            "Save this before it's gone 👇",
            "📱",
            "reveal",
            "stat_shock",
        ),
        Channel.FACEBOOK: (
            "Nobody is talking about this...",
            "😱",
            "impossible",
            "question_hook",
        ),
        Channel.TWITTER: (
            "BREAKING: This changes everything 🧵",
            "🔥",
            "shock",
            "stat_shock",
        ),
        Channel.LINKEDIN: (
            "After years of firmware analysis, here's what I found",
            "💡",
            "reveal",
            "question_hook",
        ),
    }
    hook_text, hook_emoji, hook_style, hook_subtype = hooks.get(
        channel, ("Wait until you see this! 🔥", "🔥", "shock", "countdown_321")
    )

    narration_pool = content["narration_candidates"]
    stats_pool = content["stats"]
    brand_model = content["brand_model"]

    # ── Build cinematic scenes ──
    scenes: list[dict[str, Any]] = []

    # Scene 1: Title reveal — SPLIT_REVEAL + STAT_HERO
    scenes.append(
        {
            "narration": title,
            "visual_description": "Bold title card with glowing text, floating particles, brand logo watermark",
            "effect": "split_reveal",
            "layout": "full_text",
            "transition": "crossfade",
            "text_anim": "word_by_word",
            "bg_anim": "breathing",
            "emoji": "📱",
            "stat_callout": "",
            "text_emphasis": brand_model[:35] if brand_model else title[:35],
            "badge": "🔥 NEW",
            "gradient": SCENE_GRADIENT_PALETTES[0][0],
            "particle_color": PARTICLE_COLORS["cosmic"],
            "duration_seconds": 4,
        }
    )

    # Scene 2: Key insight / Summary — TYPEWRITER + QUOTE
    scenes.append(
        {
            "narration": summary[:200]
            if summary != title
            else "Here's everything you need to know",
            "visual_description": "Text morphing in with spotlight effect, key words glowing",
            "effect": "typewriter",
            "layout": "quote_style" if len(summary) > 60 else "full_text",
            "transition": "wipe_left",
            "text_anim": "typewrite",
            "bg_anim": "shifting",
            "emoji": "💡",
            "stat_callout": stats_pool[0] if stats_pool else "NEW",
            "text_emphasis": "everything you need",
            "badge": "",
            "gradient": SCENE_GRADIENT_PALETTES[1][0],
            "particle_color": PARTICLE_COLORS["sunset"],
            "duration_seconds": 5,
        }
    )

    # Scene 3: Feature highlight — COUNTER_UP + STAT_HERO
    feature_text = (
        narration_pool[0]
        if narration_pool
        else "Packed with the latest updates and improvements"
    )
    scenes.append(
        {
            "narration": feature_text[:200],
            "visual_description": "Stats counter animation, key number zooming in with particle burst",
            "effect": "counter_up",
            "layout": "stat_hero" if stats_pool else "highlight_reel",
            "transition": "zoom_through",
            "text_anim": "scale_in",
            "bg_anim": "aurora",
            "emoji": "⚡",
            "stat_callout": stats_pool[1] if len(stats_pool) > 1 else "100%",
            "text_emphasis": "latest updates",
            "badge": "⚡ FAST",
            "gradient": SCENE_GRADIENT_PALETTES[2][0],
            "particle_color": PARTICLE_COLORS["ocean"],
            "duration_seconds": 5,
        }
    )

    # Scene 4: Technical detail — ZOOM_IN + DEVICE_SHOWCASE
    tech_text = (
        narration_pool[1]
        if len(narration_pool) > 1
        else "Compatible with all major device variants"
    )
    scenes.append(
        {
            "narration": tech_text[:200],
            "visual_description": "Device mockup with firmware flashing animation, progress bar fills",
            "effect": "dolly_zoom",
            "layout": "device_showcase",
            "transition": "curtain",
            "text_anim": "slide_from_left",
            "bg_anim": "parallax_shift",
            "emoji": "🔧",
            "stat_callout": content["versions"][0] if content["versions"] else "",
            "text_emphasis": "all variants",
            "badge": "",
            "gradient": SCENE_GRADIENT_PALETTES[3][0],
            "particle_color": PARTICLE_COLORS["mint"],
            "duration_seconds": 5,
        }
    )

    # Scene 5: Why it matters — SPLIT_REVEAL + COMPARISON
    why_text = (
        narration_pool[2]
        if len(narration_pool) > 2
        else "Don't miss out on this critical update"
    )
    scenes.append(
        {
            "narration": why_text[:200],
            "visual_description": "Before/after comparison split screen, dramatic reveal",
            "effect": "neon_glow",
            "layout": "comparison",
            "transition": "morph",
            "text_anim": "wave_in",
            "bg_anim": "breathing",
            "emoji": "🚀",
            "stat_callout": "FREE",
            "text_emphasis": "critical update",
            "badge": "FREE",
            "gradient": SCENE_GRADIENT_PALETTES[4][0],
            "particle_color": PARTICLE_COLORS["fire"],
            "duration_seconds": 4,
        }
    )

    # Scene 6: Social proof (non-rapid only)
    if profile["pacing"] not in ("rapid",):
        extra_text = (
            narration_pool[3]
            if len(narration_pool) > 3
            else "Thousands of users have already downloaded this firmware"
        )
        scenes.append(
            {
                "narration": extra_text[:200],
                "visual_description": "Animated download counter, user testimonial cards floating",
                "effect": "counter_up",
                "layout": "stat_hero",
                "transition": "dissolve",
                "text_anim": "line_by_line",
                "bg_anim": "shifting",
                "emoji": "👥",
                "stat_callout": "1000+",
                "text_emphasis": "thousands of users",
                "badge": "🏆 POPULAR",
                "gradient": SCENE_GRADIENT_PALETTES[5][0],
                "particle_color": PARTICLE_COLORS["lavender"],
                "duration_seconds": 4,
            }
        )

    # Scene 7: Version/Feature list (narrative/deliberate only, if content exists)
    if profile["pacing"] in ("narrative", "deliberate") and len(narration_pool) > 4:
        scenes.append(
            {
                "narration": narration_pool[4][:200],
                "visual_description": "Timeline nodes appearing one by one with light streaks",
                "effect": "lens_flare",
                "layout": "timeline",
                "transition": "spiral_in",
                "text_anim": "glitch_type",
                "bg_anim": "aurora",
                "emoji": "✅",
                "stat_callout": "",
                "text_emphasis": "",
                "badge": "",
                "gradient": SCENE_GRADIENT_PALETTES[6][0],
                "particle_color": PARTICLE_COLORS["peach"],
                "duration_seconds": 5,
            }
        )

    # Scene 8: Urgency (narrative/deliberate only)
    if profile["pacing"] in ("narrative", "deliberate"):
        scenes.append(
            {
                "narration": "Download now — firmware updates don't last forever",
                "visual_description": "Countdown timer animation, pulsing download button, chromatic flicker",
                "effect": "chromatic_aberration",
                "layout": "countdown",
                "transition": "glitch_cut",
                "text_anim": "scale_in",
                "bg_anim": "morphing",
                "emoji": "⏰",
                "stat_callout": "ACT NOW",
                "text_emphasis": "don't last forever",
                "badge": "⏰ LIMITED",
                "gradient": SCENE_GRADIENT_PALETTES[7][0],
                "particle_color": PARTICLE_COLORS["cherry"],
                "duration_seconds": 4,
            }
        )

    # ── Platform CTAs ──
    ctas: dict[str, tuple[str, str, str]] = {
        Channel.TIKTOK: (
            "Link in bio — GO! 🏃",
            "Follow for daily firmware drops",
            "🔥",
        ),
        Channel.INSTAGRAM: (
            "Save this + Follow for more 📲",
            "Link in bio for download",
            "💾",
        ),
        Channel.FACEBOOK: (
            "Share this with someone who needs it! 💪",
            "Click the link below",
            "🔗",
        ),
        Channel.TWITTER: ("RT if this helped you 🔄", "Thread continues below ↓", "📌"),
        Channel.LINKEDIN: (
            "Thoughts? Drop a comment 💬",
            "Follow for more firmware insights",
            "🎯",
        ),
    }
    cta_text, cta_sub, cta_emoji = ctas.get(
        channel, ("Download now — Link below! 🔗", "Follow for more", "🔗")
    )

    total_duration = (
        sum(s["duration_seconds"] for s in scenes)
        + intro["duration_seconds"]
        + outro["duration_seconds"]
        + 5
    )

    # Hashtags per platform
    base_hashtags = ["firmware", "download", "android", "tech", "update"]
    platform_tags: dict[str, list[str]] = {
        Channel.TIKTOK: ["techtok", "fyp", "foryou"],
        Channel.INSTAGRAM: ["techgram", "reels", "explore"],
        Channel.FACEBOOK: ["facebookreels", "techcommunity"],
        Channel.TWITTER: ["tech", "breaking"],
        Channel.LINKEDIN: ["technology", "innovation", "firmware"],
    }
    hashtags = base_hashtags + platform_tags.get(channel, ["viral"])

    # Color mood based on platform
    color_moods: dict[str, str] = {
        Channel.TIKTOK: "neon",
        Channel.INSTAGRAM: "vibrant",
        Channel.FACEBOOK: "warm",
        Channel.TWITTER: "dark_tech",
        Channel.LINKEDIN: "cool",
    }

    return {
        "intro": intro,
        "title": f"🔥 {title}",
        "hook": hook_text,
        "hook_emoji": hook_emoji,
        "hook_style": hook_style,
        "hook_subtype": hook_subtype,
        "scenes": scenes,
        "outro": outro,
        "cta": cta_text,
        "cta_sub": cta_sub,
        "cta_emoji": cta_emoji,
        "music_mood": profile["music_mood"],
        "pacing": profile["pacing"],
        "transitions": profile["transitions"],
        "duration_seconds": total_duration,
        "hashtags": hashtags[:8],
        "color_mood": color_moods.get(channel, "vibrant"),
        "color_grading": COLOR_GRADING_PRESETS.get(
            color_moods.get(channel, "vibrant"),
            COLOR_GRADING_PRESETS["vibrant"],
        ),
        "engagement_hook": random.choice(  # noqa: S311
            [
                "Which firmware are you running? Comment below! 👇",
                "Did this help? Let me know! 💬",
                "Tag someone who needs this update! 🏷️",
                "What device do you have? Drop it below! ⬇️",
                "Save this for later — you'll need it! 📌",
                f"Have you tried the {brand_model} yet? 🤔",
            ]
        ),
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
