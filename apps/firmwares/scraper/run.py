"""
run.py v6 — Entry point for GSMArena Ultimate Scraper.

Sub-commands:
  (default)       Run the full scrape (strategy from --strategy / --job / --preset)
  dry-run         List all discoverable brands with device counts and exit
  gen-profile     Auto-generate scraper_profile.json from a live device page
  validate        Validate an existing CSV output file
  list-presets    Show all built-in preset jobs and exit
  show-job        Print a resolved CrawlJob as JSON and exit (useful for debugging)

New flags in v6:
  --strategy      brand_walk | search_targeted | rumor_mill | hybrid
  --job           path/to/job.json — load a CrawlJob from file
  --preset        name — use a built-in preset (see list-presets)
  --sort-popular  sort brands by GSMArena stats.php3 popularity rank
  --per-brand     "samsung:500,apple:0" — per-brand device limits
  --no-per-brand  disable per-brand override map

All v5 flags retained:
  --sample-size, --max-devices-per-brand, --brand, --brands,
  --output-formats, --parquet, --bloom, --no-adaptive, --resume,
  --concurrency, --delay, --no-jitter, --proxies, --proxy-file,
  --stealth-listings, --no-headless, --output-dir, --profile,
  --log-level, --log-json, --stream, --uvloop, --robots,
  --no-validate, --no-exp-backoff, --no-dedup-model

Strict-mode Pylance: no getattr(args,...), Windows policy guarded.
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import json
import logging
import re
import sys
import time
from pathlib import Path
from typing import Any

if sys.platform == "win32":
    _policy = getattr(asyncio, "WindowsSelectorEventLoopPolicy", None)
    if _policy is not None:
        asyncio.set_event_loop_policy(_policy())


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------


def _init_logging(level: str, log_file: str, json_logs: bool = False) -> None:
    Path(log_file).parent.mkdir(parents=True, exist_ok=True)
    fmt = (
        '{"ts":"%(asctime)s","level":"%(levelname)s","name":"%(name)s","msg":"%(message)s"}'
        if json_logs
        else "%(asctime)s [%(levelname)-8s] %(name)s: %(message)s"
    )
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format=fmt,
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler(log_file, encoding="utf-8"),
        ],
    )
    for noisy in ("websockets", "asyncio", "patchright", "playwright", "camoufox"):
        logging.getLogger(noisy).setLevel(logging.WARNING)


# ---------------------------------------------------------------------------
# Argument parser
# ---------------------------------------------------------------------------


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="gsmarena-ultimate",
        description="GSMArena Ultimate Scraper v6 — God-mode GSMArena intelligence",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
STRATEGIES:
  brand_walk        Walk all brand listing pages (full catalogue)
  search_targeted   Use GSMArena Phone Finder with filters (--job / --preset)
  rumor_mill        Scrape the upcoming/rumored device feed
  hybrid            Both brand_walk + search_targeted in one run

EXAMPLES:
  python run.py                                      # full brand_walk, all brands
  python run.py --sample-size 5                      # quick sample
  python run.py --strategy rumor_mill                # upcoming devices
  python run.py --preset flagship_5g                 # 5G flagships via Phone Finder
  python run.py --preset top_brands_sampled          # top 10 brands, sampled
  python run.py --job preset_jobs/budget_global.json # custom job file
  python run.py --brand samsung --per-brand samsung:0  # Samsung unlimited
  python run.py --sort-popular --sample-size 5       # popularity-sorted sample
  python run.py --output-formats csv,sqlite,parquet  # select outputs
  python run.py list-presets                         # show all presets
  python run.py dry-run                              # list all brands
  python run.py validate --csv output/gsmarena_full.csv
  python run.py gen-profile --url https://gsmarena.com/samsung_galaxy_s24-12344.php
  python run.py show-job --preset flagship_5g        # inspect preset as JSON
        """,
    )
    sub = p.add_subparsers(dest="command")

    # dry-run
    sub.add_parser("dry-run", help="List all brands and exit")

    # list-presets
    sub.add_parser("list-presets", help="Show all built-in preset jobs")

    # show-job
    sj = sub.add_parser("show-job", help="Print resolved CrawlJob as JSON")
    sj.add_argument("--preset", type=str, default=None)
    sj.add_argument("--job", type=str, default=None, dest="job_path")

    # gen-profile
    gp = sub.add_parser("gen-profile", help="Auto-generate profile from device URL")
    gp.add_argument("--url", required=True)
    gp.add_argument("--out", default="profiles/auto_profile.json")

    # validate
    vp = sub.add_parser("validate", help="Validate an existing CSV output")
    vp.add_argument("--csv", dest="csv_path", required=True)

    # ---- Main scrape flags ------------------------------------------------
    p.add_argument("--concurrency", "-c", type=int, default=None)
    p.add_argument("--delay", "-d", type=float, default=None)
    p.add_argument("--no-jitter", action="store_true", dest="no_jitter")

    # Brand control
    p.add_argument("--brand", type=str, default=None)
    p.add_argument("--brands", type=str, default=None, metavar="A,B,...")
    p.add_argument(
        "--per-brand",
        type=str,
        default=None,
        dest="per_brand",
        metavar="slug:N,...",
        help="Per-brand device limits e.g. 'samsung:500,apple:0' (0=unlimited)",
    )

    # Strategy
    p.add_argument(
        "--strategy",
        type=str,
        default=None,
        choices=["brand_walk", "search_targeted", "rumor_mill", "hybrid"],
        help="Crawl strategy (default: brand_walk)",
    )

    # Job / preset
    p.add_argument(
        "--job",
        type=str,
        default=None,
        dest="job_path",
        metavar="path/to/job.json",
        help="Load a CrawlJob from a JSON file",
    )
    p.add_argument(
        "--preset",
        type=str,
        default=None,
        metavar="NAME",
        help="Use a built-in preset job (see list-presets)",
    )

    # Sampling
    p.add_argument(
        "--sample-size",
        type=int,
        default=0,
        dest="sample_size",
        metavar="N",
        help="oldest+mid+newest N per brand (0=all)",
    )
    p.add_argument(
        "--max-devices-per-brand",
        type=int,
        default=0,
        dest="max_devices_per_brand",
        metavar="N",
        help="Global cap per brand (0=unlimited; --per-brand overrides per-slug)",
    )

    # Sorting
    p.add_argument(
        "--sort-popular",
        action="store_true",
        dest="sort_popular",
        help="Sort brands by GSMArena popularity (stats.php3)",
    )

    # Proxy / network
    p.add_argument("--proxies", type=str, default=None, metavar="URL,...")
    p.add_argument("--proxy-file", type=str, default=None, dest="proxy_file")
    p.add_argument("--robots", action="store_true", help="Respect robots.txt")

    # Session
    p.add_argument("--resume", "-r", action="store_true")
    p.add_argument("--stealth-listings", action="store_true", dest="stealth_listings")
    p.add_argument("--no-headless", action="store_true", dest="no_headless")

    # Output
    p.add_argument("--output-dir", type=str, default=None, dest="output_dir")
    p.add_argument(
        "--output-formats",
        type=str,
        default=None,
        dest="output_formats",
        metavar="csv,json,jsonl,sqlite,excel,parquet",
    )
    p.add_argument("--parquet", action="store_true", help="Enable Parquet output")

    # Intelligence
    p.add_argument("--profile", type=str, default=None, dest="profile_path")
    p.add_argument("--bloom", action="store_true", help="Bloom filter URL dedup")
    p.add_argument(
        "--no-adaptive",
        action="store_true",
        dest="no_adaptive",
        help="Disable Scrapling adaptive element fingerprinting",
    )
    p.add_argument(
        "--no-dedup-model",
        action="store_true",
        dest="no_dedup_model",
        help="Disable brand+model_name deduplication",
    )
    p.add_argument(
        "--no-validate",
        action="store_true",
        dest="no_validate",
        help="Disable per-record data validation",
    )
    p.add_argument(
        "--no-exp-backoff",
        action="store_true",
        dest="no_exp_backoff",
        help="Use fixed cooldown instead of exponential backoff on ban",
    )

    # Logging
    p.add_argument(
        "--log-level",
        type=str,
        default=None,
        dest="log_level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
    )
    p.add_argument("--log-json", action="store_true", dest="log_json")

    # Advanced
    p.add_argument("--stream", action="store_true", help="Async stream mode")
    p.add_argument("--uvloop", action="store_true", help="Use uvloop (Linux/macOS)")

    return p


