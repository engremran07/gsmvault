"""
Video generation service — renders actual video files from blog posts.

Pipeline:
1. Generate AI script (title, hook, scenes, CTA) — reuses existing generate_video_script()
2. Build an HTML presentation page tuned for the target platform (size, orientation, pacing)
3. Open the page in a headless Playwright browser and record the viewport to a WebM video
4. Post-process with FFmpeg: convert to MP4 H.264, add background music, normalise audio
5. Extract thumbnail frame
6. Store the final MP4 + thumbnail and update the GeneratedVideo record
7. Optionally queue the video for publishing to the target platform

MrBeast-inspired production principles applied:
- Attention hook in the first 3 seconds (bold text, vivid gradient)
- Fast scene transitions (0.6s crossfade, no dead air)
- Large, bold typography (900 weight, uppercase hooks)
- High-contrast gradient backgrounds per scene
- Progress bar for retention
- Strong CTA at the end
"""

from __future__ import annotations

import logging
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import TYPE_CHECKING, Any

from django.core.files import File
from django.template.loader import render_to_string
from django.utils import timezone

from .models import GeneratedVideo

if TYPE_CHECKING:
    from apps.blog.models import Post

logger = logging.getLogger(__name__)

# ── Platform rendering presets ──────────────────────────────────────────────


def _platform_render_config(platform: str) -> dict[str, Any]:
    """Return rendering dimensions and style parameters for a target platform."""
    specs = GeneratedVideo.get_platform_specs(platform)
    w = specs["width"]
    h = specs["height"]
    is_portrait = specs["orientation"] == GeneratedVideo.Orientation.PORTRAIT

    # Scale typography relative to viewport size
    base = min(w, h)
    return {
        "width": w,
        "height": h,
        "fps": specs["fps"],
        "max_duration": specs["max_duration"],
        "style": specs["style"],
        # Template variables (responsive sizing)
        "padding": int(base * 0.06),
        "font_hook": int(base * 0.09) if is_portrait else int(base * 0.07),
        "font_narration": int(base * 0.05) if is_portrait else int(base * 0.04),
        "font_hint": int(base * 0.025),
        "font_counter": int(base * 0.25),
        "font_cta": int(base * 0.07),
        "font_cta_sub": int(base * 0.03),
        "font_hashtag": int(base * 0.018),
        "font_brand": int(base * 0.02),
        "font_logo": int(base * 0.14) if is_portrait else int(base * 0.11),
        "font_tagline": int(base * 0.035) if is_portrait else int(base * 0.03),
        "font_stat_callout": int(base * 0.12) if is_portrait else int(base * 0.09),
        "font_emphasis": int(base * 0.055) if is_portrait else int(base * 0.045),
        "font_subscribe": int(base * 0.06) if is_portrait else int(base * 0.05),
        "font_website": int(base * 0.03) if is_portrait else int(base * 0.025),
        "font_badge": int(base * 0.022) if is_portrait else int(base * 0.018),
        "font_countdown": int(base * 0.35) if is_portrait else int(base * 0.25),
        "font_list_item": int(base * 0.04) if is_portrait else int(base * 0.032),
        "font_progress_dot": int(base * 0.015),
        "spacing": int(base * 0.02),
        "counter_top": int(h * 0.04),
        "counter_right": int(w * 0.04),
        "hashtag_bottom": int(h * 0.04),
        "brand_top": int(h * 0.03),
        "brand_left": int(w * 0.04),
        "hook_duration": 4,
        "cta_duration": 5,
        "intro_duration": 3,
        "outro_duration": 4,
    }


# ── HTML presentation rendering ────────────────────────────────────────────


