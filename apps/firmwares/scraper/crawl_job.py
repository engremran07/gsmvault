"""
crawl_job.py — GSMArena Ultimate Scraper v6: CrawlJob system.

A CrawlJob is the central unit of work — it replaces the old "pile of CLI flags"
model with a first-class, versioned, JSON-serialisable job configuration that an
operator can author once and reuse, schedule, or share.

THREE CRAWL STRATEGIES
━━━━━━━━━━━━━━━━━━━━━━
  brand_walk      — Default. Walk makers.php3 → brand listing pages → device pages.
                    Best for: full catalogue, complete brand archives, legacy phones.

  search_targeted — Use GSMArena's Phone Finder (results.php3) with precise filters.
                    Best for: "all 5G flagships 2022+", "Android phones under $300",
                    "foldables", "phones with periscope", "rumored this year".

  rumor_mill      — Scrape rumored.php3 — the dedicated upcoming/rumored feed.
                    Best for: daily/weekly upcoming-device monitoring pipeline.

  hybrid          — Both brand_walk AND search_targeted in one job.
                    Dedup layer prevents duplicates. Best for: targeted enrichment
                    of a full catalogue run.

SEARCH FILTERS (Phone Finder → results.php3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Every filter on GSMArena's Phone Finder is typed here. Unset filters are omitted
from the URL so GSMArena returns unfiltered results for that dimension.

URL parameter mapping was reverse-engineered from GSMArena's form:
  sQuickSearch  — free text search (maps to 'q' and 'sQuickSearch' params)
  chsAvailabilities — comma-joined: 1=Available, 2=Coming soon, 3=Discontinued, 4=Rumored
  chsBrands     — comma-joined brand IDs (numeric, discovered at runtime from form)
  fYearMin/Max  — integer years
  fPriceMin/Max — integer USD
  chsOSes       — comma-joined: 2=Android, 3=iOS, 4=KaiOS, 5=Windows, 6=Symbian, 7=RIM
  chsNetworks   — 100=5G, 10=4G, 1=3G (bitmask-style), specific band IDs also work
  chsFormFactors— 1=Bar, 2=Flip up, 3=Flip down, 4=Slide, 5=Swivel, 6=Watch, 7=Other, 8=Foldable
  fDisplayInchesMin/Max — float
  fRamMin/Max   — integer MB
  fInternalStorageMin/Max — integer GB
  chsChipsets   — chipset name string (fuzzy matched by GSMArena)
  fCameraResMin/Max — integer MP
  fBatteryMin/Max   — integer mAh
  chsSorts      — 0=popularity, 1=price asc, 2=price desc, 3=weight, 4=camera, 5=battery
  bReviewedOnly — 1 if true
  mode          — "tablet" for tablets, default phones

Strict-mode Pylance: all fields typed, no Any on public API, no assert in prod.
"""

from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass
from dataclasses import field as dc_field
from pathlib import Path

logger = logging.getLogger(__name__)

BASE_URL = "https://www.gsmarena.com"
SEARCH_RESULTS_URL = f"{BASE_URL}/results.php3"
RUMORED_URL = f"{BASE_URL}/rumored.php3"
MAKERS_URL = f"{BASE_URL}/makers.php3"
STATS_URL = f"{BASE_URL}/stats.php3"

# ---------------------------------------------------------------------------
# Availability constants
# ---------------------------------------------------------------------------

AVAIL_AVAILABLE = 1
AVAIL_COMING_SOON = 2
AVAIL_DISCONTINUED = 3
AVAIL_RUMORED = 4

# ---------------------------------------------------------------------------
# OS constants
# ---------------------------------------------------------------------------

OS_FEATURE = 1
OS_ANDROID = 2
OS_IOS = 3
OS_KAIOS = 4
OS_WINDOWS = 5
OS_SYMBIAN = 6
OS_RIM = 7
OS_BADA = 8
OS_FIREFOX = 9

# ---------------------------------------------------------------------------
# Form factor constants
# ---------------------------------------------------------------------------

FORM_BAR = 1
FORM_FLIP_UP = 2
FORM_FLIP_DN = 3
FORM_SLIDE = 4
FORM_SWIVEL = 5
FORM_WATCH = 6
FORM_OTHER = 7
FORM_FOLDABLE = 8

# ---------------------------------------------------------------------------
# Sort constants
# ---------------------------------------------------------------------------

