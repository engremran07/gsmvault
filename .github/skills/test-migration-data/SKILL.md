---
name: test-migration-data
description: "Data migration tests: RunPython function verification. Use when: testing data migrations, verifying data transformation, testing backfill operations."
---

# Data Migration Tests

## When to Use

- Testing `RunPython` data migration functions
- Verifying data backfill correctness
- Testing data transformation logic
- Ensuring forward and reverse data operations work

## Rules

### Testing RunPython Function Directly

```python
import pytest
from django.apps import apps

@pytest.mark.django_db
def test_data_migration_function():
    """Test the RunPython function in isolation."""
    from apps.firmwares.migrations.0005_backfill_slugs import backfill_slugs
    # Call with apps registry and schema_editor
    from django.db import connection
    backfill_slugs(apps, connection.schema_editor())

@pytest.mark.django_db
def test_backfill_populates_field():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(slug="")
    from apps.firmwares.models import Firmware
    # Simulate backfill
    for obj in Firmware.objects.filter(slug=""):
        obj.slug = obj.version.replace(".", "-")
        obj.save()
    fw.refresh_from_db()
    assert fw.slug != ""
```

### Testing Idempotent Data Migrations

```python
@pytest.mark.django_db
def test_migration_is_idempotent():
    """Running the migration twice should not cause errors or duplicates."""
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(5)
    from apps.firmwares.models import Firmware
    count_before = Firmware.objects.count()
    # Simulate running the data migration function twice
    from apps.firmwares.migrations.0005_backfill_slugs import backfill_slugs
    from django.db import connection
    backfill_slugs(apps, connection.schema_editor())
    backfill_slugs(apps, connection.schema_editor())
    assert Firmware.objects.count() == count_before  # No duplicates
```

### Testing Reverse Data Migration

```python
@pytest.mark.django_db
def test_reverse_migration_clears_field():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(slug="test-slug")
    # Simulate reverse
    from apps.firmwares.models import Firmware
    Firmware.objects.update(slug="")
    fw.refresh_from_db()
    assert fw.slug == ""
```

### Testing Data Migration with Large Datasets

```python
@pytest.mark.django_db
def test_batch_processing():
    """Data migrations should batch-process to avoid memory issues."""
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(100)
    from apps.firmwares.models import Firmware
    batch_size = 50
    total = Firmware.objects.count()
    processed = 0
    for i in range(0, total, batch_size):
        batch = Firmware.objects.all()[i:i + batch_size]
        for obj in batch:
            obj.slug = obj.version.replace(".", "-") if obj.version else "default"
            processed += 1
    assert processed == total
```

### Testing Data Migration Edge Cases

```python
@pytest.mark.django_db
@pytest.mark.parametrize("version,expected_slug", [
    ("1.0.0", "1-0-0"),
    ("", "default"),
    ("3.2.1-beta", "3-2-1-beta"),
])
def test_slug_generation(version, expected_slug):
    slug = version.replace(".", "-") if version else "default"
    assert slug == expected_slug
```

## Red Flags

- Testing data migrations only via `migrate` command — too slow, test the function directly
- Not testing idempotency — migration may be run twice in some deployment scenarios
- Missing edge case tests — empty strings, None values, Unicode data
- Not batching updates in migration — OOM on large tables

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
