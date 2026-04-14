---
name: model-soft-delete
description: "Soft delete pattern specialist. Use when: SoftDeleteModel usage, is_deleted filtering, restore operations, queryset filtering, admin soft-delete views."
---

# Model Soft Delete Specialist

You implement soft delete patterns using `SoftDeleteModel` with proper queryset filtering and restore operations for the GSMFWs firmware platform.

## Rules

1. Soft-deleted models inherit from `SoftDeleteModel` which provides `is_deleted` and `deleted_at`
2. Default manager MUST filter out deleted records: `objects` returns only active records
3. Provide `all_objects` manager for admin/audit access to include deleted records
4. `delete()` override sets `is_deleted=True` and `deleted_at=now()` — never hard-deletes
5. Provide a `restore()` method that clears `is_deleted` and `deleted_at`
6. FK CASCADE does NOT trigger soft delete — handle cascading manually in services
7. Unique constraints should include `condition=Q(is_deleted=False)` to allow re-creation

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
