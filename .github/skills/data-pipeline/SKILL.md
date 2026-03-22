---
name: data-pipeline
description: "ETL workflows, management commands, Celery tasks, batch processing. Use when: building data pipelines, import/export, batch jobs, scheduled tasks, async processing."
---

# Data Pipeline Skill

## Management Command Pattern

All management commands follow this structure:

```python
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = "Description of what this command does"

    def add_arguments(self, parser):
        parser.add_argument("--batch-size", type=int, default=1000)
        parser.add_argument("--dry-run", action="store_true")

    def handle(self, *args, **options):
        batch_size = options["batch_size"]
        dry_run = options["dry_run"]

        self.stdout.write(f"Starting processing (batch_size={batch_size}, dry_run={dry_run})")

        processed = 0
        errors = 0

        for item in self.get_items().iterator(chunk_size=batch_size):
            try:
                if not dry_run:
                    self.process_item(item)
                processed += 1
            except Exception as e:
                errors += 1
                self.stderr.write(self.style.ERROR(f"Error processing {item}: {e}"))

        self.stdout.write(self.style.SUCCESS(
            f"Done: {processed} processed, {errors} errors"
        ))
```

Key rules:
- Use `self.stdout.write()` / `self.stderr.write()` — never bare `print()`
- Use `self.style.SUCCESS()`, `self.style.ERROR()`, `self.style.WARNING()` for colored output
- Always support `--dry-run` for destructive operations
- Always report a summary at the end

---

## Celery Task Pattern

```python
from celery import shared_task
import logging

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=2, default_retry_delay=300)
def my_async_task(self, param1, param2=None):
    """Docstring explaining what the task does."""
    try:
        # Update task state for progress tracking
        self.update_state(state="PROGRESS", meta={"current": 0, "total": 100})

        result = do_work(param1, param2)

        logger.info("Task completed: %s", result)
        return {"status": "success", "result": result}

    except TransientError as exc:
        # Retry on transient failures (network, timeouts)
        logger.warning("Transient error, retrying: %s", exc)
        self.retry(exc=exc)

    except Exception:
        logger.exception("Task failed permanently")
        raise
```

Key rules:
- `bind=True` to access `self` for retries and state updates
- `max_retries=2` — don't retry forever
- `default_retry_delay=300` — 5 minutes between retries
- Only retry on transient errors (network, timeouts) — not logic errors
- Use `self.update_state()` for long-running tasks so callers can poll progress
- Log at appropriate levels: `info` for success, `warning` for retries, `exception` for failures

### Calling Tasks

```python
# Fire and forget
my_async_task.delay(param1="value")

# With options
my_async_task.apply_async(
    args=["value"],
    kwargs={"param2": "opt"},
    countdown=60,  # delay 60 seconds
    queue="low_priority",
)
```

---

## Batch Processing

Process large datasets in chunks to avoid memory issues:

```python
from django.db.models import QuerySet

def process_in_batches(queryset: QuerySet, batch_size: int = 1000) -> dict:
    """Process a queryset in chunks."""
    processed = 0
    errors = 0

    for obj in queryset.iterator(chunk_size=batch_size):
        try:
            process_single(obj)
            processed += 1
        except Exception:
            errors += 1
            logger.exception("Failed to process %s", obj.pk)

    return {"processed": processed, "errors": errors}
```

For bulk creates/updates:

```python
from django.db import transaction

def bulk_upsert(items: list[dict], batch_size: int = 500) -> int:
    """Bulk create or update records."""
    to_create = []
    to_update = []

    existing = {obj.external_id: obj for obj in MyModel.objects.filter(
        external_id__in=[i["external_id"] for i in items]
    )}

    for item in items:
        if item["external_id"] in existing:
            obj = existing[item["external_id"]]
            obj.name = item["name"]
            to_update.append(obj)
        else:
            to_create.append(MyModel(**item))

    with transaction.atomic():
        MyModel.objects.bulk_create(to_create, batch_size=batch_size)
        MyModel.objects.bulk_update(to_update, ["name"], batch_size=batch_size)

    return len(to_create) + len(to_update)
```

---

## Error Handling

Pipeline error handling strategy — never let one bad record kill the whole pipeline:

```python
def run_pipeline(items):
    results = {"success": 0, "skipped": 0, "errors": []}

    for item in items:
        try:
            process(item)
            results["success"] += 1
        except ValidationError:
            results["skipped"] += 1
            logger.warning("Skipped invalid item: %s", item)
        except Exception as e:
            results["errors"].append({"item": str(item), "error": str(e)})
            logger.exception("Failed to process item: %s", item)

    # Always log the summary
    logger.info(
        "Pipeline complete: %d success, %d skipped, %d errors",
        results["success"],
        results["skipped"],
        len(results["errors"]),
    )
    return results
```

---

## Transaction Management

Wrap batch operations in atomic blocks for consistency:

```python
from django.db import transaction

# Entire batch is atomic — all or nothing
with transaction.atomic():
    for item in items:
        MyModel.objects.create(**item)

# Per-item savepoints — failed items don't roll back others
for item in items:
    try:
        with transaction.atomic():
            MyModel.objects.create(**item)
    except IntegrityError:
        logger.warning("Duplicate: %s", item)
```

Choose strategy based on requirements:
- **All-or-nothing**: Wrap entire batch in one `transaction.atomic()`
- **Best-effort**: Wrap each item in its own `transaction.atomic()` with try/except
- **Chunked atomic**: Group items into chunks, each chunk atomic

---

## Progress Reporting

### Management Commands

```python
def handle(self, *args, **options):
    total = MyModel.objects.count()
    for i, obj in enumerate(MyModel.objects.iterator(chunk_size=1000), 1):
        process(obj)
        if i % 100 == 0:
            self.stdout.write(f"Processed {i}/{total}...")
    self.stdout.write(self.style.SUCCESS(f"Done: {total} processed"))
```

### Celery Tasks

```python
@shared_task(bind=True)
def long_running_task(self, items):
    total = len(items)
    for i, item in enumerate(items, 1):
        process(item)
        self.update_state(
            state="PROGRESS",
            meta={"current": i, "total": total, "percent": int(i / total * 100)},
        )
    return {"status": "complete", "total": total}
```

Poll progress from views:

```python
from celery.result import AsyncResult

def check_task_progress(request, task_id):
    result = AsyncResult(task_id)
    if result.state == "PROGRESS":
        return JsonResponse(result.info)
    elif result.ready():
        return JsonResponse({"status": "complete", "result": result.result})
    return JsonResponse({"status": result.state})
```
