---
name: web-scraping
description: "Web scraping patterns with Scrapling and Django integration. Use when: building scrapers, data pipelines, GSMArena integration, OEM firmware scraping, rate limiting, data mapping."
---

# Web Scraping Skill

## GSMArena Integration

The scraper lives in `apps/firmwares/scraper/` — absorbed from the former standalone `gsmarena_v6` package.

### Core Usage

```python
from apps.firmwares.scraper.spider import GSMArenaSpider
from apps.firmwares.scraper.pipeline import Pipeline
from apps.firmwares.scraper.crawl_job import CrawlJob

spider = GSMArenaSpider(cfg, pipeline, job)
async for device_data in spider.stream():
    # Each yielded item is a parsed device dict
    process(device_data)
```

### 4 Strategies

| Strategy | Description |
|---|---|
| `brand_walk` | Walk all brands A-Z, scrape every device page |
| `search_targeted` | Search for specific models/brands |
| `rumor_mill` | Scrape rumored/upcoming devices only |
| `hybrid` | Combine brand_walk + rumor_mill for full coverage |

### 12 Presets

Preset jobs live in `apps/firmwares/scraper/preset_jobs/`. Each defines a strategy, brand filters, and scrape depth. Run via:

```bash
python manage.py scrape_gsmarena --preset full_database
```

---

## Django Model Mapping

All GSMArena models live in `apps/firmwares/models.py` (absorbed from dissolved `gsmarena_sync` app).

### GSMArenaDevice

| Field | Type | Description |
|---|---|---|
| `gsmarena_id` | CharField(unique) | GSMArena's internal device ID |
| `brand` | CharField | Device brand (Samsung, Apple, etc.) |
| `model_name` | CharField | Device model name |
| `url` | URLField | GSMArena device page URL |
| `specs` | JSONField | Full specs dict from scraper |
| `image_url` | URLField | Device image URL |
| `last_synced` | DateTimeField | Last successful sync timestamp |

### SyncRun

| Field | Type | Description |
|---|---|---|
| `status` | CharField | pending / running / completed / failed |
| `strategy` | CharField | Which scrape strategy was used |
| `devices_found` | IntegerField | Total devices encountered |
| `devices_created` | IntegerField | New devices inserted |
| `devices_updated` | IntegerField | Existing devices updated |
| `started_at` | DateTimeField | Run start time |
| `finished_at` | DateTimeField | Run end time |

### SyncConflict

| Field | Type | Description |
|---|---|---|
| `device` | FK → GSMArenaDevice | Which device has a conflict |
| `field` | CharField | Which field differs |
| `local_value` | TextField | Current DB value |
| `remote_value` | TextField | Incoming scraper value |
| `resolution` | CharField | pending / accept_remote / keep_local / manual |

---

## GSMArenaIngestor Pattern

Located in `apps/firmwares/gsmarena_service.py`. Orchestrates data flow from scraper to Django models.

```python
class GSMArenaIngestor:
    def start_run(self, strategy: str) -> SyncRun:
        """Create a new SyncRun record with status='running'."""

    def ingest_device(self, data: dict) -> GSMArenaDevice:
        """Upsert GSMArenaDevice by gsmarena_id.
        - If new: create device, increment devices_created
        - If existing: compare fields, create SyncConflict for differences
        """

    def finish_run(self) -> SyncRun:
        """Set status='completed', update stats, set finished_at."""
```

---

## Management Command

```powershell
& .\.venv\Scripts\python.exe manage.py scrape_gsmarena --strategy hybrid --preset full_database --settings=app.settings_dev
```

Command lives in `apps/firmwares/management/commands/scrape_gsmarena.py`.

```python
class Command(BaseCommand):
    help = "Run GSMArena scraper and ingest results"

    def add_arguments(self, parser):
        parser.add_argument("--strategy", default="hybrid")
        parser.add_argument("--preset", default="full_database")
        parser.add_argument("--dry-run", action="store_true")

    def handle(self, *args, **options):
        ingestor = GSMArenaIngestor()
        run = ingestor.start_run(strategy=options["strategy"])
        # ... run scraper, call ingest_device() per result
        ingestor.finish_run()
        self.stdout.write(self.style.SUCCESS(f"Sync complete: {run.devices_created} created"))
```

---

## Celery Task

```python
# apps/firmwares/tasks.py
from celery import shared_task

@shared_task(bind=True, max_retries=2)
def scrape_gsmarena_async(self, strategy="hybrid", preset="full_database"):
    """Run GSMArena scraper as async Celery task."""
    try:
        ingestor = GSMArenaIngestor()
        run = ingestor.start_run(strategy=strategy)
        # ... run scraper pipeline
        ingestor.finish_run()
    except Exception as exc:
        self.retry(exc=exc, countdown=300)
```

Usage: `scrape_gsmarena_async.delay(strategy="hybrid", preset="full_database")`

---

## Rate Limiting

- Respect `ScraperConfig.rate_limit_rpm` — configurable requests-per-minute
- Insert delays between requests: `asyncio.sleep(60 / rate_limit_rpm)`
- Use exponential backoff on HTTP 429 responses
- GSMArena is aggressive with blocking — rotate user agents, respect robots.txt
- Never parallel-scrape the same domain without rate limiting

---

## Data Pipeline

```
Raw JSON (from spider)
    → GSMArenaIngestor.ingest_device()
        → Upsert GSMArenaDevice (by gsmarena_id)
        → Detect conflicts → SyncConflict records
        → Optional: Link to Device model via brand + model_name match
```

Device linking happens post-ingest: match `GSMArenaDevice.brand` + `GSMArenaDevice.model_name` against `Device.brand` + `Device.model` in `apps/devices/`. This is a soft link — not all GSMArena devices have a corresponding Device record.

---

## Ingestion Job Approval Workflow

**CRITICAL**: Scraped data NEVER auto-inserts into the database. All scraped items go through admin review.

**Flow**: Scraper creates `IngestionJob` → status = `pending` → Admin reviews → `approved` or `rejected` → Processing pipeline → `done` or `failed`.

| Status | Meaning |
| --- | --- |
| `pending` | Awaiting admin review |
| `approved` | Admin approved — ready for processing |
| `rejected` | Admin rejected — will not be processed |
| `processing` | Being processed into firmware records |
| `done` | Successfully created firmware entry |
| `failed` | Processing failed (see `error` field) |
| `skipped` | Duplicate detected, auto-skipped |

Admin UI: **Admin Panel → Firmwares → Scraper → Pending Approval** with individual and bulk approve/reject actions.

---

## Common Mistakes

1. **Never auto-insert scraped data** — always create `IngestionJob` with `pending` status
2. **Always respect rate limits** — `ScraperConfig.rate_limit_rpm` is per-source, not global
3. **Proxy pool is required** for GSMArena — they aggressively block scrapers
4. **Multi-method fallback** — if one scraping method fails, fall through to the next
5. **`OEMSource` is separate from GSMArena** — OEM firmware scraping and device spec scraping are different pipelines
