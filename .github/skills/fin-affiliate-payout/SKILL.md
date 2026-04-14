---
name: fin-affiliate-payout
description: "Affiliate payout processing: thresholds, wallet credit. Use when: paying out earned commissions, enforcing minimum payout thresholds, batch payout processing."
---

# Affiliate Payout

## When to Use

- Affiliate reaches minimum payout threshold
- Processing batch payouts (weekly/monthly)
- Crediting earned commissions to affiliate wallets

## Rules

1. **Minimum threshold** — don't pay out until minimum reached (e.g., $10)
2. **Only pay approved commissions** — exclude pending/rejected
3. **Atomic** — mark commissions as paid + credit wallet in one transaction
4. **Batch processing** via Celery task — not real-time per conversion
5. **Payout record** with reference linking all included commissions

## Pattern: Payout Service

```python
from decimal import Decimal
from django.db import transaction
from django.db.models import Sum
import uuid

MINIMUM_PAYOUT = Decimal("10.00")

@transaction.atomic
def process_affiliate_payout(affiliate_user_id: int) -> dict | None:
    """Pay out pending commissions if threshold met."""
    from apps.ads.models import AffiliateCommission, AffiliatePayout
    from apps.wallet.models import Wallet, Transaction

    commissions = (
        AffiliateCommission.objects
        .select_for_update()
        .filter(affiliate_user_id=affiliate_user_id, status="pending")
    )
    total = commissions.aggregate(
        total=Sum("commission_amount")
    )["total"] or Decimal("0")

    if total < MINIMUM_PAYOUT:
        return None  # Below threshold

    # Credit wallet
    wallet = Wallet.objects.select_for_update().get(user_id=affiliate_user_id)
    wallet.balance += total
    wallet.save(update_fields=["balance", "updated_at"])

    ref = str(uuid.uuid4())
    Transaction.objects.create(
        wallet=wallet, amount=total,
        transaction_type="affiliate_payout",
        reason=f"Affiliate payout: {commissions.count()} commissions",
        reference=ref, balance_after=wallet.balance,
    )

    # Mark commissions as paid
    commissions.update(status="paid", payout_reference=ref)

    AffiliatePayout.objects.create(
        affiliate_user_id=affiliate_user_id,
        amount=total, reference=ref,
        commission_count=commissions.count(),
    )
    return {"amount": total, "reference": ref}
```

## Pattern: Batch Payout Task

```python
from celery import shared_task

@shared_task(name="ads.process_affiliate_payouts")
def batch_affiliate_payouts() -> dict:
    """Process payouts for all eligible affiliates."""
    from apps.ads.models import AffiliateCommission
    from django.db.models import Sum

    eligible = (
        AffiliateCommission.objects
        .filter(status="pending")
        .values("affiliate_user_id")
        .annotate(total=Sum("commission_amount"))
        .filter(total__gte=MINIMUM_PAYOUT)
    )
    results = {"processed": 0, "total_paid": Decimal("0")}
    for entry in eligible:
        result = process_affiliate_payout(entry["affiliate_user_id"])
        if result:
            results["processed"] += 1
            results["total_paid"] += result["amount"]
    return results
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Paying per conversion in real-time | Excessive transactions, overhead | Batch processing |
| No minimum threshold | Micro-payments clog the system | Enforce minimum |
| Paying unapproved commissions | Self-referral abuse gets paid | Filter `status="pending"` |
| No payout record | Can't audit what was paid | Create `AffiliatePayout` |

## Red Flags

- Missing minimum payout threshold
- Commission status not updated to "paid" after payout
- Payout outside `@transaction.atomic`
- No batch Celery task for periodic processing

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
