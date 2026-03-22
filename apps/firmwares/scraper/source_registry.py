"""
source_registry.py — Multi-source site registry for device spec scraping.

Maintains a registry of device specification websites — both global and
regional — that can supplement or replace GSMArena as data sources.

Each source entry defines:
  - Base URL and spec page URL patterns
  - Language/locale (for translation needs)
  - Coverage scope: global vs. regional
  - Parser hints for extracting spec tables
  - Reliability/quality tier for prioritisation

Sources are NOT auto-scraped. They feed into the FetchChain fallback
system and the admin approval workflow. Regional sites that require
translation are flagged accordingly.
"""

from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Source Health Tracker — runtime per-source health metrics
# ---------------------------------------------------------------------------


@dataclass
class _SourceHealth:
    """Mutable health state for a single source."""

    last_success: float = 0.0  # monotonic timestamp
    last_ban: float = 0.0
    consecutive_bans: int = 0
    total_success: int = 0
    total_bans: int = 0
    total_devices_found: int = 0


class SourceHealthTracker:
    """
    In-memory tracker for per-source health metrics.

    Tracks success/ban events and provides smart source selection:
      - Sources with recent bans enter a cooldown period
      - Cooldown escalates exponentially with consecutive bans
      - Healthy sources are sorted by: tier first, then success recency

    Thread-safe — used from multi-source workers reporting results.
    """

    _BASE_COOLDOWN_SECONDS = 300  # 5 minutes base cooldown after a ban
    _MAX_COOLDOWN_SECONDS = 86400  # 24 hours max cooldown

    def __init__(self) -> None:
        self._health: dict[str, _SourceHealth] = {}
        self._lock = threading.Lock()

    def _get(self, slug: str) -> _SourceHealth:
        if slug not in self._health:
            self._health[slug] = _SourceHealth()
        return self._health[slug]

    def record_success(self, slug: str, devices_found: int = 0) -> None:
        """Record a successful scrape for a source."""
        with self._lock:
            h = self._get(slug)
            h.last_success = time.monotonic()
            h.consecutive_bans = 0
            h.total_success += 1
            h.total_devices_found += devices_found

    def record_ban(self, slug: str) -> None:
        """Record that a source banned/rate-limited us."""
        with self._lock:
            h = self._get(slug)
            h.last_ban = time.monotonic()
            h.consecutive_bans += 1
            h.total_bans += 1

    def is_in_cooldown(self, slug: str) -> bool:
        """Check if a source is in ban-cooldown (should be skipped)."""
        with self._lock:
            h = self._health.get(slug)
            if not h or h.consecutive_bans == 0:
                return False
            cooldown = min(
                self._BASE_COOLDOWN_SECONDS * (2 ** (h.consecutive_bans - 1)),
                self._MAX_COOLDOWN_SECONDS,
            )
            return (time.monotonic() - h.last_ban) < cooldown

    def get_healthy_sources(self, sources: list[SpecSource]) -> list[SpecSource]:
        """
        Filter and sort sources by health.

        Removes sources in cooldown. Sorts by: tier (ascending),
        then recency of last success (most recent first), then
        those never tried go last.
        """
        healthy = [s for s in sources if not self.is_in_cooldown(s.slug)]
        now = time.monotonic()

        def _sort_key(s: SpecSource) -> tuple[int, float]:
            with self._lock:
                h = self._health.get(s.slug)
            # Tier first (lower = better), then time-since-success (lower = better)
            recency = (now - h.last_success) if h and h.last_success else 999999.0
            return (s.quality_tier, recency)

        healthy.sort(key=_sort_key)
        return healthy

    def get_source_stats(self) -> list[dict[str, object]]:
        """Return health stats for all tracked sources (for admin display)."""
        with self._lock:
            stats: list[dict[str, object]] = []
            now = time.monotonic()
            for slug, h in sorted(self._health.items()):
                cooldown = False
                if h.consecutive_bans > 0:
                    cd_secs = min(
                        self._BASE_COOLDOWN_SECONDS * (2 ** (h.consecutive_bans - 1)),
                        self._MAX_COOLDOWN_SECONDS,
                    )
                    cooldown = (now - h.last_ban) < cd_secs

                stats.append(
                    {
                        "slug": slug,
                        "total_success": h.total_success,
                        "total_bans": h.total_bans,
                        "consecutive_bans": h.consecutive_bans,
                        "total_devices": h.total_devices_found,
                        "in_cooldown": cooldown,
                        "last_success_ago": (
                            round(now - h.last_success) if h.last_success else None
                        ),
                        "last_ban_ago": (
                            round(now - h.last_ban) if h.last_ban else None
                        ),
                    }
                )
            return stats


