---
name: services-event-bus
description: "EventBus usage for cross-app communication without direct imports. Use when: notifying other apps of events, decoupled cross-app communication, replacing direct service imports."
---

# EventBus Patterns

## When to Use
- App A needs to notify App B of an event (firmware uploaded, user registered)
- Replacing forbidden cross-app service imports
- Decoupled side effects (send email when order placed, invalidate cache when model changes)
- Any place you'd be tempted to import another app's service

## Rules
- EventBus lives at `apps.core.events.bus` — singleton `event_bus` instance
- Event types defined in `apps.core.events.bus.EventTypes` — add new types there
- Publishers emit events in services — subscribers handle in signals/ready()
- Handlers MUST be idempotent — events may fire multiple times
- Heavy work in handlers → dispatch to Celery task
- NEVER import another app's models/services in a handler — use IDs and lazy lookups

## Patterns

### Publishing an Event
```python
# apps/firmwares/services.py
from apps.core.events.bus import event_bus, EventTypes

def create_firmware(*, name: str, brand_id: int, user_id: int) -> Firmware:
    firmware = Firmware.objects.create(name=name, brand_id=brand_id)
    # Notify other apps without importing them
    event_bus.emit(
        EventTypes.FIRMWARE_UPLOADED,
        firmware_id=firmware.pk,
        user_id=user_id,
        brand_id=brand_id,
    )
    return firmware
```

### Subscribing to Events
```python
# apps/notifications/signals.py
from apps.core.events.bus import event_bus, EventTypes

def handle_firmware_uploaded(*, firmware_id: int, user_id: int, **kwargs) -> None:
    """Send notification when new firmware is uploaded."""
    from .tasks import send_firmware_notification
    send_firmware_notification.delay(firmware_id=firmware_id, user_id=user_id)

# Register in AppConfig.ready()
event_bus.on(EventTypes.FIRMWARE_UPLOADED, handle_firmware_uploaded)
```

### Registration in AppConfig
```python
# apps/notifications/apps.py
from django.apps import AppConfig

class NotificationsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.notifications"

    def ready(self) -> None:
        from apps.core.events.bus import event_bus, EventTypes
        from . import signals  # noqa: F401
        # Or register directly:
        event_bus.on(EventTypes.FIRMWARE_UPLOADED, signals.handle_firmware_uploaded)
```

### Combining EventBus with Django Signals
```python
# apps/core/signals.py — platform signals for local app use
firmware_uploaded = Signal()

# apps/core/events/bus.py — EventTypes for cross-app use
class EventTypes:
    FIRMWARE_UPLOADED = "firmware.uploaded"
    USER_REGISTERED = "user.registered"
    DOWNLOAD_COMPLETED = "download.completed"
    WALLET_CREDITED = "wallet.credited"
    ORDER_PLACED = "order.placed"
```

### Event Handler Best Practices
```python
def handle_order_placed(*, order_id: int, user_id: int, **kwargs) -> None:
    """Always accept **kwargs for forward-compatibility."""
    try:
        from .tasks import process_order_notification
        process_order_notification.delay(order_id=order_id)
    except Exception:
        logger.exception("Failed to handle order.placed event for order %s", order_id)
        # Never let handler failure break the publisher
```

## Anti-Patterns
- Importing another app's service directly instead of using EventBus
- Putting heavy logic in event handlers — dispatch to Celery
- Event handlers that aren't idempotent — may fire multiple times
- Missing `**kwargs` in handler signature — breaks when new fields added

## Red Flags
- `from apps.other_app.services import` in a service file → use EventBus
- Event handler with database writes but no error handling
- Event handler that blocks on external API calls

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
