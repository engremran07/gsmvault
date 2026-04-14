---
name: fin-subscription-downgrade
description: "Tier downgrade: grace period, feature revocation. Use when: user downgrades subscription, handling feature access reduction, scheduling end-of-cycle changes."
---

# Subscription Downgrade

## When to Use

- User requests a lower tier (Premium → Subscriber, Subscriber → Registered)
- Handling feature access changes after downgrade
- Scheduling downgrade to take effect at end of billing period

## Rules

1. **Downgrade at end of period** — user keeps current features until billing cycle ends
2. **Schedule downgrade** — record `pending_tier` and apply on renewal date
3. **Revoke features** only when downgrade activates — not immediately
4. **Allow cancellation** of pending downgrade before it takes effect
5. **Notify user** with clear date when downgrade will activate

## Pattern: Scheduled Downgrade

```python
from django.db import transaction
from apps.devices.models import QuotaTier

@transaction.atomic
def schedule_downgrade(user_id: int, new_tier_slug: str) -> dict:
    """Schedule downgrade for end of current billing period."""
    subscription = Subscription.objects.select_for_update().get(user_id=user_id)
    new_tier = QuotaTier.objects.get(slug=new_tier_slug)

    if new_tier.level >= subscription.tier.level:
        raise ValueError("Downgrade must be to a lower tier")

    subscription.pending_tier = new_tier
    subscription.pending_change_date = subscription.period_end
    subscription.save(update_fields=["pending_tier", "pending_change_date",
                                     "updated_at"])
    return {
        "current_tier": subscription.tier.slug,
        "pending_tier": new_tier.slug,
        "effective_date": subscription.period_end,
    }


@transaction.atomic
def apply_pending_downgrade(subscription_id: int) -> bool:
    """Apply scheduled downgrade. Called by Celery on period_end."""
    sub = Subscription.objects.select_for_update().get(pk=subscription_id)
    if not sub.pending_tier:
        return False
    sub.tier = sub.pending_tier
    sub.pending_tier = None
    sub.pending_change_date = None
    sub.save(update_fields=["tier", "pending_tier",
                            "pending_change_date", "updated_at"])
    return True


@transaction.atomic
def cancel_pending_downgrade(user_id: int) -> bool:
    """Cancel a scheduled downgrade before it takes effect."""
    sub = Subscription.objects.select_for_update().get(user_id=user_id)
    if not sub.pending_tier:
        return False
    sub.pending_tier = None
    sub.pending_change_date = None
    sub.save(update_fields=["pending_tier", "pending_change_date", "updated_at"])
    return True
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Immediate feature revocation on downgrade | User paid for current period | Apply at period end |
| No way to cancel pending downgrade | Bad UX | Allow cancellation |
| Revoking downloads already in progress | Data loss | Only restrict new actions |

## Red Flags

- Downgrade applied immediately without scheduling
- No `pending_tier` field on subscription model
- Missing Celery task to process pending downgrades

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
