---
name: fin-order-fulfillment
description: "Order fulfillment: inventory check, notification, tracking. Use when: processing confirmed orders, checking stock, sending order notifications, updating tracking."
---

# Order Fulfillment

## When to Use

- Processing confirmed orders for delivery
- Checking inventory/stock before fulfillment
- Sending order status notifications to buyer
- Adding shipping/tracking information

## Rules

1. **Check inventory** before transitioning to "processing"
2. **Reserve stock** atomically with order confirmation
3. **Send notifications** on each status change (email + in-app)
4. **Tracking info** added when order moves to "shipped"
5. **Auto-complete** after delivery confirmation timeout

## Pattern: Fulfillment Service

```python
from django.db import transaction
from apps.shop.models import Order, Product

@transaction.atomic
def fulfill_order(order_id: int) -> None:
    """Move order to processing after inventory check."""
    order = Order.objects.select_for_update().get(pk=order_id)
    if order.status != "confirmed":
        raise ValueError("Only confirmed orders can be fulfilled")

    for item in order.items.select_for_update().select_related("product"):
        product = item.product
        if product.stock < item.quantity:
            raise ValueError(f"Insufficient stock for {product.name}")
        product.stock -= item.quantity
        product.save(update_fields=["stock", "updated_at"])

    order.status = "processing"
    order.save(update_fields=["status", "updated_at"])
    # Trigger notification via EventBus
    from apps.core.events.bus import event_bus, EventTypes
    event_bus.emit(EventTypes.ORDER_STATUS_CHANGED, {
        "order_id": order.pk, "status": "processing",
        "user_id": order.user_id,
    })


@transaction.atomic
def add_tracking(order_id: int, carrier: str, tracking_number: str) -> None:
    """Add tracking info and transition to shipped."""
    order = Order.objects.select_for_update().get(pk=order_id)
    if order.status != "processing":
        raise ValueError("Only processing orders can be shipped")
    order.carrier = carrier
    order.tracking_number = tracking_number
    order.status = "shipped"
    order.save(update_fields=["carrier", "tracking_number",
                               "status", "updated_at"])
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Fulfilling without stock check | Overselling | Check stock with `select_for_update()` |
| Stock decrement outside atomic block | Race condition on concurrent orders | Same transaction |
| No notification on status change | User left in dark | EventBus emission |

## Red Flags

- `product.stock -= quantity` without `select_for_update()`
- Fulfillment without inventory validation
- Missing tracking info when order ships

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
