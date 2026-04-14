---
applyTo: 'apps/*/tasks.py'
---

# Celery Task Conventions

## Task Declaration

Use `@shared_task` with `bind=True` and retry configuration:

```python
from celery import shared_task
import logging

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def process_firmware_upload(self, firmware_id: int) -> None:
    """Process an uploaded firmware file."""
    from .models import Firmware  # Import inside task function

    try:
        firmware = Firmware.objects.get(pk=firmware_id)
        # Processing logic...
    except Firmware.DoesNotExist:
        logger.error("Firmware %d not found", firmware_id)
        return
    except Exception as exc:
        logger.exception("Failed to process firmware %d", firmware_id)
        raise self.retry(exc=exc, countdown=2 ** self.request.retries * 60)
```

## Import Rules — CRITICAL

NEVER import models at module level — always import inside the task function:

```python
# CORRECT
@shared_task(bind=True)
def send_notification(self, user_id: int, message: str) -> None:
    from apps.notifications.models import Notification
    from apps.users.models import User
    # ...

# WRONG — module-level import causes circular imports and app loading issues
from apps.notifications.models import Notification  # FORBIDDEN at module level
```

## Exponential Backoff

Use exponential backoff for retries:

```python
@shared_task(bind=True, max_retries=5)
def sync_external_api(self, source_id: int) -> None:
    try:
        # API call...
        pass
    except requests.RequestException as exc:
        countdown = 2 ** self.request.retries * 30  # 30s, 60s, 120s, 240s, 480s
        raise self.retry(exc=exc, countdown=countdown)
```

## Idempotency

Tasks MUST be safe to re-run. Use idempotency keys or check-before-write:

```python
@shared_task(bind=True, max_retries=3)
def grant_reward(self, user_id: int, reward_type: str, idempotency_key: str) -> None:
    from apps.gamification.models import Reward

    # Check if already processed
    if Reward.objects.filter(idempotency_key=idempotency_key).exists():
        logger.info("Reward %s already granted, skipping", idempotency_key)
        return

    Reward.objects.create(
        user_id=user_id,
        reward_type=reward_type,
        idempotency_key=idempotency_key,
    )
```

## Periodic Tasks (Celery Beat)

Register periodic tasks in the app's `tasks.py`:

```python
@shared_task
def cleanup_expired_tokens() -> int:
    """Remove expired download tokens. Runs daily via Celery Beat."""
    from .models import DownloadToken

    count, _ = DownloadToken.objects.filter(
        status="expired", expires_at__lt=timezone.now() - timedelta(days=7)
    ).delete()
    logger.info("Cleaned up %d expired tokens", count)
    return count
```

## Logging

Always log task start, completion, and failure:

```python
@shared_task(bind=True, max_retries=3)
def process_ingestion_job(self, job_id: int) -> None:
    logger.info("Starting ingestion job %d", job_id)
    try:
        # Processing...
        logger.info("Completed ingestion job %d", job_id)
    except Exception as exc:
        logger.exception("Failed ingestion job %d (attempt %d)", job_id, self.request.retries)
        raise self.retry(exc=exc, countdown=2 ** self.request.retries * 60)
```

## Task Chaining

Use Celery primitives for complex workflows:

```python
from celery import chain, group

# Sequential: process → validate → notify
workflow = chain(
    process_firmware_upload.s(firmware_id),
    validate_firmware_checksum.s(),
    notify_upload_complete.s(user_id),
)
workflow.apply_async()
```

## Never Block Tasks

- No `time.sleep()` — use Celery countdown/ETA instead
- No synchronous HTTP calls without timeout: `requests.get(url, timeout=30)`
- No unbounded loops — always set iteration limits
