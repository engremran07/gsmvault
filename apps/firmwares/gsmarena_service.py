"""
GSMArena Ingestor Service — bridges the scraper into Django models.

Maps scraped device data to GSMArenaDevice, SyncRun, and SyncConflict models.
Optionally creates/updates Brand and Model records from scraped data.

Fallback chain (tried in order):
  1. Scrapling Spider (stealth sessions) — full crawl with all strategies
  2. Wayback Machine fallback — cached GSMArena pages, same parser
  3. Direct HTTP with curl_cffi impersonation rotation
  4. Direct HTTP with httpx + realistic headers

When the primary spider gets rate-limited (429), the service automatically
cascades through alternative fetch methods before giving up.
"""

import logging
import re
import time
from datetime import datetime
from typing import Any

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

logger = logging.getLogger(__name__)


class GSMArenaIngestor:
    """
    Ingests scraped GSMArena device data into the Django ORM.

    Usage:
        ingestor = GSMArenaIngestor(dry_run=False, auto_link=True)
        run = ingestor.start_run()
        for item in scraped_items:
            ingestor.ingest_device(item)
        ingestor.finish_run()
    """

    def __init__(
        self,
        *,
        dry_run: bool = False,
        auto_link: bool = True,
        exclude_discontinued: bool = False,
    ) -> None:
        self.dry_run = dry_run
        self.auto_link = auto_link
        self.exclude_discontinued = exclude_discontinued
        self._run: Any | None = None
        # Batch counters to reduce DB writes (flush every _FLUSH_INTERVAL)
        self._pending_checked = 0
        self._pending_created = 0
        self._pending_updated = 0
        self._flush_interval = 5

    def start_run(self) -> Any:
        """Create a SyncRun to track this ingestion batch."""
        from .models import SyncRun

        self._run = SyncRun.objects.create(status="running")
        logger.info("GSMArena sync run #%s started", self._run.pk)
        return self._run

    def finish_run(self, *, success: bool = True) -> Any:
        """Mark the current SyncRun as completed."""
        if not self._run:
            return None

        # Flush any pending counter increments before completing
        self._flush_counters()

        # Re-read from DB to get the latest cancel_requested value
        self._run.refresh_from_db()
        if self._run.cancel_requested or self._run.status == "stopped":
            self._run.status = "stopped"
        else:
            self._run.status = "success" if success else "failed"
        self._run.completed_at = timezone.now()
        self._run.save(update_fields=["status", "completed_at"])
        logger.info(
            "GSMArena sync run #%s finished (%s): checked=%d created=%d updated=%d",
            self._run.pk,
            self._run.status,
            self._run.devices_checked,
            self._run.devices_created,
            self._run.devices_updated,
        )
        return self._run

    def is_cancelled(self) -> bool:
        """Check if the current run has been cancelled via admin."""
        if not self._run:
            return False
        from .models import SyncRun

        cancelled = (
            SyncRun.objects.filter(pk=self._run.pk)
            .values_list("cancel_requested", flat=True)
            .first()
        )
        return bool(cancelled)

    def _flush_counters(self) -> None:
        """Flush accumulated counter increments to the DB in one UPDATE."""
        from django.db.models import F

        if not self._run:
            return
        if not (
            self._pending_checked or self._pending_created or self._pending_updated
        ):
            return

        from .models import SyncRun

        SyncRun.objects.filter(pk=self._run.pk).update(
            devices_checked=F("devices_checked") + self._pending_checked,
            devices_created=F("devices_created") + self._pending_created,
            devices_updated=F("devices_updated") + self._pending_updated,
        )
        # Sync in-memory object
        self._run.devices_checked += self._pending_checked
        self._run.devices_created += self._pending_created
        self._run.devices_updated += self._pending_updated
        self._pending_checked = 0
        self._pending_created = 0
        self._pending_updated = 0

    def _maybe_flush(self) -> None:
        """Auto-flush when accumulated count crosses the threshold."""
        total_pending = (
            self._pending_checked + self._pending_created + self._pending_updated
        )
        if total_pending >= self._flush_interval:
            self._flush_counters()

    def ingest_device(self, data: dict[str, Any]) -> Any | None:
        """
        Ingest a single scraped device record into GSMArenaDevice.

        Args:
            data: Flat dict from scraper spider output.

        Returns:
            The GSMArenaDevice instance (or None in dry_run mode).
        """

        brand = str(data.get("brand", "")).strip()
        model_name = str(data.get("model_name", "")).strip()
        url = str(data.get("url", "")).strip()

        if not brand or not model_name:
            logger.warning("Skipping device with missing brand/model: %s", data)
            self._record_error(f"Missing brand or model_name in record: {url}")
            return None

        # Skip discontinued devices when requested
        if self.exclude_discontinued:
            launch_status = str(
                data.get("launch_status_clean", "")
                or data.get("launch_status", "")
                or data.get("misc_status", "")
            ).lower()
            if "discontinued" in launch_status:
                logger.debug("Skipping discontinued device: %s %s", brand, model_name)
                return None

        gsmarena_id = self._derive_gsmarena_id(data)
        if not gsmarena_id:
            logger.warning("Cannot derive gsmarena_id for %s %s", brand, model_name)
            self._record_error(f"Cannot derive gsmarena_id: {brand} {model_name}")
            return None

        if self._run:
            self._pending_checked += 1
            self._maybe_flush()

        if self.dry_run:
            logger.info(
                "[DRY RUN] Would ingest: %s %s (%s)", brand, model_name, gsmarena_id
            )
            return None

        return self._upsert_device(gsmarena_id, brand, model_name, url, data)

    @staticmethod
    def _extract_enriched_fields(data: dict[str, Any]) -> dict[str, str]:
        """Extract dedicated spec fields from the scraped data dict."""
        # Model codes / variant names
        model_codes = str(data.get("model_variants_str", ""))[:500]
        marketed_as = str(data.get("full_name", ""))[:500]

        # Chipset — try multiple possible keys
        chipset = str(
            data.get("platform_chipset", "") or data.get("quick_processor", "")
        )[:300]

        # OS version — parse from platform_os
        platform_os = str(data.get("platform_os", "") or data.get("quick_os", ""))
        os_version = ""
        os_upgradeable_to = ""
        if platform_os:
            parts = platform_os.split(",")
            os_version = parts[0].strip()[:200]
            for part in parts[1:]:
                cleaned = part.strip().lower()
                if "upgrad" in cleaned or "planned" in cleaned:
                    os_upgradeable_to = part.strip()[:200]
                    break

        return {
            "marketed_as": marketed_as,
            "model_codes": model_codes,
            "chipset": chipset,
            "os_version": os_version,
            "os_upgradeable_to": os_upgradeable_to,
        }

    @transaction.atomic
    def _upsert_device(
        self,
        gsmarena_id: str,
        brand: str,
        model_name: str,
        url: str,
        data: dict[str, Any],
    ) -> Any:
        """Create or update a GSMArenaDevice record."""
        from .models import GSMArenaDevice

        image_url = str(data.get("image_url", ""))[:500]
        now = timezone.now()
        enriched = self._extract_enriched_fields(data)

        existing = GSMArenaDevice.objects.filter(gsmarena_id=gsmarena_id).first()

        if existing:
            self._detect_conflicts(existing, data)
            existing.brand = brand
            existing.model_name = model_name
            existing.url = url[:500]
            existing.specs = data
            existing.image_url = image_url
            existing.last_synced_at = now
            existing.marketed_as = enriched["marketed_as"]
            existing.model_codes = enriched["model_codes"]
            existing.chipset = enriched["chipset"]
            existing.os_version = enriched["os_version"]
            existing.os_upgradeable_to = enriched["os_upgradeable_to"]
            existing.save()
            if self._run:
                self._pending_updated += 1
                self._maybe_flush()
            logger.debug("Updated GSMArenaDevice: %s", gsmarena_id)
            device = existing
        else:
            device = GSMArenaDevice.objects.create(
                gsmarena_id=gsmarena_id,
                brand=brand,
                model_name=model_name,
                url=url[:500],
                specs=data,
                image_url=image_url,
                last_synced_at=now,
                review_status=GSMArenaDevice.ReviewStatus.PENDING,
                marketed_as=enriched["marketed_as"],
                model_codes=enriched["model_codes"],
                chipset=enriched["chipset"],
                os_version=enriched["os_version"],
                os_upgradeable_to=enriched["os_upgradeable_to"],
            )
            if self._run:
                self._pending_created += 1
                self._maybe_flush()
            logger.debug("Created GSMArenaDevice: %s", gsmarena_id)

        if self.auto_link and not device.local_device:
            self._try_link_local_device(device)

        return device

    def _detect_conflicts(self, existing: Any, new_data: dict[str, Any]) -> None:
        """Compare existing specs with new data and log SyncConflict records."""
        if not self._run:
            return

        from .models import SyncConflict

        old_specs = existing.specs or {}
        conflict_fields = ["model_name", "brand", "image_url"]
        for field in conflict_fields:
            old_val = str(old_specs.get(field, ""))
            new_val = str(new_data.get(field, ""))
            if old_val and new_val and old_val != new_val:
                SyncConflict.objects.create(
                    gsmarena_device=existing,
                    run=self._run,
                    field_name=field,
                    local_value=old_val,
                    remote_value=new_val,
                )

    def _try_link_local_device(self, gsm_device: Any) -> None:
        """Attempt to link GSMArenaDevice to a local Device record."""
        try:
            from apps.devices.models import Device

            device = Device.objects.filter(
                brand__name__iexact=gsm_device.brand,
                name__icontains=gsm_device.model_name,
            ).first()
            if device:
                gsm_device.local_device = device
                gsm_device.save(update_fields=["local_device"])
                logger.debug(
                    "Linked GSMArenaDevice %s → Device #%s",
                    gsm_device.gsmarena_id,
                    device.pk,
                )
        except Exception:
            logger.debug("Could not link device (devices app may not be ready)")

    def _derive_gsmarena_id(self, data: dict[str, Any]) -> str:
        """
        Derive a unique gsmarena_id from the scraped data.

        Priority: URL slug > brand_slug + model_name > brand + model_name
        """
        url = str(data.get("url", ""))
        if url:
            # Extract slug from URL like "samsung_galaxy_s24_ultra-12345.php"
            slug = url.rstrip("/").rsplit("/", 1)[-1]
            if slug.endswith(".php"):
                slug = slug[:-4]
            if slug:
                return slug

        brand_slug = str(data.get("brand_slug", ""))
        model_name = str(data.get("model_name", ""))
        if brand_slug and model_name:
            return f"{brand_slug}_{model_name.lower().replace(' ', '_')}"

        brand = str(data.get("brand", ""))
        if brand and model_name:
            return f"{brand.lower().replace(' ', '_')}_{model_name.lower().replace(' ', '_')}"

        return ""

    def _record_error(self, msg: str) -> None:
        """Append an error to the current SyncRun."""
        if self._run:
            errors = self._run.errors or []
            errors.append({"error": msg, "ts": timezone.now().isoformat()})
            self._run.errors = errors
            self._run.save(update_fields=["errors"])


