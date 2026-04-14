---
name: fin-escrow-release
description: "Escrow release on confirmation. Use when: buyer confirms delivery, releasing held funds to seller, completing marketplace transactions."
---

# Escrow Release

## When to Use

- Buyer confirms receipt of goods/service
- Releasing escrowed funds to seller wallet
- Completing a marketplace trade successfully

## Rules

1. **Only buyer or admin** can release escrow
2. **Atomic** — escrow status + seller credit in single transaction
3. **Platform fee** deducted at release time (not at hold time)
4. **Seller receives** amount minus platform fee
5. **Create transaction** records for both seller credit and fee collection

## Pattern: Escrow Release Service

```python
from decimal import Decimal
from django.db import transaction
from apps.wallet.models import Wallet, Transaction
from apps.marketplace.models import EscrowHold

@transaction.atomic
def release_escrow(
    escrow_id: int,
    released_by_id: int,
    platform_fee_rate: Decimal = Decimal("0.05"),
) -> dict:
    """Release escrowed funds to seller minus platform fee."""
    hold = EscrowHold.objects.select_for_update().get(pk=escrow_id)

    if hold.status != "held":
        raise ValueError(f"Escrow is '{hold.status}', cannot release")

    platform_fee = (hold.amount * platform_fee_rate).quantize(Decimal("0.01"))
    seller_amount = hold.amount - platform_fee

    # Credit seller
    seller_wallet = Wallet.objects.select_for_update().get(user_id=hold.seller_id)
    seller_wallet.balance += seller_amount
    seller_wallet.save(update_fields=["balance", "updated_at"])

    Transaction.objects.create(
        wallet=seller_wallet, amount=seller_amount,
        transaction_type="escrow_release",
        reason=f"Sale proceeds for listing #{hold.listing_id}",
        reference=hold.reference,
        balance_after=seller_wallet.balance,
    )

    # Update escrow status
    hold.status = "released"
    hold.released_by_id = released_by_id
    hold.platform_fee = platform_fee
    hold.save(update_fields=["status", "released_by_id",
                              "platform_fee", "updated_at"])

    return {
        "seller_received": seller_amount,
        "platform_fee": platform_fee,
        "reference": hold.reference,
    }
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Releasing without checking status | Double-release risk | Check `status == "held"` |
| Fee deduction after release | Complex, error-prone | Deduct at release time |
| No `released_by` tracking | No accountability | Record who released |

## Red Flags

- Escrow release without `select_for_update()` on both escrow and wallet
- Missing platform fee deduction at release
- No audit trail of who triggered release

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
