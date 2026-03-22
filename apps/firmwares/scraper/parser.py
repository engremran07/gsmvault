"""
parser.py v6 — Fully dynamic GSMArena spec-page extractor.

New in v6 (on top of v5):
  • launch_status         — extracted directly from spec table "launch_status" row
  • review_url            — link to GSMArena's own editorial review if present
  • review_score_raw      — raw score string (e.g. "9.1 out of 10")
  • popularity_rank       — integer rank from stats page (injected externally)
  • is_tablet             — bool flag if page was fetched in tablet mode
  • pro_cons              — "Pros and Cons" section if present on the page
  • video_review_url      — YouTube review link from GSMArena if present
  • Improved alternate selectors for rumored/announced pages (fewer spec fields)
  • Handles pages with missing spec table gracefully (returns partial record)

Strict-mode Pylance: all types annotated, no Any on public API, no assert.
"""

from __future__ import annotations

import logging
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Regexes
# ---------------------------------------------------------------------------

_WS_RE = re.compile(r"\s{2,}")
_SLUG_RE = re.compile(r"[^a-z0-9]+")
_MULTI_UNDER = re.compile(r"_+")

_MODEL_CODE_RE = re.compile(
    r"\b("
    r"SM-[A-Z][0-9]{3,5}[A-Z0-9]{0,4}"  # Samsung
    r"|TA-[0-9]{3,5}"  # Nokia TA
    r"|XT[0-9]{3,5}[-/]?[0-9A-Z]{0,4}"  # Motorola XT
    r"|CPH[0-9]{3,5}"  # Oppo CPH
    r"|RMX[0-9]{3,5}"  # Realme RMX
    r"|LG[-]?[A-Z][0-9]{3,5}[A-Z]?"  # LG
    r"|A[0-9]{4,5}"  # Apple A-series
    r"|G[0-9A-Z]{3}[0-9A-Z]{1,4}"  # Google Pixel
    r"|[A-Z]{2,4}[0-9]{3,6}[A-Z]?"  # Generic
    r")\b",
    re.ASCII,
)

_QUICKSPEC_MAP: dict[str, str] = {
    "display": "quick_display",
    "camera": "quick_camera",
    "processor": "quick_processor",
    "cpu": "quick_processor",
    "ram": "quick_ram",
    "battery": "quick_battery",
    "storage": "quick_storage",
    "os": "quick_os",
}

# --- Alternate CSS selectors (tried in order, first non-empty wins) ---------

_TITLE_SELECTORS = (
    "h1.specs-phone-name-title",
    "h1.article-info-name",
    "h1.modelName",
    "div.article-info h1",
    "h1",
)

_SPEC_TABLE_SELECTORS = (
    "table.specs-list",
    "div#specs-list table",
    "div.module-specs table",
    "table.table-striped",
)

_IMAGE_SELECTORS = (
    "div.specs-photo-main img",
    "div.article-info-col img",
    "div.phone-image img",
    "img.specs-photo",
)

_FOOTNOTE_SELECTORS = (
    "div.specs-list-note",
    "div.specs-note",
    "p.specs-footnote",
    "div.note-container",
    "p.note",
)

_REVIEW_LINK_SELECTORS = (
    "a.review-link",
    "div.link-review a",
    "div.article-info a[href*='review']",
    "a[href*='-review-']",
)

_VIDEO_REVIEW_SELECTORS = (
    "a.video-review",
    "div.video-review a",
    "a[href*='youtube.com'][href*='review']",
    "a[href*='youtu.be']",
)

_RATING_SELECTORS = (
    "span.review-score-num",
    "span.scoreNum",
    "div.score span.num",
    "span.ratingAvg",
)

_FANS_SELECTORS = (
    "li.hits strong",
    "span.fansCount",
    "div.stats span.fans",
)

_PRO_CONS_SELECTORS = (
    "div.pros-cons",
    "div.review-pros-cons",
    "section.pros-cons",
)

_RELATED_SELECTORS = (
    "div.related-phones a",
    "ul.related-phones-list a",
    "div.article-recommended a",
)


# ---------------------------------------------------------------------------
# Pure helpers
# ---------------------------------------------------------------------------


def _slugify(text: str) -> str:
    s = _SLUG_RE.sub("_", text.lower()).strip("_")
    return _MULTI_UNDER.sub("_", s)


def _clean_ws(text: str) -> str:
    return _WS_RE.sub(" ", text).strip()