def materialize_approved_device(gsm_device_id: int) -> dict[str, Any]:
    """Create or link Brand and Model records for an approved GSMArenaDevice.

    Called after admin approves a scraped GSMArena device.  Creates the
    Brand (if it doesn't exist) and Model (if it doesn't exist) in the
    firmwares catalogue and links the GSMArenaDevice to the local Device
    record when possible.

    Returns a summary dict with keys: brand_created, model_created, brand, model.
    """
    from django.utils.text import slugify

    from .models import Brand, GSMArenaDevice, Model

    result: dict[str, Any] = {
        "brand_created": False,
        "model_created": False,
        "brand": "",
        "model": "",
    }

    dev = GSMArenaDevice.objects.filter(pk=gsm_device_id).first()
    if not dev:
        return result

    brand_name = dev.brand.strip()
    model_name = dev.model_name.strip()
    if not brand_name or not model_name:
        return result

    # --- Brand ---
    brand_slug = slugify(brand_name)
    if not brand_slug:
        return result
    brand_obj, brand_created = Brand.objects.get_or_create(
        slug=brand_slug,
        defaults={"name": brand_name},
    )
    result["brand_created"] = brand_created
    result["brand"] = brand_obj.name

    # --- Model ---
    model_slug = slugify(model_name)
    if not model_slug:
        return result
    model_defaults: dict[str, Any] = {
        "name": model_name,
        "marketing_name": dev.marketed_as or "",
        "model_code": (dev.model_codes or "")[:64],
        "chipset": (dev.chipset or "")[:256],
        "os_version": (dev.os_version or "")[:128],
        "image_url": (dev.image_url or "")[:500],
    }
    model_obj, model_created = Model.objects.get_or_create(
        brand=brand_obj,
        slug=model_slug,
        defaults=model_defaults,
    )
    result["model_created"] = model_created
    result["model"] = model_obj.name

    # Update fields if model already existed but was sparse
    if not model_created:
        changed = False
        _sync_pairs: list[tuple[str, str, int]] = [
            ("marketing_name", dev.marketed_as or "", 255),
            ("model_code", (dev.model_codes or "")[:64], 64),
            ("chipset", (dev.chipset or "")[:256], 256),
            ("os_version", (dev.os_version or "")[:128], 128),
            ("image_url", (dev.image_url or "")[:500], 500),
        ]
        update_fields: list[str] = []
        for field_name, new_val, _max_len in _sync_pairs:
            if not getattr(model_obj, field_name, "") and new_val:
                setattr(model_obj, field_name, new_val)
                update_fields.append(field_name)
                changed = True
        if changed:
            model_obj.save(update_fields=update_fields)

    return result


