---
name: test-celery-task
description: "Celery task tests: task.delay(), task.apply(), result verification. Use when: testing async tasks synchronously, verifying task output, mocking task calls."
---

# Celery Task Tests

## When to Use

- Testing Celery tasks execute correctly when called synchronously
- Verifying task output and side effects
- Mocking `.delay()` calls in service tests
- Testing task error handling

## Rules

### Testing Tasks Synchronously

```python
import pytest

@pytest.mark.django_db
def test_task_runs_synchronously():
    from apps.firmwares.tasks import process_firmware
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(status="pending")
    result = process_firmware.apply(args=[fw.pk])
    assert result.successful()
    fw.refresh_from_db()
    assert fw.status == "processed"
```

### Using CELERY_ALWAYS_EAGER

```python
from django.test import override_settings

@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
@pytest.mark.django_db
def test_task_via_delay():
    from apps.firmwares.tasks import process_firmware
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(status="pending")
    result = process_firmware.delay(fw.pk)
    assert result.get() is not None
```

### Testing Task Side Effects

```python
@pytest.mark.django_db
def test_task_sends_notification():
    from apps.notifications.tasks import send_download_notification
    from tests.factories import UserFactory, FirmwareFactory
    from unittest.mock import patch
    user = UserFactory()
    fw = FirmwareFactory()
    with patch("apps.notifications.tasks.send_email") as mock_email:
        send_download_notification.apply(args=[user.pk, fw.pk])
        mock_email.assert_called_once()
```

### Mocking delay() in Service Tests

```python
@pytest.mark.django_db
def test_service_triggers_task():
    from apps.firmwares.services import upload_firmware
    from unittest.mock import patch
    with patch("apps.firmwares.tasks.process_firmware.delay") as mock_delay:
        upload_firmware(version="1.0.0")
        mock_delay.assert_called_once()
```

### Testing Task Failure

```python
@pytest.mark.django_db
def test_task_handles_missing_object():
    from apps.firmwares.tasks import process_firmware
    result = process_firmware.apply(args=[99999])
    assert result.failed() or result.result is None

@pytest.mark.django_db
def test_task_exception():
    from apps.firmwares.tasks import process_firmware
    result = process_firmware.apply(args=[None])
    assert not result.successful()
```

### Celery Fixture

```python
@pytest.fixture
def celery_eager(settings):
    settings.CELERY_TASK_ALWAYS_EAGER = True
    settings.CELERY_TASK_EAGER_PROPAGATES = True
    yield
```

## Red Flags

- Testing with real Celery broker — use `ALWAYS_EAGER` or `.apply()`
- Not testing task failure paths — tasks must handle missing objects
- Mocking the wrong path for `.delay()` — mock where it's called, not defined
- Not using `refresh_from_db()` after task — DB changes happen in task

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
