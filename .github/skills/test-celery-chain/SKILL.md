---
name: test-celery-chain
description: "Celery chain tests: task pipelines, chord patterns. Use when: testing chained tasks, task groups, chord callbacks, pipeline execution order."
---

# Celery Chain Tests

## When to Use

- Testing task chains (sequential execution)
- Testing task groups (parallel execution)
- Testing chord patterns (group + callback)
- Verifying pipeline data flow between tasks

## Rules

### Testing Task Chain

```python
import pytest
from celery import chain
from django.test import override_settings

@override_settings(CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True)
@pytest.mark.django_db
def test_firmware_processing_chain():
    from apps.firmwares.tasks import validate_file, extract_metadata, index_firmware
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    result = chain(
        validate_file.s(fw.pk),
        extract_metadata.s(),
        index_firmware.s(),
    ).apply()
    assert result.successful()
```

### Testing Task Group

```python
from celery import group

@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
@pytest.mark.django_db
def test_batch_processing_group():
    from apps.firmwares.tasks import process_firmware
    from tests.factories import FirmwareFactory
    fws = FirmwareFactory.create_batch(5)
    result = group(
        process_firmware.s(fw.pk) for fw in fws
    ).apply()
    assert all(r.successful() for r in result.results)
```

### Testing Chord (Group + Callback)

```python
from celery import chord

@override_settings(CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True)
@pytest.mark.django_db
def test_chord_callback():
    from apps.analytics.tasks import count_downloads, aggregate_results
    from tests.factories import FirmwareFactory
    fws = FirmwareFactory.create_batch(3)
    result = chord(
        [count_downloads.s(fw.pk) for fw in fws],
        aggregate_results.s(),
    ).apply()
    assert result.successful()
```

### Testing Chain Error Propagation

```python
@override_settings(CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True)
@pytest.mark.django_db
def test_chain_stops_on_error():
    from apps.firmwares.tasks import validate_file, extract_metadata
    result = chain(
        validate_file.s(99999),  # Will fail — missing firmware
        extract_metadata.s(),     # Should not execute
    ).apply()
    assert result.failed()
```

### Testing Individual Pipeline Steps

```python
@pytest.mark.django_db
def test_validate_step():
    from apps.firmwares.tasks import validate_file
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    result = validate_file.apply(args=[fw.pk])
    assert result.successful()
    # Returns data for next step
    assert result.result is not None

@pytest.mark.django_db
def test_metadata_step():
    from apps.firmwares.tasks import extract_metadata
    input_data = {"firmware_id": 1, "file_path": "/test/file.bin"}
    result = extract_metadata.apply(args=[input_data])
    assert result.successful()
```

## Red Flags

- Not using `CELERY_TASK_EAGER_PROPAGATES` — exceptions swallowed silently
- Testing chains without testing individual steps first
- Using real broker for chain tests — flaky, slow
- Not testing error propagation — chain should stop on first failure

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
