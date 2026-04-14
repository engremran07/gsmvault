---
name: test-service-bulk
description: "Bulk operation tests: bulk_create, bulk_update, batch size. Use when: testing bulk insert/update services, batch processing, large dataset operations."
---

# Bulk Operation Tests

## When to Use

- Testing `bulk_create()` with batch sizes
- Verifying `bulk_update()` modifies correct records
- Testing batch processing services
- Performance testing large dataset operations

## Rules

### Testing bulk_create

```python
import pytest

@pytest.mark.django_db
def test_bulk_create():
    from apps.firmwares.models import Firmware
    from apps.firmwares.services import bulk_import_firmwares
    data = [
        {"version": f"1.0.{i}", "build_number": str(i)}
        for i in range(100)
    ]
    created = bulk_import_firmwares(data)
    assert len(created) == 100
    assert Firmware.objects.count() == 100

@pytest.mark.django_db
def test_bulk_create_with_batch_size():
    from apps.firmwares.services import bulk_import_firmwares
    data = [{"version": f"v{i}"} for i in range(500)]
    created = bulk_import_firmwares(data, batch_size=100)
    assert len(created) == 500
```

### Testing bulk_update

```python
@pytest.mark.django_db
def test_bulk_update():
    from tests.factories import FirmwareFactory
    from apps.firmwares.services import bulk_deactivate
    firmwares = FirmwareFactory.create_batch(10, is_active=True)
    pks = [fw.pk for fw in firmwares]
    updated = bulk_deactivate(pks)
    assert updated == 10
    from apps.firmwares.models import Firmware
    assert Firmware.objects.filter(pk__in=pks, is_active=False).count() == 10
```

### Testing Partial Failure

```python
@pytest.mark.django_db
def test_bulk_create_duplicate_handling():
    from apps.firmwares.services import bulk_import_firmwares
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="1.0.0")
    data = [
        {"version": "1.0.0"},  # Duplicate
        {"version": "2.0.0"},  # New
    ]
    result = bulk_import_firmwares(data, ignore_conflicts=True)
    # Should handle duplicates gracefully
    assert result is not None
```

### Testing Empty Input

```python
@pytest.mark.django_db
def test_bulk_create_empty():
    from apps.firmwares.services import bulk_import_firmwares
    result = bulk_import_firmwares([])
    assert result == [] or len(result) == 0

@pytest.mark.django_db
def test_bulk_update_no_matches():
    from apps.firmwares.services import bulk_deactivate
    result = bulk_deactivate([99999, 99998])
    assert result == 0
```

### Testing Query Efficiency

```python
@pytest.mark.django_db
def test_bulk_create_query_count(django_assert_num_queries):
    from apps.firmwares.services import bulk_import_firmwares
    data = [{"version": f"v{i}"} for i in range(50)]
    with django_assert_num_queries(1):  # Single INSERT
        bulk_import_firmwares(data)
```

## Red Flags

- Not testing empty input — bulk operations should handle `[]` gracefully
- Missing batch_size parameter — unbounded bulk_create can OOM
- Not testing duplicate handling — `ignore_conflicts` or error?
- Using `create()` in a loop instead of `bulk_create()` — N queries instead of 1

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
