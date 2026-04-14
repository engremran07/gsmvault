---
applyTo: 'apps/*/signals.py'
---

# Django Signal Conventions

## Registration

Register signals in the app's `apps.py` `ready()` method:

```python
# apps.py
class FirmwaresConfig(AppConfig):
    name = "apps.firmwares"
    default_auto_field = "django.db.models.BigAutoField"

    def ready(self) -> None:
        import apps.firmwares.signals  # noqa: F401
```

## Signal Handlers

Use `@receiver` decorator with explicit sender:

```python
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from .models import Firmware

@receiver(post_save, sender=Firmware)
def on_firmware_saved(
    sender: type[Firmware], instance: Firmware, created: bool, **kwargs: Any
) -> None:
    if created:
        from .services import initialize_firmware_metadata
        initialize_firmware_metadata(instance)
```

## Keep Handlers Thin

Signal handlers MUST be thin — call service functions for business logic:

```python
# CORRECT — handler calls service
@receiver(post_save, sender=Firmware)
def on_firmware_created(sender: type, instance: Firmware, created: bool, **kwargs: Any) -> None:
    if created:
        from .services import process_new_firmware
        process_new_firmware(instance)

# WRONG — business logic in handler
@receiver(post_save, sender=Firmware)
def on_firmware_created(sender, instance, created, **kwargs):
    if created:
        instance.file_hash = hashlib.sha256(instance.file.read()).hexdigest()
        instance.save()
        AuditLog.objects.create(...)  # Too much logic in handler
```

## Error Handling

NEVER raise exceptions in signal handlers — log and continue:

```python
@receiver(post_save, sender=Firmware)
def on_firmware_saved(sender: type, instance: Firmware, created: bool, **kwargs: Any) -> None:
    try:
        if created:
            from .services import notify_firmware_uploaded
            notify_firmware_uploaded(instance)
    except Exception:
        logger.exception("Failed to process firmware signal for pk=%d", instance.pk)
        # Do NOT re-raise — other signal handlers must still run
```

## Cross-App Communication

Prefer `EventBus` over Django signals for cross-app communication:

```python
# PREFERRED — EventBus for cross-app events
from apps.core.events.bus import event_bus, EventTypes

@receiver(post_save, sender=Firmware)
def emit_firmware_event(sender: type, instance: Firmware, created: bool, **kwargs: Any) -> None:
    if created:
        event_bus.emit(EventTypes.FIRMWARE_UPLOADED, {
            "firmware_id": instance.pk,
            "user_id": instance.user_id,
        })
```

Use Django signals for within-app events only. Use `apps.core.events.EventBus` for cross-app.

## Platform Signals

Use platform-level signals defined in `apps.core.signals`:

```python
from apps.core.signals import firmware_uploaded, firmware_download_ready, storage_quota_exhausted
```

## Type Hints

Signal handlers must have full type hints:

```python
@receiver(post_save, sender=Firmware)
def on_firmware_saved(
    sender: type[Firmware],
    instance: Firmware,
    created: bool,
    **kwargs: Any,
) -> None:
    ...
```

## Avoiding Infinite Loops

When modifying the instance inside a `post_save` handler, use `update_fields` and guard:

```python
@receiver(post_save, sender=Firmware)
def compute_hash(sender: type, instance: Firmware, created: bool, **kwargs: Any) -> None:
    update_fields = kwargs.get("update_fields")
    if update_fields and "file_hash" in update_fields:
        return  # Prevent recursion
    if created and not instance.file_hash:
        instance.file_hash = compute_file_hash(instance.file)
        instance.save(update_fields=["file_hash"])
```