# Module-level singleton — persists for the lifetime of the process
source_health_tracker = SourceHealthTracker()


@dataclass(frozen=True)
class SpecSource:
    """A device specification website that can be scraped."""

    name: str
    slug: str
    base_url: str
    scope: str  # "global" or "regional"
    language: str  # ISO 639-1 code, e.g. "en", "pt", "de"
    country: str  # ISO 3166-1 alpha-2, e.g. "US", "IN", "BR"
    needs_translation: bool
    quality_tier: int  # 1 = best, 3 = lowest
    device_url_pattern: str  # Python format string with {slug} placeholder
    spec_table_selector: str  # CSS selector for the spec table container
    notes: str = ""
    enabled: bool = True


# ---------------------------------------------------------------------------
# Global sources — English, worldwide coverage
# ---------------------------------------------------------------------------

GLOBAL_SOURCES: list[SpecSource] = [
    SpecSource(
        name="GSMArena",
        slug="gsmarena",
        base_url="https://www.gsmarena.com",
        scope="global",
        language="en",
        country="US",
        needs_translation=False,
        quality_tier=1,
        device_url_pattern="https://www.gsmarena.com/{slug}.php",
        spec_table_selector="#specs-list",
        notes="Primary source. Most comprehensive mobile device database.",
    ),
    SpecSource(
        name="DeviceSpecifications",
        slug="devicespecifications",
        base_url="https://www.devicespecifications.com",
        scope="global",
        language="en",
        country="US",
        needs_translation=False,
        quality_tier=2,
        device_url_pattern="https://www.devicespecifications.com/en/model/{slug}",
        spec_table_selector=".model-information-table",
        notes="Good coverage, structured specs. Alternative when GSMArena is blocked.",
    ),
    SpecSource(
        name="PhoneArena",
        slug="phonearena",
        base_url="https://www.phonearena.com",
        scope="global",
        language="en",
        country="US",
        needs_translation=False,
        quality_tier=1,
        device_url_pattern="https://www.phonearena.com/phones/{slug}",
        spec_table_selector=".phoneFinder_mainSpecs",
        notes="High quality specs + reviews. US-focused but covers global devices.",
    ),
    SpecSource(
        name="GSMChoice",
        slug="gsmchoice",
        base_url="https://www.gsmchoice.com",
        scope="global",
        language="en",
        country="US",
        needs_translation=False,
        quality_tier=2,
        device_url_pattern="https://www.gsmchoice.com/en/catalogue/{slug}",
        spec_table_selector=".specstable",
        notes="Decent spec coverage, lighter anti-bot measures than GSMArena.",
    ),
    SpecSource(
        name="Kimovil",
        slug="kimovil",
        base_url="https://www.kimovil.com",
        scope="global",
        language="en",
        country="US",
        needs_translation=False,
        quality_tier=2,
        device_url_pattern="https://www.kimovil.com/en/where-to-buy-{slug}",
        spec_table_selector=".table-specs",
        notes="Good for pricing and availability. Multi-language support built in.",
    ),
    SpecSource(
        name="NotebookCheck",
        slug="notebookcheck",
        base_url="https://www.notebookcheck.net",
        scope="global",
        language="en",
        country="DE",
        needs_translation=False,
        quality_tier=2,
        device_url_pattern="https://www.notebookcheck.net/smartphones/{slug}",
        spec_table_selector=".specs",
        notes="German origin, English edition. Excellent for detailed reviews + benchmarks.",
    ),
    SpecSource(
        name="PhoneDB",
        slug="phonedb",
        base_url="https://phonedb.net",
        scope="global",
        language="en",
        country="US",
        needs_translation=False,
        quality_tier=3,
        device_url_pattern="https://phonedb.net/index.php?m=device&s=specifications&id={slug}",
        spec_table_selector="#phone_info",
        notes="Older-style database. Good for legacy devices and band/frequency data.",
    ),
]

