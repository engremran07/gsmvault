---
name: fin-ledger-double-entry
description: "Double-entry accounting pattern for transactions. Use when: recording financial events, ensuring system balance, creating ledger entries."
---

# Double-Entry Accounting

## When to Use

- Every financial operation that moves value
- Purchase, refund, transfer, reward, fee collection
- Ensuring the platform's books always balance

## Rules

1. **Every debit has a matching credit** — sum of all entries must be zero
2. **Both entries in same `@transaction.atomic`** — never partial
3. **Entries are immutable** — never update/delete; create reversals instead
4. **Store balance_after** on each entry for fast reconciliation
5. **Use account types**: user_wallet, platform_revenue, escrow, fees

## Pattern: Double-Entry Ledger

```python
from decimal import Decimal
from django.db import transaction
from apps.wallet.models import LedgerEntry
import uuid

@transaction.atomic
def record_purchase(
    buyer_wallet_id: int,
    seller_wallet_id: int,
    amount: Decimal,
    platform_fee: Decimal,
    order_id: int,
) -> str:
    """Record a purchase with fee split. Returns reference ID."""
    ref = str(uuid.uuid4())
    seller_amount = amount - platform_fee

    entries = [
        # Buyer pays
        LedgerEntry(account_id=buyer_wallet_id, amount=-amount,
                    entry_type="debit", reference=ref, description="Purchase"),
        # Seller receives (minus fee)
        LedgerEntry(account_id=seller_wallet_id, amount=seller_amount,
                    entry_type="credit", reference=ref, description="Sale proceeds"),
        # Platform collects fee
        LedgerEntry(account_id=0, amount=platform_fee,  # platform account
                    entry_type="credit", reference=ref, description="Platform fee"),
    ]
    LedgerEntry.objects.bulk_create(entries)
    # Invariant: -amount + seller_amount + platform_fee == 0
    return ref
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Updating balance field without ledger entry | No auditable trail | Always create entries |
| Deleting ledger entries | Destroys financial history | Create reversal entries |
| Entries that don't sum to zero | Books don't balance | Validate sum == 0 |
| Entries outside `@transaction.atomic` | Partial entries = broken state | Always atomic |

## Red Flags

- Any `LedgerEntry.objects.delete()` or `.update()` call
- Debit entries without matching credits
- Floating-point arithmetic on amounts
- Missing reference linking related entries

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/wallet/` — Wallet, Transaction, LedgerEntry models
- `.claude/rules/financial-safety.md` — double-entry requirements
