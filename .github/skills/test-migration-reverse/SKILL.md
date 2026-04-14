---
name: test-migration-reverse
description: "Reverse migration tests: rollback, data preservation. Use when: testing migration reversibility, verifying rollback works, data safety on downgrade."
---

# Reverse Migration Tests

## When to Use

- Verifying migrations can be rolled back without data loss
- Testing `RunPython` reverse functions
- Ensuring `AlterField` reverse doesn't break data
- Pre-deploy rollback safety checks

## Rules

### Testing Migration Rollback

```python
import pytest
from django.core.management import call_command
from io import StringIO

@pytest.mark.django_db(transaction=True)
def test_migration_is_reversible():
    """Test that the latest migration can be rolled back."""
    out = StringIO()
    # Apply all first
    call_command("migrate", "firmwares", verbosity=0, stdout=out)
    # Roll back one
    call_command("migrate", "firmwares", "0001", verbosity=0, stdout=out)
    # Re-apply
    call_command("migrate", "firmwares", verbosity=0, stdout=out)
```

### Testing Data Preservation on Rollback

```python
@pytest.mark.django_db(transaction=True)
def test_rollback_preserves_data():
    from tests.factories import FirmwareFactory
    from apps.firmwares.models import Firmware
    FirmwareFactory.create_batch(3)
    count_before = Firmware.objects.count()
    # Rollback and re-migrate
    call_command("migrate", "firmwares", "0001", verbosity=0)
    call_command("migrate", "firmwares", verbosity=0)
    count_after = Firmware.objects.count()
    # Data should survive if migration is non-destructive
```

### Checking Irreversible Migrations

```python
def test_identify_irreversible_migrations():
    """List any migrations that cannot be reversed."""
    import os
    import ast
    migrations_dir = "apps/firmwares/migrations/"
    for filename in os.listdir(migrations_dir):
        if filename.startswith("0") and filename.endswith(".py"):
            filepath = os.path.join(migrations_dir, filename)
            with open(filepath) as f:
                content = f.read()
            if "RunPython" in content and "reverse_code" not in content:
                # This migration has RunPython without reverse
                pass  # Log or document these
```

### Testing RunPython Reverse

```python
@pytest.mark.django_db(transaction=True)
def test_data_migration_reverse():
    """Test that RunPython data migrations have working reverse functions."""
    from django.core.management import call_command
    # Apply the data migration
    call_command("migrate", "firmwares", "0005", verbosity=0)
    # Reverse it
    call_command("migrate", "firmwares", "0004", verbosity=0)
    # Re-apply
    call_command("migrate", "firmwares", "0005", verbosity=0)
```

## Red Flags

- `RunPython` without `reverse_code` — makes migration irreversible
- Using `migrations.RunPython.noop` as reverse without verifying it's safe
- Not testing rollback in CI — only discovered during emergency rollback
- Dropping columns without creating reverse migration to re-add them

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
