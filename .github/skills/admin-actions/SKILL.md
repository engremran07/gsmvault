---
name: admin-actions
description: "Custom admin actions: bulk operations, confirmation pages. Use when: adding bulk approve/reject, batch operations, custom admin toolbar actions."
---

# Admin Actions

## When to Use
- Adding bulk approve/reject for ingestion jobs or firmware submissions
- Implementing batch status changes (activate/deactivate)
- Building export or cleanup actions
- Any multi-select operation in the admin change list

## Rules
- ALWAYS decorate with `@admin.action(description="...")` for display name
- ALWAYS type-hint the queryset parameter
- Use `queryset.update()` for simple field changes — avoids N+1
- For complex operations that trigger signals, iterate and call `save()`
- Add confirmation for destructive actions (delete, revoke, reset)
- Log bulk actions to `AuditLog` for traceability

## Patterns

### Simple Status Action
```python
from django.contrib import admin
from django.db.models import QuerySet

from .models import Firmware


@admin.action(description="Mark selected as active")
def activate_firmware(
    modeladmin: admin.ModelAdmin[Firmware],
    request: HttpRequest,
    queryset: QuerySet[Firmware],
) -> None:
    updated = queryset.update(is_active=True)
    modeladmin.message_user(request, f"{updated} firmware(s) activated.")


@admin.action(description="Mark selected as inactive")
def deactivate_firmware(
    modeladmin: admin.ModelAdmin[Firmware],
    request: HttpRequest,
    queryset: QuerySet[Firmware],
) -> None:
    updated = queryset.update(is_active=False)
    modeladmin.message_user(request, f"{updated} firmware(s) deactivated.")


@admin.register(Firmware)
class FirmwareAdmin(admin.ModelAdmin[Firmware]):
    actions = [activate_firmware, deactivate_firmware]
```

### Action as Method
```python
@admin.register(IngestionJob)
class IngestionJobAdmin(admin.ModelAdmin[IngestionJob]):
    actions = ["approve_selected", "reject_selected"]

    @admin.action(description="Approve selected ingestion jobs")
    def approve_selected(self, request: HttpRequest, queryset: QuerySet[IngestionJob]) -> None:
        pending = queryset.filter(status="pending")
        updated = pending.update(status="approved")
        self.message_user(request, f"{updated} job(s) approved.")

    @admin.action(description="Reject selected ingestion jobs")
    def reject_selected(self, request: HttpRequest, queryset: QuerySet[IngestionJob]) -> None:
        pending = queryset.filter(status="pending")
        updated = pending.update(status="rejected")
        self.message_user(request, f"{updated} job(s) rejected.")
```

### Action with Service Layer
```python
from django.db import transaction

@admin.action(description="Recalculate trust scores")
def recalculate_trust(
    modeladmin: admin.ModelAdmin[Device],
    request: HttpRequest,
    queryset: QuerySet[Device],
) -> None:
    from .services import recalculate_trust_score

    success, failed = 0, 0
    for device in queryset.iterator():
        try:
            with transaction.atomic():
                recalculate_trust_score(device)
            success += 1
        except Exception:
            failed += 1

    modeladmin.message_user(
        request,
        f"Recalculated: {success} success, {failed} failed.",
    )
```

### Action with Confirmation Page
```python
from django.template.response import TemplateResponse

@admin.action(description="Delete selected permanently")
def hard_delete(
    modeladmin: admin.ModelAdmin[Firmware],
    request: HttpRequest,
    queryset: QuerySet[Firmware],
) -> TemplateResponse | None:
    if request.POST.get("confirm"):
        count = queryset.count()
        queryset.delete()
        modeladmin.message_user(request, f"{count} item(s) permanently deleted.")
        return None

    return TemplateResponse(
        request,
        "admin/confirm_action.html",
        {"queryset": queryset, "action": "hard_delete", "title": "Confirm Deletion"},
    )
```

## Anti-Patterns
- NEVER iterate with `save()` for simple field updates — use `queryset.update()`
- NEVER perform destructive actions without confirmation
- NEVER skip logging for audit-sensitive bulk operations
- NEVER modify unrelated models in an action without `transaction.atomic()`

## Red Flags
- Action modifying thousands of records without batching
- Missing `message_user` call — user gets no feedback
- Destructive action without confirmation step

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/admin.py` — existing admin action implementations