def _get_last_successful_method() -> str:
    """Query the most recent successful SyncRun for its method_used."""
    from .models import SyncRun

    last_run = (
        SyncRun.objects.filter(status="success", method_used__gt="")
        .order_by("-completed_at")
        .values_list("method_used", flat=True)
        .first()
    )
    return last_run or ""


def run_gsmarena_scrape(
    *,
    strategy: str = "brand_walk",
    preset: str | None = None,
    brand_limit: int | None = None,
    sample_size: int | None = None,
    dry_run: bool = False,
    auto_link: bool = True,
    exclude_scraped: bool = False,
    exclude_discontinued: bool = False,
) -> dict[str, Any]:
    """
    Run the GSMArena scraper with automatic multi-method fallback.

    Before running, checks the last successful SyncRun to determine
    which method worked previously and prioritises it.

    Tier ordering:
      - If last success was a fallback method → try fallback first, then spider
      - Otherwise → try spider first, then fallback

    Within the FetchChain, the last successful method is boosted to the
    top of the priority list so it is tried first.
    """
    ingestor = GSMArenaIngestor(
        dry_run=dry_run,
        auto_link=auto_link,
        exclude_discontinued=exclude_discontinued,
    )
    run = ingestor.start_run()

    total = 0
    method = "none"
    success = False

    try:
        # -- Determine preferred method from last successful run ------------
        last_method = _get_last_successful_method()
        if last_method:
            logger.info("Last successful scraping method: '%s'", last_method)
        else:
            logger.info("No previous successful method recorded — using default order")

        # If last success was a non-spider (fallback) method, try fallback first
        spider_first = last_method in ("", "spider")

        if spider_first:
            # --- Normal order: Spider → Fallback ----------------------------
            total, method = _try_spider_then_fallback(
                ingestor=ingestor,
                strategy=strategy,
                preset=preset,
                brand_limit=brand_limit,
                sample_size=sample_size,
                exclude_scraped=exclude_scraped,
                preferred_fallback=last_method if last_method != "spider" else "",
            )
        else:
            # --- Reversed: Fallback (preferred) → Spider -------------------
            logger.info(
                "Last method '%s' was a fallback — trying fallback tier first",
                last_method,
            )
            total, method = _try_fallback_then_spider(
                ingestor=ingestor,
                strategy=strategy,
                preset=preset,
                brand_limit=brand_limit,
                sample_size=sample_size,
                exclude_scraped=exclude_scraped,
                preferred_fallback=last_method,
            )

        success = total > 0

        # ── Final fallback: if GSMArena is fully blocked, try multi-source ─
        if not success and not ingestor.is_cancelled():
            logger.warning(
                "GSMArena fully blocked — cascading to multi-source discovery"
            )
            try:
                ms_result = run_multi_source_discovery(
                    brand_limit=brand_limit or 10,
                    max_workers=3,
                    per_site_delay=2.0,
                    auto_approve=False,
                )
                ms_count = ms_result.get("devices_ingested", 0)
                if ms_count > 0:
                    total += ms_count
                    method = "multi_source"
                    success = True
                    logger.info("Multi-source fallback: %d devices ingested", ms_count)
            except Exception:
                logger.exception("Multi-source fallback failed")

        if not success:
            ingestor._record_error(
                "All scraping methods exhausted — IP may be rate-limited"
            )

        # Persist which method succeeded
        _save_method_used(run, method)

    except Exception:
        logger.exception("run_gsmarena_scrape crashed — ensuring cleanup")
        ingestor._record_error("Scrape crashed unexpectedly (see server logs)")
    finally:
        ingestor.finish_run(success=success)

    result = _build_result(run, dry_run, method=method)

    # Attach rate limit info for the admin status endpoint
    try:
        from .scraper.fetch_methods import probe_available_methods

        result["available_methods"] = probe_available_methods()
    except ImportError:
        pass

    return result


