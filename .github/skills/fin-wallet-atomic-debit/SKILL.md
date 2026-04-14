---
name: fin-wallet-atomic-debit
description: "Atomic wallet debit with select_for_update. Use when: deducting credits, charging for downloads, spending wallet balance, any balance reduction."
---

# Atomic Wallet Debit

## When to Use

- Deducting credits from a user wallet
- Charging for premium downloads, shop purchases, or marketplace fees
- Any operation that reduces a wallet balance

## Rules

1. **Always** use `select_for_update()` before reading the balance
2. **Always** wrap in `@transaction.atomic`
3. **Always** check sufficient balance before debit
4. **Always** create a transaction record in the same atomic block
5. **Always** use `Decimal` — never `float`

## Pattern: Safe Wallet Debit

```python
from decimal import Decimal
from django.db import transaction
from apps.wallet.models import Wallet, Transaction

@transaction.atomic
def debit_wallet(
    user_id: int,
    amount: Decimal,
    reason: str,
    related_object: str = "",
) -> Transaction:
    """Atomically debit a wallet. Raises ValueError if insufficient funds."""
    wallet = (
        Wallet.objects
        .select_for_update()
        .get(user_id=user_id)
    )
    if wallet.balance < amount:
        raise ValueError(
            f"Insufficient balance: {wallet.balance} < {amount}"
        )
    wallet.balance -= amount
    wallet.save(update_fields=["balance", "updated_at"])

    return Transaction.objects.create(
        wallet=wallet,
        amount=-amount,
        transaction_type="debit",
        reason=reason,
        related_object=related_object,
        balance_after=wallet.balance,
    )
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| `wallet = Wallet.objects.get(...)` without `select_for_update()` | Race condition: two requests read same balance | Add `.select_for_update()` |
| `if wallet.balance >= amount` outside `@transaction.atomic` | TOCTOU: balance can change between check and write | Move check inside atomic block |
| `wallet.balance = wallet.balance - float(amount)` | Float precision loss | Use `Decimal` exclusively |
| Debit without creating a `Transaction` record | No audit trail | Always create log entry |

## Red Flags

- Any wallet debit without `select_for_update()` in the same queryset
- Balance check separated from debit by non-atomic code
- `float()` cast on monetary values
- Missing `update_fields` on `save()` (risks overwriting concurrent changes)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/wallet/models.py` — Wallet, Transaction models
- `.claude/rules/financial-safety.md` — concurrency and precision rules