# ---------------------------------------------------------------------------
# Command handlers
# ---------------------------------------------------------------------------


def _cmd_scrape(args: argparse.Namespace) -> int:
    from .crawl_job import CrawlJob, get_preset
    from .pipeline import OutputPipeline
    from .profile_engine import ProfileEngine
    from .settings import Settings
    from .spider import GSMArenaSpider

    # -- Resolve per_brand overrides ----------------------------------------
    per_brand: dict[str, int] | None = None
    if args.per_brand:
        per_brand = {}
        for part in str(args.per_brand).split(","):
            if ":" in part:
                slug, _, limit = part.partition(":")
                try:
                    per_brand[slug.strip().lower()] = int(limit.strip())
                except ValueError:
                    pass

    # -- Build Settings -----------------------------------------------------
    cfg = Settings.from_cli(
        concurrency=args.concurrency,
        delay=args.delay,
        no_jitter=bool(args.no_jitter),
        brand=args.brand,
        brands=args.brands,
        proxies_str=args.proxies,
        proxy_file=args.proxy_file,
        resume=bool(args.resume),
        headless=not bool(args.no_headless),
        stealth_listings=bool(args.stealth_listings),
        output_dir=args.output_dir,
        profile_path=args.profile_path,
        log_level=args.log_level,
        use_uvloop=bool(args.uvloop),
        sample_size=int(args.sample_size),
        max_devices_per_brand=int(args.max_devices_per_brand),
        per_brand_overrides=per_brand or {},
        output_formats=args.output_formats,
        validate=not bool(args.no_validate),
        respect_robots=bool(args.robots),
        bloom=bool(args.bloom),
        adaptive=not bool(args.no_adaptive),
        dedup_model=not bool(args.no_dedup_model),
        exponential_backoff=not bool(args.no_exp_backoff),
        parquet=bool(args.parquet),
        crawl_strategy=args.strategy or "brand_walk",
        crawl_job_path=args.job_path or None,
        crawl_preset=args.preset or None,
        sort_by_popularity=bool(args.sort_popular),
    )

    _init_logging(cfg.log_level, cfg.log_file, json_logs=bool(args.log_json))
    log = logging.getLogger("run")

    # -- Resolve CrawlJob ---------------------------------------------------
    job: CrawlJob | None = None
    if args.job_path:
        try:
            job = CrawlJob.from_file(str(args.job_path))
            cfg.crawl_strategy = job.strategy
            if job.sample_size:
                cfg.sample_size = job.sample_size
            if job.output_dir:
                cfg.output_dir = job.output_dir
            log.info("CrawlJob loaded: %s (%s)", job.job_id, job.strategy)
        except Exception as exc:
            log.error("Failed to load CrawlJob from %s: %s", args.job_path, exc)
            return 1
    elif args.preset:
        try:
            job = get_preset(str(args.preset))
            cfg.crawl_strategy = job.strategy
            if job.sample_size:
                cfg.sample_size = job.sample_size
            log.info("Preset loaded: %s (%s)", job.job_id, job.strategy)
        except KeyError as exc:
            log.error("%s", exc)
            return 1

    # -- Apply job overrides to cfg -----------------------------------------
    if job:
        if job.concurrency is not None:
            cfg.concurrent_requests = job.concurrency
        if job.delay is not None:
            cfg.download_delay = job.delay
        if job.headless is not None:
            cfg.headless = job.headless
        if job.bloom_filter is not None:
            cfg.bloom_filter = job.bloom_filter
        if job.adaptive is not None:
            cfg.adaptive_fingerprint = job.adaptive
        if job.sort_by_popularity:
            cfg.sort_by_popularity = True
        if job.brands_include:
            cfg.brands_filter = job.brands_include
        if job.per_brand_limits:
            cfg.per_brand_overrides = {
                **cfg.per_brand_overrides,
                **job.per_brand_limits,
            }
        if job.max_devices_per_brand and not cfg.max_devices_per_brand:
            cfg.max_devices_per_brand = job.max_devices_per_brand

    # -- Popularity fetch ---------------------------------------------------
    if cfg.sort_by_popularity:
        from .spider import GSMArenaSpider as _SpiderClass

        log.info("Fetching GSMArena popularity rankings...")
        # Temporary spider just for the fetch
        _tmp = _SpiderClass.__new__(_SpiderClass)
        popularity = _tmp._fetch_popularity_ranking()  # type: ignore[attr-defined]
    else:
        popularity = {}

    # -- Build pipeline & spider -------------------------------------------
    profile = ProfileEngine(cfg.profile_path, cfg.output_dir)
    pipeline = OutputPipeline(cfg, profile)

    spider = GSMArenaSpider(cfg, pipeline, job=job)
    if popularity:
        spider._popularity = popularity  # type: ignore[attr-defined]

    t0 = time.monotonic()
    try:
        if args.stream:
            log.info("Stream mode")
            asyncio.run(_stream(spider))
        else:
            log.info("Blocking mode")
            spider.start(use_uvloop=cfg.use_uvloop)
    except KeyboardInterrupt:
        log.info("Interrupted — checkpoint saved by Scrapling")
    except Exception:
        log.exception("Unhandled exception during crawl")
        return 1
    finally:
        log.info("Total wall time: %.1f min", (time.monotonic() - t0) / 60)
    return 0