def _try_spider_then_fallback(
    *,
    ingestor: GSMArenaIngestor,
    strategy: str,
    preset: str | None,
    brand_limit: int | None,
    sample_size: int | None,
    exclude_scraped: bool,
    preferred_fallback: str,
) -> tuple[int, str]:
    """Normal tier order: Spider first, then FetchChain fallback."""
    spider_count = _run_spider_tier(
        ingestor=ingestor,
        strategy=strategy,
        preset=preset,
        brand_limit=brand_limit,
        sample_size=sample_size,
        exclude_scraped=exclude_scraped,
    )
    if spider_count > 0 or ingestor.is_cancelled():
        return spider_count, "spider"

    logger.warning("Spider returned 0 devices — cascading to fallback methods")
    fallback_count, fallback_method = _run_fallback_tiers(
        ingestor=ingestor, preferred_method=preferred_fallback
    )
    method = fallback_method if fallback_count > 0 else "none"
    return spider_count + fallback_count, method


def _try_fallback_then_spider(
    *,
    ingestor: GSMArenaIngestor,
    strategy: str,
    preset: str | None,
    brand_limit: int | None,
    sample_size: int | None,
    exclude_scraped: bool,
    preferred_fallback: str,
) -> tuple[int, str]:
    """Reversed order: FetchChain (preferred method first), then Spider."""
    fallback_count, fallback_method = _run_fallback_tiers(
        ingestor=ingestor, preferred_method=preferred_fallback
    )
    if fallback_count > 0 or ingestor.is_cancelled():
        return fallback_count, fallback_method or preferred_fallback or "fallback"

    logger.warning(
        "Fallback returned 0 devices — cascading to spider",
    )
    spider_count = _run_spider_tier(
        ingestor=ingestor,
        strategy=strategy,
        preset=preset,
        brand_limit=brand_limit,
        sample_size=sample_size,
        exclude_scraped=exclude_scraped,
    )
    method = "spider" if spider_count > 0 else "none"
    return fallback_count + spider_count, method


def _save_method_used(run: Any, method: str) -> None:
    """Persist the method that succeeded on this SyncRun."""
    if run and method and method != "none":
        run.method_used = method[:50]
        run.save(update_fields=["method_used"])