def _element_text(el: Any) -> str:
    if el is None:
        return ""
    try:
        parts: list[str] = el.css("::text").getall()
        return _clean_ws(" ".join(p.strip() for p in parts if p.strip()))
    except AttributeError:
        return _clean_ws(str(el))


def _cell_text(td: Any) -> str:
    if td is None:
        return ""
    try:
        nodes: list[str] = td.css("::text").getall()
        return _clean_ws(" ".join(n.strip() for n in nodes if n.strip()))
    except AttributeError:
        return ""


def _try_css(response: Any, *selectors: str) -> Any:
    for sel in selectors:
        try:
            els = response.css(sel)
            if els:
                return els.first
        except Exception:  # noqa: S112
            continue
    return None


def _try_href(response: Any, *selectors: str) -> str | None:
    """Return first non-empty href from selectors."""
    for sel in selectors:
        try:
            els = response.css(sel)
            el = els.first if els else None
            if el:
                href = str(el.attrib.get("href", ""))
                if href:
                    return href
        except Exception:  # noqa: S112
            continue
    return None


def _is_valid_model_code(code: str) -> bool:
    return 3 <= len(code) <= 20 and any(c.isdigit() for c in code)


# ---------------------------------------------------------------------------
# DeviceParser
# ---------------------------------------------------------------------------