async def _stream(spider: Any) -> None:
    n = 0
    async for _ in spider.stream():
        n += 1
        if n % 50 == 0:
            stats = spider._pipeline.stats
            print(
                f"\r  ⚡ {n} | {stats.rate:.1f}/s"
                f" | bans={spider._ban_count}"
                f" | warns={stats.total_validation_warnings}"
                f" | dead={len(spider._pipeline.dead_letter)}   ",
                end="",
                flush=True,
            )
    print()


def _cmd_dry_run() -> int:
    _init_logging("INFO", "logs/dry_run.log")
    log = logging.getLogger("dry-run")
    try:
        from scrapling.fetchers import Fetcher  # type: ignore[import-untyped]

        page = Fetcher.get("https://www.gsmarena.com/makers.php3")
        brands: list[tuple[str, str, int]] = []
        for a in page.css("div.st-text td > a"):
            href = str(a.attrib.get("href", ""))
            m = re.match(r"^([a-z0-9_\-]+)-phones-(\d+)\.php", href)
            if m:
                raw = " ".join(a.css("::text").getall()).strip()
                name = re.sub(r"\s*\d+\s*device.*$", "", raw, flags=re.I).strip()
                cm = re.search(r"(\d+)\s*device", raw, re.I)
                count = int(cm.group(1)) if cm else 0
                brands.append((m.group(1), name or m.group(1).title(), count))

        total = sum(c for _, _, c in brands)
        print(f"\nDiscovered {len(brands)} brands | ~{total:,} total devices\n")
        print(f"  {'SLUG':<30} {'NAME':<25} DEVICES")
        print(f"  {'-' * 30} {'-' * 25} -------")
        for slug, name, count in sorted(brands):
            cs = f"{count:>7,}" if count else "     ?"
            print(f"  {slug:<30} {name:<25} {cs}")
        print(
            f"\n  python run.py --sample-size 5   # ~{len(brands) * 15:,} devices (fast)"
        )
        print(f"  python run.py                   # ~{total:,} devices (full)\n")
    except Exception as exc:
        log.error("dry-run failed: %s", exc)
        return 1
    return 0