SORT_POPULARITY = 0
SORT_PRICE_ASC = 1
SORT_PRICE_DESC = 2
SORT_WEIGHT = 3
SORT_CAMERA = 4
SORT_BATTERY = 5

# ---------------------------------------------------------------------------
# Network gen shortcuts
# ---------------------------------------------------------------------------

NET_5G = 100
NET_4G = 10
NET_3G = 1

# ---------------------------------------------------------------------------
# Chipset family shortcuts (fuzzy-matched by GSMArena's search engine)
# ---------------------------------------------------------------------------

CHIP_SNAPDRAGON_ELITE = "Snapdragon 8 Elite"
CHIP_SNAPDRAGON_8GEN3 = "Snapdragon 8 Gen 3"
CHIP_DIMENSITY_9400 = "Dimensity 9400"
CHIP_EXYNOS_2500 = "Exynos 2500"
CHIP_A18_PRO = "Apple A18 Pro"
CHIP_TENSOR_G4 = "Google Tensor G4"


# ---------------------------------------------------------------------------
# SearchFilters — every Phone Finder dimension, typed
# ---------------------------------------------------------------------------


@dataclass
class SearchFilters:
    """
    Maps to every filter on gsmarena.com/search.php3.
    None = not filtered (GSMArena returns all values for that dimension).

    Usage:
        f = SearchFilters(
            availabilities=[AVAIL_AVAILABLE, AVAIL_COMING_SOON],
            year_min=2022,
            os_ids=[OS_ANDROID],
            has_5g=True,
            display_min_inches=6.0,
            battery_min_mah=4000,
            sort=SORT_POPULARITY,
        )
        url = f.build_url(page=1)
    """

    # -- General -------------------------------------------------------------
    # Brand IDs (numeric, as discovered from GSMArena form at runtime)
    # Use brand_slugs instead — runtime converter maps slug → ID
    brand_slugs: list[str] = dc_field(default_factory=list)
    brand_ids: list[int] = dc_field(default_factory=list)  # populated at runtime

    year_min: int | None = None
    year_max: int | None = None

    # 1=Available, 2=Coming soon, 3=Discontinued, 4=Rumored
    availabilities: list[int] = dc_field(default_factory=list)

    price_min_usd: int | None = None
    price_max_usd: int | None = None

    # Free text (maps to sQuickSearch + q params)
    free_text: str | None = None

    # -- Network -------------------------------------------------------------
    has_5g: bool | None = None  # shortcut for chsNetworks=100
    has_4g: bool | None = None  # shortcut for chsNetworks=10
    has_3g: bool | None = None  # shortcut for chsNetworks=1
    # Specific band IDs (advanced — use sparingly)
    network_band_ids: list[int] = dc_field(default_factory=list)

    # -- SIM -----------------------------------------------------------------
    dual_sim: bool | None = None
    has_esim: bool | None = None

    # -- Body ----------------------------------------------------------------
    # 1=Bar, 2=Flip up, 3=Flip down, 4=Slide, 5=Swivel, 6=Watch, 7=Other, 8=Foldable
    form_factors: list[int] = dc_field(default_factory=list)
    has_qwerty: bool | None = None
    weight_min_g: int | None = None
    weight_max_g: int | None = None
    # IP cert slugs e.g. "ipx8", "mil_std_810h"
    ip_certs: list[str] = dc_field(default_factory=list)

    # -- Platform ------------------------------------------------------------
    # OS IDs: 1=Feature, 2=Android, 3=iOS, 4=KaiOS, 5=Windows, 6=Symbian...
    os_ids: list[int] = dc_field(default_factory=list)
    os_version_min: str | None = None  # e.g. "14" for Android 14+
    # Chipset name (fuzzy match by GSMArena)
    chipset_name: str | None = None

    # -- Memory --------------------------------------------------------------
    ram_min_mb: int | None = None  # GSMArena uses MB, e.g. 8192 for 8GB
    ram_max_mb: int | None = None
    storage_min_gb: int | None = None
    storage_max_gb: int | None = None
    has_card_slot: bool | None = None

    # -- Display -------------------------------------------------------------
    display_min_inches: float | None = None
    display_max_inches: float | None = None
    display_min_ppi: int | None = None
    # tech: "ips", "oled", "ltpo"
    display_tech: str | None = None
    refresh_rate_min: int | None = None
    has_hdr: bool | None = None
    notch_style: str | None = None  # "none", "yes", "punch_hole"

    # -- Camera --------------------------------------------------------------
    camera_mp_min: int | None = None
    camera_count_min: int | None = None  # 1=one, 2=two, 3=three, 4=four+
    has_ois: bool | None = None
    has_telephoto: bool | None = None
    has_ultrawide: bool | None = None

    # -- Selfie --------------------------------------------------------------
    selfie_mp_min: int | None = None
    has_front_flash: bool | None = None
    has_under_display_cam: bool | None = None

    # -- Audio ---------------------------------------------------------------
    has_headphone_jack: bool | None = None
    has_dual_speakers: bool | None = None

    # -- Connectivity --------------------------------------------------------
    wifi_gen: int | None = None  # 4,5,6,7
    bt_version_min: float | None = None  # e.g. 5.2
    has_nfc: bool | None = None
    has_ir: bool | None = None
    has_fm_radio: bool | None = None
    has_usb_c: bool | None = None

    # -- Battery -------------------------------------------------------------
    battery_min_mah: int | None = None
    battery_max_mah: int | None = None
    battery_removable: bool | None = None
    charging_min_watts: int | None = None
    wireless_charging: bool | None = None

    # -- Result controls -----------------------------------------------------
    # 0=popularity, 1=price asc, 2=price desc, 3=weight, 4=camera, 5=battery
    sort: int = SORT_POPULARITY
    reviewed_only: bool = False
    mode: str = "phones"  # "phones" or "tablet"
    max_results: int = 0  # 0 = all pages

    # -- Runtime state (not serialised to JSON) ------------------------------
    _discovered_brand_map: dict[str, int] = dc_field(
        default_factory=dict, repr=False, compare=False
    )

    def build_url(self, page: int = 1) -> str:
        """
        Construct the results.php3 URL for this filter set.
        Called once to get page 1, then follow pagination links from the response.
        """
        params: dict[str, str] = {}

        # Availability
        if self.availabilities:
            params["sAvailabilities"] = "%2C".join(str(a) for a in self.availabilities)

        # Year
        if self.year_min is not None:
            params["fYearMin"] = str(self.year_min)
        if self.year_max is not None:
            params["fYearMax"] = str(self.year_max)

        # Price
        if self.price_min_usd is not None:
            params["fPriceMin"] = str(self.price_min_usd)
        if self.price_max_usd is not None:
            params["fPriceMax"] = str(self.price_max_usd)

        # OS
        if self.os_ids:
            params["chsOSes"] = "%2C".join(str(o) for o in self.os_ids)

        # Network
        net_flags: list[int] = list(self.network_band_ids)
        if self.has_5g:
            net_flags.append(NET_5G)
        if self.has_4g and NET_4G not in net_flags:
            net_flags.append(NET_4G)
        if self.has_3g and NET_3G not in net_flags:
            net_flags.append(NET_3G)
        if net_flags:
            params["chsNetworks"] = "%2C".join(str(n) for n in net_flags)

        # Form factor
        if self.form_factors:
            params["chsFormFactors"] = "%2C".join(str(f) for f in self.form_factors)

        # Display
        if self.display_min_inches is not None:
            params["fDisplayInchesMin"] = str(self.display_min_inches)
        if self.display_max_inches is not None:
            params["fDisplayInchesMax"] = str(self.display_max_inches)

        # RAM (MB)
        if self.ram_min_mb is not None:
            params["fRamMin"] = str(self.ram_min_mb)
        if self.ram_max_mb is not None:
            params["fRamMax"] = str(self.ram_max_mb)

        # Storage (GB)
        if self.storage_min_gb is not None:
            params["fInternalStorageMin"] = str(self.storage_min_gb)
        if self.storage_max_gb is not None:
            params["fInternalStorageMax"] = str(self.storage_max_gb)

        # Camera
        if self.camera_mp_min is not None:
            params["fCameraResMin"] = str(self.camera_mp_min)

        # Battery
        if self.battery_min_mah is not None:
            params["fBatteryMin"] = str(self.battery_min_mah)
        if self.battery_max_mah is not None:
            params["fBatteryMax"] = str(self.battery_max_mah)

        # Weight
        if self.weight_min_g is not None:
            params["fWeightMin"] = str(self.weight_min_g)
        if self.weight_max_g is not None:
            params["fWeightMax"] = str(self.weight_max_g)

        # Chipset
        if self.chipset_name:
            params["chsChipsets"] = self.chipset_name

        # Brand IDs (populated at runtime by spider)
        if self.brand_ids:
            params["chsBrands"] = "%2C".join(str(b) for b in self.brand_ids)

        # Free text
        if self.free_text:
            params["sQuickSearch"] = self.free_text
            params["q"] = self.free_text

        # Sort
        if self.sort != SORT_POPULARITY:
            params["chsSorts"] = str(self.sort)

        # Reviewed only
        if self.reviewed_only:
            params["bReviewedOnly"] = "1"

        # Mode
        if self.mode == "tablet":
            params["mode"] = "tablet"

        # Page (GSMArena uses #P for pagination in results, but also p= param)
        if page > 1:
            params["p"] = str(page)

        base = f"{SEARCH_RESULTS_URL}?"
        return base + "&".join(f"{k}={v}" for k, v in params.items())

    def describe(self) -> str:
        """Human-readable filter summary for logging."""
        parts: list[str] = []
        if self.brand_slugs:
            parts.append(f"brands={','.join(self.brand_slugs)}")
        if self.availabilities:
            amap = {1: "Available", 2: "Coming", 3: "Discontinued", 4: "Rumored"}
            parts.append(
                "avail=" + "+".join(amap.get(a, str(a)) for a in self.availabilities)
            )
        if self.year_min or self.year_max:
            y = f"year={self.year_min or '?'}–{self.year_max or '?'}"
            parts.append(y)
        if self.has_5g:
            parts.append("5G")
        if self.os_ids:
            omap = {2: "Android", 3: "iOS", 4: "KaiOS"}
            parts.append("os=" + "+".join(omap.get(o, str(o)) for o in self.os_ids))
        if self.chipset_name:
            parts.append(f"chip={self.chipset_name}")
        if self.free_text:
            parts.append(f'q="{self.free_text}"')
        if self.price_min_usd or self.price_max_usd:
            parts.append(
                f"price=${self.price_min_usd or 0}–${self.price_max_usd or '∞'}"
            )
        if self.battery_min_mah:
            parts.append(f"bat>={self.battery_min_mah}mAh")
        if self.form_factors:
            fmap = {8: "Foldable", 6: "Watch", 2: "Flip", 1: "Bar"}
            parts.append(
                "form=" + "+".join(fmap.get(f, str(f)) for f in self.form_factors)
            )
        return " | ".join(parts) if parts else "no filters (all phones)"

    def to_dict(self) -> dict[str, object]:
        """Serialise to plain dict for JSON storage (skips runtime state)."""
        d: dict[str, object] = {}
        for fname, fval in self.__dict__.items():
            if fname.startswith("_"):
                continue
            if fval is None or fval == [] or fval == {}:
                continue
            if fname == "sort" and fval == 0:
                continue
            if fname == "reviewed_only" and not fval:
                continue
            if fname == "mode" and fval == "phones":
                continue
            if fname == "max_results" and fval == 0:
                continue
            d[fname] = fval
        return d

    @classmethod
    def from_dict(cls, d: dict[str, object]) -> SearchFilters:
        """Deserialise from plain dict."""
        inst = cls()
        for k, v in d.items():
            if hasattr(inst, k) and not k.startswith("_"):
                setattr(inst, k, v)
        return inst