def _run_spider_tier(
    *,
    ingestor: GSMArenaIngestor,
    strategy: str,
    preset: str | None,
    brand_limit: int | None,
    sample_size: int | None,
    exclude_scraped: bool,
) -> int:
    """Run the Scrapling spider. Returns number of items ingested."""
    try:
        from .scraper.crawl_job import CrawlJob, get_preset
        from .scraper.pipeline import OutputPipeline
        from .scraper.profile_engine import ProfileEngine
        from .scraper.settings import Settings
        from .scraper.spider import GSMArenaSpider
    except ImportError:
        logger.error("Scraper package not found at apps.firmwares.scraper")
        return 0

    cli_args: dict[str, Any] = {"crawl_strategy": strategy}
    if sample_size:
        cli_args["sample_size"] = sample_size
    if brand_limit:
        cli_args["brand_limit"] = brand_limit

    cfg = Settings.from_cli(**cli_args)
    cfg.stealth_listings = True

    job: CrawlJob | None = None
    if preset:
        job = get_preset(preset)
        if not job:
            logger.error("Unknown preset: %s", preset)
            return 0

    profile = ProfileEngine(cfg.profile_path, cfg.output_dir)
    pipeline = OutputPipeline(cfg, profile)

    if exclude_scraped:
        seeded = pipeline.dedup.seed_from_db()
        logger.info("Exclude-scraped: seeded %d into dedup", seeded)

    spider = GSMArenaSpider(cfg, pipeline, job=job)
    count = 0

    try:
        result = spider.start()
        logger.info("Spider finished: %d items, paused=%s", len(result), result.paused)
        for item in result:
            try:
                ingestor.ingest_device(item)
                count += 1
            except Exception:
                logger.exception(
                    "Spider tier: failed to ingest item (brand=%s, model=%s)",
                    item.get("brand", "?"),
                    item.get("model_name", "?"),
                )
    except Exception:
        logger.exception("Spider tier failed")

    return count


def _run_fallback_tiers(
    *, ingestor: GSMArenaIngestor, preferred_method: str = ""
) -> tuple[int, str]:
    """
    Fallback: fetch GSMArena brand list + device pages via FetchChain.

    Uses the same parser as the spider but fetches pages through
    alternative HTTP methods (Wayback, curl_cffi, httpx).

    If preferred_method is set, that method is tried first in the chain.

    Automatically harvests a free proxy pool for IP rotation.

    Returns:
        (devices_ingested, method_name) where method_name is the actual
        FetchChain method that succeeded (e.g. "wayback", "curl_cffi/chrome136").
    """
    try:
        from .scraper.fetch_methods import FetchChain
        from .scraper.parser import DeviceParser
        from .scraper.proxy_pool import ProxyPool
    except ImportError:
        logger.error("fetch_methods or parser not importable")
        return 0, ""

    # Harvest proxy pool for IP rotation
    pool: ProxyPool | None = None
    try:
        pool = ProxyPool()
        pool.harvest()
        stats = pool.get_stats()
        logger.info(
            "ProxyPool: %d alive proxies from %d sources",
            stats["alive"],
            len(stats.get("sources", {})),
        )
        if stats["alive"] == 0:
            logger.warning("ProxyPool: no working proxies — falling back to direct")
            pool = None
    except Exception as exc:
        logger.warning("ProxyPool: harvest failed (%s) — using direct", exc)
        pool = None

    chain = FetchChain(preferred_method=preferred_method, proxy_pool=pool)
    if preferred_method:
        logger.info(
            "Fallback: preferred method '%s' boosted to top of chain",
            preferred_method,
        )
    parser = DeviceParser()
    total_ingested = 0

    # Step 1: Fetch brands page
    brands_url = "https://www.gsmarena.com/makers.php3"
    brands_result = chain.fetch(brands_url)

    if not brands_result.html or brands_result.is_banned:
        logger.error(
            "Fallback: cannot fetch brands page (method=%s, banned=%s)",
            brands_result.method_name,
            brands_result.is_banned,
        )
        _record_rate_limit(chain, ingestor)
        return 0, ""

    logger.info(
        "Fallback: brands page fetched via %s (%d bytes)",
        brands_result.method_name,
        len(brands_result.html),
    )

    # Step 2: Parse brand links from HTML
    brands = _parse_brands_from_html(brands_result.html)
    logger.info("Fallback: %d brands discovered", len(brands))

    if not brands:
        return 0, ""

    # Step 3: For each brand, fetch listing pages and device pages
    for brand_info in brands[:30]:  # Limit to avoid massive crawls
        # Check cancellation before each brand
        if ingestor.is_cancelled():
            logger.info("Fallback: cancelled by admin — stopping brand walk")
            break

        brand_name = brand_info["name"]
        brand_url = brand_info["url"]

        listing_result = chain.fetch(brand_url)
        if not listing_result.html or listing_result.is_banned:
            logger.warning("Fallback: skipping %s (banned on listing)", brand_name)
            if listing_result.is_banned and chain.rate_state.ban_count >= 5:
                logger.error("Fallback: too many bans — stopping brand walk")
                break
            continue

        # Parse device cards from brand listing
        device_cards = _parse_device_cards_from_html(
            listing_result.html, brand_name, brand_info["slug"]
        )
        logger.info(
            "Fallback: %s — %d devices found via %s",
            brand_name,
            len(device_cards),
            listing_result.method_name,
        )

        # Step 4: Fetch device spec pages (limit per brand)
        for card in device_cards[:20]:
            # Check cancellation before each device
            if ingestor.is_cancelled():
                logger.info("Fallback: cancelled by admin — stopping device walk")
                break

            device_url = card["url"]
            device_result = chain.fetch(device_url)

            if not device_result.html or device_result.is_banned:
                if chain.rate_state.ban_count >= 10:
                    logger.error("Fallback: too many bans — stopping entirely")
                    _record_rate_limit(chain, ingestor)
                    return total_ingested, chain.last_successful_method
                continue

            # Parse device spec page using the same parser
            record = _parse_device_from_html(
                parser,
                device_result.html,
                device_url,
                card.get("brand", brand_name),
                card.get("brand_slug", brand_info["slug"]),
                card.get("model_name", ""),
                card.get("image_url", ""),
            )

            if record:
                ingestor.ingest_device(record)
                total_ingested += 1

            # Respectful delay between device fetches
            time.sleep(2.0)

    if chain.rate_state.ban_count > 0:
        _record_rate_limit(chain, ingestor)

    logger.info("Fallback tiers: %d devices ingested total", total_ingested)
    return total_ingested, chain.last_successful_method


