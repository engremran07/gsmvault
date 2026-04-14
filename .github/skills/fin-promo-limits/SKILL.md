---
name: fin-promo-limits
description: "Promo code limits: per-user, total uses, expiry. Use when: enforcing code usage caps, preventing abuse, configuring campaign limits."
---

# Promo Code Limits

## When to Use

- Configuring maximum uses per promo code
- Enforcing per-user usage limits (one per customer)
- Setting campaign start/end dates
- Preventing promo code abuse

## Rules

1. **Total usage cap** — `max_uses` field, enforce with `select_for_update()`
2. **Per-user limit** — default 1 use per user per code
3. **Date range** — `valid_from` and `valid_until` fields
4. **Minimum order** — optional `min_order_amount` threshold
5. **Tier restriction** — some codes only for specific subscription tiers

## Pattern: Limit Configuration

```python
from django.db import models
from decimal import Decimal

class PromoCode(models.Model):
    code = models.CharField(max_length=20, unique=True, db_index=True)
    code_type = models.CharField(max_length=30)
    # Limits
    max_uses = models.PositiveIntegerField(default=1)
    max_uses_per_user = models.PositiveIntegerField(default=1)
    times_used = models.PositiveIntegerField(default=0)
    # Date range
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    # Conditions
    min_order_amount = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0")
    )
    required_tier = models.CharField(max_length=20, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "shop_promocode"
```

## Pattern: Limit Checks

```python
from django.utils import timezone

def check_promo_limits(user_id: int, code) -> list[str]:
    """Return list of violation messages (empty = valid)."""
    errors = []
    now = timezone.now()

    if not code.is_active:
        errors.append("Code is inactive")
    if now < code.valid_from:
        errors.append("Code is not yet active")
    if now > code.valid_until:
        errors.append("Code has expired")
    if code.times_used >= code.max_uses:
        errors.append("Code has reached maximum uses")

    user_uses = PromoCodeUsage.objects.filter(
        promo_code=code, user_id=user_id
    ).count()
    if user_uses >= code.max_uses_per_user:
        errors.append("You have already used this code")

    return errors
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| `max_uses = 0` meaning unlimited | Ambiguous, invites abuse | Use `None` or explicit flag |
| Checking limits without row lock | Race condition on concurrent redemptions | `select_for_update()` |
| No per-user limit | One user redeems code 1000 times | Default `max_uses_per_user=1` |
| Missing date validation | Expired codes still work | Check `valid_from`/`valid_until` |

## Red Flags

- Unlimited usage with no per-user cap
- Limit check and redemption in separate transactions
- No tracking of individual redemptions in `PromoCodeUsage`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
