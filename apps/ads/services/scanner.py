"""
Ad placement scanner — discovers ad-worthy locations in public templates.

Two scanning modes:
1. **Template scan** (admin-triggered, one-time/rare):
   Scans public HTML template files for content sections where ad placements
   make sense (articles, sidebars, lists/feeds, footers).  Automatically
   creates ``AdPlacement`` records for every discovered slot and stores
   detailed ``AutoAdsScanResult`` analysis.

2. **Blog post content scan** (auto, per-post via Celery):
   Analyzes the HTML body of a published blog post to find paragraph breaks
   and determine optimal in-content ad insertion points.

Admin templates, error pages, and base layouts are **always excluded**.
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from typing import Any

from django.conf import settings
from django.template.defaultfilters import slugify

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Directories to EXCLUDE from template scanning (admin / infra / layouts)
# ---------------------------------------------------------------------------
EXCLUDED_DIRS: set[str] = {
    "admin",
    "admin_suite",
    "layouts",
    "base",
    "errors",
    "account",  # allauth account templates
}

# ---------------------------------------------------------------------------
# Public template directories we actively scan for ad placement potential
# ---------------------------------------------------------------------------
PUBLIC_DIRS: set[str] = {
    "blog",
    "forum",
    "firmwares",
    "devices",
    "pages",
    "bounty",
    "tags",
    "users",
    "components",
    "core",
    "ads",
    "consent",
    "distribution",
    "seo",
    "analytics",
}

# Regex: existing ad slot references in templates
AD_SLOT_PATTERN = re.compile(
    r"(?:ads:slot|<!--\s*ad-slot:|{%\s*render_ad_slot\s+['\"])(?P<name>[\w\-\s]+)",
    re.IGNORECASE,
)

# Content-structure patterns (what makes a template suitable for ads)
CONTENT_PATTERNS: dict[str, re.Pattern[str]] = {
    "article": re.compile(r"<article[^>]*>", re.IGNORECASE),
    "main_content": re.compile(
        r'class="[^"]*(?:content|main|body|prose)[^"]*"', re.IGNORECASE
    ),
    "sidebar": re.compile(r'class="[^"]*(?:sidebar|aside|rail)[^"]*"', re.IGNORECASE),
    "footer": re.compile(r"<footer[^>]*>", re.IGNORECASE),
    "list": re.compile(r'class="[^"]*(?:list|grid|feed|posts)[^"]*"', re.IGNORECASE),
    "hero": re.compile(r'class="[^"]*(?:hero|banner|jumbotron)[^"]*"', re.IGNORECASE),
    "card_grid": re.compile(
        r'class="[^"]*(?:card|tile)[^"]*".*class="[^"]*(?:grid|flex)[^"]*"',
        re.IGNORECASE | re.DOTALL,
    ),
}

# ---------------------------------------------------------------------------
# Placement rules:  content_type → list of placements to auto-create
# Each entry = (suffix, allowed_types, allowed_sizes, description_template)
# ---------------------------------------------------------------------------
PLACEMENT_RULES: dict[str, list[tuple[str, str, str, str]]] = {
    "article": [
        (
            "in-article-top",
            "banner,native",
            "728x90,300x250",
            "Above-the-fold banner inside article content in {tpl}",
        ),
        (
            "in-article-mid",
            "native,html",
            "300x250,336x280",
            "Mid-article native ad between paragraphs in {tpl}",
        ),
    ],
    "main_content": [
        (
            "content-top",
            "banner,native,html",
            "728x90,970x250",
            "Top of main content area in {tpl}",
        ),
        (
            "content-bottom",
            "banner,native",
            "728x90,300x250",
            "Bottom of main content area in {tpl}",
        ),
    ],
    "sidebar": [
        (
            "sidebar-top",
            "banner,native",
            "300x250,300x600,160x600",
            "Top of sidebar in {tpl}",
        ),
        (
            "sidebar-sticky",
            "banner",
            "300x250,300x600",
            "Sticky sidebar unit in {tpl}",
        ),
    ],
    "list": [
        (
            "in-feed",
            "native,html",
            "300x250,fluid",
            "In-feed ad between list/grid items in {tpl}",
        ),
    ],
    "footer": [
        (
            "above-footer",
            "banner,html",
            "728x90,970x90",
            "Leaderboard above footer in {tpl}",
        ),
    ],
    "hero": [
        (
            "after-hero",
            "banner",
            "970x250,728x90",
            "Banner directly after hero/banner section in {tpl}",
        ),
    ],
    "card_grid": [
        (
            "in-grid",
            "native",
            "fluid",
            "Native ad card injected into card grid in {tpl}",
        ),
    ],
    "auto_ads": [
        (
            "anchor-bottom",
            "banner,html",
            "728x90,320x50",
            "Sticky anchor ad at page bottom — auto-ads in {tpl}",
        ),
        (
            "vignette",
            "banner,html,native",
            "300x250,336x280,fluid",
            "Full-screen vignette/interstitial ad — auto-ads in {tpl}",
        ),
    ],
}


# ===== 1. Template scan (admin-triggered, synchronous) ====================


def scan_templates_for_placements() -> dict[str, Any]:
    """
    Scan public-facing HTML templates and **auto-create** AdPlacement records
    for every viable ad slot discovered in the content structure.

    Returns dict with ``scanned``, ``created``, ``updated``, ``suggestions``.
    """
    from apps.ads.models import AdPlacement, AutoAdsScanResult

    templates_dir = Path(settings.BASE_DIR) / "templates"
    if not templates_dir.exists():
        return {"status": "error", "reason": "templates_dir_not_found"}

    created = 0
    updated = 0
    scanned = 0
    suggestions: list[dict[str, Any]] = []

    for path in templates_dir.rglob("*.html"):
        relative = path.relative_to(templates_dir)
        top_dir = relative.parts[0] if len(relative.parts) > 1 else ""

        # Skip excluded directories
        if top_dir in EXCLUDED_DIRS:
            continue

        # Skip fragments (standalone HTMX snippets — too small for ads)
        if "fragments" in relative.parts:
            continue

        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except Exception:  # noqa: S112
            continue

        scanned += 1
        relative_path = str(relative)

        # Derive a stable prefix from the template path
        # e.g. "blog/post_detail.html" → "blog-post-detail"
        tpl_slug = slugify(relative_path.replace("/", " ").replace(".html", ""))

        # --- Discover existing explicit ad-slot tags ---
        for match in AD_SLOT_PATTERN.finditer(text):
            raw_name = match.group("name").strip()
            if not raw_name:
                continue
            slug = slugify(raw_name)
            _obj, flag = AdPlacement.objects.get_or_create(
                slug=slug,
                defaults={
                    "code": slug or raw_name.lower().replace(" ", "-"),
                    "name": raw_name,
                    "allowed_types": "banner,native,html",
                    "context": "auto",
                    "template_reference": relative_path,
                },
            )
            if flag:
                created += 1
            else:
                updated += 1

        # --- Analyse content structure ---
        content_analysis: dict[str, int] = {}
        for pattern_name, pattern in CONTENT_PATTERNS.items():
            matches = pattern.findall(text)
            if matches:
                content_analysis[pattern_name] = len(matches)

        if not content_analysis:
            continue

        # ---  AUTO-CREATE placements from rules ---
        suggestion_list = _suggest_placements(content_analysis, relative_path)
        tpl_created = 0

        for content_type in content_analysis:
            rules = PLACEMENT_RULES.get(content_type, [])
            for suffix, allowed_types, allowed_sizes, desc_tpl in rules:
                slug = f"{tpl_slug}-{suffix}"
                code = slug
                name = f"{tpl_slug} {suffix}".replace("-", " ").title()
                _obj, flag = AdPlacement.objects.get_or_create(
                    slug=slug,
                    defaults={
                        "code": code,
                        "name": name,
                        "description": desc_tpl.format(tpl=relative_path),
                        "allowed_types": allowed_types,
                        "allowed_sizes": allowed_sizes,
                        "context": top_dir or "global",
                        "page_context": relative_path,
                        "template_reference": relative_path,
                        "is_enabled": True,
                        "is_active": True,
                    },
                )
                if flag:
                    created += 1
                    tpl_created += 1
                else:
                    updated += 1

        # Store detailed scan result
        AutoAdsScanResult.objects.update_or_create(
            template_path=relative_path,
            defaults={
                "content_analysis": content_analysis,
                "suggested_placements": suggestion_list,
                "score": _calculate_placement_score(content_analysis),
            },
        )
        suggestions.append(
            {
                "template": relative_path,
                "content_types": list(content_analysis.keys()),
                "placements_created": tpl_created,
            }
        )

    logger.info(
        "Template scan complete. Scanned: %d, Created: %d, Updated: %d",
        scanned,
        created,
        updated,
    )

    return {
        "status": "success",
        "scanned": scanned,
        "created": created,
        "updated": updated,
        "suggestions": suggestions[:30],
    }


# ===== 2. Blog post body scan (called from Celery task) ===================


def scan_blog_post_body(post_id: int) -> dict[str, Any]:
    """
    Analyse the body HTML of a blog post, count paragraphs, headings, images,
    and create an ``AutoAdsScanResult`` with optimal in-content ad positions.

    Called asynchronously via Celery whenever a blog post is published.
    """
    from apps.ads.models import AutoAdsScanResult

    try:
        from apps.blog.models import Post

        post = Post.objects.filter(pk=post_id).first()
        if post is None:
            return {"status": "error", "reason": "post_not_found"}
    except Exception as exc:
        logger.error("Failed to load post %s: %s", post_id, exc)
        return {"status": "error", "reason": str(exc)}

    body = post.body or ""
    if len(body) < 100:
        return {"status": "skipped", "reason": "body_too_short"}

    # Count structural elements
    paragraphs = len(re.findall(r"<p[\s>]", body, re.IGNORECASE))
    headings = len(re.findall(r"<h[1-6][\s>]", body, re.IGNORECASE))
    images = len(re.findall(r"<img[\s>]", body, re.IGNORECASE))
    lists = len(re.findall(r"<[uo]l[\s>]", body, re.IGNORECASE))
    blockquotes = len(re.findall(r"<blockquote[\s>]", body, re.IGNORECASE))

    content_analysis: dict[str, int] = {}
    if paragraphs:
        content_analysis["paragraphs"] = paragraphs
    if headings:
        content_analysis["headings"] = headings
    if images:
        content_analysis["images"] = images
    if lists:
        content_analysis["lists"] = lists
    if blockquotes:
        content_analysis["blockquotes"] = blockquotes

    if not content_analysis:
        return {"status": "skipped", "reason": "no_structural_content"}

    # Determine in-content ad insertion positions
    suggested: list[dict[str, str]] = []

    if paragraphs >= 3:
        suggested.append(
            {
                "type": "in_article",
                "position": "after_paragraph_3",
                "rationale": "In-article ad after initial engagement (3rd paragraph)",
            }
        )
    if paragraphs >= 6:
        suggested.append(
            {
                "type": "in_article_mid",
                "position": f"after_paragraph_{paragraphs // 2}",
                "rationale": f"Mid-article ad (paragraph {paragraphs // 2} of {paragraphs})",
            }
        )
    if paragraphs >= 9:
        suggested.append(
            {
                "type": "in_article_late",
                "position": f"after_paragraph_{paragraphs - 2}",
                "rationale": "Late-article ad for engaged readers",
            }
        )
    if images >= 2:
        suggested.append(
            {
                "type": "after_image",
                "position": "after_second_image",
                "rationale": "Image context ads perform well next to visual content",
            }
        )

    # Score based on content richness
    score = min(
        (
            paragraphs * 5.0
            + headings * 8.0
            + images * 6.0
            + lists * 3.0
            + blockquotes * 2.0
        ),
        100.0,
    )

    template_path = f"blog/post:{post.pk}:{post.slug}"

    # Update-or-create: one scan result per blog post
    AutoAdsScanResult.objects.update_or_create(
        template_path=template_path,
        defaults={
            "content_analysis": content_analysis,
            "suggested_placements": suggested,
            "score": score,
            "applied": False,
        },
    )

    logger.info(
        "Blog post scan complete: post=%s, paragraphs=%d, suggestions=%d",
        post_id,
        paragraphs,
        len(suggested),
    )

    return {
        "status": "success",
        "post_id": post_id,
        "paragraphs": paragraphs,
        "suggestions": len(suggested),
        "score": score,
    }


# ===== Helpers =============================================================


def _suggest_placements(
    content_analysis: dict[str, int], template_path: str
) -> list[dict[str, str]]:
    """Generate placement suggestions based on template content analysis."""
    suggestions: list[dict[str, str]] = []

    if "article" in content_analysis or "main_content" in content_analysis:
        suggestions.append(
            {
                "type": "in_article",
                "position": "after_paragraph_3",
                "rationale": "In-article ads perform well after initial content engagement",
            }
        )
        suggestions.append(
            {
                "type": "post_top",
                "position": "before_content",
                "rationale": "Above-the-fold placement for high visibility",
            }
        )

    if "sidebar" in content_analysis:
        suggestions.append(
            {
                "type": "sidebar_rect",
                "position": "sidebar_top",
                "rationale": "Sidebar ads are highly visible without disrupting content",
            }
        )

    if "list" in content_analysis:
        suggestions.append(
            {
                "type": "in_feed",
                "position": "every_nth_item",
                "rationale": "In-feed ads blend naturally with list content",
            }
        )

    if "footer" in content_analysis:
        suggestions.append(
            {
                "type": "footer_banner",
                "position": "above_footer",
                "rationale": "Catch users who read to the end",
            }
        )

    return suggestions


def _calculate_placement_score(content_analysis: dict[str, int]) -> float:
    """Calculate a score (0–100) indicating how suitable the template is for ads."""
    score = 0.0
    weights = {
        "article": 0.3,
        "main_content": 0.25,
        "sidebar": 0.2,
        "list": 0.15,
        "footer": 0.1,
    }
    for content_type, weight in weights.items():
        if content_type in content_analysis:
            score += weight * min(content_analysis[content_type], 3)

    return min(score, 1.0) * 100
