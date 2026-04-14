---
name: services-background-tasks
description: "Background task patterns: Celery tasks, error handling, results. Use when: running async operations, processing uploads, sending emails, any long-running work."
---

# Background Task Patterns

## When to Use
- Long-running operations (file processing, PDF generation, large exports)
- Operations that shouldn't block the HTTP response (email, webhooks)
- Work triggered by model changes (post-save processing)
- Fan-out operations (notify 1000 subscribers)

## Rules
- Tasks live in `tasks.py` per app — one file per app
- Use `@shared_task` decorator (not `@app.task`) for portability
- Tasks accept only serializable arguments (int, str, dict) — never model instances
- Use `transaction.on_commit()` to dispatch tasks after DB changes are committed
- Always set `max_retries` and `default_retry_delay` for retriable tasks
- Log task start, completion, and failure

## Patterns

### Basic Celery Task
```python
# apps/firmwares/tasks.py
import logging
from celery import shared_task

logger = logging.getLogger(__name__)

@shared_task
def process_firmware_upload(firmware_id: int) -> dict:
    """Process uploaded firmware: checksum, scan, metadata extraction."""
    from .models import Firmware
    from . import services
    logger.info("Processing firmware %s", firmware_id)
    firmware = Firmware.objects.get(pk=firmware_id)
    result = services.process_firmware(firmware=firmware)
    logger.info("Firmware %s processed: %s", firmware_id, result)
    return result
```

### Dispatching After Commit
```python
from django.db import transaction

@transaction.atomic
def upload_firmware(*, user_id: int, file) -> Firmware:
    firmware = Firmware.objects.create(user_id=user_id, file=file, status="processing")
    # Only dispatch AFTER the transaction commits
    transaction.on_commit(lambda: process_firmware_upload.delay(firmware.pk))
    return firmware
```

### Task with Retries
```python
@shared_task(bind=True, max_retries=3, default_retry_delay=120)
def sync_external_data(self, source_id: int) -> None:
    """Sync data from external API with retry logic."""
    from .models import ExternalSource
    source = ExternalSource.objects.get(pk=source_id)
    try:
        data = fetch_external_api(source.url)
        services.process_external_data(source=source, data=data)
    except ConnectionError as exc:
        logger.warning("External sync failed for source %s, retrying", source_id)
        raise self.retry(exc=exc)
```

### Task Chaining
```python
from celery import chain

def process_firmware_pipeline(firmware_id: int) -> None:
    """Chain multiple tasks for firmware processing."""
    workflow = chain(
        validate_firmware.s(firmware_id),
        extract_metadata.s(),
        generate_thumbnails.s(),
        notify_upload_complete.s(),
    )
    workflow.apply_async()
```

### Task with Progress Tracking
```python
@shared_task(bind=True)
def bulk_import_firmwares(self, import_job_id: int) -> dict:
    """Bulk import with progress updates."""
    from .models import ImportJob
    job = ImportJob.objects.get(pk=import_job_id)
    total = len(job.data)
    for i, entry in enumerate(job.data):
        _process_single_entry(entry)
        if i % 100 == 0:
            self.update_state(state="PROGRESS", meta={"current": i, "total": total})
    job.status = "completed"
    job.save(update_fields=["status"])
    return {"processed": total}
```

### Error Handling Task
```python
@shared_task(bind=True, max_retries=3)
def risky_operation(self, item_id: int) -> None:
    try:
        do_work(item_id)
    except RecoverableError as exc:
        raise self.retry(exc=exc, countdown=60 * (2 ** self.request.retries))
    except PermanentError:
        logger.exception("Permanent failure for item %s", item_id)
        mark_as_failed(item_id)
        # Don't retry — mark and move on
```

## Anti-Patterns
- Passing model instances to tasks — not serializable, stale data
- Dispatching tasks inside `@transaction.atomic` without `on_commit` — task runs before commit
- Tasks without `max_retries` — infinite retry loops
- No logging in tasks — silent failures

## Red Flags
- `.delay(firmware)` with model instance → should be `.delay(firmware.pk)`
- Task dispatched inside atomic block without `on_commit()`
- `@shared_task` without any retry configuration for external calls
- Missing `bind=True` on tasks that use `self.retry()`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
