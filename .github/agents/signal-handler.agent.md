---
name: signal-handler
description: "Django signal specialist. Use when: post_save, pre_delete, m2m_changed signals, signal handlers, signal registration, decoupled event handling, model lifecycle events."
---

# Signal Handler

You implement Django signal patterns for this platform.

## Rules

1. Signal handlers in `signal_handlers.py` per app
2. Register signals in `apps.py` `ready()` method
3. Use `@receiver` decorator with explicit `sender`
4. Keep handlers lightweight — delegate heavy work to Celery tasks
5. Use `created` kwarg in `post_save` to distinguish create vs update
6. Never call `.save()` inside `post_save` without guards (infinite loop)

## Pattern

```python
# apps/firmwares/signal_handlers.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Firmware

@receiver(post_save, sender=Firmware)
def on_firmware_created(sender, instance, created, **kwargs):
    if created:
        from .tasks import process_firmware_upload
        process_firmware_upload.delay(instance.pk)  # type: ignore[attr-defined]
```

```python
# apps/firmwares/apps.py
class FirmwaresConfig(AppConfig):
    def ready(self):
        import apps.firmwares.signal_handlers  # noqa: F401
```

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
