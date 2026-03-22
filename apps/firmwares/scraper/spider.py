"""
spider.py v6 — GSMArena Ultimate Spider.

Three crawl strategies, all wired:

  brand_walk      — makers.php3 → brand listing pages → device pages.
  search_targeted — GSMArena Phone Finder (results.php3) → device pages.
                    Brand IDs auto-discovered from makers.php3 first.
  rumor_mill      — rumored.php3 → device pages (announced/upcoming feed).
  hybrid          — brand_walk + search_targeted in one run; dedup prevents
                    duplicate device page requests.

New in v6:
  • parse_search_results() — handles results.php3 pagination (same card CSS)
  • parse_rumor_mill()     — handles rumored.php3 alternate layout
  • _fetch_popularity_ranking() — parses stats.php3 for brand popularity order
  • CrawlJob integration   — spider.__init__ accepts optional CrawlJob; all
    per-brand limits come from job.brand_limit(slug) or cfg.brand_limit(slug)
  • brand_id discovery     — makers.php3 HTML used to populate
    SearchFilters.brand_ids before building the search URL
  • Strategy dispatch      — start_requests() routes to correct first URL
    based on cfg.crawl_strategy / job.strategy

Session routing:
  "fast"    → FetcherSession(impersonate="chrome")  — listings, search results
  "stealth" → AsyncStealthySession(headless=True)   — device spec pages

Strict-mode Pylance: full annotations, no assert, no bare except.
"""

from __future__ import annotations

import asyncio
import logging
import re
import time
from collections.abc import AsyncGenerator
from pathlib import Path
from typing import Any

from scrapling.engines.toolbelt.proxy_rotation import (  # type: ignore[import-untyped]
    ProxyRotator,
)
from scrapling.fetchers import (  # type: ignore[import-untyped]
    AsyncStealthySession,
    FetcherSession,
)
from scrapling.spiders import Request, Response, Spider  # type: ignore[import-untyped]

from .crawl_job import (
    STRATEGY_HYBRID,
    STRATEGY_RUMOR_MILL,
    STRATEGY_SEARCH_TARGETED,
    CrawlJob,
    SearchFilters,
    discover_brand_ids,
)
from .parser import DeviceParser, _element_text
from .pipeline import OutputPipeline
from .settings import Settings

logger = logging.getLogger(__name__)

BASE_URL = "https://www.gsmarena.com"
BRANDS_URL = f"{BASE_URL}/makers.php3"
RUMORED_URL = f"{BASE_URL}/rumored.php3"
STATS_URL = f"{BASE_URL}/stats.php3"

SID_FAST = "fast"
SID_STEALTH = "stealth"

PRIORITY_STATS = 25
PRIORITY_BRANDS = 20
PRIORITY_LISTING = 15
PRIORITY_SEARCH = 12
PRIORITY_DEVICE = 5

_BAN_CODES: frozenset[int] = frozenset({403, 429, 503, 999})
_BAN_SIGNALS: tuple[str, ...] = (
    "access denied",
    "you have been blocked",
    "cloudflare",
    "please verify you are a human",
    "captcha",
    "too many requests",
    "rate limit exceeded",
    "unusual traffic",
    "error 1020",
    "bot detection",
    "challenge-platform",
    "cf-browser-verification",
    "ddos protection by",
    "enable javascript and cookies",
    "automated access",
    "suspicious activity",
)

_DEVICE_ID_RE: re.Pattern[str] = re.compile(r"-(\d+)\.php")

# ---------------------------------------------------------------------------
# Sampling helpers
# ---------------------------------------------------------------------------


def _device_id(url: str) -> int:
    m = _DEVICE_ID_RE.search(url)
    return int(m.group(1)) if m else 0


