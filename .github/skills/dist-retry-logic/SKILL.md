---
name: dist-retry-logic
description: "Retry logic for failed distribution jobs. Use when: handling transient API failures, implementing exponential backoff, configuring max retry limits."
---

# Distribution Retry Logic

## When to Use
- Handling transient API failures (timeout, 5xx, rate limit)
- Implementing exponential backoff between retries
- Configuring `DistributionSettings.max_retries` and `retry_backoff_seconds`
- Moving permanently failed jobs to dead-letter state

## Rules
- `DistributionSettings.max_retries` = 3 (default)
- `DistributionSettings.retry_backoff_seconds` = 1800 (30 minutes default)
- Exponential backoff: `backoff * (2 ** attempt)` — 30min, 60min, 120min
- `ShareJob.attempt_count` tracks retry count
- After max retries exhausted → `ShareJob.status = "failed"` (terminal)
- Retryable errors: timeout, 429, 500, 502, 503, 504
- Non-retryable errors: 401, 403, 404 → fail immediately

## Patterns

### Retry Classification
```python
# apps/distribution/services/retry.py
RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}

def is_retryable(*, status_code: int | None = None, exception: Exception | None = None) -> bool:
    """Determine if a failure should be retried."""
    if status_code and status_code in RETRYABLE_STATUS_CODES:
        return True
    if exception:
        import httpx
        return isinstance(exception, (httpx.TimeoutException, httpx.NetworkError, ConnectionError))
    return False

def calculate_backoff(*, attempt: int, base_seconds: int = 1800) -> int:
    """Exponential backoff: 1800, 3600, 7200, ..."""
    return base_seconds * (2 ** attempt)
```

### Celery Task with Retry
```python
# apps/distribution/tasks.py
from celery import shared_task

@shared_task(bind=True, max_retries=3)
def execute_distribution_job(self, job_id: int) -> dict:
    from apps.distribution.models import ShareJob, DistributionSettings
    settings = DistributionSettings.get_solo()
    job = ShareJob.objects.get(pk=job_id)

    try:
        result = dispatch_to_connector(job=job)
        job.status = "completed"
        job.save(update_fields=["status"])
        return result
    except Exception as exc:
        job.attempt_count += 1
        job.last_error = str(exc)[:500]

        if job.attempt_count >= settings.max_retries or not is_retryable(exception=exc):
            job.status = "failed"
            job.save(update_fields=["attempt_count", "last_error", "status"])
            return {"status": "permanently_failed"}

        job.status = "retrying"
        backoff = calculate_backoff(
            attempt=job.attempt_count,
            base_seconds=settings.retry_backoff_seconds,
        )
        job.schedule_at = timezone.now() + timedelta(seconds=backoff)
        job.save(update_fields=["attempt_count", "last_error", "status", "schedule_at"])
        raise self.retry(exc=exc, countdown=backoff)
```

## Anti-Patterns
- Retrying 401/403 errors — auth issues won't self-resolve
- No exponential backoff — hammering a failing API
- Infinite retries without a max cap — jobs never terminate
- Not logging `last_error` — can't diagnose failures

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
