---
name: fin-subscription-tiers
description: "Subscription tier management: Free/Registered/Subscriber/Premium. Use when: defining tiers, checking tier features, configuring tier limits."
---

# Subscription Tier Management

## When to Use

- Defining download limits, feature access, and ad-gating per tier
- Checking user tier to gate functionality
- Displaying tier-specific UI elements

## Rules

1. **Tier hierarchy**: Free < Registered < Subscriber < Premium
2. **Tier config in database** via `QuotaTier` model — not hardcoded
3. **Check tier in service layer** — never in templates
4. **Cache tier lookups** — tiers change rarely
5. **Default to most restrictive** tier if lookup fails

## Pattern: Tier Hierarchy

```python
from enum import IntEnum

class TierLevel(IntEnum):
    FREE = 0
    REGISTERED = 1
    SUBSCRIBER = 2
    PREMIUM = 3

TIER_FEATURES = {
    TierLevel.FREE: {"daily_downloads": 2, "ad_gated": True, "captcha": True},
    TierLevel.REGISTERED: {"daily_downloads": 5, "ad_gated": True, "captcha": True},
    TierLevel.SUBSCRIBER: {"daily_downloads": 50, "ad_gated": False, "captcha": False},
    TierLevel.PREMIUM: {"daily_downloads": -1, "ad_gated": False, "captcha": False},
}
```

## Pattern: Tier Check Service

```python
from apps.devices.models import QuotaTier

def get_user_tier(user) -> QuotaTier:
    """Get user's current subscription tier."""
    if not user.is_authenticated:
        return QuotaTier.objects.get(slug="free")
    subscription = getattr(user, "subscription", None)
    if subscription and subscription.is_active:
        return subscription.tier
    return QuotaTier.objects.get(slug="registered")


def user_can_access(user, feature: str) -> bool:
    """Check if user's tier grants access to a feature."""
    tier = get_user_tier(user)
    return getattr(tier, f"can_{feature}", False)
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| `if user.tier == "premium"` in templates | Logic in template layer | Use service + context processor |
| Hardcoded tier limits in views | Can't change without deploy | Use `QuotaTier` database model |
| No default tier for anonymous users | Crash on unauthenticated request | Default to "free" |

## Red Flags

- Tier logic scattered across views instead of centralized service
- Hardcoded strings for tier names without constants
- Missing fallback for unknown/expired tiers

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/devices/models.py` — QuotaTier model
- `apps/firmwares/download_service.py` — download gating per tier