# ---------------------------------------------------------------------------
# CrawlJob — first-class unit of work
# ---------------------------------------------------------------------------

STRATEGY_BRAND_WALK = "brand_walk"
STRATEGY_SEARCH_TARGETED = "search_targeted"
STRATEGY_RUMOR_MILL = "rumor_mill"
STRATEGY_HYBRID = "hybrid"

_VALID_STRATEGIES = frozenset(
    {
        STRATEGY_BRAND_WALK,
        STRATEGY_SEARCH_TARGETED,
        STRATEGY_RUMOR_MILL,
        STRATEGY_HYBRID,
    }
)


@dataclass
class CrawlJob:
    """
    First-class crawl job configuration.

    A CrawlJob answers the questions:
      - Which strategy to use?
      - Which brands to include (if brand_walk / hybrid)?
      - How many devices per brand (overridable per-brand)?
      - What filters to apply (if search_targeted / hybrid)?
      - What sampling to use?
      - What output formats?

    Designed to be authored as a JSON file and loaded via CrawlJob.from_file().
    """

    # -- Identity ------------------------------------------------------------
    job_id: str = "default"
    description: str = ""
    version: str = "6.0"

    # -- Strategy ------------------------------------------------------------
    strategy: str = STRATEGY_BRAND_WALK

    # -- Brand control -------------------------------------------------------
    # Empty = ALL brands
    brands_include: list[str] = dc_field(default_factory=list)
    brands_exclude: list[str] = dc_field(default_factory=list)

    # Global default; per-brand overrides take precedence
    # 0 = unlimited
    max_devices_per_brand: int = 0

    # Per-brand overrides: {"samsung": 500, "apple": 0} (0=unlimited for that brand)
    per_brand_limits: dict[str, int] = dc_field(default_factory=dict)

    # -- Sampling ------------------------------------------------------------
    # 0 = full crawl; N = oldest+mid+newest N per brand
    sample_size: int = 0

    # -- Search filters (used when strategy is search_targeted or hybrid) ----
    filters: SearchFilters | None = None

    # -- Sort / priority -----------------------------------------------------
    # If True, fetches stats.php3 and scrapes in popularity order
    sort_by_popularity: bool = False

    # -- Output overrides ----------------------------------------------------
    # Empty dict = use profile defaults
    output_formats: dict[str, bool] = dc_field(default_factory=dict)
    output_dir: str | None = None

    # -- Behaviour overrides -------------------------------------------------
    # None = inherit from Settings
    concurrency: int | None = None
    delay: float | None = None
    headless: bool | None = None
    bloom_filter: bool | None = None
    adaptive: bool | None = None

    def validate(self) -> list[str]:
        """Return list of validation errors (empty = valid)."""
        errors: list[str] = []
        if self.strategy not in _VALID_STRATEGIES:
            errors.append(f"Unknown strategy: {self.strategy!r}")
        if self.strategy in (STRATEGY_SEARCH_TARGETED, STRATEGY_HYBRID):
            if self.filters is None:
                errors.append(f"strategy={self.strategy} requires 'filters' to be set")
        if self.sample_size < 0:
            errors.append(f"sample_size must be >= 0, got {self.sample_size}")
        if self.max_devices_per_brand < 0:
            errors.append(
                f"max_devices_per_brand must be >= 0, got {self.max_devices_per_brand}"
            )
        return errors

    def brand_limit(self, brand_slug: str) -> int:
        """Effective device limit for a brand: per-brand override or global default."""
        return self.per_brand_limits.get(brand_slug, self.max_devices_per_brand)

    def effective_brands(self, all_brands: list[str]) -> list[str]:
        """
        Apply include/exclude logic to a discovered brand list.
        Returns brands to actually crawl.
        """
        if self.brands_include:
            pool = [b for b in all_brands if b in self.brands_include]
        else:
            pool = list(all_brands)
        if self.brands_exclude:
            pool = [b for b in pool if b not in self.brands_exclude]
        return pool

    def to_dict(self) -> dict[str, object]:
        d: dict[str, object] = {
            "job_id": self.job_id,
            "description": self.description,
            "version": self.version,
            "strategy": self.strategy,
        }
        if self.brands_include:
            d["brands_include"] = self.brands_include
        if self.brands_exclude:
            d["brands_exclude"] = self.brands_exclude
        if self.max_devices_per_brand:
            d["max_devices_per_brand"] = self.max_devices_per_brand
        if self.per_brand_limits:
            d["per_brand_limits"] = self.per_brand_limits
        if self.sample_size:
            d["sample_size"] = self.sample_size
        if self.filters is not None:
            d["filters"] = self.filters.to_dict()
        if self.sort_by_popularity:
            d["sort_by_popularity"] = True
        if self.output_formats:
            d["output_formats"] = self.output_formats
        if self.output_dir:
            d["output_dir"] = self.output_dir
        for k in ("concurrency", "delay", "headless", "bloom_filter", "adaptive"):
            v = getattr(self, k)
            if v is not None:
                d[k] = v
        return d

    @classmethod
    def from_dict(cls, d: dict[str, object]) -> CrawlJob:
        inst = cls()
        simple_fields = {
            "job_id",
            "description",
            "version",
            "strategy",
            "brands_include",
            "brands_exclude",
            "max_devices_per_brand",
            "per_brand_limits",
            "sample_size",
            "sort_by_popularity",
            "output_formats",
            "output_dir",
            "concurrency",
            "delay",
            "headless",
            "bloom_filter",
            "adaptive",
        }
        for k in simple_fields:
            if k in d:
                setattr(inst, k, d[k])
        if "filters" in d and isinstance(d["filters"], dict):
            inst.filters = SearchFilters.from_dict(d["filters"])
        return inst

    @classmethod
    def from_file(cls, path: str) -> CrawlJob:
        p = Path(path)
        if not p.exists():
            raise FileNotFoundError(f"CrawlJob file not found: {path}")
        with p.open(encoding="utf-8") as fh:
            raw: dict[str, object] = json.load(fh)
        # Strip _comment keys
        data = {k: v for k, v in raw.items() if not k.startswith("_")}
        job = cls.from_dict(data)
        errors = job.validate()
        if errors:
            raise ValueError(f"CrawlJob validation errors in {path}: {errors}")
        logger.info(
            "Loaded CrawlJob '%s' strategy=%s filters=%s",
            job.job_id,
            job.strategy,
            job.filters.describe() if job.filters else "none",
        )
        return job

    def save(self, path: str) -> None:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(self.to_dict(), fh, indent=2, ensure_ascii=False)
        logger.info("CrawlJob '%s' saved → %s", self.job_id, path)


