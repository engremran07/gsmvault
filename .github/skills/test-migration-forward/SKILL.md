---
name: test-migration-forward
description: "Forward migration tests: apply, verify schema changes. Use when: testing new migrations apply cleanly, verifying table/column creation, migration squashing."
---

# Forward Migration Tests

## When to Use

- Verifying new migrations apply without errors
- Testing schema changes (new tables, columns, indexes)
- Checking migration ordering and dependencies
- Post-squash verification

## Rules

### Testing Migrations Apply

```python
import pytest
from django.core.management import call_command
from io import StringIO

def test_migrations_apply_cleanly():
    """Verify all migrations can be applied from scratch."""
    out = StringIO()
    call_command("migrate", "--run-syncdb", verbosity=0, stdout=out)
    # No exceptions = success

def test_no_pending_migrations():
    """Verify makemigrations produces no new changes."""
    out = StringIO()
    call_command("makemigrations", "--check", "--dry-run", verbosity=0, stdout=out)
    # Exit code 0 = no changes needed
```

### Testing Migration Plan

```python
def test_migration_plan():
    from django.core.management import call_command
    from io import StringIO
    out = StringIO()
    call_command("showmigrations", "--plan", stdout=out)
    output = out.getvalue()
    # All migrations should be applied (marked with [X])
    unapplied = [line for line in output.split("\n") if "[ ]" in line]
    assert len(unapplied) == 0, f"Unapplied migrations: {unapplied}"
```

### Testing Specific Model Creation

```python
@pytest.mark.django_db
def test_firmware_table_exists():
    from django.db import connection
    tables = connection.introspection.table_names()
    assert "firmwares_firmware" in tables

@pytest.mark.django_db
def test_model_has_expected_fields():
    from apps.firmwares.models import Firmware
    field_names = [f.name for f in Firmware._meta.get_fields()]
    assert "version" in field_names
    assert "created_at" in field_names
```

### Testing Index Creation

```python
@pytest.mark.django_db
def test_indexes_exist():
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT indexname FROM pg_indexes
            WHERE tablename = 'firmwares_firmware'
        """)
        indexes = [row[0] for row in cursor.fetchall()]
        assert len(indexes) > 0  # At least PK index
```

### Checking Migration Dependencies

```python
def test_migration_dependencies():
    from django.apps import apps
    from importlib import import_module
    for app_config in apps.get_app_configs():
        if app_config.name.startswith("apps."):
            try:
                migrations_module = import_module(
                    f"{app_config.name}.migrations"
                )
            except ImportError:
                continue
```

## Red Flags

- Not running `makemigrations --check` in CI — catches missing migrations
- Testing migrations only on fresh DB — should also test on existing data
- Not checking for circular migration dependencies
- Squashing without testing the squashed migration applies cleanly

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
