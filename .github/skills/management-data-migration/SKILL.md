---
name: management-data-migration
description: "Data migrations: RunPython, reversible operations. Use when: migrating data between schema changes, backfilling fields, transforming existing data."
---

# Data Migrations

## When to Use
- Backfilling a new field with computed values from existing data
- Moving data between models during app consolidation
- Transforming data format (e.g., JSON field restructure)
- Setting initial values for a new non-nullable field
- Cleaning up orphaned records after schema changes

## Rules
- Create empty migration: `manage.py makemigrations <app> --empty -n <description>`
- Always make data migrations reversible with `reverse_code`
- Use `apps.get_model()` inside RunPython — never import models directly
- Batch large updates with `iterator()` and `bulk_update()`
- Data migrations run inside a transaction by default — keep operations consistent
- NEVER edit Django auto-generated migration files manually

## Patterns

### Basic Data Migration
```python
# apps/firmwares/migrations/0025_backfill_slug.py
from django.db import migrations


def backfill_slugs(apps, schema_editor):
    """Generate slugs for existing firmware records."""
    Firmware = apps.get_model("firmwares", "Firmware")
    from django.utils.text import slugify

    for firmware in Firmware.objects.filter(slug="").iterator():
        firmware.slug = slugify(firmware.name)[:200]
        firmware.save(update_fields=["slug"])


def reverse_backfill(apps, schema_editor):
    """Clear generated slugs."""
    Firmware = apps.get_model("firmwares", "Firmware")
    Firmware.objects.filter(slug__isnull=False).update(slug="")


class Migration(migrations.Migration):
    dependencies = [
        ("firmwares", "0024_firmware_slug"),
    ]

    operations = [
        migrations.RunPython(backfill_slugs, reverse_backfill),
    ]
```

### Batch Processing Large Tables
```python
def backfill_download_counts(apps, schema_editor):
    """Backfill download_count from DownloadSession aggregation."""
    Firmware = apps.get_model("firmwares", "Firmware")
    DownloadSession = apps.get_model("firmwares", "DownloadSession")

    batch_size = 500
    firmwares = list(Firmware.objects.all().only("pk"))

    for i in range(0, len(firmwares), batch_size):
        batch = firmwares[i:i + batch_size]
        for fw in batch:
            fw.download_count = DownloadSession.objects.filter(
                firmware=fw, status="completed"
            ).count()

        Firmware.objects.bulk_update(batch, ["download_count"], batch_size=batch_size)


class Migration(migrations.Migration):
    dependencies = [("firmwares", "0030_firmware_download_count")]

    operations = [
        migrations.RunPython(backfill_download_counts, migrations.RunPython.noop),
    ]
```

### Moving Data Between Apps (Consolidation)
```python
def move_crawler_rules(apps, schema_editor):
    """Move CrawlerRule data from dissolved crawler_guard to apps.security."""
    OldRule = apps.get_model("crawler_guard", "CrawlerRule")
    NewRule = apps.get_model("security", "CrawlerRule")

    for old in OldRule.objects.iterator():
        NewRule.objects.get_or_create(
            path_pattern=old.path_pattern,
            defaults={
                "action": old.action,
                "requests_per_minute": old.requests_per_minute,
                "is_active": old.is_active,
            },
        )


def reverse_move(apps, schema_editor):
    NewRule = apps.get_model("security", "CrawlerRule")
    NewRule.objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [
        ("security", "0010_crawlerrule"),
        ("crawler_guard", "0005_final"),
    ]

    operations = [
        migrations.RunPython(move_crawler_rules, reverse_move),
    ]
```

### Setting Defaults for New Required Fields
```python
def set_default_tier(apps, schema_editor):
    """Set default QuotaTier for users without one."""
    User = apps.get_model("users", "User")
    QuotaTier = apps.get_model("devices", "QuotaTier")

    free_tier, _ = QuotaTier.objects.get_or_create(
        name="Free",
        defaults={"daily_limit": 5, "requires_ad": True},
    )

    User.objects.filter(quota_tier__isnull=True).update(quota_tier=free_tier)
```

### Creating Migration File
```powershell
# Create empty migration for data operations
& .\.venv\Scripts\python.exe manage.py makemigrations firmwares --empty -n backfill_download_counts --settings=app.settings_dev

# Run migrations
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev

# Reverse a specific migration
& .\.venv\Scripts\python.exe manage.py migrate firmwares 0029 --settings=app.settings_dev
```

## Anti-Patterns
- NEVER import models directly in migration files — use `apps.get_model()`
- NEVER use `migrations.RunPython.noop` for destructive operations — write a real reverse
- NEVER modify auto-generated schema migration files
- NEVER do I/O (API calls, file reads) in data migrations
- NEVER create data migrations without testing reverse operation

## Red Flags
- `from apps.firmwares.models import Firmware` inside a migration
- `RunPython.noop` as reverse for a migration that deletes data
- Data migration processing millions of rows without batching
- Missing `dependencies` that could cause ordering issues

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/migrations/` — existing migrations
- `.claude/rules/migrations-safety.md` — migration safety rules