def _parse_brands_from_html(html: str) -> list[dict[str, str]]:
    """Parse brand list from GSMArena makers.php3 HTML."""
    brands: list[dict[str, str]] = []
    # Pattern: <a href="samsung-phones-9.php">Samsung<br><span>1449 devices</span></a>
    pattern = re.compile(
        r'<a\s+href="([a-z0-9_-]+-phones-\d+\.php)"[^>]*>'
        r"([^<]+?)(?:<br|<span)",
        re.IGNORECASE,
    )
    for match in pattern.finditer(html):
        href = match.group(1)
        name = match.group(2).strip()
        slug_match = re.match(r"^([a-z0-9_-]+)-phones-", href)
        slug = slug_match.group(1) if slug_match else name.lower().replace(" ", "_")
        brands.append(
            {
                "name": name,
                "slug": slug,
                "url": f"https://www.gsmarena.com/{href}",
            }
        )
    return brands


def _parse_device_cards_from_html(
    html: str, brand: str, brand_slug: str
) -> list[dict[str, str]]:
    """Parse device card list from a GSMArena brand listing page HTML."""
    cards: list[dict[str, str]] = []
    # Pattern: <a href="samsung_galaxy_s24_ultra-12345.php">
    # Model name in <strong> or <span> inside the <a>
    link_pattern = re.compile(
        r'<a\s+href="([a-z0-9_-]+-\d+\.php)"[^>]*>',
        re.IGNORECASE,
    )
    name_pattern = re.compile(
        r"<(?:strong|span)[^>]*>([^<]+)</(?:strong|span)>",
    )

    for link_match in link_pattern.finditer(html):
        href = link_match.group(1)
        # Skip non-device links
        if "phones-" in href or "news-" in href or "review-" in href:
            continue

        # Find model name near this link
        context = html[link_match.start() : link_match.start() + 500]
        name_match = name_pattern.search(context)
        model_name = name_match.group(1).strip() if name_match else ""

        if not model_name:
            continue

        # Find image URL
        img_match = re.search(r'<img[^>]+src="([^"]+)"', context)
        image_url = img_match.group(1) if img_match else ""

        cards.append(
            {
                "url": f"https://www.gsmarena.com/{href}",
                "brand": brand,
                "brand_slug": brand_slug,
                "model_name": model_name,
                "image_url": image_url,
            }
        )

    return cards


def _parse_device_from_html(
    parser: Any,
    html: str,
    url: str,
    brand: str,
    brand_slug: str,
    model_name: str,
    image_url: str,
) -> dict[str, Any] | None:
    """Parse device specs from raw HTML using a mock response wrapper."""
    try:
        # Create a minimal response-like object for the parser
        response = _HtmlResponse(html, url)
        record = parser.parse(response, brand, brand_slug, model_name, image_url)
        return record
    except Exception as exc:
        logger.warning("Fallback: parse failed for %s: %s", url, exc)
        return None


class _HtmlResponse:
    """Minimal response wrapper for parser compatibility."""

    def __init__(self, html: str, url: str) -> None:
        self._html = html
        self.url = url
        self._adapter: Any = None

    def css(self, selector: str) -> Any:
        """CSS selector via Scrapling's Selector."""
        if self._adapter is None:
            self._adapter = self._make_adapter()
        return self._adapter.css(selector)

    def _make_adapter(self) -> Any:
        try:
            from scrapling.parser import Adaptor  # type: ignore[import-untyped]

            return Adaptor(self._html, url=self.url)
        except ImportError:
            from scrapling import Selector  # type: ignore[import-untyped]

            return Selector(self._html)


def _record_rate_limit(chain: Any, ingestor: GSMArenaIngestor) -> None:
    """Record rate limit info from the FetchChain into the SyncRun."""
    state = chain.rate_state
    ingestor._record_error(
        f"Rate limited: {state.ban_count} bans, "
        f"retry_after={state.retry_after_seconds}s, "
        f"methods_exhausted={state.methods_exhausted}"
    )