def _cmd_list_presets() -> int:
    from .crawl_job import list_presets

    presets = list_presets()
    print(f"\n  {'ID':<35} {'STRATEGY':<20} DESCRIPTION")
    print(f"  {'-' * 35} {'-' * 20} {'-' * 40}")
    for p in presets:
        print(f"  {p['id']:<35} {p['strategy']:<20} {p['description']}")
        if p["filters"]:
            print(f"    {'':35} filters: {p['filters']}")
    print("\n  Usage: python run.py --preset <ID>\n")
    return 0


def _cmd_show_job(preset: str | None, job_path: str | None) -> int:
    from .crawl_job import CrawlJob, get_preset

    try:
        if preset:
            job = get_preset(preset)
        elif job_path:
            job = CrawlJob.from_file(job_path)
        else:
            print("Provide --preset or --job", file=sys.stderr)
            return 1
        print(json.dumps(job.to_dict(), indent=2, ensure_ascii=False))
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


def _cmd_gen_profile(url: str, out: str) -> int:
    _init_logging("INFO", "logs/gen_profile.log")
    log = logging.getLogger("gen-profile")
    try:
        from scrapling.fetchers import Fetcher  # type: ignore[import-untyped]

        page = Fetcher.get(url)
        sections: list[str] = []
        for th in page.css("table.specs-list th"):
            label = " ".join(th.css("::text").getall()).strip()
            if label and label not in sections:
                sections.append(label)
        profile: dict[str, object] = {
            "_comment": f"Auto-generated from {url}",
            "_version": "6.0",
            "mode": "full",
            "include_sections": sections,
            "exclude_sections": [],
            "include_fields": [],
            "exclude_fields": ["tests_performance", "tests_loudspeaker_test"],
            "field_aliases": {
                "platform_os": "os_version",
                "platform_chipset": "chipset",
                "platform_cpu": "cpu",
                "platform_gpu": "gpu",
                "misc_models": "variant_codes_raw",
                "network_technology": "network_gen",
                "body_dimensions": "dimensions",
                "body_weight": "weight_g",
                "display_type": "screen_type",
                "display_size": "screen_size_inches",
                "display_resolution": "screen_resolution",
                "memory_internal": "storage_ram",
                "battery_capacity": "battery_mah",
                "misc_price": "price_eur",
            },
            "always_include_meta": True,
            "normalize_values": True,
            "extract_model_codes": True,
            "ai_canonicalize": False,
            "ai_enrich": False,
            "output_formats": {
                "csv": True,
                "json": True,
                "jsonl": True,
                "sqlite": True,
                "excel": False,
                "parquet": False,
            },
            "schema_export": True,
        }
        Path(out).parent.mkdir(parents=True, exist_ok=True)
        with open(out, "w", encoding="utf-8") as fh:
            json.dump(profile, fh, indent=2, ensure_ascii=False)
        print(f"\nProfile ({len(sections)} sections) → {out}")
        print(f"Sections: {sections}\n")
    except Exception as exc:
        log.error("gen-profile failed: %s", exc)
        return 1
    return 0


