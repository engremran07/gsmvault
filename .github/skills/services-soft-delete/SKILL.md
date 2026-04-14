---
name: services-soft-delete
description: "Soft delete patterns: is_deleted flag, SoftDeleteModel, queryset filtering. Use when: implementing soft delete, restoring deleted records, filtering out deleted items."
---

# Soft Delete Patterns

## When to Use
- Records that must be recoverable after deletion (firmwares, users, orders)
- Audit requirements that forbid physical deletion
- Preserving FK integrity for historical records
- Models inheriting from `SoftDeleteModel` (from `apps.core.models`)

## Rules
- Inherit from `SoftDeleteModel` (via `apps.core.models`) for soft-delete support
- Use the default manager to auto-filter deleted records from normal queries
- Provide an `all_objects` manager for admin views that need to see deleted records
- Soft-deleted records: set `is_deleted=True` + `deleted_at=timezone.now()`
- Hard delete only via explicit admin action or data retention cleanup

## Patterns

### Model with SoftDeleteModel Base
```python
from apps.core.models import SoftDeleteModel

class Firmware(SoftDeleteModel):
    name = models.CharField(max_length=255)
    # ... fields ...

    class Meta:
        db_table = "firmwares_firmware"
        verbose_name = "Firmware"
        ordering = ["-created_at"]
```

### Custom Manager for Soft Delete
```python
from django.db import models
from django.utils import timezone

class SoftDeleteQuerySet(models.QuerySet):
    def delete(self) -> tuple[int, dict[str, int]]:
        return self.update(is_deleted=True, deleted_at=timezone.now()), {}

    def hard_delete(self) -> tuple[int, dict[str, int]]:
        return super().delete()

    def alive(self) -> "SoftDeleteQuerySet":
        return self.filter(is_deleted=False)

    def dead(self) -> "SoftDeleteQuerySet":
        return self.filter(is_deleted=True)

class SoftDeleteManager(models.Manager):
    def get_queryset(self) -> SoftDeleteQuerySet:
        return SoftDeleteQuerySet(self.model, using=self._db).alive()

class AllObjectsManager(models.Manager):
    def get_queryset(self) -> SoftDeleteQuerySet:
        return SoftDeleteQuerySet(self.model, using=self._db)
```

### Service Layer Soft Delete
```python
from django.utils import timezone

def soft_delete_firmware(*, firmware_id: int, deleted_by_id: int) -> None:
    """Soft-delete a firmware entry."""
    firmware = Firmware.objects.get(pk=firmware_id)
    firmware.is_deleted = True
    firmware.deleted_at = timezone.now()
    firmware.save(update_fields=["is_deleted", "deleted_at"])
    logger.info("Firmware %s soft-deleted by user %s", firmware_id, deleted_by_id)

def restore_firmware(*, firmware_id: int) -> Firmware:
    """Restore a soft-deleted firmware entry."""
    firmware = Firmware.all_objects.get(pk=firmware_id, is_deleted=True)
    firmware.is_deleted = False
    firmware.deleted_at = None
    firmware.save(update_fields=["is_deleted", "deleted_at"])
    return firmware
```

### Admin View Showing Deleted Records
```python
# In admin views — use all_objects to see soft-deleted records
def admin_deleted_list(request):
    deleted = Firmware.all_objects.filter(is_deleted=True).order_by("-deleted_at")
    return _render_admin(request, "admin/firmwares/deleted.html", {"items": deleted})
```

## Anti-Patterns
- Overriding `Model.delete()` without also overriding `QuerySet.delete()` — bulk deletes bypass model method
- Forgetting to filter `is_deleted=False` in service queries — use the default manager
- Hard-deleting records that have FK references — breaks referential integrity
- Soft-deleting without setting `deleted_at` — no audit trail of when

## Red Flags
- `Model.objects.all()` on a soft-delete model without default manager filtering
- `.delete()` call on a model that should be soft-deleted
- Missing `all_objects` manager for admin/recovery views

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