def _build_result(run: Any, dry_run: bool, *, method: str = "spider") -> dict[str, Any]:
    """Build the standard result dict from a SyncRun."""
    return {
        "run_id": run.pk if run else None,
        "status": run.status if run else "error",
        "devices_checked": run.devices_checked if run else 0,
        "devices_created": run.devices_created if run else 0,
        "devices_updated": run.devices_updated if run else 0,
        "errors": run.errors if run else [],
        "dry_run": dry_run,
        "method": method,
    }


def lookup_gsmarena_brand(brand_name: str) -> dict[str, Any]:
    """
    Look up brand info from existing GSMArenaDevice records.

    Returns dict with description extracted from specs.
    """
    from .models import GSMArenaDevice

    device = (
        GSMArenaDevice.objects.filter(brand__iexact=brand_name)
        .order_by("-last_synced_at")
        .first()
    )
    if not device:
        return {}

    specs = device.specs or {}
    brand_desc = f"{brand_name} — {specs.get('full_name', device.model_name)}"
    return {"description": brand_desc}


def lookup_gsmarena_model(brand_name: str, model_name: str) -> dict[str, Any]:
    """
    Look up model info from existing GSMArenaDevice records.

    Returns dict with marketing_name, model_code, release_date, description.
    """
    from .models import GSMArenaDevice

    device = (
        GSMArenaDevice.objects.filter(
            brand__iexact=brand_name,
            model_name__icontains=model_name,
        )
        .order_by("-last_synced_at")
        .first()
    )
    if not device:
        return {}

    specs = device.specs or {}
    result: dict[str, Any] = {}

    if specs.get("full_name"):
        result["marketing_name"] = specs["full_name"]

    model_codes = specs.get("misc_models", "")
    if model_codes:
        first_code = model_codes.split(",")[0].strip()
        result["model_code"] = first_code

    announced = specs.get("launch_announced", "")
    if announced:
        result["release_date"] = _parse_launch_date(announced)

    desc_parts = []
    if specs.get("display_size"):
        desc_parts.append(specs["display_size"])
    if specs.get("platform_chipset"):
        desc_parts.append(specs["platform_chipset"])
    if specs.get("battery_type"):
        desc_parts.append(specs["battery_type"])
    if desc_parts:
        result["description"] = " | ".join(desc_parts)

    return result


def lookup_gsmarena_variant(
    brand_name: str, model_name: str, region: str
) -> dict[str, Any]:
    """
    Look up variant info from existing GSMArenaDevice records.

    Returns dict with chipset, ram_options, storage_options, board_id.
    """
    from .models import GSMArenaDevice

    device = (
        GSMArenaDevice.objects.filter(
            brand__iexact=brand_name,
            model_name__icontains=model_name,
        )
        .order_by("-last_synced_at")
        .first()
    )
    if not device:
        return {}

    specs = device.specs or {}
    result: dict[str, Any] = {}

    if specs.get("platform_chipset"):
        result["chipset"] = specs["platform_chipset"]

    memory = specs.get("memory_internal", "")
    if memory:
        ram_set: set[str] = set()
        storage_set: set[str] = set()
        for part in memory.split(","):
            part = part.strip()
            tokens = part.split()
            for token in tokens:
                if "GB" in token and "RAM" in part:
                    ram_set.add(token)
                elif "GB" in token or "TB" in token:
                    storage_set.add(token)
        if ram_set:
            result["ram_options"] = ", ".join(sorted(ram_set))
        if storage_set:
            result["storage_options"] = ", ".join(sorted(storage_set))

    model_codes = specs.get("misc_models", "")
    if model_codes:
        codes = [c.strip() for c in model_codes.split(",")]
        if region:
            region_lower = region.lower()
            for code in codes:
                if region_lower in code.lower():
                    result["board_id"] = code
                    break
        if "board_id" not in result and codes:
            result["board_id"] = codes[0]

    return result


def _parse_launch_date(announced: str) -> str:
    """
    Parse GSMArena 'launch_announced' string into YYYY-MM-DD or YYYY.

    Examples: "2024, January 17" → "2024-01-17", "2024" → "2024"
    """
    announced = announced.strip()
    months = {
        "january": 1,
        "february": 2,
        "march": 3,
        "april": 4,
        "may": 5,
        "june": 6,
        "july": 7,
        "august": 8,
        "september": 9,
        "october": 10,
        "november": 11,
        "december": 12,
    }

    parts = [p.strip() for p in announced.replace(",", " ").split()]
    year = ""
    month = 0
    day = 0

    for part in parts:
        if part.isdigit() and len(part) == 4:
            year = part
        elif part.lower() in months:
            month = months[part.lower()]
        elif part.isdigit() and len(part) <= 2:
            day = int(part)

    if year and month and day:
        try:
            dt = datetime(int(year), month, day)
            return dt.strftime("%Y-%m-%d")
        except ValueError:
            pass
    if year and month:
        return f"{year}-{month:02d}-01"
    return year


# ---------------------------------------------------------------------------
# Multi-Source Discovery — "Swarm Scrape"
# ---------------------------------------------------------------------------


