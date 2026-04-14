---
applyTo: 'apps/*/migrations/*.py'
---

# Migration File Instructions

## Golden Rule

**Never edit migration files manually.** Always use Django management commands to generate and manage migrations.

## Workflow

```powershell
# 1. Make model changes in models.py
# 2. Generate migration
& .\.venv\Scripts\python.exe manage.py makemigrations <app_name> --settings=app.settings_dev

# 3. Review the generated migration file
# 4. Apply migration
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev

# 5. Always run makemigrations BEFORE pushing model changes
```

## Dissolved App Models

Models migrated from dissolved apps MUST preserve existing database tables using `db_table` in Meta:

```python
class Meta:
    db_table = "original_app_tablename"  # e.g., "crawler_guard_crawlerrule"
```

This prevents data loss — no data migration needed, the ORM simply points to the existing table.

Reference of dissolved apps and their targets:

| Dissolved App | Target App | db_table prefix |
|---|---|---|
| `security_suite` | `apps.security` | `security_suite_*` |
| `security_events` | `apps.security` | `security_events_*` |
| `crawler_guard` | `apps.security` | `crawler_guard_*` |
| `ai_behavior` | `apps.devices` | `ai_behavior_*` |
| `device_registry` | `apps.devices` | `device_registry_*` |
| `gsmarena_sync` | `apps.firmwares` | `gsmarena_sync_*` |
| `fw_verification` | `apps.firmwares` | `fw_verification_*` |
| `fw_scraper` | `apps.firmwares` | `fw_scraper_*` |
| `download_links` | `apps.firmwares` | `download_links_*` |
| `admin_audit` | `apps.admin` | `admin_audit_*` |
| `email_system` | `apps.notifications` | `email_system_*` |
| `webhooks` | `apps.notifications` | `webhooks_*` |

## Data Migrations

Use `RunPython` with both forward and reverse functions:

```python
from django.db import migrations

def forward_func(apps, schema_editor):
    MyModel = apps.get_model("myapp", "MyModel")
    for obj in MyModel.objects.all():
        obj.new_field = compute_value(obj.old_field)
        obj.save(update_fields=["new_field"])

def reverse_func(apps, schema_editor):
    MyModel = apps.get_model("myapp", "MyModel")
    MyModel.objects.update(new_field=None)

class Migration(migrations.Migration):
    dependencies = [
        ("myapp", "0005_previous"),
    ]
    operations = [
        migrations.RunPython(forward_func, reverse_func),
    ]
```

**Rules for data migrations:**
- Always provide a reverse function (use `migrations.RunPython.noop` only if truly irreversible)
- Use `apps.get_model()` — never import models directly
- Process in batches for large datasets to avoid memory/lock issues
- Wrap in `@transaction.atomic` if consistency is critical

## Testing Migrations

Always test both directions:

```powershell
# Forward
& .\.venv\Scripts\python.exe manage.py migrate myapp --settings=app.settings_dev

# Reverse to previous
& .\.venv\Scripts\python.exe manage.py migrate myapp 0005_previous --settings=app.settings_dev

# Forward again
& .\.venv\Scripts\python.exe manage.py migrate myapp --settings=app.settings_dev
```

## Squashing

Squash migrations only when the count becomes unwieldy (20+):

```powershell
& .\.venv\Scripts\python.exe manage.py squashmigrations myapp 0001 0020 --settings=app.settings_dev
```

## Forbidden Practices

- Never delete migration files that have been applied to any database
- Never rename migration files
- Never reorder migration dependencies manually
- Never use `RawSQL` in migrations — use `RunSQL` with proper reverse SQL
- Never import app models directly — always use `apps.get_model()`
- Never add `RunPython` without a reverse function unless explicitly irreversible
