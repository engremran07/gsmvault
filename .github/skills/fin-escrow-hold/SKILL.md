---
name: fin-escrow-hold
description: "Escrow hold pattern for marketplace transactions. Use when: marketplace P2P trades, holding buyer funds until seller delivers, protecting both parties."
---

# Escrow Hold

## When to Use

- Marketplace P2P transactions where buyer pays before seller delivers
- Bounty claims where payout is contingent on acceptance
- Any transaction requiring trusted intermediary pattern

## Rules

1. **Debit buyer instantly** — funds leave their wallet immediately
2. **Hold in escrow account** — not in seller's wallet yet
3. **Atomic** — buyer debit + escrow entry in single transaction
4. **Escrow expires** after configurable timeout → auto-refund
5. **Both parties** can see escrow status

## Pattern: Escrow Hold Service

```python
from decimal import Decimal
from django.db import transaction
from apps.wallet.models import Wallet, Transaction
from apps.marketplace.models import EscrowHold
import uuid

@transaction.atomic
def create_escrow(
    buyer_id: int,
    seller_id: int,
    amount: Decimal,
    listing_id: int,
    hold_days: int = 14,
) -> EscrowHold:
    """Hold buyer funds in escrow for a marketplace trade."""
    if amount <= Decimal("0"):
        raise ValueError("Escrow amount must be positive")

    wallet = Wallet.objects.select_for_update().get(user_id=buyer_id)
    if wallet.balance < amount:
        raise ValueError("Insufficient balance for escrow")

    # Debit buyer
    wallet.balance -= amount
    wallet.save(update_fields=["balance", "updated_at"])

    ref = str(uuid.uuid4())
    Transaction.objects.create(
        wallet=wallet, amount=-amount,
        transaction_type="escrow_hold",
        reason=f"Escrow for listing #{listing_id}",
        reference=ref, balance_after=wallet.balance,
    )

    from datetime import date, timedelta
    return EscrowHold.objects.create(
        buyer_id=buyer_id, seller_id=seller_id,
        amount=amount, listing_id=listing_id,
        reference=ref, status="held",
        expires_at=date.today() + timedelta(days=hold_days),
    )
```

## Pattern: Expiry Check Task

```python
from celery import shared_task
from datetime import date

@shared_task(name="marketplace.expire_escrows")
def expire_stale_escrows() -> int:
    """Refund escrows that have exceeded hold period."""
    expired = EscrowHold.objects.filter(
        status="held", expires_at__lt=date.today()
    )
    count = 0
    for hold in expired:
        refund_escrow(hold.pk, reason="Escrow expired")
        count += 1
    return count
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Sending funds directly to seller | No buyer protection | Hold in escrow first |
| No expiry on escrow | Funds locked forever if seller ghosts | Auto-refund on expiry |
| Escrow without deducting buyer balance | Double-spending risk | Debit immediately |

## Red Flags

- Marketplace trade without escrow hold
- No expiry date on escrow records
- Missing Celery task for expired escrows

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
