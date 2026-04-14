---
name: fin-subscription-grace-period
description: "Grace period handling for expired subscriptions. Use when: subscription lapses, payment fails, managing access during grace window."
---

# Subscription Grace Period

## When to Use

- Subscription payment fails or expires
- Providing a window for renewal before feature revocation
- Handling lapsed subscribers who return to pay

## Rules

1. **Grace period length** configurable per tier (e.g., 3 days for Subscriber, 7 for Premium)
2. **During grace**: maintain current tier access with a "renewal needed" banner
3. **After grace expires**: downgrade to Registered (not Free — reward account creation)
4. **Celery task** checks daily for expired grace periods
5. **Re-activation** during grace: no data loss, no proration penalty

## Pattern: Grace Period Logic

```python
from datetime import date, timedelta
from django.db import transaction

GRACE_DAYS = {"subscriber": 3, "premium": 7}

def is_in_grace_period(subscription) -> bool:
    """Check if subscription is within grace period."""
    if subscription.status != "expired":
        return False
    grace = GRACE_DAYS.get(subscription.tier.slug, 3)
    grace_end = subscription.period_end + timedelta(days=grace)
    return date.today() <= grace_end


@transaction.atomic
def process_expired_subscriptions() -> int:
    """Downgrade subscriptions past their grace period."""
    from apps.devices.models import QuotaTier
    registered = QuotaTier.objects.get(slug="registered")
    count = 0

    expired = Subscription.objects.select_for_update().filter(
        status="expired",
    )
    for sub in expired:
        grace = GRACE_DAYS.get(sub.tier.slug, 3)
        grace_end = sub.period_end + timedelta(days=grace)
        if date.today() > grace_end:
            sub.tier = registered
            sub.status = "lapsed"
            sub.save(update_fields=["tier", "status", "updated_at"])
            count += 1
    return count
```

## Pattern: Access Check with Grace

```python
def user_has_tier_access(user, required_tier_level: int) -> bool:
    """Check tier access, allowing grace period."""
    sub = getattr(user, "subscription", None)
    if not sub:
        return required_tier_level <= 1  # Registered level
    if sub.status == "active":
        return sub.tier.level >= required_tier_level
    if is_in_grace_period(sub):
        return sub.tier.level >= required_tier_level
    return False
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Immediate downgrade on expiry | Users lose access during payment retry | Grace period |
| Downgrade to Free on lapse | Punishes account holders | Downgrade to Registered |
| No banner during grace period | User doesn't know to renew | Show renewal prompt |

## Red Flags

- No grace period between expiry and downgrade
- Grace period not configurable per tier
- Missing daily Celery task for grace period processing

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
