---
name: fin-order-refund
description: "Refund processing: wallet credit, partial refunds. Use when: processing full or partial refunds, crediting wallet on return, handling refund disputes."
---

# Order Refund

## When to Use

- Customer requests a refund (full or partial)
- Admin-initiated refund for quality issues
- Automated refund on fulfillment failure

## Rules

1. **Refund to wallet** — credit back to the original payment source
2. **Partial refunds** supported — track refunded amount per order
3. **Total refunds cannot exceed** original order amount
4. **Restore inventory** on full refund (not partial)
5. **Atomic** — wallet credit + order status + refund log in one transaction

## Pattern: Refund Service

```python
from decimal import Decimal
from django.db import transaction
from apps.shop.models import Order, RefundRecord
from apps.wallet.models import Wallet, Transaction

@transaction.atomic
def process_refund(
    order_id: int,
    amount: Decimal,
    reason: str,
    admin_id: int | None = None,
) -> RefundRecord:
    """Process a full or partial refund."""
    order = Order.objects.select_for_update().get(pk=order_id)

    # Validate refund amount
    previous_refunds = (
        RefundRecord.objects
        .filter(order=order)
        .aggregate(total=models.Sum("amount"))
    )["total"] or Decimal("0")

    if previous_refunds + amount > order.total:
        raise ValueError("Refund exceeds order total")

    # Credit wallet
    wallet = Wallet.objects.select_for_update().get(user_id=order.user_id)
    wallet.balance += amount
    wallet.save(update_fields=["balance", "updated_at"])

    Transaction.objects.create(
        wallet=wallet, amount=amount,
        transaction_type="refund",
        reason=f"Refund for order #{order.pk}: {reason}",
        balance_after=wallet.balance,
    )

    # Record refund
    refund = RefundRecord.objects.create(
        order=order, amount=amount, reason=reason,
        refunded_by_id=admin_id,
    )

    # Update order status if fully refunded
    if previous_refunds + amount >= order.total:
        order.status = "refunded"
        order.save(update_fields=["status", "updated_at"])

    return refund
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Refund exceeding original amount | Platform loses money | Validate cumulative refunds |
| No refund record | Can't audit who approved the refund | Create `RefundRecord` |
| Subtracting from revenue without wallet credit | User doesn't get money back | Credit wallet |
| Restoring stock on partial refund | Item wasn't returned | Only restore on full refund |

## Red Flags

- Missing cumulative refund cap check
- Refund outside `@transaction.atomic`
- No `admin_id` tracking on admin-initiated refunds
- Wallet credit without `select_for_update()`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
