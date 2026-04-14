---
name: models-signals
description: "post_save, pre_delete, m2m_changed signal patterns and anti-patterns. Use when: reacting to model lifecycle events, cross-app communication via signals, audit logging."
---

# Model Signals

## When to Use
- Cross-app communication without direct imports (app A notifies app B)
- Audit logging on save/delete events
- Cache invalidation on model changes
- Triggering async tasks after model operations
- Reacting to M2M relationship changes

## Rules
- Signal handlers go in `signals.py` per app — never inline in `models.py`
- Connect signals in `AppConfig.ready()` method in `apps.py`
- Platform-level signals defined in `apps/core/signals.py` — use those first
- For cross-app communication, prefer `apps.core.events.EventBus` over raw signals
- Signal handlers MUST be idempotent — they can fire multiple times
- Never put heavy logic in signals — dispatch to Celery tasks

## Patterns

### Signal Handler in signals.py
```python
# apps/firmwares/signals.py
import logging
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from .models import Firmware

logger = logging.getLogger(__name__)

@receiver(post_save, sender=Firmware)
def on_firmware_saved(sender: type[Firmware], instance: Firmware, created: bool, **kwargs: Any) -> None:
    if created:
        logger.info("New firmware created: %s (pk=%s)", instance.name, instance.pk)
        # Dispatch to async task for heavy work
        from .tasks import process_new_firmware
        process_new_firmware.delay(instance.pk)

@receiver(pre_delete, sender=Firmware)
def on_firmware_deleted(sender: type[Firmware], instance: Firmware, **kwargs: Any) -> None:
    logger.info("Firmware being deleted: %s (pk=%s)", instance.name, instance.pk)
```

### Connecting in AppConfig.ready()
```python
# apps/firmwares/apps.py
from django.apps import AppConfig

class FirmwaresConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.firmwares"
    verbose_name = "Firmwares"

    def ready(self) -> None:
        import apps.firmwares.signals  # noqa: F401
```

### Platform Signals (apps.core.signals)
```python
# apps/core/signals.py — already defined
from django.dispatch import Signal

firmware_uploaded = Signal()       # Sent when firmware file is uploaded
firmware_download_ready = Signal() # Sent when download token is created
storage_quota_exhausted = Signal() # Sent when storage quota is exceeded

# Usage in services:
from apps.core.signals import firmware_uploaded
firmware_uploaded.send(sender=Firmware, instance=firmware, user=user)
```

### M2M Changed Signal
```python
from django.db.models.signals import m2m_changed

@receiver(m2m_changed, sender=ForumTopic.tags.through)
def on_topic_tags_changed(
    sender: type, instance: ForumTopic, action: str, pk_set: set[int] | None, **kwargs: Any
) -> None:
    if action in ("post_add", "post_remove", "post_clear"):
        # Invalidate cached tag list
        cache_key = f"topic_tags_{instance.pk}"
        cache.delete(cache_key)
```

### EventBus for Cross-App Communication
```python
# Prefer EventBus over signals for cross-app:
from apps.core.events.bus import event_bus, EventTypes

# Publishing (in services.py):
event_bus.emit(EventTypes.FIRMWARE_UPLOADED, firmware_id=firmware.pk, user_id=user.pk)

# Subscribing (in signals.py or ready()):
event_bus.on(EventTypes.FIRMWARE_UPLOADED, handle_new_firmware)
```

## Anti-Patterns
- Heavy processing in signal handlers — dispatch to Celery tasks
- Cross-app model imports in signal handlers — use EventBus instead
- Not making handlers idempotent — signals can fire multiple times
- Connecting signals in `models.py` — always in `signals.py` + `ready()`
- Raising exceptions in signal handlers — can break the save transaction
- Using `pre_save` to modify unrelated models — side effects are hidden

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Signals](https://docs.djangoproject.com/en/5.2/topics/signals/)
- `apps/core/signals.py` — platform signal definitions
- `apps/core/events/bus.py` — EventBus for cross-app events
