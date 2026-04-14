---
name: services-notification
description: "Notification service patterns: in-app, email, push. Use when: sending user notifications, in-app alerts, email notifications, push notifications, notification preferences."
---

# Notification Service Patterns

## When to Use
- Alerting users about events (firmware approved, download ready, new reply)
- Multi-channel notifications (in-app + email + push)
- Notification preferences and opt-out handling
- Batch notification delivery

## Rules
- Notification models live in `apps.notifications` (EmailTemplate, EmailQueue)
- Service functions create notification records — Celery tasks deliver them
- Always check user notification preferences before sending
- Use `transaction.on_commit()` to queue notifications after DB changes commit
- Never block the request to send notifications — always async via Celery

## Patterns

### Creating In-App Notifications
```python
# apps/notifications/services.py
import logging
from .models import Notification

logger = logging.getLogger(__name__)

def notify_user(
    *,
    user_id: int,
    notification_type: str,
    title: str,
    message: str,
    action_url: str = "",
    data: dict | None = None,
) -> Notification:
    """Create an in-app notification."""
    return Notification.objects.create(
        user_id=user_id,
        notification_type=notification_type,
        title=title,
        message=message,
        action_url=action_url,
        data=data or {},
    )
```

### Multi-Channel Notification
```python
from django.db import transaction

def send_firmware_approved_notification(
    *, firmware_id: int, user_id: int
) -> None:
    """Notify via in-app + email when firmware is approved."""
    # In-app notification
    notify_user(
        user_id=user_id,
        notification_type="firmware_approved",
        title="Firmware Approved",
        message="Your firmware submission has been approved.",
        action_url=f"/firmwares/{firmware_id}/",
    )
    # Queue email (async)
    transaction.on_commit(
        lambda: send_templated_email.delay(
            user_id=user_id,
            template_name="firmware_approved",
            context={"firmware_id": firmware_id},
        )
    )
```

### Batch Notifications
```python
def notify_subscribers(
    *, topic_id: int, reply_id: int, author_id: int
) -> int:
    """Notify all topic subscribers about a new reply."""
    subscriber_ids = list(
        ForumTopicSubscription.objects
        .filter(topic_id=topic_id, is_active=True)
        .exclude(user_id=author_id)  # Don't notify the author
        .values_list("user_id", flat=True)
    )
    notifications = [
        Notification(
            user_id=uid,
            notification_type="new_reply",
            title="New reply in subscribed topic",
            action_url=f"/forum/t/{topic_id}/#reply-{reply_id}",
        )
        for uid in subscriber_ids
    ]
    Notification.objects.bulk_create(notifications, batch_size=500)
    return len(notifications)
```

### Mark as Read
```python
def mark_notifications_read(*, user_id: int, notification_ids: list[int]) -> int:
    """Mark specific notifications as read."""
    return Notification.objects.filter(
        pk__in=notification_ids, user_id=user_id, is_read=False
    ).update(is_read=True)

def mark_all_read(*, user_id: int) -> int:
    return Notification.objects.filter(
        user_id=user_id, is_read=False
    ).update(is_read=True)
```

## Anti-Patterns
- Sending emails synchronously inside request/response cycle
- Notifying users who have opted out of that notification type
- Creating notifications outside `@transaction.atomic` when paired with model changes
- Notifying the actor about their own action

## Red Flags
- `send_mail()` called directly in a view without Celery
- No preference check before sending notifications
- Missing `batch_size` on bulk notification creation

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
