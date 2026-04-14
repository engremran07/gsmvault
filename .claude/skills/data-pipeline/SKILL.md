---
name: data-pipeline
description: "ETL workflows, management commands, Celery tasks, batch processing. Use when: building data pipelines, import/export, batch jobs, scheduled tasks, async processing."
user-invocable: true
---

# Data Pipeline

> Full reference: @.github/skills/data-pipeline/SKILL.md

## Quick Rules

- All management commands live in `apps/<app>/management/commands/<name>.py`
- Celery tasks in `apps/<app>/tasks.py` — always use `@shared_task(bind=True)`
- ALL multi-model operations use `@transaction.atomic`
- Scraped data NEVER auto-inserts — always creates `IngestionJob(status="pending")`
- Batch size 1000 default; support `--dry-run` flag on all commands
- Log progress to `self.stdout` in commands, `logger` in Celery tasks

## Management Command Pattern

```python
from django.core.management.base import BaseCommand
import logging
logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = "Description"

    def add_arguments(self, parser):
        parser.add_argument("--batch-size", type=int, default=1000)
        parser.add_argument("--dry-run", action="store_true")

    def handle(self, *args, **options):
        if options["dry_run"]:
            self.stdout.write(self.style.WARNING("DRY RUN — no writes"))
        # ... processing
```

## Celery Task Pattern

```python
from celery import shared_task
from django.db import transaction
import logging
logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def process_batch(self, batch_ids: list[int]) -> dict:
    try:
        with transaction.atomic():
            # ... work
        return {"processed": len(batch_ids)}
    except Exception as exc:
        logger.exception("Batch failed: %s", exc)
        raise self.retry(exc=exc)
```
