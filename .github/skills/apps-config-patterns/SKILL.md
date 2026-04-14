---
name: apps-config-patterns
description: "AppConfig patterns: ready(), default_auto_field, signal registration. Use when: creating new apps, configuring apps.py, registering signals, setting up app metadata."
---

# AppConfig Patterns

## When to Use
- Creating a new Django app in `apps/`
- Registering signal handlers via `ready()`
- Setting `default_auto_field` for consistent primary keys
- Configuring `verbose_name` for admin display

## Rules
- ALWAYS set `name = "apps.<appname>"` matching the directory path
- ALWAYS set `default_auto_field = "django.db.models.BigAutoField"`
- ALWAYS set `verbose_name = "Human Readable Name"`
- Class name follows `<Appname>Config` pattern
- Import signal handlers in `ready()` — NEVER at module level
- Use `noqa: F401` on signal imports (side-effect import)
- If app has no signals, omit `ready()` entirely
- Register in `INSTALLED_APPS` with full dotted path: `"apps.firmwares"`

## Patterns

### Standard AppConfig
```python
# apps/firmwares/apps.py
from django.apps import AppConfig


class FirmwaresConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.firmwares"
    verbose_name = "Firmwares"
```

### AppConfig with Signal Registration
```python
# apps/devices/apps.py
from django.apps import AppConfig


class DevicesConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.devices"
    verbose_name = "Devices"

    def ready(self) -> None:
        import apps.devices.signals  # noqa: F401
```

### AppConfig with Multiple Signals
```python
# apps/notifications/apps.py
from django.apps import AppConfig


class NotificationsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.notifications"
    verbose_name = "Notifications"

    def ready(self) -> None:
        # Import all signal handler modules
        import apps.notifications.signals  # noqa: F401
        # EventBus subscriptions can also go here
        from apps.core.events.bus import event_bus, EventTypes
        from . import handlers
        event_bus.subscribe(EventTypes.FIRMWARE_UPLOADED, handlers.on_firmware_uploaded)
```

### Infrastructure App (apps.core)
```python
# apps/core/apps.py
from django.apps import AppConfig


class CoreConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.core"
    verbose_name = "Core Infrastructure"

    def ready(self) -> None:
        import apps.core.signals  # noqa: F401
```

### INSTALLED_APPS Registration
```python
# app/settings.py
INSTALLED_APPS = [
    # Django built-in
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Third-party
    "rest_framework",
    "django_celery_beat",
    "allauth",
    # Infrastructure (load first)
    "apps.core",
    "apps.site_settings",
    # Auth & Users
    "apps.users",
    "apps.user_profile",
    # All other apps (alphabetical)
    "apps.admin",
    "apps.ads",
    "apps.ai",
    "apps.analytics",
    # ... remaining apps
]
```

### Signals File (Referenced by ready())
```python
# apps/devices/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Device


@receiver(post_save, sender=Device)
def on_device_created(sender, instance, created, **kwargs):  # type: ignore[no-untyped-def]
    if created:
        from .services import initialize_trust_score
        initialize_trust_score(instance)
```

### Common Mistakes Checklist

| Check | Correct | Wrong |
|-------|---------|-------|
| App name | `name = "apps.firmwares"` | `name = "firmwares"` |
| Class name | `FirmwaresConfig` | `FirmwareConfig` (must match app label convention) |
| Auto field | `"django.db.models.BigAutoField"` | Missing (uses default AutoField) |
| Signal import | In `ready()` | At module top level |
| INSTALLED_APPS | `"apps.firmwares"` | `"apps.firmwares.apps.FirmwaresConfig"` |

## Anti-Patterns
- NEVER import signals at module level — causes import order issues
- NEVER register the same app twice in `INSTALLED_APPS`
- NEVER use hyphens in app names — Django doesn't support them
- NEVER hard-code dependencies on other apps in `apps.py`
- NEVER add an empty `ready()` method — omit it if no signals

## Red Flags
- Missing `default_auto_field` — uses deprecated `AutoField`
- `name` doesn't match directory path (`name = "firmwares"` for `apps/firmwares/`)
- Signal import at top of `apps.py` instead of inside `ready()`
- Missing `verbose_name` — admin shows technical app label

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `.claude/rules/apps-config.md` — app config rules
- `apps/*/apps.py` — existing app configurations
- `app/settings.py` — INSTALLED_APPS registration