# ---------------------------------------------------------------------------
# Regional sources — may need translation
# ---------------------------------------------------------------------------

REGIONAL_SOURCES: list[SpecSource] = [
    # India
    SpecSource(
        name="91mobiles",
        slug="91mobiles",
        base_url="https://www.91mobiles.com",
        scope="regional",
        language="en",
        country="IN",
        needs_translation=False,
        quality_tier=1,
        device_url_pattern="https://www.91mobiles.com/{slug}",
        spec_table_selector=".specs-table",
        notes="India's largest mobile review site. English. Excellent for Indian pricing.",
    ),
    SpecSource(
        name="Smartprix",
        slug="smartprix",
        base_url="https://www.smartprix.com",
        scope="regional",
        language="en",
        country="IN",
        needs_translation=False,
        quality_tier=2,
        device_url_pattern="https://www.smartprix.com/mobiles/{slug}",
        spec_table_selector=".sm-specifications",
        notes="Indian price comparison + specs. Good for budget/mid-range coverage.",
    ),
    SpecSource(
        name="FoneArena",
        slug="fonearena",
        base_url="https://www.fonearena.com",
        scope="regional",
        language="en",
        country="IN",
        needs_translation=False,
        quality_tier=2,
        device_url_pattern="https://www.fonearena.com/phones/{slug}",
        spec_table_selector=".phone-specs-list",
        notes="Indian mobile site, English. Good for Indian-market exclusives.",
    ),
    # Brazil
    SpecSource(
        name="TudoCelular",
        slug="tudocelular",
        base_url="https://www.tudocelular.com",
        scope="regional",
        language="pt",
        country="BR",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://www.tudocelular.com/celulares/fichas-tecnicas/{slug}",
        spec_table_selector=".phone-spec-table",
        notes="Brazil's top mobile site. Portuguese. Covers LatAm-exclusive devices.",
    ),
    SpecSource(
        name="Tecnoblog",
        slug="tecnoblog",
        base_url="https://tecnoblog.net",
        scope="regional",
        language="pt",
        country="BR",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://tecnoblog.net/sobre/{slug}/ficha-tecnica/",
        spec_table_selector=".specs",
        notes="Major Brazilian tech blog. Portuguese. Good for LatAm market insights.",
    ),
    # France
    SpecSource(
        name="01net",
        slug="01net",
        base_url="https://www.01net.com",
        scope="regional",
        language="fr",
        country="FR",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://www.01net.com/fiche-produit/{slug}/",
        spec_table_selector=".product-specs",
        notes="France's leading tech site. Covers EU-market devices. French language.",
    ),
    SpecSource(
        name="Les Numériques",
        slug="lesnumeriques",
        base_url="https://www.lesnumeriques.com",
        scope="regional",
        language="fr",
        country="FR",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://www.lesnumeriques.com/telephone-portable/{slug}/fiche-technique.html",
        spec_table_selector=".specifications",
        notes="Premium French tech reviews. Detailed specs for EU models.",
    ),
    # Germany
    SpecSource(
        name="Notebookcheck DE",
        slug="notebookcheck_de",
        base_url="https://www.notebookcheck.com",
        scope="regional",
        language="de",
        country="DE",
        needs_translation=True,
        quality_tier=1,
        device_url_pattern="https://www.notebookcheck.com/smartphones/{slug}",
        spec_table_selector=".specs",
        notes="German-language edition. More thorough than English for some EU models.",
    ),
    # China
    SpecSource(
        name="ZOL",
        slug="zol",
        base_url="https://detail.zol.com.cn",
        scope="regional",
        language="zh",
        country="CN",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://detail.zol.com.cn/cell_phone/{slug}/param.shtml",
        spec_table_selector=".detailed-parameters",
        notes="China's ZOL. Covers China-exclusive devices (Huawei HarmonyOS, etc.).",
    ),
    # Russia / CIS
    SpecSource(
        name="4PDA",
        slug="4pda",
        base_url="https://4pda.to",
        scope="regional",
        language="ru",
        country="RU",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://4pda.to/devdb/{slug}",
        spec_table_selector=".specifications",
        notes="Russia & CIS device database. Covers regional variants.",
    ),
    # Japan
    SpecSource(
        name="Kakaku",
        slug="kakaku",
        base_url="https://kakaku.com",
        scope="regional",
        language="ja",
        country="JP",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://kakaku.com/item/{slug}/spec/",
        spec_table_selector=".specTable",
        notes="Japan's #1 price-comparison. Covers Japan-exclusive carriers & models.",
    ),
    # Korea
    SpecSource(
        name="DanaMU",
        slug="danamu",
        base_url="https://www.danamu.com",
        scope="regional",
        language="ko",
        country="KR",
        needs_translation=True,
        quality_tier=3,
        device_url_pattern="https://www.danamu.com/phone/{slug}",
        spec_table_selector=".spec-table",
        notes="Korean mobile database. Covers Korean carrier variants (SKT, KT, LG U+).",
    ),
    # Turkey
    SpecSource(
        name="Epey",
        slug="epey",
        base_url="https://www.epey.com",
        scope="regional",
        language="tr",
        country="TR",
        needs_translation=True,
        quality_tier=2,
        device_url_pattern="https://www.epey.com/cep-telefonlari/{slug}/",
        spec_table_selector=".spec-table",
        notes="Turkey's top comparison site. Covers Turkish-market pricing and models.",
    ),
]