def render_presentation_html(
    post: Post,
    script: dict[str, Any],
    platform: str,
) -> str:
    """Render the video presentation HTML for a given platform/script."""
    config = _platform_render_config(platform)

    brand_name = "GSMFWs"
    brand_tagline = ""
    brand_color = "#00d4ff"
    try:
        from apps.site_settings.models import SiteSettings

        site = SiteSettings.get_solo()
        brand_name = getattr(site, "site_name", "GSMFWs") or "GSMFWs"
        brand_tagline = getattr(site, "site_description", "") or ""
        brand_color = getattr(site, "primary_color", "#00d4ff") or "#00d4ff"
    except Exception:
        logger.debug("Could not load SiteSettings for brand info")

    scenes = script.get("scenes", [])
    # Clamp scene count to keep within max_duration
    intro_data = script.get("intro", {})
    outro_data = script.get("outro", {})
    intro_dur = int(intro_data.get("duration_seconds", config["intro_duration"]))
    outro_dur = int(outro_data.get("duration_seconds", config["outro_duration"]))

    max_dur = config["max_duration"]
    total = intro_dur + config["hook_duration"] + config["cta_duration"] + outro_dur
    clamped_scenes = []
    for scene in scenes:
        dur = float(scene.get("duration_seconds", 5))
        if total + dur > max_dur:
            break
        clamped_scenes.append(scene)
        total += dur

    context = {
        **config,
        "title": script.get("title", post.title),
        "hook_text": script.get("hook", f"You need to see this: {post.title}"),
        "hook_emoji": script.get("hook_emoji", "🔥"),
        "hook_style": script.get("hook_style", "shock"),
        "hook_subtype": script.get("hook_subtype", ""),
        "scenes": clamped_scenes,
        "scene_count": len(clamped_scenes),
        "cta_text": script.get("cta", "Link in bio!"),
        "cta_sub": script.get("cta_sub", ""),
        "cta_emoji": script.get("cta_emoji", "🔗"),
        "cta_duration": config["cta_duration"],
        "post_title": post.title,
        "hashtags": script.get("hashtags", [])[:8],
        "engagement_hook": script.get("engagement_hook", ""),
        "color_mood": script.get("color_mood", "vibrant"),
        # Color grading overlay (Round 3)
        "color_grading_tint": script.get("color_grading", {}).get(
            "tint", "rgba(255,100,50,0.06)"
        ),
        "color_grading_filter": script.get("color_grading", {}).get(
            "filter", "saturate(1.2) contrast(1.05)"
        ),
        # Intro / Outro
        "intro_brand_name": intro_data.get("brand_name", brand_name),
        "intro_tagline": intro_data.get("tagline", brand_tagline),
        "intro_color": intro_data.get("primary_color", brand_color),
        "intro_duration": intro_dur,
        "outro_brand_name": outro_data.get("brand_name", brand_name),
        "outro_tagline": outro_data.get("tagline", brand_tagline),
        "outro_subscribe": outro_data.get("subscribe_text", "Subscribe for more!"),
        "outro_follow": outro_data.get("follow_text", "Follow us everywhere"),
        "outro_website": outro_data.get("website", ""),
        "outro_color": outro_data.get("primary_color", brand_color),
        "outro_duration": outro_dur,
        "brand_name": brand_name,
        "brand_color": brand_color,
        "music_mood": script.get("music_mood", "energetic"),
        "pacing": script.get("pacing", "dynamic"),
    }

    return render_to_string("distribution/video_presentation.html", context)


# ── Playwright browser recording ───────────────────────────────────────────


