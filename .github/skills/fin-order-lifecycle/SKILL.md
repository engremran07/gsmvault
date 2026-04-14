---
name: fin-order-lifecycle
description: "Order state machine: pending→confirmed→processing→shipped→delivered. Use when: building order workflows, validating state transitions, tracking order status."
---

# Order Lifecycle

## When to Use

- Creating shop purchase orders
- Validating allowed state transitions
- Building order status tracking UI

## Rules

1. **Defined states**: pending → confirmed → processing → shipped → delivered (+ cancelled, refunded)
2. **Transitions must be validated** — no jumping from pending to delivered
3. **Each transition** creates a status log entry with timestamp
4. **Atomic transitions** — status change + side effects in `@transaction.atomic`
5. **Only specific roles** can trigger certain transitions (user vs admin vs system)

## Pattern: State Machine

```python
from django.db import transaction

VALID_TRANSITIONS = {
    "pending": ["confirmed", "cancelled"],
    "confirmed": ["processing", "cancelled", "refunded"],
    "processing": ["shipped", "cancelled"],
    "shipped": ["delivered"],
    "delivered": ["refunded"],
    "cancelled": [],
    "refunded": [],
}

@transaction.atomic
def transition_order(
    order_id: int,
    new_status: str,
    actor_id: int,
    note: str = "",
) -> None:
    """Transition order to new status with validation."""
    from apps.shop.models import Order, OrderStatusLog

    order = Order.objects.select_for_update().get(pk=order_id)
    allowed = VALID_TRANSITIONS.get(order.status, [])

    if new_status not in allowed:
        raise ValueError(
            f"Cannot transition from '{order.status}' to '{new_status}'. "
            f"Allowed: {allowed}"
        )
    old_status = order.status
    order.status = new_status
    order.save(update_fields=["status", "updated_at"])

    OrderStatusLog.objects.create(
        order=order,
        from_status=old_status,
        to_status=new_status,
        changed_by_id=actor_id,
        note=note,
    )
```

## Pattern: Status Check Helper

```python
def order_can_be_cancelled(order) -> bool:
    return "cancelled" in VALID_TRANSITIONS.get(order.status, [])

def order_can_be_refunded(order) -> bool:
    return "refunded" in VALID_TRANSITIONS.get(order.status, [])
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| `order.status = "delivered"` without validation | Skips state machine | Use `transition_order()` |
| No status log table | Can't track when/who changed status | Always log transitions |
| String comparison without constant map | Typos cause silent bugs | Use `VALID_TRANSITIONS` dict |

## Red Flags

- Direct `order.status = x; order.save()` bypassing transition validation
- Missing `OrderStatusLog` entries
- No `select_for_update()` on status transitions

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/shop/models.py` — Order, OrderStatusLog
- `apps/shop/services.py` — order transition logic
