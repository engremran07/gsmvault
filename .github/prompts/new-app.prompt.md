---
agent: 'agent'
description: 'Scaffold a new Django app with models, views, URLs, services, admin, apps.py, and tests following platform conventions.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# New App

Scaffold a complete new Django app following all GSMFWs platform conventions. The user will provide the app name and purpose.

## Step 1 — Pre-Creation Checks

1. Verify the app name doesn't conflict with existing apps: `list_dir` on `apps/`.
2. Search for existing functionality that might overlap: `semantic_search` for the feature domain.
3. Confirm the app truly needs to be separate — prefer extending existing apps over creating new ones.

## Step 2 — Create App Structure

Create the following files in `apps/<app_name>/`:

### `apps/<app_name>/__init__.py`
Empty file.

### `apps/<app_name>/apps.py`
```python
from django.apps import AppConfig


class <AppName>Config(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.<app_name>"
    verbose_name = "<Human Readable Name>"

    def ready(self) -> None:
        import apps.<app_name>.signals  # noqa: F401
```

### `apps/<app_name>/models.py`
```python
from django.conf import settings
from django.db import models

from apps.core.models import TimestampedModel


class ExampleModel(TimestampedModel):
    """Brief description."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="<app_name>_examples",
    )
    name = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "<app_name>_examplemodel"
        verbose_name = "Example"
        verbose_name_plural = "Examples"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return self.name
```

### `apps/<app_name>/services.py`
```python
"""Business logic for <app_name>."""

from django.db import transaction


@transaction.atomic
def create_example(*, user: "User", name: str) -> "ExampleModel":
    """Create a new example."""
    from apps.<app_name>.models import ExampleModel

    return ExampleModel.objects.create(user=user, name=name)
```

### `apps/<app_name>/views.py`
```python
from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.shortcuts import render


@login_required
def example_list(request: HttpRequest) -> HttpResponse:
    """List examples for current user."""
    from apps.<app_name>.models import ExampleModel

    examples = ExampleModel.objects.filter(user=request.user, is_active=True)

    if request.headers.get("HX-Request"):
        return render(request, "<app_name>/fragments/list.html", {"examples": examples})
    return render(request, "<app_name>/list.html", {"examples": examples})
```

### `apps/<app_name>/urls.py`
```python
from django.urls import path

from . import views

app_name = "<app_name>"

urlpatterns = [
    path("", views.example_list, name="list"),
]
```

### `apps/<app_name>/admin.py`
```python
from django.contrib import admin

from .models import ExampleModel


@admin.register(ExampleModel)
class ExampleModelAdmin(admin.ModelAdmin["ExampleModel"]):
    list_display = ("name", "user", "is_active", "created_at")
    list_filter = ("is_active",)
    search_fields = ("name",)
    raw_id_fields = ("user",)
```

### `apps/<app_name>/signals.py`
```python
"""Signals for <app_name>."""
```

### `apps/<app_name>/tests.py`
```python
"""Tests for apps.<app_name>."""

import pytest

from apps.<app_name>.models import ExampleModel


@pytest.mark.django_db
class TestExampleModel:
    def test_str(self) -> None:
        """__str__ returns name."""
        ...
```

### `apps/<app_name>/migrations/__init__.py`
Empty file.

## Step 3 — Register the App

1. Add `"apps.<app_name>"` to `INSTALLED_APPS` in `app/settings.py`.
2. Add URL include to `app/urls.py`:
   ```python
   path("<app_name>/", include("apps.<app_name>.urls")),
   ```

## Step 4 — Create Templates

Create template directories:

- `templates/<app_name>/list.html` — Full page template extending base.
- `templates/<app_name>/fragments/list.html` — HTMX fragment (no `{% extends %}`).

## Step 5 — Generate Migrations

```powershell
& .\.venv\Scripts\python.exe manage.py makemigrations <app_name> --settings=app.settings_dev
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev
```

## Step 6 — Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## Step 7 — Documentation

Update these files to include the new app:
- `README.md` — Add app to feature list.
- `AGENTS.md` — Add app to Architecture section.
- `.github/copilot-instructions.md` — Add app summary.