# ---------------------------------------------------------------------------
# Preset library — 8 built-in job configurations
# ---------------------------------------------------------------------------


def _make_presets() -> dict[str, CrawlJob]:
    """Build the preset library. Called once at module load."""
    presets: dict[str, CrawlJob] = {}

    # 1. full_catalogue — everything, no filters
    presets["full_catalogue"] = CrawlJob(
        job_id="full_catalogue",
        description="Full GSMArena catalogue — all brands, all models, all time",
        strategy=STRATEGY_BRAND_WALK,
        sample_size=0,
        max_devices_per_brand=0,
    )

    # 2. sample_survey — fast representative snapshot (~3k devices in <2h)
    presets["sample_survey"] = CrawlJob(
        job_id="sample_survey",
        description="Representative sample: oldest+mid+newest 5 devices per brand",
        strategy=STRATEGY_BRAND_WALK,
        sample_size=5,
        sort_by_popularity=True,
    )

    # 3. flagship_5g — premium 5G phones 2020+
    presets["flagship_5g"] = CrawlJob(
        job_id="flagship_5g",
        description="All flagship 5G smartphones released 2020 onwards",
        strategy=STRATEGY_SEARCH_TARGETED,
        filters=SearchFilters(
            availabilities=[AVAIL_AVAILABLE],
            year_min=2020,
            has_5g=True,
            os_ids=[OS_ANDROID, OS_IOS],
            sort=SORT_POPULARITY,
        ),
    )

    # 4. budget_global — affordable phones under $250
    presets["budget_global"] = CrawlJob(
        job_id="budget_global",
        description="Budget smartphones under $250, available now",
        strategy=STRATEGY_SEARCH_TARGETED,
        filters=SearchFilters(
            availabilities=[AVAIL_AVAILABLE],
            price_max_usd=250,
            os_ids=[OS_ANDROID],
            sort=SORT_POPULARITY,
        ),
    )

    # 5. rumored_upcoming — the rumor mill feed + announced not yet available
    presets["rumored_upcoming"] = CrawlJob(
        job_id="rumored_upcoming",
        description="All rumored and announced-but-not-available phones",
        strategy=STRATEGY_RUMOR_MILL,
    )

    # 6. foldables — all foldable form factor devices
    presets["foldables"] = CrawlJob(
        job_id="foldables",
        description="All foldable smartphones ever listed on GSMArena",
        strategy=STRATEGY_SEARCH_TARGETED,
        filters=SearchFilters(
            form_factors=[FORM_FOLDABLE],
            sort=SORT_POPULARITY,
        ),
    )

    # 7. android_flagship_snapdragon — Snapdragon 8 series flagships
    presets["android_flagship_snapdragon"] = CrawlJob(
        job_id="android_flagship_snapdragon",
        description="Android phones with Snapdragon 8-series chips (2020+)",
        strategy=STRATEGY_SEARCH_TARGETED,
        filters=SearchFilters(
            availabilities=[AVAIL_AVAILABLE],
            year_min=2020,
            os_ids=[OS_ANDROID],
            free_text="Snapdragon 8",
            sort=SORT_POPULARITY,
        ),
    )

    # 8. big_battery — phones with 5000+ mAh battery
    presets["big_battery"] = CrawlJob(
        job_id="big_battery",
        description="All phones with 5000mAh+ battery, available now",
        strategy=STRATEGY_SEARCH_TARGETED,
        filters=SearchFilters(
            availabilities=[AVAIL_AVAILABLE],
            battery_min_mah=5000,
            os_ids=[OS_ANDROID],
            sort=SORT_BATTERY,
        ),
    )

    # 9. ios_all — every iPhone ever listed
    presets["ios_all"] = CrawlJob(
        job_id="ios_all",
        description="Complete iPhone / Apple iOS device catalogue",
        strategy=STRATEGY_BRAND_WALK,
        brands_include=["apple"],
        max_devices_per_brand=0,
    )

    # 10. wearables — smartwatches and wearable category
    presets["wearables"] = CrawlJob(
        job_id="wearables",
        description="All smartwatches and wearable devices",
        strategy=STRATEGY_SEARCH_TARGETED,
        filters=SearchFilters(
            form_factors=[FORM_WATCH],
            sort=SORT_POPULARITY,
        ),
    )

    # 11. top_brands_sampled — top 10 brands by popularity, sampled
    presets["top_brands_sampled"] = CrawlJob(
        job_id="top_brands_sampled",
        description="Top 10 brands (Samsung, Apple, Xiaomi…) sampled 10 devices each",
        strategy=STRATEGY_BRAND_WALK,
        brands_include=[
            "samsung",
            "apple",
            "xiaomi",
            "huawei",
            "oppo",
            "vivo",
            "realme",
            "motorola",
            "oneplus",
            "google",
        ],
        sample_size=10,
        sort_by_popularity=True,
    )

    # 12. hybrid_5g_complete — brand walk + search-targeted 5G enrichment
    presets["hybrid_5g_complete"] = CrawlJob(
        job_id="hybrid_5g_complete",
        description="Full brand walk + search-targeted 5G pass for maximum coverage",
        strategy=STRATEGY_HYBRID,
        sample_size=0,
        filters=SearchFilters(
            has_5g=True,
            year_min=2019,
            availabilities=[AVAIL_AVAILABLE, AVAIL_COMING_SOON],
            sort=SORT_POPULARITY,
        ),
    )

    return presets


