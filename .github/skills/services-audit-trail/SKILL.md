---
name: services-audit-trail
description: "Audit trail patterns: logging changes, AuditLog creation, tracking field changes. Use when: recording model changes, admin actions, security events, compliance logging."
---

# Audit Trail Patterns

## When to Use
- Recording who changed what and when (compliance requirement)
- Tracking field-level changes on sensitive models
- Logging admin actions (approve, reject, ban, modify)
- Security event auditing (login, permission change, data access)

## Rules
- Use `AuditLog` model from `apps.admin.models` for admin audit trails
- Create audit records inside the same `@transaction.atomic` as the change
- Log the old AND new values for field changes
- Never log sensitive data (passwords, tokens, API keys)
- Audit log creation MUST NOT block the primary operation — catch errors

## Patterns

### Field Change Tracking in Service
```python
import logging
from django.db import transaction
from apps.admin.models import AuditLog, FieldChange

logger = logging.getLogger(__name__)

@transaction.atomic
def update_firmware_status(
    *, firmware_id: int, new_status: str, changed_by_id: int
) -> None:
    firmware = Firmware.objects.select_for_update().get(pk=firmware_id)
    old_status = firmware.status
    firmware.status = new_status
    firmware.save(update_fields=["status"])
    # Record the change
    audit = AuditLog.objects.create(
        user_id=changed_by_id,
        action="update",
        model_name="Firmware",
        object_id=str(firmware.pk),
        description=f"Status changed from {old_status} to {new_status}",
    )
    FieldChange.objects.create(
        audit_log=audit,
        field_name="status",
        old_value=old_status,
        new_value=new_status,
    )
```

### Generic Audit Helper
```python
from typing import Any

def create_audit_entry(
    *,
    user_id: int,
    action: str,
    model_name: str,
    object_id: str,
    changes: dict[str, tuple[Any, Any]] | None = None,
    description: str = "",
) -> None:
    """Create an audit log entry with optional field changes."""
    audit = AuditLog.objects.create(
        user_id=user_id,
        action=action,
        model_name=model_name,
        object_id=object_id,
        description=description,
    )
    if changes:
        field_changes = [
            FieldChange(
                audit_log=audit,
                field_name=field,
                old_value=str(old) if old is not None else "",
                new_value=str(new) if new is not None else "",
            )
            for field, (old, new) in changes.items()
        ]
        FieldChange.objects.bulk_create(field_changes)
```

### Diff Detection Before Save
```python
def get_changed_fields(instance: models.Model, update_fields: list[str]) -> dict:
    """Compare current instance with database version."""
    if not instance.pk:
        return {}
    try:
        db_instance = type(instance).objects.get(pk=instance.pk)
    except type(instance).DoesNotExist:
        return {}
    changes = {}
    for field in update_fields:
        old_val = getattr(db_instance, field)
        new_val = getattr(instance, field)
        if old_val != new_val:
            changes[field] = (old_val, new_val)
    return changes
```

### Security Event Logging
```python
from apps.security.models import SecurityEvent

def log_security_event(
    *, event_type: str, user_id: int | None, ip_address: str, details: str
) -> None:
    SecurityEvent.objects.create(
        event_type=event_type,
        user_id=user_id,
        ip_address=ip_address,
        details=details,
    )
```

## Anti-Patterns
- Logging passwords, tokens, or API keys in audit records
- Creating audit records outside the transaction — change succeeds but audit fails
- Auditing every single field on every save — audit only meaningful changes
- Blocking the primary operation if audit creation fails

## Red Flags
- Sensitive model changes without audit log creation
- Audit log without `user_id` — no accountability
- Missing old/new values — can't reconstruct what happened

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
