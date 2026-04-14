---
name: models-custom-managers
description: "Custom Manager and QuerySet classes for reusable query logic. Use when: adding reusable filters, scoped default querysets, soft-delete managers, active/inactive filtering."
---

# Custom Managers

## When to Use
- Adding reusable query methods across views and services
- Filtering out soft-deleted or inactive records by default
- Creating scoped managers (e.g., `PublishedManager`, `ActiveManager`)
- Replacing repeated `.filter()` chains with named methods

## Rules
- Custom managers go in `managers.py` per app, not inline in `models.py`
- Type the manager: `class MyManager(models.Manager["MyModel"]):`
- Always define `get_queryset()` return type: `-> QuerySet["MyModel"]`
- Default manager MUST be named `objects` — additional managers use descriptive names
- Never put business logic in managers — only query construction

## Patterns

### Basic Custom Manager
```python
# apps/firmwares/managers.py
from django.db import models
from django.db.models import QuerySet

class FirmwareManager(models.Manager["Firmware"]):
    def get_queryset(self) -> QuerySet["Firmware"]:
        return super().get_queryset().select_related("brand", "model")

    def active(self) -> QuerySet["Firmware"]:
        return self.get_queryset().filter(is_active=True)

    def by_brand(self, brand_slug: str) -> QuerySet["Firmware"]:
        return self.active().filter(brand__slug=brand_slug)

    def recent(self, days: int = 30) -> QuerySet["Firmware"]:
        cutoff = timezone.now() - timedelta(days=days)
        return self.active().filter(created_at__gte=cutoff)
```

### Attaching to Model
```python
# apps/firmwares/models.py
from apps.core.models import TimestampedModel
from .managers import FirmwareManager

class Firmware(TimestampedModel):
    name = models.CharField(max_length=255)
    brand = models.ForeignKey("Brand", on_delete=models.CASCADE, related_name="firmwares_brand")
    is_active = models.BooleanField(default=True)

    objects = FirmwareManager()

    class Meta:
        db_table = "firmwares_firmware"
```

### Soft-Delete Manager Pair
```python
class ActiveManager(models.Manager["MyModel"]):
    """Default manager — excludes soft-deleted records."""
    def get_queryset(self) -> QuerySet["MyModel"]:
        return super().get_queryset().filter(is_deleted=False)

class AllObjectsManager(models.Manager["MyModel"]):
    """Includes soft-deleted records."""
    pass

class ForumTopic(TimestampedModel):
    is_deleted = models.BooleanField(default=False)

    objects = ActiveManager()       # Default: active only
    all_objects = AllObjectsManager()  # Admin: everything
```

### Manager with Type Annotations
```python
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .models import Device

class DeviceManager(models.Manager["Device"]):
    def trusted(self) -> QuerySet["Device"]:
        return self.get_queryset().filter(trust_score__gte=80)

    def for_user(self, user_id: int) -> QuerySet["Device"]:
        return self.get_queryset().filter(user_id=user_id)
```

## Anti-Patterns
- Defining managers inline in `models.py` for large apps — use `managers.py`
- Putting side effects in managers (sending emails, logging) — managers only build queries
- Forgetting type parameter on `Manager["Model"]` — Pyright will flag this
- Overriding `objects` to exclude records without providing an `all_objects` escape hatch

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Custom Managers](https://docs.djangoproject.com/en/5.2/topics/db/managers/)