def run_multi_source_discovery(
    *,
    source_slugs: list[str] | None = None,
    max_workers: int = 4,
    per_site_delay: float = 5.0,
    brand_limit: int = 30,
    dry_run: bool = False,
    auto_approve: bool = False,
) -> dict[str, Any]:
    """
    Discover brands/models from multiple specification sites concurrently.

    Each source runs in its own thread with independent rate limiting.
    Results are cross-referenced: devices found by 2+ sources get higher
    confidence. All discoveries go through the ingestion approval workflow.

    This is complementary to the existing GSMArena-specific scraper — it
    sweeps the broader ecosystem for data that GSMArena might miss.
    """
    try:
        from .scraper.multi_source import run_multi_source_scrape
        from .scraper.proxy_pool import ProxyPool
    except ImportError:
        logger.error("multi_source or proxy_pool not importable")
        return {"status": "error", "error": "Missing scraper modules"}

    from .models import SyncRun

    # Create a tracking run
    run = SyncRun.objects.create(
        status="running",
        method_used="multi_source",
    )

    # Harvest proxy pool
    pool: ProxyPool | None = None
    try:
        pool = ProxyPool()
        pool.harvest()
        stats = pool.get_stats()
        logger.info(
            "MultiSource: %d alive proxies harvested",
            stats["alive"],
        )
        if stats["alive"] == 0:
            pool = None
    except Exception as exc:
        logger.warning("MultiSource: proxy harvest failed (%s)", exc)
        pool = None

    # Cancel-check via SyncRun status
    def _is_cancelled() -> bool:
        run.refresh_from_db(fields=["status"])
        return run.status in ("stopped", "cancelled")

    # Run the swarm
    result = run_multi_source_scrape(
        source_slugs=source_slugs,
        max_workers=max_workers,
        per_site_delay=per_site_delay,
        brand_limit=brand_limit,
        cancel_check=_is_cancelled,
        proxy_pool=pool,
    )

    # Ingest the merged records as GSMArenaDevice entries (pending approval)
    ingested = 0
    if not dry_run:
        ingested = _ingest_multi_source_records(result.merged_records, auto_approve)

    # Finalise the run
    run.status = "success" if result.unique_devices > 0 else "failed"
    run.devices_checked = result.total_devices
    run.devices_created = ingested
    run.save(update_fields=["status", "devices_checked", "devices_created"])

    return {
        "run_id": run.pk,
        "status": run.status,
        "sources_attempted": result.sources_attempted,
        "sources_succeeded": result.sources_succeeded,
        "sources_banned": result.sources_banned,
        "total_brands": result.total_brands,
        "total_devices": result.total_devices,
        "unique_devices": result.unique_devices,
        "cross_referenced": result.cross_referenced,
        "ingested": ingested,
        "elapsed_seconds": round(result.elapsed_seconds, 1),
        "per_source": [
            {
                "source": sr.source_name,
                "brands": sr.brands_found,
                "devices": sr.devices_found,
                "banned": sr.was_banned,
                "elapsed": round(sr.elapsed_seconds, 1),
                "errors": sr.errors[:3],
            }
            for sr in result.per_source
        ],
        "dry_run": dry_run,
        "proxy_stats": pool.get_stats() if pool else None,
    }


def _ingest_multi_source_records(
    records: list[dict[str, Any]], auto_approve: bool = False
) -> int:
    """
    Create GSMArenaDevice entries from multi-source records.

    Records go into the standard approval workflow (pending by default).
    Cross-referenced records (found by 2+ sources) can optionally be
    auto-approved since they have higher confidence.
    """
    from .models import GSMArenaDevice

    created = 0
    for record in records:
        brand = record.get("brand", "")
        model_name = record.get("model_name", "")
        if not brand or not model_name:
            continue

        # Derive a deterministic gsmarena_id for multi-source records
        brand_slug = _normalise(brand).replace(" ", "_")
        model_slug = _normalise(model_name).replace(" ", "_")
        gsmarena_id = f"ms_{brand_slug}_{model_slug}"

        # Deduplicate: check by gsmarena_id (primary key) or brand+model
        exists = GSMArenaDevice.objects.filter(
            Q(gsmarena_id=gsmarena_id)
            | Q(brand__iexact=brand, model_name__iexact=model_name)
        ).exists()
        if exists:
            continue

        # Determine review status
        is_cross_ref = record.get("cross_referenced", False)
        review = (
            GSMArenaDevice.ReviewStatus.APPROVED
            if (auto_approve and is_cross_ref)
            else GSMArenaDevice.ReviewStatus.PENDING
        )

        GSMArenaDevice.objects.create(
            gsmarena_id=gsmarena_id,
            brand=brand,
            model_name=model_name,
            url=record.get("source_url", "")[:500],
            image_url=record.get("image_url", "")[:500],
            review_status=review,
            last_synced_at=timezone.now(),
            specs={
                "multi_source": True,
                "sources": record.get("sources", []),
                "source_count": record.get("source_count", 1),
                "confidence": record.get("confidence", 0.2),
            },
        )
        created += 1

    logger.info("MultiSource: ingested %d new device records", created)
    return created


def _normalise(text: str) -> str:
    """Lowercase, strip non-alphanum, collapse whitespace."""
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", "", text.lower())).strip()
