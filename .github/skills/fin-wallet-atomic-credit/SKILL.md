---
name: fin-wallet-atomic-credit
description: "Atomic wallet credit operations. Use when: adding credits, processing refunds to wallet, reward payouts, any balance increase."
---

# Atomic Wallet Credit

## When to Use

- Adding credits to a user wallet (purchase, reward, refund)
- Processing referral rewards, bounty payouts, or ad-watch credits
- Any operation that increases a wallet balance

## Rules

1. **Always** use `select_for_update()` even for credits — prevents lost updates
2. **Always** wrap in `@transaction.atomic`
3. **Always** create a transaction record with reason and source
4. **Always** use `Decimal` — never `float`
5. **Never** credit without validating the source (prevent fabricated credits)

## Pattern: Safe Wallet Credit

```python
from decimal import Decimal
from django.db import transaction
from apps.wallet.models import Wallet, Transaction

@transaction.atomic
def credit_wallet(
    user_id: int,
    amount: Decimal,
    reason: str,
    source_type: str = "",
    source_id: str = "",
) -> Transaction:
    """Atomically credit a wallet."""
    if amount <= Decimal("0"):
        raise ValueError("Credit amount must be positive")

    wallet = (
        Wallet.objects
        .select_for_update()
        .get(user_id=user_id)
    )
    wallet.balance += amount
    wallet.save(update_fields=["balance", "updated_at"])

    return Transaction.objects.create(
        wallet=wallet,
        amount=amount,
        transaction_type="credit",
        reason=reason,
        source_type=source_type,
        source_id=source_id,
        balance_after=wallet.balance,
    )
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Credit without `select_for_update()` | Two concurrent credits can overwrite each other | Always lock row |
| `amount = Decimal(10.5)` | Float constructor loses precision | Use `Decimal("10.50")` |
| Credit without transaction record | No audit trail for where money came from | Always log |
| Accepting negative amounts in credit function | Could be used to drain wallet | Validate `amount > 0` |

## Red Flags

- Credit operations outside `@transaction.atomic`
- Missing source tracking (who authorized this credit?)
- No validation on amount positivity
- Direct `F()` expression updates without transaction log

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/wallet/models.py` — Wallet, Transaction models
- `.claude/rules/financial-safety.md` — concurrency and precision rules