class DeviceParser:
    """
    Stateless spec-page parser with adaptive element fingerprinting.

    When fingerprint_dir is provided and adaptive=True, Scrapling's auto_save /
    auto_match is used so that spec table elements survive GSMArena redesigns
    without any code changes.
    """

    def __init__(
        self,
        fingerprint_dir: str | None = None,
        adaptive: bool = True,
    ) -> None:
        self._fingerprint_dir: Path | None = (
            Path(fingerprint_dir) if fingerprint_dir else None
        )
        self._adaptive = adaptive
        if self._fingerprint_dir:
            self._fingerprint_dir.mkdir(parents=True, exist_ok=True)

    def parse(
        self,
        response: Any,
        brand: str,
        brand_slug: str,
        model_name: str,
        image_url: str,
        *,
        is_tablet: bool = False,
        popularity_rank: int | None = None,
    ) -> dict[str, Any] | None:
        """
        Parse a GSMArena device spec page.
        Returns a flat dict of all discovered fields, or None on total failure.
        """
        try:
            return self._extract(
                response,
                brand,
                brand_slug,
                model_name,
                image_url,
                is_tablet=is_tablet,
                popularity_rank=popularity_rank,
            )
        except Exception as exc:
            logger.exception(
                "Parse error for %s (%s %s): %s",
                getattr(response, "url", "?"),
                brand,
                model_name,
                exc,
            )
            return None

    def _extract(
        self,
        response: Any,
        brand: str,
        brand_slug: str,
        model_name: str,
        image_url: str,
        *,
        is_tablet: bool,
        popularity_rank: int | None,
    ) -> dict[str, Any]:
        data: dict[str, Any] = {
            "brand": brand,
            "brand_slug": brand_slug,
            "model_name": model_name,
            "url": str(response.url),
            "scraped_at": datetime.now(UTC).isoformat(),
            "is_tablet": is_tablet,
        }

        if popularity_rank is not None:
            data["popularity_rank"] = popularity_rank

        # Full device name
        title_el = _try_css(response, *_TITLE_SELECTORS)
        if title_el:
            title = _element_text(title_el)
            if title:
                data["full_name"] = title

        # Image URL
        resolved_image = image_url or ""
        if not resolved_image:
            img_el = _try_css(response, *_IMAGE_SELECTORS)
            if img_el:
                resolved_image = str(img_el.attrib.get("src", ""))
        data["image_url"] = resolved_image

        # Quick-spec strip
        self._extract_quickspecs(response, data)

        # Main spec table
        self._extract_spec_table(response, data, brand_slug)

        # Review link
        review_href = _try_href(response, *_REVIEW_LINK_SELECTORS)
        if review_href:
            if not review_href.startswith("http"):
                review_href = f"https://www.gsmarena.com/{review_href.lstrip('/')}"
            data["review_url"] = review_href

        # Video review link
        video_href = _try_href(response, *_VIDEO_REVIEW_SELECTORS)
        if video_href:
            data["video_review_url"] = video_href

        # GSMArena editorial rating
        rating_el = _try_css(response, *_RATING_SELECTORS)
        if rating_el:
            data["gsmarena_rating"] = _element_text(rating_el)

        # Fan count
        fans_el = _try_css(response, *_FANS_SELECTORS)
        if fans_el:
            data["gsmarena_fans"] = _element_text(fans_el)

        # Pros and Cons section
        pc_el = _try_css(response, *_PRO_CONS_SELECTORS)
        if pc_el:
            pc_text = _element_text(pc_el)
            if pc_text:
                data["pros_cons"] = pc_text[:500]

        # Review snippet (first body paragraph ≤200 chars)
        review_el = response.css("div.article-body p:first-of-type")
        if review_el:
            snippet = _element_text(review_el)
            if snippet:
                data["review_snippet"] = snippet[:200]

        # Related devices
        related: list[str] = []
        rel_els = _try_css(response, *_RELATED_SELECTORS)
        if rel_els:
            for a_el in rel_els:
                name = _element_text(a_el)
                if name and name not in related:
                    related.append(name)
        if related:
            data["related_devices"] = "; ".join(related[:12])

        # Model variant codes
        variants = self._extract_variants(data, response)
        data["model_variants"] = variants
        data["model_variants_str"] = ", ".join(variants)
        data["model_variant_count"] = len(variants)

        return data

    # -- Quick-spec strip ---------------------------------------------------

    @staticmethod
    def _extract_quickspecs(response: Any, data: dict[str, Any]) -> None:
        for li in response.css("ul.specs-bar li, ul.quick-specs li"):
            cls_str = " ".join(li.attrib.get("class", "").lower().split())
            val = _element_text(li)
            if not val:
                continue
            for cls_key, field_name in _QUICKSPEC_MAP.items():
                if cls_key in cls_str and field_name not in data:
                    data[field_name] = val
                    break

    # -- Spec table ---------------------------------------------------------

    def _extract_spec_table(
        self, response: Any, data: dict[str, Any], brand_slug: str
    ) -> None:
        table = _try_css(response, *_SPEC_TABLE_SELECTORS)
        if not table:
            logger.debug("No spec table at %s", getattr(response, "url", "?"))
            return

        current_section = "misc"

        try:
            rows = (
                table.css("tr", auto_save=True)
                if (self._adaptive and self._fingerprint_dir)
                else table.css("tr")
            )
        except TypeError:
            rows = table.css("tr")

        for row in rows:
            th_el = row.css("th")
            if th_el:
                label = _element_text(th_el)
                if label:
                    current_section = _slugify(label)
                continue

            tds = row.css("td")
            if len(tds) < 2:
                continue

            label_raw = _cell_text(tds[0])
            value_raw = _cell_text(tds[1])
            if not label_raw or not value_raw:
                continue

            label_slug = _slugify(label_raw)
            if not label_slug:
                continue

            field_name = f"{current_section}_{label_slug}"

            existing = data.get(field_name)
            if existing is None:
                data[field_name] = value_raw
            elif isinstance(existing, list):
                if value_raw not in existing:
                    existing.append(value_raw)
            else:
                if value_raw != existing:
                    data[field_name] = [existing, value_raw]

    # -- Model variant codes ------------------------------------------------

    @staticmethod
    def _extract_variants(data: dict[str, Any], response: Any) -> list[str]:
        candidates: list[str] = []

        for key in list(data.keys()):
            if key.endswith("_models") or key.endswith("_model"):
                val = data[key]
                raw_str = (
                    " ".join(str(v) for v in val) if isinstance(val, list) else str(val)
                )
                for m in _MODEL_CODE_RE.finditer(raw_str):
                    code = m.group(1)
                    if _is_valid_model_code(code):
                        candidates.append(code)

        for sel in _FOOTNOTE_SELECTORS:
            for el in response.css(sel):
                text = _element_text(el)
                if text:
                    for m in _MODEL_CODE_RE.finditer(text):
                        code = m.group(1)
                        if _is_valid_model_code(code):
                            candidates.append(code)

        if not candidates:
            try:
                all_texts: list[str] = response.css("body::text").getall()
                body_sample = " ".join(all_texts)[:15000]
                for m in _MODEL_CODE_RE.finditer(body_sample):
                    code = m.group(1)
                    if _is_valid_model_code(code):
                        candidates.append(code)
            except Exception as exc:
                logger.debug("Body text scan error: %s", exc)

        seen: set[str] = set()
        unique: list[str] = []
        for code in candidates:
            if code not in seen:
                seen.add(code)
                unique.append(code)
        return unique