def _sample_cards(cards: list[dict[str, str]], n: int) -> list[dict[str, str]]:
    """Oldest n + centre n + newest n. Deduplicates; returns all if ≤ 3n."""
    if len(cards) <= n * 3:
        return list(cards)

    seen: set[str] = set()
    result: list[dict[str, str]] = []

    def _add(batch: list[dict[str, str]]) -> None:
        for c in batch:
            if c["url"] not in seen:
                seen.add(c["url"])
                result.append(c)

    total = len(cards)
    mid = total // 2
    half_n = max(n // 2, 1)

    _add(cards[:n])
    _add(cards[max(0, mid - half_n) : mid + half_n])
    _add(cards[max(0, total - n) :])
    return result


# ---------------------------------------------------------------------------
# GSMArenaSpider
# ---------------------------------------------------------------------------

_YieldType = Request | dict[str, Any]


class GSMArenaSpider(Spider):
    """
    God-mode GSMArena spider supporting all three crawl strategies.
    Accepts an optional CrawlJob for full per-brand configurability.
    """

    name: str = "gsmarena_v6"
    start_urls: list[str] = []

    concurrent_requests: int = 4
    download_delay: float = 4.0

    def __init__(
        self,
        cfg: Settings,
        pipeline: OutputPipeline,
        job: CrawlJob | None = None,
    ) -> None:
        self._cfg = cfg
        self._pipeline = pipeline
        self._job = job
        self._parser = DeviceParser(
            fingerprint_dir=cfg.fingerprint_dir,
            adaptive=cfg.adaptive_fingerprint,
        )

        # Derive effective strategy
        if job:
            self._strategy = job.strategy
        else:
            self._strategy = cfg.crawl_strategy

        self._ban_count: int = 0
        self._total_enqueued: int = 0
        self._t0: float = time.monotonic()

        self._brand_cards: dict[str, list[dict[str, str]]] = {}
        self._attempt: dict[str, int] = {}
        self._brand_id_map: dict[str, int] = {}  # slug → numeric GSMArena ID
        self._popularity: dict[str, int] = {}  # slug → rank (1 = most popular)
        self._search_done: bool = False  # flag for hybrid strategy

        # Push Scrapling class-level attrs BEFORE super().__init__
        self.__class__.concurrent_requests = cfg.concurrent_requests
        self.__class__.download_delay = cfg.download_delay

        self._stealth_dir = str(Path(cfg.crawl_dir) / "stealth_profile")
        Path(self._stealth_dir).mkdir(parents=True, exist_ok=True)

        super().__init__(crawldir=cfg.crawl_dir)

    # -- Session registration -----------------------------------------------

    def configure_sessions(self, manager: Any) -> None:
        rotator = (
            ProxyRotator(self._cfg.proxies)  # type: ignore[arg-type]
            if self._cfg.proxies
            else None
        )
        if rotator:
            logger.info("ProxyRotator: %d proxies", len(self._cfg.proxies))

        # Session 1: curl_cffi with Chrome impersonation (fast, low resource)
        fast = FetcherSession(
            impersonate="chrome",
            follow_redirects=True,
            retries=self._cfg.max_retries,
            proxy_rotator=rotator,
        )
        manager.add(SID_FAST, fast)

        # Session 2: Stealth browser (camoufox-based, highest anti-detection)
        stealth = AsyncStealthySession(
            headless=self._cfg.headless,
            network_idle=True,
            retries=self._cfg.max_retries,
            retry_delay=2,
            user_data_dir=self._stealth_dir,
            proxy_rotator=rotator,
        )
        manager.add(SID_STEALTH, stealth, lazy=True)

        # Session 3: curl_cffi with Firefox impersonation (alternate TLS fingerprint)
        try:
            fast_ff = FetcherSession(
                impersonate="firefox135",
                follow_redirects=True,
                retries=self._cfg.max_retries,
                proxy_rotator=rotator,
            )
            manager.add("fast_firefox", fast_ff)
            logger.info("Registered session: fast_firefox (curl_cffi/firefox135)")
        except Exception as exc:
            logger.debug("fast_firefox session not available: %s", exc)

        # Session 4: curl_cffi with Safari impersonation (Apple TLS fingerprint)
        try:
            fast_safari = FetcherSession(
                impersonate="safari184",
                follow_redirects=True,
                retries=self._cfg.max_retries,
                proxy_rotator=rotator,
            )
            manager.add("fast_safari", fast_safari)
            logger.info("Registered session: fast_safari (curl_cffi/safari184)")
        except Exception as exc:
            logger.debug("fast_safari session not available: %s", exc)

        # Session 5: Playwright-based dynamic browser — DISABLED
        # DynamicSession lacks __aexit__ causing spider crash on cleanup
        # (scrapling.spiders.session.close calls __aexit__ but DynamicSession
        #  only has __exit__). Re-enable when scrapling fixes this.
        # try:
        #     from scrapling.fetchers import DynamicSession
        #     dynamic = DynamicSession(
        #         headless=self._cfg.headless, network_idle=True,
        #         retries=self._cfg.max_retries, retry_delay=2,
        #         proxy_rotator=rotator,
        #     )
        #     manager.add("dynamic", dynamic, lazy=True)
        #     logger.info("Registered session: dynamic (Playwright)")
        # except Exception as exc:
        #     logger.debug("dynamic session not available: %s", exc)
        logger.debug("dynamic session skipped (DynamicSession __aexit__ bug)")

    # -- Lifecycle hooks ----------------------------------------------------

    async def start_requests(self) -> AsyncGenerator[Request, None]:  # type: ignore[override]
        if self._cfg.respect_robots:
            if not self._check_robots_txt():
                logger.error("robots.txt disallows crawling — exiting.")
                return

        # We ALWAYS fetch makers.php3 first:
        #   • brand_walk  → enqueue brand listing pages
        #   • search_targeted → discover brand IDs, build search URL
        #   • rumor_mill  → after makers, yield rumored.php3
        #   • hybrid      → do both brand_walk + search_targeted

        if self._strategy == STRATEGY_RUMOR_MILL:
            # For rumor mill we can skip makers entirely
            yield Request(
                url=RUMORED_URL,
                callback=self.parse_rumor_mill,
                sid=SID_STEALTH,
                priority=PRIORITY_BRANDS,
                meta={"_strategy": STRATEGY_RUMOR_MILL},
            )
        else:
            # All other strategies need the makers page
            yield Request(
                url=BRANDS_URL,
                callback=self.parse,
                sid=SID_STEALTH,
                priority=PRIORITY_BRANDS,
                meta={"_is_start": True},
            )

    async def on_start(self, resuming: bool = False) -> None:  # type: ignore[override]
        strategy_desc = self._strategy
        if self._job:
            strategy_desc += f" (job: {self._job.job_id})"
        logger.info(self._cfg.summary())
        logger.info(
            "Spider v6 starting | strategy=%s | sample=%d | adaptive=%s | resuming=%s",
            strategy_desc,
            self._cfg.sample_size,
            self._cfg.adaptive_fingerprint,
            resuming,
        )

    async def on_close(self) -> None:
        self._pipeline.finalize()
        elapsed = time.monotonic() - self._t0
        logger.info("=" * 70)
        logger.info(
            "CRAWL COMPLETE — %.1f min | strategy=%s", elapsed / 60, self._strategy
        )
        for line in self._pipeline.stats.summary(self._total_enqueued or None):
            logger.info(line)
        for line in self._pipeline.brand_progress.summary_lines():
            logger.info(line)
        logger.info("Output CSV    : %s", self._cfg.output_csv)
        logger.info("Output SQLite : %s", self._cfg.output_sqlite)
        logger.info("Output Parquet: %s", self._cfg.output_parquet)
        logger.info("=" * 70)

    async def on_error(self, request: Request, error: Exception) -> None:  # type: ignore[override]
        url = str(getattr(request, "url", "?"))
        logger.error("Request error [%s]: %s", url, error)
        attempt = self._attempt.get(url, 0) + 1
        self._attempt[url] = attempt
        brand = str((request.meta or {}).get("brand", ""))
        self._pipeline.record_failure(url, str(error), brand)
        if attempt >= self._cfg.max_retries:
            self._pipeline.record_dead_letter(url, str(error), attempt)

    async def on_scraped_item(self, item: dict[str, Any]) -> dict[str, Any] | None:  # type: ignore[override]
        written = self._pipeline.process(item)
        if written:
            n = self._pipeline.stats.total_scraped
            if n % 100 == 0:
                logger.info(
                    "✓ %d | %.2f/s | bans=%d | ETA=%s | warns=%d | dead=%d",
                    n,
                    self._pipeline.stats.rate,
                    self._ban_count,
                    self._pipeline.stats.eta(self._total_enqueued or None),
                    self._pipeline.stats.total_validation_warnings,
                    len(self._pipeline.dead_letter),
                )
        return item

    # -- Strategy: brand_walk entry point -----------------------------------

    async def parse(self, response: Response) -> AsyncGenerator[_YieldType, None]:
        """Entry: parse makers page; dispatch based on strategy."""
        if self._is_banned(response):
            logger.error("Banned on makers page — cannot continue")
            return

        try:
            " ".join(response.css("body::text").getall())
        except Exception:  # noqa: S110
            pass

        # Discover brand IDs for search_targeted / hybrid
        if self._strategy in (STRATEGY_SEARCH_TARGETED, STRATEGY_HYBRID):
            try:
                body = " ".join(
                    str(a.attrib.get("href", ""))
                    for a in response.css("div.st-text td > a")
                )
                self._brand_id_map = discover_brand_ids(body)
                logger.info(
                    "Brand ID map: %d brands discovered", len(self._brand_id_map)
                )
            except Exception as exc:
                logger.warning("Brand ID discovery failed: %s", exc)

        # Discover brand list
        brands = self._parse_brands(response)
        logger.info("Brands discovered: %d", len(brands))

        # Apply include/exclude from job or cfg.brands_filter
        if self._job:
            brand_slugs = [b["slug"] for b in brands]
            filtered_slugs = set(self._job.effective_brands(brand_slugs))
            brands = [b for b in brands if b["slug"] in filtered_slugs]
        elif self._cfg.brands_filter:
            brands = [b for b in brands if b["slug"] in self._cfg.brands_filter]
        logger.info("After filter: %d brands", len(brands))

        # Popularity sort (optional)
        if self._cfg.sort_by_popularity and self._popularity:
            brands.sort(key=lambda b: self._popularity.get(b["slug"], 9999))
            logger.info("Brands sorted by popularity rank")

        # Route based on strategy
        if self._strategy == STRATEGY_SEARCH_TARGETED:
            # Build search URL and yield it as first request
            async for req in self._yield_search_start():
                yield req
            return

        if self._strategy == STRATEGY_HYBRID:
            # Yield search start AND continue with brand walk
            async for req in self._yield_search_start():
                yield req
            # Fall through to brand walk below

        # brand_walk (and hybrid's brand walk arm)
        for brand in brands:
            self._brand_cards.setdefault(brand["slug"], [])
            sid = SID_STEALTH if self._cfg.stealth_listings else SID_FAST
            yield Request(
                url=brand["url"],
                callback=self.parse_brand_listing,
                sid=sid,
                priority=PRIORITY_LISTING,
                meta={
                    "brand": brand["name"],
                    "brand_slug": brand["slug"],
                    "page_num": 1,
                    "attempt": 0,
                },
            )

    async def _yield_search_start(
        self,
    ) -> AsyncGenerator[Request, None]:
        """Yield the first search results page based on job filters."""
        filters: SearchFilters | None = None
        if self._job and self._job.filters:
            filters = self._job.filters
        else:
            # No job / no filters → search for everything (no params)
            filters = SearchFilters()

        # Populate brand IDs from discovered map
        if filters.brand_slugs and self._brand_id_map:
            filters.brand_ids = [
                self._brand_id_map[slug]
                for slug in filters.brand_slugs
                if slug in self._brand_id_map
            ]

        url = filters.build_url(page=1)
        logger.info(
            "Search-targeted crawl: %s → %s",
            filters.describe(),
            url[:120],
        )
        yield Request(
            url=url,
            callback=self.parse_search_results,
            sid=SID_STEALTH,
            priority=PRIORITY_SEARCH,
            meta={"_filters": filters, "page_num": 1, "attempt": 0},
        )

    # -- Strategy: search_targeted ------------------------------------------

    async def parse_search_results(
        self, response: Response
    ) -> AsyncGenerator[_YieldType, None]:
        """Parse results.php3 pages — same card structure as brand listing."""
        meta: dict[str, Any] = response.meta or {}
        page_num: int = int(meta.get("page_num", 1))
        filters: SearchFilters | None = meta.get("_filters")
        attempt: int = int(meta.get("attempt", 0))

        if self._is_banned(response):
            backoff = self._cfg.backoff_delay(attempt)
            logger.warning(
                "Banned search results p%d — backoff %.1fs", page_num, backoff
            )
            self._ban_count += 1
            await asyncio.sleep(backoff)
            yield Request(
                url=str(response.url),
                callback=self.parse_search_results,
                sid=SID_STEALTH,
                priority=PRIORITY_SEARCH + 5,
                meta={**meta, "attempt": attempt + 1},
            )
            return

        # Parse device cards — same structure as brand listing
        cards = self._parse_model_cards(response, brand="", brand_slug="")
        logger.info("Search results p%d: %d devices", page_num, len(cards))

        for card in cards:
            if self._pipeline.dedup.is_seen(
                card["url"], card.get("brand", ""), card.get("model_name", "")
            ):
                continue
            self._total_enqueued += 1
            self._pipeline.dedup.mark(
                card["url"], card.get("brand", ""), card.get("model_name", "")
            )
            yield Request(
                url=card["url"],
                callback=self.parse_device,
                sid=SID_STEALTH,
                priority=PRIORITY_DEVICE,
                meta={**card, "attempt": 0},
            )

        # Check max_results limit
        max_results = filters.max_results if filters else 0
        if max_results and self._total_enqueued >= max_results:
            logger.info(
                "Search max_results=%d reached — stopping pagination", max_results
            )
            return

        # Pagination
        next_url = self._next_page(response)
        if next_url and filters:
            yield Request(
                url=next_url,
                callback=self.parse_search_results,
                sid=SID_STEALTH,
                priority=PRIORITY_SEARCH,
                meta={"_filters": filters, "page_num": page_num + 1, "attempt": 0},
            )

    # -- Strategy: rumor_mill -----------------------------------------------

    async def parse_rumor_mill(
        self, response: Response
    ) -> AsyncGenerator[_YieldType, None]:
        """Parse rumored.php3 — upcoming and announced device feed."""
        meta: dict[str, Any] = response.meta or {}
        attempt: int = int(meta.get("attempt", 0))

        if self._is_banned(response):
            backoff = self._cfg.backoff_delay(attempt)
            logger.warning("Banned on rumor mill — backoff %.1fs", backoff)
            self._ban_count += 1
            await asyncio.sleep(backoff)
            yield Request(
                url=str(response.url),
                callback=self.parse_rumor_mill,
                sid=SID_STEALTH,
                priority=PRIORITY_BRANDS + 5,
                meta={"attempt": attempt + 1},
            )
            return

        # Rumored page uses div.makers structure like brand pages, but also
        # may use article cards — try both selectors
        cards = self._parse_model_cards(response, brand="", brand_slug="")
        if not cards:
            # Fallback: rumored page sometimes uses article card structure
            cards = self._parse_article_cards(response)

        logger.info("Rumor mill: %d upcoming/rumored devices found", len(cards))

        for card in cards:
            if self._pipeline.dedup.is_seen(
                card["url"], card.get("brand", ""), card.get("model_name", "")
            ):
                continue
            self._total_enqueued += 1
            self._pipeline.dedup.mark(
                card["url"], card.get("brand", ""), card.get("model_name", "")
            )
            yield Request(
                url=card["url"],
                callback=self.parse_device,
                sid=SID_STEALTH,
                priority=PRIORITY_DEVICE,
                meta={**card, "attempt": 0, "_is_rumored": True},
            )

        # Pagination for rumored page
        next_url = self._next_page(response)
        if next_url:
            yield Request(
                url=next_url,
                callback=self.parse_rumor_mill,
                sid=SID_STEALTH,
                priority=PRIORITY_BRANDS,
                meta={"attempt": 0},
            )

    # -- Brand listing (brand_walk) -----------------------------------------

    async def parse_brand_listing(
        self, response: Response
    ) -> AsyncGenerator[_YieldType, None]:
        meta: dict[str, Any] = response.meta or {}
        brand: str = str(meta.get("brand", ""))
        slug: str = str(meta.get("brand_slug", ""))
        page_num: int = int(meta.get("page_num", 1))
        attempt: int = int(meta.get("attempt", 0))

        if self._is_banned(response):
            backoff = self._cfg.backoff_delay(attempt)
            logger.warning(
                "Banned listing [%s] p%d — backoff %.1fs", brand, page_num, backoff
            )
            self._ban_count += 1
            self._pipeline.stats.total_banned += 1
            await asyncio.sleep(backoff)
            yield Request(
                url=str(response.url),
                callback=self.parse_brand_listing,
                sid=SID_STEALTH,
                priority=PRIORITY_LISTING + 5,
                meta={**meta, "attempt": attempt + 1},
            )
            return

        new_cards = self._parse_model_cards(response, brand, slug)

        if self._cfg.sampling_enabled:
            existing = self._brand_cards.setdefault(slug, [])
            for c in new_cards:
                if not any(x["url"] == c["url"] for x in existing):
                    existing.append(c)

        next_url = self._next_page(response)
        has_next = bool(next_url) and page_num < self._cfg.max_pages_per_brand

        if has_next and next_url:
            sid = SID_STEALTH if self._cfg.stealth_listings else SID_FAST
            yield Request(
                url=next_url,
                callback=self.parse_brand_listing,
                sid=sid,
                priority=PRIORITY_LISTING,
                meta={
                    "brand": brand,
                    "brand_slug": slug,
                    "page_num": page_num + 1,
                    "attempt": 0,
                },
            )

        if self._cfg.sampling_enabled and not has_next:
            all_cards = sorted(
                self._brand_cards.get(slug, []),
                key=lambda c: _device_id(c["url"]),
            )
            selected = _sample_cards(all_cards, self._cfg.sample_size)
            logger.info(
                "[%s] sample %d of %d (n=%d)",
                brand,
                len(selected),
                len(all_cards),
                self._cfg.sample_size,
            )
            cards_to_enqueue = selected
            self._pipeline.brand_progress.set_expected(brand, len(selected))
        elif not self._cfg.sampling_enabled:
            cards_to_enqueue = new_cards
            if not has_next:
                total = self._pipeline.stats.per_brand.get(brand, 0) + len(new_cards)
                self._pipeline.brand_progress.set_expected(brand, total)
        else:
            cards_to_enqueue = []

        # Effective limit: job per-brand override → cfg global
        limit = (
            self._job.brand_limit(slug) if self._job else self._cfg.brand_limit(slug)
        )
        if limit > 0:
            already = self._pipeline.stats.per_brand.get(brand, 0)
            remaining = limit - already
            cards_to_enqueue = cards_to_enqueue[: max(0, remaining)]

        for card in cards_to_enqueue:
            if self._pipeline.dedup.is_seen(
                card["url"], card.get("brand", ""), card.get("model_name", "")
            ):
                continue
            self._total_enqueued += 1
            self._pipeline.dedup.mark(
                card["url"], card.get("brand", ""), card.get("model_name", "")
            )
            yield Request(
                url=card["url"],
                callback=self.parse_device,
                sid=SID_STEALTH,
                priority=PRIORITY_DEVICE,
                meta={**card, "attempt": 0},
            )

        logger.debug("[%s] p%d: %d enqueued", brand, page_num, len(cards_to_enqueue))

    # -- Device spec page ---------------------------------------------------

    async def parse_device(
        self, response: Response
    ) -> AsyncGenerator[_YieldType, None]:
        meta: dict[str, Any] = response.meta or {}
        brand: str = str(meta.get("brand", ""))
        slug: str = str(meta.get("brand_slug", ""))
        model_name: str = str(meta.get("model_name", ""))
        image_url: str = str(meta.get("image_url", ""))
        attempt: int = int(meta.get("attempt", 0))
        is_rumored: bool = bool(meta.get("_is_rumored", False))
        is_tablet: bool = bool(meta.get("_is_tablet", False))

        if self._is_banned(response):
            backoff = self._cfg.backoff_delay(attempt)
            logger.warning(
                "Banned device [%s] attempt=%d — backoff %.1fs",
                model_name,
                attempt,
                backoff,
            )
            self._ban_count += 1
            self._pipeline.stats.total_banned += 1
            await asyncio.sleep(backoff)

            if attempt >= self._cfg.max_retries:
                self._pipeline.record_dead_letter(
                    str(response.url), "max retries on ban", attempt
                )
                return

            yield Request(
                url=str(response.url),
                callback=self.parse_device,
                sid=SID_STEALTH,
                priority=PRIORITY_DEVICE + 10,
                meta={**meta, "attempt": attempt + 1},
            )
            return

        popularity_rank = self._popularity.get(slug) if slug else None

        record = self._parser.parse(
            response,
            brand,
            slug,
            model_name,
            image_url,
            is_tablet=is_tablet,
            popularity_rank=popularity_rank,
        )
        if record is None:
            logger.warning("Parser returned None for %s", response.url)
            self._pipeline.record_failure(
                str(response.url), "parser returned None", brand
            )
            return

        if is_rumored:
            record["_source"] = "rumor_mill"

        yield record

    # -- HTML parsing helpers -----------------------------------------------

    def _parse_brands(self, response: Response) -> list[dict[str, str]]:
        brands: list[dict[str, str]] = []
        for a in response.css("div.st-text td > a"):
            href = str(a.attrib.get("href", ""))
            m = re.match(r"^([a-z0-9_\-]+)-phones-\d+\.php", href)
            if not m:
                continue
            slug = m.group(1)
            raw_name = " ".join(a.css("::text").getall()).strip()
            name = (
                re.sub(r"\s*\d+\s*device.*$", "", raw_name, flags=re.I).strip()
                or slug.title()
            )
            brands.append(
                {
                    "slug": slug,
                    "name": name,
                    "url": f"{BASE_URL}/{href}",
                }
            )
        return brands

    def _parse_model_cards(
        self, response: Response, brand: str, brand_slug: str
    ) -> list[dict[str, str]]:
        """Parse device cards from brand listing, search results, and rumored pages."""
        cards: list[dict[str, str]] = []
        for li in response.css("div.makers ul li, div.section-body ul li"):
            a_list = li.css("a")
            a = a_list.first if a_list else None
            if not a:
                continue
            href = str(a.attrib.get("href", ""))
            if not href:
                continue
            url = href if href.startswith("http") else f"{BASE_URL}/{href}"

            name_parts = (
                a.css("strong::text").getall()
                or a.css("span::text").getall()
                or a.css("::text").getall()
            )
            model_name = " ".join(p.strip() for p in name_parts if p.strip()).strip()

            img_list = li.css("img")
            img = img_list.first if img_list else None
            image_url = str(img.attrib.get("src", "")) if img else ""

            # Try to extract brand from URL slug if not provided
            resolved_brand = brand
            resolved_slug = brand_slug
            if not resolved_brand:
                m = re.search(r"https://www\.gsmarena\.com/([a-z0-9_]+)_", url)
                if m:
                    resolved_slug = m.group(1)
                    resolved_brand = resolved_slug.title()

            cards.append(
                {
                    "url": url,
                    "brand": resolved_brand,
                    "brand_slug": resolved_slug,
                    "model_name": model_name,
                    "image_url": image_url,
                }
            )
        return cards

    def _parse_article_cards(self, response: Response) -> list[dict[str, str]]:
        """Fallback card parser for article-style pages (rumored page alt layout)."""
        cards: list[dict[str, str]] = []
        for a in response.css("article a[href*='.php'], div.article a[href*='.php']"):
            href = str(a.attrib.get("href", ""))
            if not _DEVICE_ID_RE.search(href):
                continue
            url = href if href.startswith("http") else f"{BASE_URL}/{href}"
            model_name = _element_text(a)
            if not model_name:
                continue
            cards.append(
                {
                    "url": url,
                    "brand": "",
                    "brand_slug": "",
                    "model_name": model_name,
                    "image_url": "",
                }
            )
        return cards

    def _next_page(self, response: Response) -> str | None:
        nav_list = response.css(
            "a.prevnextbutton[title='Next page'], a[title='Next page']"
        )
        nav = nav_list.first if nav_list else None
        if not nav:
            return None
        href = str(nav.attrib.get("href", ""))
        if not href or "php" not in href:
            return None
        return href if href.startswith("http") else f"{BASE_URL}/{href}"

    # -- Ban detection ------------------------------------------------------

    @staticmethod
    def _is_banned(response: Response) -> bool:
        if getattr(response, "status", 200) in _BAN_CODES:
            return True
        try:
            body = " ".join(response.css("body::text").getall()).lower()[:2000]
        except Exception:
            return False
        return any(sig in body for sig in _BAN_SIGNALS)

    async def is_blocked(self, response: Response) -> bool:  # type: ignore[override]
        """Scrapling 0.4.2 hook — delegates to static `_is_banned`."""
        return self._is_banned(response)

    # -- Robots.txt ---------------------------------------------------------

    def _check_robots_txt(self) -> bool:
        try:
            from urllib.robotparser import RobotFileParser

            rp = RobotFileParser()
            rp.set_url(f"{BASE_URL}/robots.txt")
            rp.read()
            allowed: bool = rp.can_fetch("*", BRANDS_URL)
            logger.info("robots.txt: allowed=%s", allowed)
            return allowed
        except Exception as exc:
            logger.warning("robots.txt check failed (%s) — proceeding", exc)
            return True

    # -- Popularity ranking -------------------------------------------------

    def _fetch_popularity_ranking(self) -> dict[str, int]:
        """
        Fetch stats.php3 and return slug → rank mapping.
        Called once synchronously before crawl starts if sort_by_popularity=True.
        Returns empty dict on failure (non-fatal).
        """
        try:
            from scrapling.fetchers import Fetcher  # type: ignore[import-untyped]

            page = Fetcher.get(STATS_URL)
            ranks: dict[str, int] = {}
            rank = 1
            for a in page.css("table a[href*='-phones-']"):
                href = str(a.attrib.get("href", ""))
                m = re.match(r"([a-z0-9_\-]+)-phones-\d+\.php", href)
                if m:
                    ranks[m.group(1)] = rank
                    rank += 1
            logger.info("Popularity ranking: %d brands from stats.php3", len(ranks))
            return ranks
        except Exception as exc:
            logger.warning("Popularity fetch failed: %s — using default order", exc)
            return {}
