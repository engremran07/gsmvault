"""
multi_source.py — Concurrent multi-source device data orchestrator.

Strategy: "Swarm Scrape" — instead of hammering one site, distribute
load across *all* registered spec sources simultaneously. Each source
gets its own FetchChain and rate state, so a ban on GSMArena doesn't
stop us from pulling brands/models/chipsets from DeviceSpecifications,
PhoneArena, Kimovil, 91mobiles, etc.

Because our goal is *structured data* (brands, models, variants,
chipsets) — NOT full reviews — we can:

1. **Prioritise lightweight pages** — brand/model listing pages are
   small and fast; we skip heavy detail pages when possible.
2. **Cross-reference** — if 3+ sources agree on a model name or chipset,
   we mark it as high-confidence, reducing the need for manual review.
3. **Stagger per-site** — each source has its own delay timer so no
   single site sees more than 1 request per N seconds.
4. **Proxy-rotate per-site** — the shared ProxyPool assigns different
   IPs to different source workers.
5. **Merge-deduplicate** — all sources feed into a unified record set,
   normalised by brand+model+variant key.

This module does NOT touch the Django ORM or models — it yields raw
dicts that the calling service pipes into GSMArenaIngestor or the
IngestionJob approval workflow.
"""

from __future__ import annotations

import hashlib
import logging
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from typing import Any

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Normalisation helpers — key to deduplication across sources
# ---------------------------------------------------------------------------

_WS = re.compile(r"\s+")
_NON_ALNUM = re.compile(r"[^a-z0-9 ]")


def _normalise(text: str) -> str:
    """Lowercase, strip non-alphanum, collapse whitespace."""
    return _WS.sub(" ", _NON_ALNUM.sub("", text.lower())).strip()


def _device_fingerprint(brand: str, model: str) -> str:
    """Deterministic key for dedup: md5(normalised brand + model)."""
    raw = f"{_normalise(brand)}|{_normalise(model)}"
    return hashlib.md5(raw.encode()).hexdigest()  # noqa: S324


# ---------------------------------------------------------------------------
# Per-source worker
# ---------------------------------------------------------------------------


@dataclass
class SourceWorkerResult:
    """Result from one source worker."""

    source_slug: str
    source_name: str
    brands_found: int = 0
    devices_found: int = 0
    errors: list[str] = field(default_factory=list)
    records: list[dict[str, Any]] = field(default_factory=list)
    elapsed_seconds: float = 0.0
    was_banned: bool = False


# Brand-listing URL patterns per source (best-effort — not all sources
# have a single brands page; those that do get scraped in phase 1)
_BRAND_LIST_URLS: dict[str, str] = {
    "gsmarena": "https://www.gsmarena.com/makers.php3",
    "devicespecifications": "https://www.devicespecifications.com/en/brand",
    "phonearena": "https://www.phonearena.com/phones/manufacturers",
    "gsmchoice": "https://www.gsmchoice.com/en/brands/",
    "kimovil": "https://www.kimovil.com/en/brands",
    "phonedb": "https://phonedb.net/index.php?m=device&s=brand_list",
    "91mobiles": "https://www.91mobiles.com/brand",
    "smartprix": "https://www.smartprix.com/mobiles/brand",
    "fonearena": "https://www.fonearena.com/phones/manufacturers",
}

# Regex patterns for extracting brand links — per source, compiled lazily
_BRAND_PARSERS: dict[str, re.Pattern[str]] = {}


