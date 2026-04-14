---
name: fin-subscription-upgrade
description: "Tier upgrade logic: proration, immediate activation. Use when: user upgrades subscription, switching from lower to higher tier, calculating prorated charges."
---

# Subscription Upgrade

## When to Use

- User clicks "Upgrade" from Registered → Subscriber or Subscriber → Premium
- Calculating prorated cost for mid-cycle upgrades
- Immediately granting higher-tier features after payment

## Rules

1. **Immediate activation** — new tier features available instantly after payment
2. **Prorate charges** — charge only for remaining days in current billing cycle
3. **Atomic** — payment + tier change in single `@transaction.atomic`
4. **Log the upgrade** with old tier, new tier, prorated amount, timestamp
5. **Notify user** after successful upgrade (email + in-app)

## Pattern: Prorated Upgrade

```python
from decimal import Decimal
from datetime import date
from django.db import transaction

@transaction.atomic
def upgrade_subscription(
    user_id: int,
    new_tier_slug: str,
) -> dict:
    """Upgrade user to a higher tier with proration."""
    from apps.devices.models import QuotaTier
    from apps.wallet.models import Wallet

    subscription = Subscription.objects.select_for_update().get(user_id=user_id)
    old_tier = subscription.tier
    new_tier = QuotaTier.objects.get(slug=new_tier_slug)

    if new_tier.level <= old_tier.level:
        raise ValueError("New tier must be higher than current tier")

    # Calculate proration
    remaining_days = (subscription.period_end - date.today()).days
    total_days = (subscription.period_end - subscription.period_start).days
    if total_days > 0:
        credit = old_tier.price * Decimal(remaining_days) / Decimal(total_days)
        charge = new_tier.price * Decimal(remaining_days) / Decimal(total_days)
        prorated = (charge - credit).quantize(Decimal("0.01"))
    else:
        prorated = new_tier.price

    # Charge wallet
    wallet = Wallet.objects.select_for_update().get(user_id=user_id)
    if wallet.balance < prorated:
        raise ValueError("Insufficient balance for upgrade")
    wallet.balance -= prorated
    wallet.save(update_fields=["balance", "updated_at"])

    # Activate new tier immediately
    subscription.tier = new_tier
    subscription.save(update_fields=["tier", "updated_at"])

    return {"old_tier": old_tier.slug, "new_tier": new_tier.slug,
            "prorated_charge": prorated}
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Upgrade takes effect next billing cycle | Poor UX, user paid for nothing | Immediate activation |
| Charging full price without proration | Overcharging the user | Calculate remaining days |
| Upgrade without locking subscription row | Race condition on concurrent upgrades | `select_for_update()` |

## Red Flags

- Tier change outside `@transaction.atomic`
- No proration calculation for mid-cycle upgrades
- Missing audit log of old→new tier transition

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
