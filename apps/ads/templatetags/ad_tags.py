"""Template tags for rendering ad placements in public templates."""

from __future__ import annotations

import logging
import random

from django import template
from django.utils.safestring import mark_safe

register = template.Library()
logger = logging.getLogger(__name__)

# Placeholder ad sizes for visual layout when no real ad is configured
SLOT_SIZES: dict[str, tuple[str, str]] = {
    "sidebar-top": ("100%", "250px"),
    "sidebar-sticky": ("100%", "600px"),
    "in-article-top": ("100%", "90px"),
    "in-article-mid": ("100%", "250px"),
    "content-top": ("100%", "90px"),
    "content-bottom": ("100%", "250px"),
    "in-feed": ("100%", "120px"),
    "above-footer": ("100%", "90px"),
    "after-hero": ("100%", "90px"),
    "in-grid": ("100%", "250px"),
    "anchor-bottom": ("100%", "90px"),
    "vignette": ("100%", "300px"),
}

_PLACEHOLDER_LABELS = [
    "Your Ad Here",
    "Advertise With Us",
    "Ad Space Available",
]


@register.simple_tag(takes_context=True)
def render_ad_slot(context: dict, slot_code: str, css_class: str = "") -> str:  # type: ignore[type-arg]
    """Render an ad slot — real creative or themed placeholder.

    Usage::

        {% load ad_tags %}
        {% render_ad_slot "sidebar-top" %}
        {% render_ad_slot "in-article-top" css_class="my-6" %}
    """
    try:
        from apps.ads.models import AdNetwork, AdPlacement, PlacementAssignment
    except Exception:
        return ""

    placement = (
        AdPlacement.objects.filter(code=slot_code, is_active=True, is_enabled=True)
        .only("pk", "name", "code", "allowed_sizes")
        .first()
    )
    if not placement:
        return ""

    # Check for assigned creatives with an active network
    has_network = AdNetwork.objects.filter(is_enabled=True, is_deleted=False).exists()

    creative_html = ""
    if has_network:
        assignments = list(
            PlacementAssignment.objects.filter(
                placement=placement,
                is_active=True,
                is_enabled=True,
                creative__is_active=True,
                creative__is_enabled=True,
            )
            .select_related("creative")
            .only(
                "weight",
                "creative__html",
                "creative__html_code",
                "creative__image_url",
                "creative__click_url",
                "creative__creative_type",
                "creative__script_code",
            )
        )
        if assignments:
            chosen = _weighted_pick(assignments)
            creative_html = _render_creative(chosen.creative)  # type: ignore[attr-defined]

    if creative_html:
        return mark_safe(  # noqa: S308 — admin-controlled placement codes
            f'<div class="ad-slot ad-slot--{slot_code} {css_class}" '
            f'data-slot="{slot_code}">{creative_html}</div>'
        )

    # Placeholder
    return mark_safe(_render_placeholder(slot_code, placement.name, css_class))  # noqa: S308


def _weighted_pick(assignments: list) -> object:  # type: ignore[type-arg]
    """Weighted random pick from PlacementAssignment list."""
    weights = [a.weight for a in assignments]
    return random.choices(assignments, weights=weights, k=1)[0]  # noqa: S311


def _render_creative(creative: object) -> str:  # type: ignore[type-arg]
    """Render a single AdCreative to HTML string."""
    from django.utils.html import escape

    ct = getattr(creative, "creative_type", "")
    html = getattr(creative, "html", "") or getattr(creative, "html_code", "")
    if ct == "html" and html:
        return html  # Admin-authored HTML — trusted
    if ct == "script":
        script = getattr(creative, "script_code", "")
        if script:
            return script
    if ct == "banner":
        img = getattr(creative, "image_url", "")
        click = getattr(creative, "click_url", "")
        if img:
            alt = escape(getattr(creative, "name", "Ad"))
            if click:
                return (
                    f'<a href="{escape(click)}" target="_blank" rel="noopener sponsored">'
                    f'<img src="{escape(img)}" alt="{alt}" class="w-full rounded">'
                    f"</a>"
                )
            return f'<img src="{escape(img)}" alt="{alt}" class="w-full rounded">'
    return ""


def _render_placeholder(slot_code: str, name: str, css_class: str) -> str:
    """Render a themed placeholder box for an empty ad slot."""
    w, h = SLOT_SIZES.get(slot_code, ("100%", "120px"))
    label = random.choice(_PLACEHOLDER_LABELS)  # noqa: S311
    return (
        f'<div class="ad-placeholder ad-placeholder--{slot_code} {css_class}" '
        f'data-slot="{slot_code}" '
        f'style="width:{w};min-height:{h};" '
        f'title="{name}">'
        f"<div "
        f'style="width:100%;height:100%;min-height:{h};display:flex;flex-direction:column;'
        f"align-items:center;justify-content:center;gap:0.5rem;"
        f"border:1px dashed var(--color-border);border-radius:0.75rem;"
        f"background:var(--color-bg-secondary);color:var(--color-text-muted);"
        f'font-size:0.75rem;opacity:0.6;">'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" '
        f'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" '
        f'stroke-linejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"/>'
        f'<path d="M2 10h20"/></svg>'
        f"<span>{label}</span>"
        f"</div>"
        f"</div>"
    )
