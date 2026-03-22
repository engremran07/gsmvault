"""
settings.py v6 — Master typed configuration for GSMArena Ultimate Scraper.

Load order (lowest → highest priority):
  1. Dataclass defaults
  2. .env file (auto-loaded at module import via _load_dotenv)
  3. GSMA_* environment variables
  4. Explicit Settings.from_cli() keyword arguments
  5. CrawlJob fields (override Settings where provided)

New in v6:
  • crawl_job_path      — path to a CrawlJob JSON file (enables --job flag)
  • crawl_strategy      — "brand_walk" | "search_targeted" | "rumor_mill" | "hybrid"
  • per_brand_overrides — dict[slug, int] per-brand device limits (0=unlimited)
  • sort_by_popularity  — fetch stats.php3 and sort brand-walk by popularity rank
  • per_brand_delay     — dict[slug, float] per-brand delay multiplier

No external runtime dependencies beyond stdlib.
Strict-mode Pylance: full annotations, no assert, no getattr() on args.
"""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from dataclasses import field as dc_field
from pathlib import Path

# ---------------------------------------------------------------------------
# .env loader
# ---------------------------------------------------------------------------


def _load_dotenv(env_path: str = ".env") -> None:
    p = Path(env_path)
    if not p.exists():
        return
    with p.open(encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            os.environ.setdefault(key.strip(), val.strip().strip('"').strip("'"))


_load_dotenv()


def _read_proxy_file(path: str | None) -> list[str]:
    if not path:
        return []
    p = Path(path)
    if not p.exists():
        return []
    with p.open(encoding="utf-8") as fh:
        return [
            ln.strip() for ln in fh if ln.strip() and not ln.strip().startswith("#")
        ]


def _parse_bool(val: str) -> bool:
    return val.strip().lower() in ("1", "true", "yes", "on")


def _parse_dict_int(val: str) -> dict[str, int]:
    """Parse 'samsung:500,apple:0' → {'samsung': 500, 'apple': 0}"""
    out: dict[str, int] = {}
    for part in val.split(","):
        part = part.strip()
        if ":" in part:
            k, _, v = part.partition(":")
            try:
                out[k.strip().lower()] = int(v.strip())
            except ValueError:
                pass
    return out


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------


@dataclass
class Settings:
    """
    Single source of truth for every tunable parameter.
    All fields map to a GSMA_* env var and a from_cli() parameter.
    """

    # -- Concurrency & timing -----------------------------------------------
    concurrent_requests: int = dc_field(
        default_factory=lambda: int(os.getenv("GSMA_CONCURRENCY", "4"))
    )
    download_delay: float = dc_field(
        default_factory=lambda: float(os.getenv("GSMA_DELAY", "4.0"))
    )
    randomize_delay: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_RANDOMIZE_DELAY", "true"))
    )

    # -- Anti-ban & retry ---------------------------------------------------
    max_retries: int = dc_field(
        default_factory=lambda: int(os.getenv("GSMA_MAX_RETRIES", "5"))
    )
    ban_cooldown: float = dc_field(
        default_factory=lambda: float(os.getenv("GSMA_BAN_COOLDOWN", "60.0"))
    )
    exponential_backoff: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_EXP_BACKOFF", "true"))
    )
    backoff_base: float = dc_field(
        default_factory=lambda: float(os.getenv("GSMA_BACKOFF_BASE", "2.0"))
    )
    backoff_max: float = dc_field(
        default_factory=lambda: float(os.getenv("GSMA_BACKOFF_MAX", "300.0"))
    )

    # -- Sessions ------------------------------------------------------------
    headless: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_HEADLESS", "true"))
    )
    stealth_listings: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_STEALTH_LISTINGS", "false"))
    )

    # -- Proxies -------------------------------------------------------------
    proxies: list[str] = dc_field(default_factory=list)
    proxy_file: str | None = dc_field(
        default_factory=lambda: os.getenv("GSMA_PROXY_FILE") or None
    )

    # -- Brand filtering ----------------------------------------------------
    brands_filter: list[str] = dc_field(default_factory=list)

    # -- Crawl strategy & job -----------------------------------------------
    # Strategy: "brand_walk" | "search_targeted" | "rumor_mill" | "hybrid"
    crawl_strategy: str = dc_field(
        default_factory=lambda: os.getenv("GSMA_STRATEGY", "brand_walk")
    )
    # Path to a CrawlJob JSON file. When set, job overrides strategy/filters/limits.
    crawl_job_path: str | None = dc_field(
        default_factory=lambda: os.getenv("GSMA_JOB") or None
    )
    # Preset name (from crawl_job.PRESETS). Mutually exclusive with crawl_job_path.
    crawl_preset: str | None = dc_field(
        default_factory=lambda: os.getenv("GSMA_PRESET") or None
    )

    # -- Sampling ------------------------------------------------------------
    sample_size: int = dc_field(
        default_factory=lambda: int(os.getenv("GSMA_SAMPLE_SIZE", "0"))
    )
    # Global default: 0 = unlimited
    max_devices_per_brand: int = dc_field(
        default_factory=lambda: int(os.getenv("GSMA_MAX_DEVICES_PER_BRAND", "0"))
    )
    # Per-brand overrides: slug → limit (0 = unlimited for that brand)
    # Env: GSMA_PER_BRAND_LIMITS="samsung:500,apple:200"
    per_brand_overrides: dict[str, int] = dc_field(
        default_factory=lambda: _parse_dict_int(os.getenv("GSMA_PER_BRAND_LIMITS", ""))
    )

    # -- Popularity sort -----------------------------------------------------
    # If True: fetch stats.php3 first and sort brand-walk by popularity rank
    sort_by_popularity: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_SORT_POPULAR", "false"))
    )

    # -- Robots.txt ---------------------------------------------------------
    respect_robots: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_RESPECT_ROBOTS", "false"))
    )

    # -- Dedup --------------------------------------------------------------
    dedup_by_model: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_DEDUP_MODEL", "true"))
    )
    bloom_filter: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_BLOOM_FILTER", "false"))
    )
    bloom_capacity: int = dc_field(
        default_factory=lambda: int(os.getenv("GSMA_BLOOM_CAPACITY", "1000000"))
    )
    bloom_error_rate: float = dc_field(
        default_factory=lambda: float(os.getenv("GSMA_BLOOM_ERROR_RATE", "0.001"))
    )

    # -- Output -------------------------------------------------------------
    output_dir: str = dc_field(
        default_factory=lambda: os.getenv("GSMA_OUTPUT_DIR", "output")
    )
    output_csv: str = dc_field(default="")
    output_json: str = dc_field(default="")
    output_jsonl: str = dc_field(default="")
    output_sqlite: str = dc_field(default="")
    output_excel: str = dc_field(default="")
    output_parquet: str = dc_field(default="")
    output_formats_cli: str = dc_field(
        default_factory=lambda: os.getenv("GSMA_OUTPUT_FORMATS", "")
    )
    flush_every: int = dc_field(
        default_factory=lambda: int(os.getenv("GSMA_FLUSH_EVERY", "25"))
    )

    # -- Data validation ----------------------------------------------------
    validate_on_write: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_VALIDATE", "true"))
    )

    # -- Profile ------------------------------------------------------------
    profile_path: str = dc_field(
        default_factory=lambda: os.getenv(
            "GSMA_PROFILE", "profiles/scraper_profile.json"
        )
    )

    # -- Checkpoint / resume ------------------------------------------------
    crawl_dir: str = dc_field(
        default_factory=lambda: os.getenv("GSMA_CRAWLDIR", "checkpoints")
    )
    resume: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_RESUME", "false"))
    )

    # -- Logging ------------------------------------------------------------
    log_level: str = dc_field(
        default_factory=lambda: os.getenv("GSMA_LOG_LEVEL", "INFO").upper()
    )
    log_file: str = dc_field(
        default_factory=lambda: os.getenv("GSMA_LOG_FILE", "logs/gsmarena.log")
    )
    log_json: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_LOG_JSON", "false"))
    )

    # -- Advanced -----------------------------------------------------------
    max_pages_per_brand: int = dc_field(
        default_factory=lambda: int(os.getenv("GSMA_MAX_PAGES", "500"))
    )
    use_uvloop: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_UVLOOP", "false"))
    )
    adaptive_fingerprint: bool = dc_field(
        default_factory=lambda: _parse_bool(os.getenv("GSMA_ADAPTIVE", "true"))
    )
    fingerprint_dir: str = dc_field(
        default_factory=lambda: os.getenv(
            "GSMA_FINGERPRINT_DIR", "checkpoints/fingerprints"
        )
    )
    # Per-brand request delay multiplier: "samsung:2.0,apple:1.5"
    per_brand_delay: dict[str, float] = dc_field(default_factory=dict)

    # -------------------------------------------------------------------------

    def __post_init__(self) -> None:
        self._resolve_proxies()
        self._resolve_brands()
        self._resolve_output_paths()
        self._ensure_dirs()

    def _resolve_proxies(self) -> None:
        file_proxies = _read_proxy_file(self.proxy_file)
        self.proxies = list(dict.fromkeys(self.proxies + file_proxies))

    def _resolve_brands(self) -> None:
        if not self.brands_filter:
            env_brands = os.getenv("GSMA_BRANDS", "")
            if env_brands:
                self.brands_filter = [
                    b.strip().lower() for b in env_brands.split(",") if b.strip()
                ]
        if not self.brands_filter:
            single = os.getenv("GSMA_BRAND", "")
            if single:
                self.brands_filter = [single.strip().lower()]

    def _resolve_output_paths(self) -> None:
        d = self.output_dir
        if not self.output_csv:
            self.output_csv = f"{d}/gsmarena_full.csv"
        if not self.output_json:
            self.output_json = f"{d}/gsmarena_full.json"
        if not self.output_jsonl:
            self.output_jsonl = f"{d}/gsmarena_full.jsonl"
        if not self.output_sqlite:
            self.output_sqlite = f"{d}/gsmarena_full.db"
        if not self.output_excel:
            self.output_excel = f"{d}/gsmarena_full.xlsx"
        if not self.output_parquet:
            self.output_parquet = f"{d}/gsmarena_full.parquet"

    def _ensure_dirs(self) -> None:
        for d in (
            self.output_dir,
            self.crawl_dir,
            str(Path(self.log_file).parent),
            self.fingerprint_dir,
        ):
            Path(d).mkdir(parents=True, exist_ok=True)

    # -- CLI factory ---------------------------------------------------------

    @classmethod
    def from_cli(
        cls,
        *,
        concurrency: int | None = None,
        delay: float | None = None,
        no_jitter: bool = False,
        brand: str | None = None,
        brands: str | None = None,
        proxies_str: str | None = None,
        proxy_file: str | None = None,
        resume: bool = False,
        headless: bool = True,
        stealth_listings: bool = False,
        output_dir: str | None = None,
        profile_path: str | None = None,
        log_level: str | None = None,
        use_uvloop: bool = False,
        sample_size: int = 0,
        max_devices_per_brand: int = 0,
        per_brand_overrides: dict[str, int] | None = None,
        output_formats: str | None = None,
        validate: bool = True,
        respect_robots: bool = False,
        bloom: bool = False,
        adaptive: bool = True,
        dedup_model: bool = True,
        exponential_backoff: bool = True,
        parquet: bool = False,
        crawl_strategy: str | None = None,
        crawl_job_path: str | None = None,
        crawl_preset: str | None = None,
        sort_by_popularity: bool = False,
    ) -> Settings:
        """Keyword-only factory. All params explicit, zero getattr() masking."""
        inst = cls()

        if concurrency is not None:
            inst.concurrent_requests = int(concurrency)
        if delay is not None:
            inst.download_delay = float(delay)
        if no_jitter:
            inst.randomize_delay = False
        if sample_size > 0:
            inst.sample_size = sample_size
        if max_devices_per_brand > 0:
            inst.max_devices_per_brand = max_devices_per_brand
        if per_brand_overrides:
            inst.per_brand_overrides = per_brand_overrides

        if brands:
            inst.brands_filter = [
                b.strip().lower() for b in brands.split(",") if b.strip()
            ]
        elif brand:
            inst.brands_filter = [brand.strip().lower()]

        if proxies_str:
            extra = [p.strip() for p in proxies_str.split(",") if p.strip()]
            inst.proxies = list(dict.fromkeys(inst.proxies + extra))
        if proxy_file:
            inst.proxy_file = proxy_file
            inst._resolve_proxies()

        inst.resume = resume
        inst.headless = headless
        inst.stealth_listings = stealth_listings
        inst.use_uvloop = use_uvloop
        inst.validate_on_write = validate
        inst.respect_robots = respect_robots
        inst.bloom_filter = bloom
        inst.adaptive_fingerprint = adaptive
        inst.dedup_by_model = dedup_model
        inst.exponential_backoff = exponential_backoff
        inst.sort_by_popularity = sort_by_popularity

        if crawl_strategy:
            inst.crawl_strategy = crawl_strategy
        if crawl_job_path:
            inst.crawl_job_path = crawl_job_path
        if crawl_preset:
            inst.crawl_preset = crawl_preset

        if output_formats:
            inst.output_formats_cli = output_formats
        if parquet:
            inst.output_formats_cli = (inst.output_formats_cli + ",parquet").strip(",")

        if output_dir:
            inst.output_dir = output_dir
            inst._resolve_output_paths()
        if profile_path:
            inst.profile_path = profile_path
        if log_level:
            inst.log_level = log_level.upper()

        inst._ensure_dirs()
        return inst

    # -- Derived properties -------------------------------------------------

    @property
    def is_windows(self) -> bool:
        return sys.platform == "win32"

    @property
    def sampling_enabled(self) -> bool:
        return self.sample_size > 0

    def brand_limit(self, slug: str) -> int:
        """
        Effective device limit for a brand.
        per_brand_overrides takes precedence over max_devices_per_brand.
        0 = unlimited.
        """
        return self.per_brand_overrides.get(slug, self.max_devices_per_brand)

    def effective_output_formats(
        self, profile_formats: dict[str, bool]
    ) -> dict[str, bool]:
        if not self.output_formats_cli:
            return profile_formats
        cli_set = {
            f.strip().lower() for f in self.output_formats_cli.split(",") if f.strip()
        }
        all_keys = set(profile_formats.keys()) | {"parquet"}
        return {k: k in cli_set for k in all_keys}

    def backoff_delay(self, attempt: int) -> float:
        import random

        if not self.exponential_backoff:
            return self.ban_cooldown
        cap = min(self.backoff_max, self.backoff_base**attempt)
        return random.uniform(0, cap)  # noqa: S311

    def delay_for_brand(self, slug: str) -> float:
        """Return download delay with optional per-brand multiplier."""
        multiplier = self.per_brand_delay.get(slug, 1.0)
        return self.download_delay * multiplier

    def summary(self) -> str:
        b = ", ".join(self.brands_filter) if self.brands_filter else "ALL brands"
        sampling = (
            f"oldest+mid+newest ×{self.sample_size}"
            if self.sampling_enabled
            else "ALL models"
        )
        cap = (
            f" (max {self.max_devices_per_brand}/brand)"
            if self.max_devices_per_brand
            else ""
        )
        overrides = (
            f"\n  Per-brand overrides : {self.per_brand_overrides}"
            if self.per_brand_overrides
            else ""
        )
        lines = (
            [
                "=" * 70,
                "  GSMArena Ultimate Scraper  v6",
                "=" * 70,
                f"  Strategy         : {self.crawl_strategy}",
                f"  Concurrency      : {self.concurrent_requests}",
                f"  Delay            : {self.download_delay}s"
                + (" ±50% jitter" if self.randomize_delay else " fixed"),
                f"  Brand filter     : {b}",
                f"  Sampling         : {sampling}{cap}",
                f"  Sort by popular  : {self.sort_by_popularity}",
                f"  Adaptive tracking: {self.adaptive_fingerprint}",
                f"  Bloom dedup      : {self.bloom_filter}",
                f"  Exp backoff      : {self.exponential_backoff}",
                f"  Robots.txt       : {'respected' if self.respect_robots else 'ignored'}",
                f"  Proxies          : {len(self.proxies)}",
                f"  Headless         : {self.headless}",
                f"  Profile          : {self.profile_path}",
                f"  Resume           : {self.resume}",
                f"  Output dir       : {self.output_dir}",
                f"  Log level        : {self.log_level}",
            ]
            + ([overrides] if overrides else [])
            + ["=" * 70]
        )
        return "\n".join(lines)
