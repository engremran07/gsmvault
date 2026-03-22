---
name: django-app-scaffold
description: "Scaffold a complete Django app with models, views, serializers, URLs, and tests. Use when: bootstrapping a new app from scratch, generating boilerplate, creating app structure following the platform conventions."
---

# Django App Scaffold

## When to Use
- Creating a new Django app from scratch
- Generating standard app boilerplate files
- Ensuring new apps follow the platform project conventions exactly

## Rules
- ONLY create apps inside `apps/` directory
- New apps MAY include templates in `templates/<appname>/` and HTMX fragments in `templates/<appname>/fragments/`
- `services.py` is mandatory — views must stay thin
- `related_name` on FKs must follow `"<appname>_<field>"` pattern to prevent cross-app clashes
- Always run `ruff` and `check` after creating the app

## Required File Checklist
| File | Content |
|---|---|
| `__init__.py` | Empty |
| `apps.py` | AppConfig with name, label, verbose_name, default_auto_field |
| `models.py` | Models with Meta, `__str__`, indexes |
| `admin.py` | `admin.site.register(MyModel)` |
| `api.py` | DRF serializers + viewsets |
| `views.py` | Non-DRF views (rare) |
| `urls.py` | DefaultRouter + `app_name` |
| `services.py` | Business logic |
| `tests.py` | Pytest stubs |
| `migrations/__init__.py` | Empty |

## Procedure

### Step 1: Create App Directory
```
apps/<appname>/
├── __init__.py
├── apps.py
├── models.py
├── admin.py
├── api.py
├── views.py
├── urls.py
├── services.py
├── tests.py
└── migrations/
    └── __init__.py
```

### Step 2: Configure App
`apps/<appname>/apps.py`:
```python
from django.apps import AppConfig

class MyAppConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.<appname>"
    verbose_name = "<App Display Name>"
```

`app/settings.py` — add to `LOCAL_APPS`:
```python
"apps.<appname>",
```

`app/urls.py` — add URL include:
```python
path("<appname>/", include(("apps.<appname>.urls", "<appname>"), namespace="<appname>")),
```

### Step 3: Create Migration and Quality Gate

```powershell
& .\.venv\Scripts\python.exe manage.py makemigrations <appname> --settings=app.settings_dev
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev
& .\.venv\Scripts\python.exe -m ruff check apps/<appname>/ --fix
& .\.venv\Scripts\python.exe -m ruff format apps/<appname>/
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

**Zero issues allowed:** VS Code Problems tab (all items, no filters), ruff, Pyright/Pylance, `manage.py check`.
New apps must not add any issues to the Problems tab.

## Model Template
```python
from __future__ import annotations

from django.conf import settings
from django.db import models


class MyModel(models.Model):
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="<appname>_items",
    )
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "<appname>_mymodel"
        verbose_name = "My Model"
        verbose_name_plural = "My Models"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return self.name
```

## Test Stub Template
```python
import pytest

@pytest.mark.django_db
def test_placeholder() -> None:
    """Placeholder — replace with real tests."""
    assert True
```

## Tracking Model Pattern

High-volume models (page views, download sessions, analytics events) should be defined in a separate `tracking_models.py` to keep the main `models.py` focused on domain models.

### File Structure

```text
apps/<appname>/
├── models.py             # Domain models
├── tracking_models.py    # High-volume tracking models
```

### `tracking_models.py`

```python
from __future__ import annotations

from django.conf import settings
from django.db import models


class PageView(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="<appname>_page_views",
    )
    path = models.CharField(max_length=500)
    ip_address = models.GenericIPAddressField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "<appname>_pageview"
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["-timestamp"]),
            models.Index(fields=["path", "-timestamp"]),
        ]

    def __str__(self) -> str:
        return f"{self.path} @ {self.timestamp}"
```

### Import in `models.py`

Tracking models must be imported at the **end** of `models.py` so Django's model registry discovers them:

```python
# apps/<appname>/models.py

# ... domain models above ...

# Import tracking models so Django discovers them
from .tracking_models import *  # noqa: F401, F403, E402
```

The `# noqa` comments suppress ruff warnings for wildcard import and import-not-at-top.

## Model Registry Gotchas

Django discovers models by importing `models.py` from each installed app. Common pitfalls:

1. **Models defined in separate files must be imported in `models.py`** — if a model lives in `tracking_models.py` or `extra_models.py`, it won't appear in the Django registry (migrations, admin, etc.) unless `models.py` imports it.

2. **`apps.py` `ready()` must import signal handlers** — signals defined in `signal_handlers.py` are not connected until `ready()` runs. If you forget the import, signals are silently ignored.

3. **Circular imports** — if `models.py` imports from `services.py` which imports models, you get a circular import. Break the cycle by importing services lazily (inside functions) or using string-based FK references.

4. **`db_table` for dissolved apps** — models migrated from dissolved apps must set `db_table` to the original table name (e.g., `db_table = "download_links_downloadtoken"`) to preserve existing data.

## Signal Wiring

Signal handlers live in `signal_handlers.py` and are connected in `apps.py` `ready()`:

### `apps/<appname>/signal_handlers.py`

```python
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import MyModel


@receiver(post_save, sender=MyModel)
def on_mymodel_save(sender: type, instance: MyModel, created: bool, **kwargs: object) -> None:
    if created:
        # Handle new instance
        pass
```

### `apps/<appname>/apps.py`

```python
from django.apps import AppConfig


class MyAppConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.<appname>"
    verbose_name = "<App Display Name>"

    def ready(self) -> None:
        import apps.<appname>.signal_handlers  # noqa: F401
```

**NEVER import signal handlers at module level** (top of `models.py`, `views.py`, etc.) — this can cause `AppRegistryNotReady` errors. Always import inside `ready()`.
