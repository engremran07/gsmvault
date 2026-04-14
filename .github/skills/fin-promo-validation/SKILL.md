---
name: fin-promo-validation
description: "Promo code validation: eligibility, stacking rules. Use when: validating promo code at checkout, checking user eligibility, enforcing code stacking policy."
---

# Promo Code Validation

## When to Use

- User enters a promo code at checkout
- Validating code eligibility before applying discount
- Enforcing no-stacking policy (one code per order)

## Rules

1. **Validate all conditions** before applying — never partial apply
2. **No stacking** — one promo code per order unless explicitly allowed
3. **Tier eligibility** — some codes restricted to certain tiers
4. **New user codes** — validate account age if "new user only"
5. **Return clear errors** — tell user exactly why code is invalid

## Pattern: Comprehensive Validation

```python
from decimal import Decimal
from django.utils import timezone

def validate_promo_eligibility(
    user_id: int,
    code,
    order_total: Decimal = Decimal("0"),
) -> None:
    """Validate promo code. Raises ValueError with reason on failure."""
    now = timezone.now()

    # Active check
    if not code.is_active:
        raise ValueError("This promo code is no longer active")

    # Date range
    if now < code.valid_from:
        raise ValueError("This promo code is not yet active")
    if now > code.valid_until:
        raise ValueError("This promo code has expired")

    # Usage limits
    if code.times_used >= code.max_uses:
        raise ValueError("This promo code has been fully redeemed")

    # Per-user limit
    from apps.shop.models import PromoCodeUsage
    user_uses = PromoCodeUsage.objects.filter(
        promo_code=code, user_id=user_id,
    ).count()
    if user_uses >= code.max_uses_per_user:
        raise ValueError("You have already used this promo code")

    # Minimum order
    if order_total < code.min_order_amount:
        raise ValueError(
            f"Minimum order of {code.min_order_amount} required"
        )

    # Tier restriction
    if code.required_tier:
        from apps.devices.models import QuotaTier
        user_tier = get_user_tier_slug(user_id)
        if user_tier != code.required_tier:
            raise ValueError(
                f"This code is for {code.required_tier} tier members only"
            )

    # New user restriction
    if code.new_users_only:
        from apps.users.models import User
        user = User.objects.get(pk=user_id)
        if (now - user.date_joined).days > 30:
            raise ValueError("This code is for new users only")
```

## Pattern: No-Stacking Check

```python
def validate_no_stacking(order_id: int, new_code_id: int) -> None:
    """Ensure only one promo code per order."""
    from apps.shop.models import OrderPromo
    existing = OrderPromo.objects.filter(order_id=order_id).exists()
    if existing:
        raise ValueError(
            "Only one promo code can be applied per order. "
            "Remove the existing code first."
        )
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Applying code before full validation | Partial application on later failure | Validate all first |
| Generic "invalid code" error | User can't fix the issue | Specific error messages |
| Allowing multiple codes per order | Unintended discount stacking | Enforce no-stacking |
| Skipping tier check | Wrong users get exclusive discounts | Validate tier |

## Red Flags

- Validation split across multiple layers (view + service + model)
- Generic error messages without specifics
- Missing `new_users_only` check on acquisition codes

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