PRESETS: dict[str, CrawlJob] = _make_presets()


def list_presets() -> list[dict[str, str]]:
    """Return a list of preset summaries for display."""
    return [
        {
            "id": job.job_id,
            "strategy": job.strategy,
            "description": job.description,
            "filters": job.filters.describe() if job.filters else "",
        }
        for job in PRESETS.values()
    ]


def get_preset(name: str) -> CrawlJob:
    """Load a preset by name. Raises KeyError if not found."""
    if name not in PRESETS:
        available = ", ".join(sorted(PRESETS.keys()))
        raise KeyError(f"Unknown preset: {name!r}. Available: {available}")
    return PRESETS[name]


def save_all_presets(directory: str) -> None:
    """Write all preset jobs as JSON files to the given directory."""
    d = Path(directory)
    d.mkdir(parents=True, exist_ok=True)
    for job in PRESETS.values():
        path = d / f"{job.job_id}.json"
        data: dict[str, object] = {
            "_comment": job.description,
            "_strategy": job.strategy,
        }
        data.update(job.to_dict())
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2, ensure_ascii=False)
    logger.info("Saved %d preset jobs → %s", len(PRESETS), directory)


# ---------------------------------------------------------------------------
# Brand ID discovery helpers (runtime)
# ---------------------------------------------------------------------------

_BRAND_ID_RE: re.Pattern[str] = re.compile(r"([a-z0-9_\-]+)-phones-(\d+)\.php", re.I)


def discover_brand_ids(makers_html: str) -> dict[str, int]:
    """
    Parse the makers page HTML and return slug → numeric ID mapping.
    Used to populate SearchFilters.brand_ids from brand_slugs.

    Example: "samsung-phones-9.php" → {"samsung": 9}
    """
    mapping: dict[str, int] = {}
    for m in _BRAND_ID_RE.finditer(makers_html):
        slug = m.group(1).lower()
        brand_id = int(m.group(2))
        mapping[slug] = brand_id
    return mapping