def _get_brand_parser(slug: str) -> re.Pattern[str]:
    """Return compiled regex for extracting brand links from a source HTML."""
    if slug not in _BRAND_PARSERS:
        patterns: dict[str, str] = {
            "gsmarena": (
                r'<a\s+href="([a-z0-9_-]+-phones-\d+\.php)"[^>]*>'
                r"([^<]+?)(?:<br|<span)"
            ),
            "devicespecifications": (
                r'<a\s+href="(/en/brand/[^"]+)"[^>]*>\s*'
                r"<[^>]+>\s*([^<]+?)\s*</"
            ),
            "phonearena": (
                r'<a\s+href="(/phones/[^"]*manufacturer[^"]*)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "gsmchoice": (
                r'<a\s+href="(/en/catalogue/[a-z0-9_-]+/)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "kimovil": (
                r'<a\s+href="(/en/where-to-buy-[^"]+)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "phonedb": (
                r'<a\s+href="(/index\.php\?m=device&s=brand&id=[^"]+)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "91mobiles": (
                r'<a\s+href="(https?://www\.91mobiles\.com/[a-z0-9-]+-brand)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "smartprix": (
                r'<a\s+href="(/mobiles/[a-z0-9-]+-brand)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "fonearena": (
                r'<a\s+href="(/phones/[a-z0-9_-]+)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
        }
        pattern = patterns.get(slug, r'<a\s+href="([^"]+)"[^>]*>([^<]+?)</a>')
        _BRAND_PARSERS[slug] = re.compile(pattern, re.IGNORECASE)
    return _BRAND_PARSERS[slug]


def _parse_brands_generic(html: str, slug: str, base_url: str) -> list[dict[str, str]]:
    """
    Extract brand entries from any source's brand listing page.

    Returns list of {"name": ..., "slug": ..., "url": ...} dicts.
    """
    parser = _get_brand_parser(slug)
    brands: list[dict[str, str]] = []
    seen_slugs: set[str] = set()

    for match in parser.finditer(html):
        href = match.group(1).strip()
        name = match.group(2).strip()
        if not name or len(name) < 2:
            continue

        brand_slug = _normalise(name).replace(" ", "_")
        if brand_slug in seen_slugs:
            continue
        seen_slugs.add(brand_slug)

        # Resolve relative URLs
        if href.startswith("/"):
            url = f"{base_url.rstrip('/')}{href}"
        elif href.startswith("http"):
            url = href
        else:
            url = f"{base_url.rstrip('/')}/{href}"

        brands.append({"name": name, "slug": brand_slug, "url": url})

    return brands


def _scrape_single_source(
    source_slug: str,
    source_name: str,
    base_url: str,
    proxy_pool: Any | None,
    cancel_check: Any | None,
    per_site_delay: float,
    brand_limit: int,
) -> SourceWorkerResult:
    """
    Worker: scrape one source for brand/model listings.

    Each worker creates its own FetchChain so rate states are independent.
    This means a ban on source A doesn't affect fetching from source B.
    """
    from .fetch_methods import FetchChain

    result = SourceWorkerResult(source_slug=source_slug, source_name=source_name)
    t0 = time.monotonic()

    brand_list_url = _BRAND_LIST_URLS.get(source_slug)
    if not brand_list_url:
        result.errors.append(f"No brand list URL configured for {source_slug}")
        result.elapsed_seconds = time.monotonic() - t0
        return result

    # Each source gets its own chain → independent rate/ban tracking
    chain = FetchChain(proxy_pool=proxy_pool)
    consecutive_bans = 0  # for exponential backoff

    try:
        # PHASE 1: Fetch the brand listing page
        logger.info("MultiSource[%s]: fetching brand list", source_name)
        brands_page = chain.fetch(brand_list_url)

        if not brands_page.html or brands_page.is_banned:
            result.was_banned = brands_page.is_banned
            result.errors.append(
                f"Could not fetch brand list (banned={brands_page.is_banned})"
            )
            result.elapsed_seconds = time.monotonic() - t0
            return result

        brands = _parse_brands_generic(brands_page.html, source_slug, base_url)
        result.brands_found = len(brands)
        logger.info(
            "MultiSource[%s]: %d brands discovered",
            source_name,
            len(brands),
        )

        if not brands:
            result.elapsed_seconds = time.monotonic() - t0
            return result

        # PHASE 2: For each brand, fetch the device listing page
        for brand_info in brands[:brand_limit]:
            if cancel_check and cancel_check():
                logger.info("MultiSource[%s]: cancelled", source_name)
                break

            # Per-site delay + exponential backoff on consecutive bans
            backoff = per_site_delay * (2**consecutive_bans)
            backoff = min(backoff, 60.0)  # cap at 60 seconds
            time.sleep(backoff)

            brand_url = brand_info["url"]
            brand_name = brand_info["name"]

            listing = chain.fetch(brand_url)
            if not listing.html or listing.is_banned:
                if listing.is_banned:
                    result.was_banned = True
                    consecutive_bans += 1
                    if chain.rate_state.ban_count >= 3:
                        logger.warning(
                            "MultiSource[%s]: too many bans, stopping",
                            source_name,
                        )
                        break
                continue

            # Successful fetch — reset consecutive ban counter
            consecutive_bans = 0

            # Extract model names from the listing page (generic extraction)
            models = _extract_models_from_listing(
                listing.html, brand_name, source_slug, base_url
            )

            for model in models:
                result.records.append(
                    {
                        "brand": brand_name,
                        "brand_slug": brand_info["slug"],
                        "model_name": model["name"],
                        "source": source_slug,
                        "source_url": model.get("url", ""),
                        "image_url": model.get("image_url", ""),
                        "fingerprint": _device_fingerprint(brand_name, model["name"]),
                    }
                )
                result.devices_found += 1

    except Exception as exc:
        logger.exception("MultiSource[%s]: error: %s", source_name, exc)
        result.errors.append(str(exc))

    result.elapsed_seconds = time.monotonic() - t0
    logger.info(
        "MultiSource[%s]: done — %d brands, %d devices in %.1fs%s",
        source_name,
        result.brands_found,
        result.devices_found,
        result.elapsed_seconds,
        " (BANNED)" if result.was_banned else "",
    )
    return result


# ---------------------------------------------------------------------------
# Generic model extraction from listing pages
# ---------------------------------------------------------------------------

# Common patterns for device links across sites
_MODEL_PATTERNS: dict[str, re.Pattern[str]] = {}


def _get_model_parser(slug: str) -> re.Pattern[str]:
    """Return a regex for extracting model entries from listing HTML."""
    if slug not in _MODEL_PATTERNS:
        patterns: dict[str, str] = {
            "gsmarena": (
                r'<a\s+href="([a-z0-9_-]+-\d+\.php)"[^>]*>'
                r".*?<(?:strong|span)[^>]*>([^<]+?)</(?:strong|span)>"
            ),
            "devicespecifications": (
                r'<a\s+href="(/en/model/[^"]+)"[^>]*>\s*([^<]+?)\s*</a>'
            ),
            "phonearena": (
                r'<a\s+href="(/phones/[^"]+)"[^>]*>\s*'
                r"(?:<[^>]*>)*\s*([^<]+?)\s*</a>"
            ),
            "gsmchoice": (
                r'<a\s+href="(/en/catalogue/[^/"]+/[^"]+)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "kimovil": (
                r'<a\s+href="(/en/where-to-buy-[^"]+)"[^>]*>\s*'
                r"([^<]+?)\s*</a>"
            ),
            "phonedb": (
                r'<a\s+href="(/index\.php\?m=device&s=specifications&id=[^"]+)"'
                r"[^>]*>\s*([^<]+?)\s*</a>"
            ),
            "91mobiles": (
                r'<a\s+href="(https?://www\.91mobiles\.com/[^"]+)"[^>]*>\s*'
                r"<[^>]*>\s*([^<]+?)\s*</[^>]*>\s*</a>"
            ),
            "smartprix": (
                r'<a\s+href="(/mobiles/[^"]+)"[^>]*>\s*'
                r"<[^>]*>\s*([^<]+?)\s*</[^>]*>\s*</a>"
            ),
            "fonearena": (
                r'<a\s+href="(/phones/[^"]+)"[^>]*>\s*'
                r"<[^>]*>\s*([^<]+?)\s*</[^>]*>\s*</a>"
            ),
        }
        pattern = patterns.get(slug, r'<a\s+href="([^"]+)"[^>]*>([^<]+?)</a>')
        _MODEL_PATTERNS[slug] = re.compile(pattern, re.IGNORECASE | re.DOTALL)
    return _MODEL_PATTERNS[slug]


def _extract_models_from_listing(
    html: str, brand: str, source_slug: str, base_url: str
) -> list[dict[str, str]]:
    """Extract model entries from a brand's device listing page."""
    parser = _get_model_parser(source_slug)
    models: list[dict[str, str]] = []
    seen: set[str] = set()

    for match in parser.finditer(html):
        href = match.group(1).strip()
        name = match.group(2).strip()

        if not name or len(name) < 3:
            continue

        # Skip navigation / non-device links
        lower_name = name.lower()
        if any(
            skip in lower_name
            for skip in ("home", "brands", "compare", "news", "review", "login")
        ):
            continue

        # Deduplicate within this page
        norm_name = _normalise(name)
        if norm_name in seen:
            continue
        seen.add(norm_name)

        # Resolve URL
        if href.startswith("/"):
            url = f"{base_url.rstrip('/')}{href}"
        elif href.startswith("http"):
            url = href
        else:
            url = f"{base_url.rstrip('/')}/{href}"

        models.append({"name": name, "url": url})

    return models


# ---------------------------------------------------------------------------
# Multi-source orchestrator
# ---------------------------------------------------------------------------


@dataclass
class MultiSourceResult:
    """Aggregate result from the multi-source swarm scrape."""

    total_brands: int = 0
    total_devices: int = 0
    unique_devices: int = 0
    sources_attempted: int = 0
    sources_succeeded: int = 0
    sources_banned: int = 0
    elapsed_seconds: float = 0.0
    per_source: list[SourceWorkerResult] = field(default_factory=list)
    merged_records: list[dict[str, Any]] = field(default_factory=list)
    cross_referenced: int = 0  # devices confirmed by 2+ sources


def run_multi_source_scrape(
    *,
    source_slugs: list[str] | None = None,
    max_workers: int = 4,
    per_site_delay: float = 5.0,
    brand_limit: int = 30,
    cancel_check: Any | None = None,
    proxy_pool: Any | None = None,
    use_health_tracking: bool = True,
) -> MultiSourceResult:
    """
    Scrape multiple sources concurrently for brand/model data.

    Each source runs in its own thread with its own FetchChain instance.
    This means:
      - Independent rate limiting per source
      - A ban on GSMArena doesn't stop DeviceSpecifications
      - Cross-referencing finds high-confidence records

    Health-aware source selection:
      - Sources that recently got banned enter a cooldown period
      - Healthy sources are prioritised by tier and recency
      - Per-source results are reported to the health tracker

    Args:
        source_slugs: Which sources to scrape. None = all English sources.
        max_workers: Thread pool size (capped by source count).
        per_site_delay: Seconds between requests TO THE SAME site.
        brand_limit: Max brands to crawl per source.
        cancel_check: Callable that returns True to stop early.
        proxy_pool: Optional ProxyPool instance for IP rotation.
        use_health_tracking: Whether to use the health tracker for
            source selection and result reporting. Default True.

    Returns:
        MultiSourceResult with per-source details and merged records.
    """
    from .source_registry import (
        SpecSource,
        get_enabled_sources,
        get_source,
        source_health_tracker,
    )

    t0 = time.monotonic()
    result = MultiSourceResult()

    # Select sources
    if source_slugs:
        raw_sources: list[SpecSource | None] = [get_source(s) for s in source_slugs]
        sources: list[SpecSource] = [s for s in raw_sources if s is not None]
    else:
        # Default: all enabled English sources (no translation needed)
        sources = [s for s in get_enabled_sources() if not s.needs_translation]

    # Apply health-aware filtering: skip sources in cooldown, sort by health
    if use_health_tracking and sources:
        pre_count = len(sources)
        sources = source_health_tracker.get_healthy_sources(sources)
        skipped = pre_count - len(sources)
        if skipped:
            logger.info(
                "MultiSource: %d/%d sources skipped (in cooldown)",
                skipped,
                pre_count,
            )

    if not sources:
        logger.warning("MultiSource: no sources selected")
        return result

    result.sources_attempted = len(sources)
    effective_workers = min(max_workers, len(sources))

    logger.info(
        "MultiSource: starting swarm scrape — %d sources, %d workers, "
        "%.1fs per-site delay, %d brand limit",
        len(sources),
        effective_workers,
        per_site_delay,
        brand_limit,
    )

    # Launch one thread per source — each fully independent
    source_results: list[SourceWorkerResult] = []

    with ThreadPoolExecutor(max_workers=effective_workers) as executor:
        future_to_source = {}
        for source in sources:
            future = executor.submit(
                _scrape_single_source,
                source_slug=source.slug,
                source_name=source.name,
                base_url=source.base_url,
                proxy_pool=proxy_pool,
                cancel_check=cancel_check,
                per_site_delay=per_site_delay,
                brand_limit=brand_limit,
            )
            future_to_source[future] = source.name

        for future in as_completed(future_to_source):
            source_name = future_to_source[future]
            try:
                worker_result = future.result()
                source_results.append(worker_result)
            except Exception as exc:
                logger.exception("MultiSource: %s worker crashed: %s", source_name, exc)
                source_results.append(
                    SourceWorkerResult(
                        source_slug="?",
                        source_name=source_name,
                        errors=[f"Worker crash: {exc}"],
                    )
                )

    # Aggregate results + report to health tracker
    for sr in source_results:
        result.total_brands += sr.brands_found
        result.total_devices += sr.devices_found
        if sr.devices_found > 0:
            result.sources_succeeded += 1
        if sr.was_banned:
            result.sources_banned += 1

        # Report health events
        if use_health_tracking:
            if sr.was_banned:
                source_health_tracker.record_ban(sr.source_slug)
            elif sr.devices_found > 0:
                source_health_tracker.record_success(
                    sr.source_slug, devices_found=sr.devices_found
                )

    result.per_source = source_results

    # Merge and cross-reference
    result.merged_records, result.cross_referenced = _merge_and_crossref(source_results)
    result.unique_devices = len(result.merged_records)
    result.elapsed_seconds = time.monotonic() - t0

    logger.info(
        "MultiSource: DONE — %d unique devices (%d cross-referenced) from "
        "%d/%d sources in %.1fs",
        result.unique_devices,
        result.cross_referenced,
        result.sources_succeeded,
        result.sources_attempted,
        result.elapsed_seconds,
    )

    return result


# ---------------------------------------------------------------------------
# Cross-referencing and merge logic
# ---------------------------------------------------------------------------


def _merge_and_crossref(
    source_results: list[SourceWorkerResult],
) -> tuple[list[dict[str, Any]], int]:
    """
    Merge records from all sources by device fingerprint.

    When 2+ sources agree on the same brand+model, the record gets a
    higher confidence score and is marked as cross-referenced.

    Returns:
        (merged_records, cross_referenced_count)
    """
    # Group by fingerprint
    fingerprint_map: dict[str, list[dict[str, Any]]] = {}

    for sr in source_results:
        for record in sr.records:
            fp = record.get("fingerprint", "")
            if not fp:
                continue
            if fp not in fingerprint_map:
                fingerprint_map[fp] = []
            fingerprint_map[fp].append(record)

    merged: list[dict[str, Any]] = []
    cross_referenced = 0

    for _fp, records in fingerprint_map.items():
        # Pick the "best" record (prefer higher quality tier sources)
        source_order = ["gsmarena", "phonearena", "devicespecifications", "kimovil"]
        best = records[0]
        for preferred_slug in source_order:
            for r in records:
                if r.get("source") == preferred_slug:
                    best = r
                    break

        # Collect all source URLs for reference
        sources_seen = list({r["source"] for r in records})
        confidence = min(len(sources_seen), 5) / 5.0  # 0.2–1.0

        merged_record = {
            **best,
            "sources": sources_seen,
            "source_count": len(sources_seen),
            "confidence": round(confidence, 2),
            "cross_referenced": len(sources_seen) >= 2,
        }

        if len(sources_seen) >= 2:
            cross_referenced += 1

        merged.append(merged_record)

    # Sort: cross-referenced first, then by brand/model
    merged.sort(
        key=lambda r: (
            -r.get("source_count", 0),
            r.get("brand", ""),
            r.get("model_name", ""),
        )
    )

    return merged, cross_referenced
