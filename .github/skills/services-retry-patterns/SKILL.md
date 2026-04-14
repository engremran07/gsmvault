---
name: services-retry-patterns
description: "Retry logic: exponential backoff, max retries, dead letter queues. Use when: calling external APIs, handling transient failures, implementing resilient service calls."
---

# Retry Patterns

## When to Use
- Calling external APIs that may be temporarily unavailable
- Network operations that can fail transiently
- Webhook delivery with guaranteed delivery
- Any operation where transient failures are expected

## Rules
- Always set `max_retries` — never retry indefinitely
- Use exponential backoff: `delay = base * (2 ** attempt)` with jitter
- Distinguish recoverable (retry) vs permanent (fail) errors
- Log every retry attempt with attempt number
- Move permanently failed items to a dead letter queue / failed status
- Never retry on validation errors or auth failures — those are permanent

## Patterns

### Celery Task with Exponential Backoff
```python
import logging
import random
from celery import shared_task

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=5)
def call_external_api(self, endpoint_id: int) -> dict:
    """Call external API with exponential backoff retry."""
    try:
        result = _make_api_call(endpoint_id)
        return result
    except (ConnectionError, TimeoutError) as exc:
        # Exponential backoff with jitter
        countdown = (2 ** self.request.retries) * 30 + random.randint(0, 30)
        logger.warning(
            "API call failed (attempt %d/%d), retrying in %ds: %s",
            self.request.retries + 1, self.max_retries, countdown, exc,
        )
        raise self.retry(exc=exc, countdown=countdown)
    except PermissionError:
        logger.error("Permanent auth failure for endpoint %d", endpoint_id)
        # Don't retry — permanent failure
        _mark_endpoint_failed(endpoint_id)
```

### Service-Level Retry Decorator
```python
import time
import functools
from typing import TypeVar, Callable

T = TypeVar("T")

def retry_with_backoff(
    max_retries: int = 3,
    base_delay: float = 1.0,
    exceptions: tuple = (ConnectionError, TimeoutError),
) -> Callable:
    """Decorator for synchronous retry with exponential backoff."""
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> T:
            last_exception = None
            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as exc:
                    last_exception = exc
                    if attempt < max_retries:
                        delay = base_delay * (2 ** attempt)
                        logger.warning(
                            "%s attempt %d failed, retrying in %.1fs",
                            func.__name__, attempt + 1, delay,
                        )
                        time.sleep(delay)
            raise last_exception  # type: ignore[misc]
        return wrapper
    return decorator

# Usage:
@retry_with_backoff(max_retries=3, base_delay=2.0)
def fetch_oem_firmware_list(url: str) -> dict:
    import requests
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()
```

### Dead Letter Queue Pattern
```python
@shared_task(bind=True, max_retries=5)
def deliver_notification(self, notification_id: int) -> None:
    from .models import Notification
    notification = Notification.objects.get(pk=notification_id)
    try:
        _do_deliver(notification)
        notification.status = "delivered"
    except RecoverableError as exc:
        if self.request.retries >= self.max_retries:
            notification.status = "dead_letter"
            logger.error("Notification %d moved to dead letter", notification_id)
        else:
            notification.save(update_fields=["status"])
            raise self.retry(exc=exc, countdown=60 * (2 ** self.request.retries))
    except PermanentError:
        notification.status = "permanent_failure"
        logger.error("Permanent failure for notification %d", notification_id)
    notification.save(update_fields=["status"])
```

### Retry Budget Pattern
```python
from django.core.cache import cache

def check_retry_budget(service_name: str, max_per_hour: int = 100) -> bool:
    """Prevent retry storms — limit total retries per service per hour."""
    key = f"retry_budget:{service_name}"
    current = cache.get(key, 0)
    if current >= max_per_hour:
        logger.warning("Retry budget exhausted for %s", service_name)
        return False
    cache.set(key, current + 1, timeout=3600)
    return True
```

## Anti-Patterns
- Retrying without backoff — hammers failing service
- No `max_retries` — infinite loop on permanent failures
- Retrying validation/auth errors — they won't magically succeed
- No logging on retries — invisible failure patterns
- Retrying inside `@transaction.atomic` — each retry holds a DB connection

## Red Flags
- `while True: try/except/continue` pattern → use structured retry
- Fixed `time.sleep(5)` between retries → use exponential backoff
- Retry without distinguishing error types → permanent errors get retried

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
