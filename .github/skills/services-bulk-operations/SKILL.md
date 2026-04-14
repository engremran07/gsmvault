---
name: services-bulk-operations
description: "bulk_create, bulk_update, batch processing patterns. Use when: inserting many records, updating records in batch, processing large datasets efficiently."
---

# Bulk Operations Patterns

## When to Use
- Creating 10+ records at once (CSV import, scraper ingestion, seed data)
- Updating a field across many rows (status changes, bulk approval)
- Processing large querysets in memory-safe batches
- Migrating data between models or apps

## Rules
- Use `bulk_create()` instead of looping `.create()` — one query vs N queries
- Use `bulk_update()` instead of looping `.save()` — specify `update_fields`
- Set `batch_size` on bulk operations to avoid memory issues (500–1000 typical)
- `bulk_create()` does NOT call `save()` or fire `post_save` signals — handle side effects explicitly
- Use `.iterator()` on large querysets to avoid loading all rows into memory
- Wrap bulk writes in `@transaction.atomic` for consistency

## Patterns

### Bulk Create with Batch Size
```python
from django.db import transaction
from .models import Firmware

@transaction.atomic
def import_firmware_batch(entries: list[dict]) -> int:
    """Import firmware entries in bulk. Returns count created."""
    firmware_objects = [
        Firmware(
            name=entry["name"],
            brand_id=entry["brand_id"],
            model_id=entry["model_id"],
            file_size=entry["file_size"],
            status="pending",
        )
        for entry in entries
    ]
    created = Firmware.objects.bulk_create(firmware_objects, batch_size=500)
    return len(created)
```

### Bulk Update Specific Fields
```python
@transaction.atomic
def bulk_approve_firmware(firmware_ids: list[int], reviewer_id: int) -> int:
    """Approve multiple firmware entries at once."""
    firmwares = list(Firmware.objects.filter(pk__in=firmware_ids, status="pending"))
    for fw in firmwares:
        fw.status = "approved"
        fw.reviewed_by_id = reviewer_id
    Firmware.objects.bulk_update(firmwares, ["status", "reviewed_by_id"], batch_size=500)
    return len(firmwares)
```

### Batch Processing with Iterator
```python
import logging
from django.db.models import QuerySet

logger = logging.getLogger(__name__)

def process_large_dataset(queryset: QuerySet, batch_size: int = 1000) -> int:
    """Process a large queryset in memory-safe batches."""
    processed = 0
    batch: list = []
    for obj in queryset.iterator(chunk_size=batch_size):
        batch.append(obj)
        if len(batch) >= batch_size:
            _process_batch(batch)
            processed += len(batch)
            logger.info("Processed %d records so far", processed)
            batch = []
    if batch:
        _process_batch(batch)
        processed += len(batch)
    return processed
```

### Queryset Update (Single Query)
```python
def deactivate_expired_tokens() -> int:
    """Mark expired download tokens as expired — single UPDATE query."""
    from django.utils import timezone
    count = DownloadToken.objects.filter(
        status="active", expires_at__lt=timezone.now()
    ).update(status="expired")
    return count
```

### Bulk Create with ignore_conflicts
```python
def upsert_device_fingerprints(fingerprints: list[dict]) -> None:
    """Insert fingerprints, skip duplicates."""
    objects = [DeviceFingerprint(**fp) for fp in fingerprints]
    DeviceFingerprint.objects.bulk_create(
        objects, batch_size=500, ignore_conflicts=True
    )
```

## Anti-Patterns
- Looping `.create()` inside a for loop — N queries instead of 1
- `bulk_create()` without `batch_size` on large datasets — OOM risk
- Expecting `post_save` signals to fire from `bulk_create()` — they don't
- Loading entire table into memory with `list(Model.objects.all())` — use `.iterator()`
- Forgetting `update_fields` on `bulk_update()` — updates ALL columns

## Red Flags
- For loop with `.save()` on 100+ records → should be `bulk_update()`
- Missing `batch_size` parameter on bulk operations with 1000+ records
- `Model.objects.all()` without `.iterator()` on tables with 100k+ rows

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