def _cmd_validate(csv_path: str) -> int:
    _init_logging("INFO", "logs/validate.log")
    log = logging.getLogger("validate")
    log.info("Validating: %s", csv_path)
    try:
        from .enricher import DataEnricher

        enricher = DataEnricher()
        total = 0
        total_warnings = 0
        total_errors = 0
        issues: list[dict[str, object]] = []
        with open(csv_path, encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                total += 1
                vr = enricher.validate(dict(row))
                total_warnings += len(vr.warnings)
                total_errors += len(vr.errors)
                if vr.warnings or vr.errors:
                    issues.append(
                        {
                            "url": row.get("url", ""),
                            "brand": row.get("brand", ""),
                            "model": row.get("model_name", ""),
                            "warnings": vr.warnings,
                            "errors": vr.errors,
                        }
                    )
        report = {
            "total_records": total,
            "records_with_issues": len(issues),
            "total_warnings": total_warnings,
            "total_errors": total_errors,
            "issues": issues[:500],
        }
        out_path = Path(csv_path).parent / "validation_report.json"
        with open(out_path, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2, ensure_ascii=False)
        print(
            f"\nValidation: {total:,} records | {len(issues):,} issues | "
            f"{total_warnings:,} warnings | {total_errors:,} errors"
        )
        print(f"Report → {out_path}\n")
    except Exception as exc:
        log.error("validate failed: %s", exc)
        return 1
    return 0


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> int:
    args = _build_parser().parse_args()
    cmd: str | None = args.command

    if cmd == "dry-run":
        return _cmd_dry_run()
    if cmd == "list-presets":
        return _cmd_list_presets()
    if cmd == "show-job":
        return _cmd_show_job(
            getattr(args, "preset", None),
            getattr(args, "job_path", None),
        )
    if cmd == "gen-profile":
        return _cmd_gen_profile(args.url, args.out)
    if cmd == "validate":
        return _cmd_validate(args.csv_path)
    return _cmd_scrape(args)


if __name__ == "__main__":
    sys.exit(main())
