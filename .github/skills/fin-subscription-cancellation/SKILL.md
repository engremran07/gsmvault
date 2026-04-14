---
name: fin-subscription-cancellation
description: "Cancellation flow: confirmation, data retention. Use when: user cancels subscription, handling cancellation confirmation, retaining user data post-cancel."
---

# Subscription Cancellation

## When to Use

- User requests subscription cancellation
- Building the cancellation confirmation UI
- Handling data retention after cancellation

## Rules

1. **Cancel at end of period** — user keeps access until billing cycle ends
2. **Require confirmation** — show what they'll lose, offer alternatives
3. **Retain data** — downloads, history, wallet balance stay intact
4. **Record reason** — optional survey for churn analysis
5. **Allow re-subscription** — easy path back without data loss

## Pattern: Cancellation Service

```python
from django.db import transaction
from datetime import date

@transaction.atomic
def request_cancellation(
    user_id: int,
    reason: str = "",
) -> dict:
    """Schedule cancellation for end of billing period."""
    sub = Subscription.objects.select_for_update().get(user_id=user_id)
    if sub.status != "active":
        raise ValueError("Only active subscriptions can be cancelled")

    sub.cancel_requested = True
    sub.cancel_reason = reason
    sub.cancel_requested_at = date.today()
    sub.save(update_fields=["cancel_requested", "cancel_reason",
                            "cancel_requested_at", "updated_at"])
    return {
        "access_until": sub.period_end,
        "tier": sub.tier.slug,
        "status": "cancellation_scheduled",
    }


@transaction.atomic
def process_cancellation(subscription_id: int) -> None:
    """Apply cancellation at period end. Called by Celery."""
    sub = Subscription.objects.select_for_update().get(pk=subscription_id)
    if not sub.cancel_requested:
        return
    from apps.devices.models import QuotaTier
    sub.tier = QuotaTier.objects.get(slug="registered")
    sub.status = "cancelled"
    sub.cancel_requested = False
    sub.save(update_fields=["tier", "status", "cancel_requested", "updated_at"])


@transaction.atomic
def revoke_cancellation(user_id: int) -> bool:
    """Allow user to change their mind before period ends."""
    sub = Subscription.objects.select_for_update().get(user_id=user_id)
    if not sub.cancel_requested:
        return False
    sub.cancel_requested = False
    sub.cancel_reason = ""
    sub.save(update_fields=["cancel_requested", "cancel_reason", "updated_at"])
    return True
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Immediate cancellation | User loses paid access | Cancel at period end |
| Deleting user data on cancel | Destroys history, violates retention | Soft downgrade only |
| No confirmation step | Accidental cancellations | Require explicit confirm |
| No way to revoke cancellation | Bad UX | Allow undo before period end |

## Red Flags

- `User.objects.filter(...).delete()` on cancellation
- No `cancel_requested` flag (immediate cancellation)
- Missing churn reason collection
- Wallet balance zeroed on cancellation

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
