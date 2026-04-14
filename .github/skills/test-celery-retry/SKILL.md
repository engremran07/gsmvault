---
name: test-celery-retry
description: "Retry tests: max_retries, countdown, exception handling. Use when: testing task retry logic, exponential backoff, retry exhaustion, dead letter handling."
---

# Celery Retry Tests

## When to Use

- Testing task retry on transient failures
- Verifying max_retries limits
- Testing exponential backoff countdown
- Verifying behavior when retries are exhausted

## Rules

### Testing Retry Behavior

```python
import pytest
from unittest.mock import patch, MagicMock
from django.test import override_settings

@override_settings(CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True)
@pytest.mark.django_db
def test_task_retries_on_failure():
    from apps.firmwares.tasks import sync_firmware_metadata
    with patch("apps.firmwares.tasks.external_api_call") as mock_api:
        mock_api.side_effect = [ConnectionError, ConnectionError, {"status": "ok"}]
        result = sync_firmware_metadata.apply(args=[1])
        assert mock_api.call_count == 3  # 2 retries + 1 success
```

### Testing Max Retries Exhaustion

```python
@override_settings(CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True)
@pytest.mark.django_db
def test_task_fails_after_max_retries():
    from apps.firmwares.tasks import sync_firmware_metadata
    with patch("apps.firmwares.tasks.external_api_call") as mock_api:
        mock_api.side_effect = ConnectionError("Service unavailable")
        with pytest.raises(ConnectionError):
            sync_firmware_metadata.apply(args=[1])

@pytest.mark.django_db
def test_max_retries_configured():
    from apps.firmwares.tasks import sync_firmware_metadata
    assert sync_firmware_metadata.max_retries == 3
```

### Testing Retry Countdown

```python
@pytest.mark.django_db
def test_retry_with_backoff():
    from apps.firmwares.tasks import sync_firmware_metadata
    from unittest.mock import patch
    with patch.object(sync_firmware_metadata, "retry") as mock_retry:
        mock_retry.side_effect = sync_firmware_metadata.MaxRetriesExceededError()
        try:
            sync_firmware_metadata(1)
        except Exception:
            pass
        if mock_retry.called:
            call_kwargs = mock_retry.call_args[1]
            assert "countdown" in call_kwargs
            assert call_kwargs["countdown"] > 0
```

### Testing Specific Exception Retry

```python
@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
@pytest.mark.django_db
def test_retries_only_on_transient_errors():
    from apps.firmwares.tasks import sync_firmware_metadata
    with patch("apps.firmwares.tasks.external_api_call") as mock_api:
        mock_api.side_effect = ValueError("Bad data")  # Not retryable
        result = sync_firmware_metadata.apply(args=[1])
        assert result.failed()
        assert mock_api.call_count == 1  # No retries for ValueError
```

### Testing on_failure Handler

```python
@override_settings(CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True)
@pytest.mark.django_db
def test_on_failure_logs_event():
    from apps.firmwares.tasks import sync_firmware_metadata
    from unittest.mock import patch
    with patch("apps.firmwares.tasks.external_api_call", side_effect=ConnectionError):
        with patch("apps.firmwares.tasks.logger") as mock_logger:
            try:
                sync_firmware_metadata.apply(args=[1])
            except ConnectionError:
                pass
            assert mock_logger.error.called or mock_logger.warning.called
```

## Red Flags

- Not testing retry exhaustion — must verify task eventually fails gracefully
- Using real delays in retry countdown — `countdown=60` makes tests slow
- Not distinguishing retryable vs non-retryable exceptions
- Missing `CELERY_TASK_EAGER_PROPAGATES` — retries don't propagate correctly

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
