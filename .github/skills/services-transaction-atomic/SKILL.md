---
name: services-transaction-atomic
description: "@transaction.atomic patterns for multi-model operations. Use when: writing to multiple models, ensuring data consistency, wrapping service functions in transactions."
---

# Transaction Atomic Patterns

## When to Use
- Any service function that writes to 2+ models
- Operations that must fully succeed or fully rollback
- Wallet/financial operations (ALWAYS)
- Bulk creation with dependent records

## Rules
- All multi-model writes MUST use `@transaction.atomic`
- Nested `@transaction.atomic` creates savepoints — this is safe and expected
- Never catch `IntegrityError` inside an atomic block and continue — the transaction is already broken
- Place the decorator on the outermost service function, not on individual ORM calls
- Combine with `select_for_update()` for concurrent writes

## Patterns

### Basic Atomic Service
```python
from django.db import transaction
from .models import Order, OrderItem

@transaction.atomic
def create_order(*, user_id: int, items: list[dict]) -> Order:
    """Create order with items — all or nothing."""
    order = Order.objects.create(user_id=user_id, status="pending")
    order_items = [
        OrderItem(order=order, product_id=item["product_id"], quantity=item["qty"])
        for item in items
    ]
    OrderItem.objects.bulk_create(order_items)
    return order
```

### Atomic with Manual Savepoints
```python
from django.db import transaction

@transaction.atomic
def process_payment(*, order_id: int, payment_data: dict) -> None:
    order = Order.objects.select_for_update().get(pk=order_id)
    # Create savepoint for payment attempt
    sid = transaction.savepoint()
    try:
        charge_result = external_payment_gateway(payment_data)
        if not charge_result.success:
            transaction.savepoint_rollback(sid)
            order.status = "payment_failed"
            order.save(update_fields=["status"])
            return
        transaction.savepoint_commit(sid)
    except Exception:
        transaction.savepoint_rollback(sid)
        raise
    order.status = "paid"
    order.save(update_fields=["status"])
```

### Context Manager Style
```python
def update_firmware_status(*, firmware_id: int, new_status: str) -> None:
    with transaction.atomic():
        firmware = Firmware.objects.select_for_update().get(pk=firmware_id)
        old_status = firmware.status
        firmware.status = new_status
        firmware.save(update_fields=["status"])
        AuditLog.objects.create(
            model_name="Firmware", object_id=firmware_id,
            action="status_change", old_value=old_status, new_value=new_status,
        )
```

### Atomic with on_commit for Side Effects
```python
from django.db import transaction

@transaction.atomic
def approve_firmware(*, firmware_id: int, reviewer_id: int) -> None:
    firmware = Firmware.objects.select_for_update().get(pk=firmware_id)
    firmware.status = "approved"
    firmware.reviewed_by_id = reviewer_id
    firmware.save(update_fields=["status", "reviewed_by_id"])
    # Only send notification AFTER commit succeeds
    transaction.on_commit(lambda: send_approval_notification.delay(firmware_id))
```

## Anti-Patterns
- Writing to 2+ models without `@transaction.atomic` — data inconsistency risk
- Sending emails/notifications inside atomic block — use `transaction.on_commit()`
- Catching `IntegrityError` inside atomic and continuing — transaction is doomed
- Using `@transaction.atomic` on read-only functions — unnecessary overhead

## Red Flags
- Service with multiple `.create()` / `.save()` calls and no `@transaction.atomic`
- `send_mail()` or `.delay()` inside atomic block without `on_commit`
- `try/except IntegrityError` inside `@transaction.atomic` without savepoint

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