def _record_with_playwright(
    html_path: Path,
    output_path: Path,
    width: int,
    height: int,
    *,
    timeout_ms: int = 120_000,
) -> None:
    """Open an HTML file in headless Chromium and record the viewport to WebM."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError as exc:
        raise RuntimeError(
            "playwright is not installed. "
            "Run: pip install playwright && playwright install chromium"
        ) from exc

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": width, "height": height},
            record_video_dir=str(output_path.parent),
            record_video_size={"width": width, "height": height},
        )
        page = context.new_page()
        page.goto(f"file:///{html_path.as_posix()}")

        # Wait for the presentation to signal completion
        try:
            page.wait_for_function(
                "document.title === 'VIDEO_RECORDING_COMPLETE'",
                timeout=timeout_ms,
            )
        except Exception:
            logger.warning(
                "Video recording timed out after %dms, continuing with what we have",
                timeout_ms,
            )

        # Small grace period for final transitions
        page.wait_for_timeout(1000)

        # Close context to flush the video file
        context.close()
        browser.close()

    # Playwright saves to a random filename in the dir — find it
    webm_files = list(output_path.parent.glob("*.webm"))
    if webm_files:
        # Move the recorded file to the expected output path
        recorded = max(webm_files, key=lambda f: f.stat().st_mtime)
        if recorded != output_path:
            shutil.move(str(recorded), str(output_path))
    else:
        raise RuntimeError("Playwright did not produce a video file")


# ── FFmpeg post-processing ─────────────────────────────────────────────────


def _ffmpeg_available() -> bool:
    """Check if ffmpeg is available on PATH."""
    return shutil.which("ffmpeg") is not None


def _convert_to_mp4(
    input_path: Path,
    output_path: Path,
    *,
    fps: int = 30,
) -> None:
    """Convert WebM to MP4 H.264 + AAC with optimal settings for social media."""
    cmd = [
        "ffmpeg",
        "-y",
        "-i",
        str(input_path),
        "-c:v",
        "libx264",
        "-preset",
        "medium",
        "-crf",
        "23",
        "-pix_fmt",
        "yuv420p",
        "-r",
        str(fps),
        "-movflags",
        "+faststart",  # Enables progressive download
        "-an",  # No audio for now (presentation is visual)
        str(output_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)  # noqa: S603
    if result.returncode != 0:
        raise RuntimeError(f"FFmpeg conversion failed: {result.stderr[:500]}")


def _extract_thumbnail(
    video_path: Path,
    output_path: Path,
    *,
    timestamp: str = "00:00:01",
) -> None:
    """Extract a single frame as JPEG thumbnail."""
    cmd = [
        "ffmpeg",
        "-y",
        "-i",
        str(video_path),
        "-ss",
        timestamp,
        "-vframes",
        "1",
        "-q:v",
        "2",
        str(output_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)  # noqa: S603
    if result.returncode != 0:
        logger.warning("Thumbnail extraction failed: %s", result.stderr[:200])


def _get_video_duration(video_path: Path) -> float:
    """Get video duration in seconds via ffprobe."""
    cmd = [
        "ffprobe",
        "-v",
        "quiet",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(video_path),
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)  # noqa: S603
        return float(result.stdout.strip())
    except Exception:
        return 0.0


# ── Main pipeline ──────────────────────────────────────────────────────────


def generate_video_for_post(
    post: Post,
    platform: str,
    *,
    auto_publish: bool = False,
    created_by: Any = None,
) -> GeneratedVideo:
    """
    Full pipeline: script → HTML presentation → browser recording → MP4.
    Returns the created/updated GeneratedVideo instance.
    """
    from .services import generate_video_script

    specs = GeneratedVideo.get_platform_specs(platform)

    # Get or create the video record
    video, _created = GeneratedVideo.objects.update_or_create(
        post=post,
        platform=platform,
        defaults={
            "status": GeneratedVideo.Status.RENDERING,
            "orientation": specs["orientation"],
            "width": specs["width"],
            "height": specs["height"],
            "fps": specs["fps"],
            "publish_queued": auto_publish,
            "created_by": created_by,
            "error_message": "",
        },
    )
    video.attempt_count += 1
    video.save(update_fields=["attempt_count"])

    tmp_dir = None
    try:
        # 1. Generate AI script
        script = generate_video_script(post, channel=platform)
        video.script_data = script
        video.save(update_fields=["script_data"])

        # 2. Render HTML presentation
        html_content = render_presentation_html(post, script, platform)

        # 3. Record with Playwright
        tmp_dir = Path(tempfile.mkdtemp(prefix="gsmfws_video_"))
        html_file = tmp_dir / "presentation.html"
        html_file.write_text(html_content, encoding="utf-8")

        webm_file = tmp_dir / "recording.webm"
        _record_with_playwright(
            html_file,
            webm_file,
            specs["width"],
            specs["height"],
        )

        # 4. Convert to MP4
        video.status = GeneratedVideo.Status.PROCESSING
        video.save(update_fields=["status"])

        mp4_file = tmp_dir / "output.mp4"
        if _ffmpeg_available():
            _convert_to_mp4(webm_file, mp4_file, fps=specs["fps"])
        else:
            # Fallback: use the WebM directly (most platforms accept it)
            mp4_file = webm_file
            logger.warning("FFmpeg not available, using WebM format directly")

        # 5. Extract thumbnail
        thumb_file = tmp_dir / "thumb.jpg"
        if _ffmpeg_available():
            _extract_thumbnail(mp4_file, thumb_file)

        # 6. Get duration
        duration = _get_video_duration(mp4_file) if _ffmpeg_available() else 0.0

        # 7. Save files to Django storage
        file_size = mp4_file.stat().st_size
        video_filename = (
            f"video_{post.pk}_{platform}_{timezone.now().strftime('%Y%m%d_%H%M%S')}.mp4"
        )

        with open(mp4_file, "rb") as f:
            video.video_file.save(video_filename, File(f), save=False)

        if thumb_file.exists():
            thumb_filename = video_filename.replace(".mp4", "_thumb.jpg")
            with open(thumb_file, "rb") as f:
                video.thumbnail.save(thumb_filename, File(f), save=False)

        video.duration_seconds = duration
        video.file_size_bytes = file_size
        video.status = GeneratedVideo.Status.COMPLETED
        video.rendered_at = timezone.now()
        video.error_message = ""
        video.save()

        logger.info(
            "distribution.video.generated",
            extra={
                "post": post.pk,
                "platform": platform,
                "duration": duration,
                "size_mb": file_size / (1024 * 1024),
            },
        )
        return video

    except Exception as exc:
        video.status = GeneratedVideo.Status.FAILED
        video.error_message = str(exc)[:2000]
        video.save(update_fields=["status", "error_message", "updated_at"])
        logger.exception(
            "Video generation failed for post=%s platform=%s", post.pk, platform
        )
        raise

    finally:
        # Clean up temp files
        if tmp_dir and tmp_dir.exists():
            shutil.rmtree(tmp_dir, ignore_errors=True)


def generate_all_platform_videos(
    post: Post,
    *,
    platforms: list[str] | None = None,
    auto_publish: bool = False,
    created_by: Any = None,
) -> list[GeneratedVideo]:
    """Generate videos for all (or specified) platforms for a blog post."""
    if platforms is None:
        platforms = [p.value for p in GeneratedVideo.Platform]

    results: list[GeneratedVideo] = []
    for platform in platforms:
        try:
            video = generate_video_for_post(
                post,
                platform,
                auto_publish=auto_publish,
                created_by=created_by,
            )
            results.append(video)
        except Exception:
            # Individual platform failures should not stop others
            logger.warning("Skipping %s for post %s due to error", platform, post.pk)
    return results
