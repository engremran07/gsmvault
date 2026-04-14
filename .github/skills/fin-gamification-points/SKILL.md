---
name: fin-gamification-points
description: "Points system: earn, spend, balance tracking. Use when: awarding points for actions, spending points on rewards, tracking point balances."
---

# Gamification Points System

## When to Use

- Awarding points for user actions (downloads, reviews, forum posts)
- Spending points on rewards or premium features
- Displaying point balances and transaction history

## Rules

1. **Atomic operations** — `select_for_update()` on point balance for spend
2. **Earn events** are idempotent — same action shouldn't award twice
3. **Point types**: earned (spendable) vs bonus (display-only)
4. **Transaction log** for every earn/spend event
5. **Never negative** — validate before spending

## Pattern: Points Service

```python
from decimal import Decimal
from django.db import transaction
from apps.gamification.models import PointBalance, PointTransaction

POINTS_SCHEDULE = {
    "download": 5,
    "review": 10,
    "forum_post": 3,
    "forum_reply": 2,
    "referral_signup": 50,
    "daily_login": 1,
    "bounty_fulfilled": 100,
}

@transaction.atomic
def award_points(
    user_id: int,
    action: str,
    source_id: str = "",
) -> PointTransaction | None:
    """Award points for an action. Returns None if duplicate."""
    points = POINTS_SCHEDULE.get(action, 0)
    if points <= 0:
        return None

    # Idempotency check
    if source_id and PointTransaction.objects.filter(
        user_id=user_id, action=action, source_id=source_id,
    ).exists():
        return None

    balance = PointBalance.objects.select_for_update().get(user_id=user_id)
    balance.total_points += points
    balance.save(update_fields=["total_points", "updated_at"])

    return PointTransaction.objects.create(
        user_id=user_id, points=points, action=action,
        source_id=source_id, transaction_type="earn",
        balance_after=balance.total_points,
    )


@transaction.atomic
def spend_points(
    user_id: int,
    points: int,
    reason: str,
) -> PointTransaction:
    """Spend points on a reward. Raises ValueError if insufficient."""
    balance = PointBalance.objects.select_for_update().get(user_id=user_id)
    if balance.total_points < points:
        raise ValueError(f"Insufficient points: {balance.total_points} < {points}")

    balance.total_points -= points
    balance.save(update_fields=["total_points", "updated_at"])

    return PointTransaction.objects.create(
        user_id=user_id, points=-points,
        action="spend", transaction_type="spend",
        reason=reason, balance_after=balance.total_points,
    )
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| No idempotency check on earn | Same post awards points repeatedly | Check `source_id` uniqueness |
| Points as float | Precision issues, fractional points | Integer points |
| Spend without `select_for_update()` | Race condition, negative balance | Lock balance row |
| No transaction log | Can't audit point history | Always create `PointTransaction` |

## Red Flags

- Double-awarding for the same action
- Spend operations without balance lock
- Missing point transaction history

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/gamification/models.py` — PointBalance, PointTransaction
