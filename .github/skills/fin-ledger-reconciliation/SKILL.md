---
name: fin-ledger-reconciliation
description: "Balance reconciliation and audit. Use when: verifying wallet balances match ledger, detecting discrepancies, running periodic balance checks."
---

# Ledger Reconciliation

## When to Use

- Periodic (daily/hourly) balance verification
- After bulk operations or migrations
- Investigating reported balance discrepancies
- Compliance audits

## Rules

1. **Computed balance** (sum of transactions) must equal **stored balance**
2. **All ledger entries** must sum to zero across the system
3. **Run as Celery task** — never block request/response
4. **Log discrepancies** with severity — never silently correct
5. **Never auto-fix** balances — flag for admin review

## Pattern: Reconciliation Service

```python
from decimal import Decimal
from django.db.models import Sum
from apps.wallet.models import Wallet, Transaction
import logging

logger = logging.getLogger(__name__)

def reconcile_wallet(wallet_id: int) -> dict:
    """Compare stored balance vs computed balance."""
    wallet = Wallet.objects.get(pk=wallet_id)
    computed = (
        Transaction.objects
        .filter(wallet_id=wallet_id)
        .aggregate(total=Sum("amount"))
    )["total"] or Decimal("0")

    discrepancy = wallet.balance - computed
    result = {
        "wallet_id": wallet_id,
        "stored_balance": wallet.balance,
        "computed_balance": computed,
        "discrepancy": discrepancy,
        "status": "ok" if discrepancy == Decimal("0") else "mismatch",
    }
    if discrepancy != Decimal("0"):
        logger.error(
            "Balance mismatch wallet=%d stored=%s computed=%s diff=%s",
            wallet_id, wallet.balance, computed, discrepancy,
        )
    return result


def reconcile_all_wallets() -> list[dict]:
    """Reconcile every wallet. Returns list of mismatches."""
    mismatches = []
    for wid in Wallet.objects.values_list("id", flat=True).iterator():
        result = reconcile_wallet(wid)
        if result["status"] == "mismatch":
            mismatches.append(result)
    return mismatches
```

## Pattern: Celery Task

```python
from celery import shared_task

@shared_task(name="wallet.reconcile_all")
def reconcile_all_task() -> int:
    mismatches = reconcile_all_wallets()
    if mismatches:
        # Notify admins — never auto-correct
        logger.critical("Found %d balance mismatches", len(mismatches))
    return len(mismatches)
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Auto-correcting mismatches | Masks bugs, destroys evidence | Flag for admin |
| Running reconciliation in request/response | Blocks user, times out | Use Celery task |
| Ignoring zero-amount discrepancies | Rounding errors accumulate | Log all discrepancies |

## Red Flags

- `wallet.balance = computed_balance` without admin approval
- Reconciliation that suppresses or ignores errors
- No alerting on mismatches

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