# ---------------------------------------------------------------------------
# Registry helper functions
# ---------------------------------------------------------------------------

ALL_SOURCES: list[SpecSource] = GLOBAL_SOURCES + REGIONAL_SOURCES

# Slug → source lookup
_SOURCE_MAP: dict[str, SpecSource] = {s.slug: s for s in ALL_SOURCES}


def get_source(slug: str) -> SpecSource | None:
    """Look up a source by slug."""
    return _SOURCE_MAP.get(slug)


def get_enabled_sources(*, scope: str | None = None) -> list[SpecSource]:
    """Return enabled sources, optionally filtered by scope."""
    sources = [s for s in ALL_SOURCES if s.enabled]
    if scope:
        sources = [s for s in sources if s.scope == scope]
    return sources


def get_sources_by_language(language: str) -> list[SpecSource]:
    """Return all sources for a given language code."""
    return [s for s in ALL_SOURCES if s.language == language and s.enabled]


def get_sources_needing_translation() -> list[SpecSource]:
    """Return sources that need translation before data can be used."""
    return [s for s in ALL_SOURCES if s.needs_translation and s.enabled]


@dataclass
class SourceRegistrySummary:
    """Summary of the source registry for admin display."""

    total: int = 0
    global_count: int = 0
    regional_count: int = 0
    languages: list[str] = field(default_factory=list)
    countries: list[str] = field(default_factory=list)
    needs_translation: int = 0


def get_registry_summary() -> SourceRegistrySummary:
    """Build a summary of the source registry."""
    enabled = get_enabled_sources()
    languages = sorted({s.language for s in enabled})
    countries = sorted({s.country for s in enabled})
    return SourceRegistrySummary(
        total=len(enabled),
        global_count=len([s for s in enabled if s.scope == "global"]),
        regional_count=len([s for s in enabled if s.scope == "regional"]),
        languages=languages,
        countries=countries,
        needs_translation=len([s for s in enabled if s.needs_translation]),
    )
