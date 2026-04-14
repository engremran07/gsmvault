---
name: fin-promo-codes
description: "Promotional code system: generation, validation, limits. Use when: creating discount codes, coupon system, promo campaigns, credit grants."
---

# Promotional Code System

## When to Use

- Creating discount/coupon codes for marketing campaigns
- Generating bulk promo codes for events
- Building a code redemption flow

## Rules

1. **Unique codes** — cryptographically random, uppercase alphanumeric
2. **Types**: percentage_discount, fixed_discount, free_credits, tier_upgrade
3. **Expiry date** — all codes must have an expiration
4. **Usage tracking** — record who used which code and when
5. **Atomic redemption** — validate + apply + mark used in one transaction

## Pattern: Code Generation

```python
import secrets
import string

def generate_promo_code(prefix: str = "GSM", length: int = 8) -> str:
    """Generate a unique promo code like GSM-A3X9K2M1."""
    chars = string.ascii_uppercase + string.digits
    code = "".join(secrets.choice(chars) for _ in range(length))
    return f"{prefix}-{code}"


def bulk_generate_codes(
    campaign_name: str,
    count: int,
    **code_kwargs,
) -> list:
    """Generate multiple unique codes for a campaign."""
    from apps.shop.models import PromoCode
    codes = []
    for _ in range(count):
        code = generate_promo_code()
        while PromoCode.objects.filter(code=code).exists():
            code = generate_promo_code()
        codes.append(PromoCode(
            code=code, campaign=campaign_name, **code_kwargs
        ))
    return PromoCode.objects.bulk_create(codes)
```

## Pattern: Code Redemption

```python
from django.db import transaction
from decimal import Decimal

@transaction.atomic
def redeem_promo_code(user_id: int, code_str: str) -> dict:
    """Validate and apply a promo code."""
    from apps.shop.models import PromoCode, PromoCodeUsage
    code = PromoCode.objects.select_for_update().get(code=code_str.upper())

    # Validation (see fin-promo-validation skill)
    validate_promo_eligibility(user_id, code)

    # Apply benefit
    if code.code_type == "free_credits":
        from apps.wallet.models import Wallet
        wallet = Wallet.objects.select_for_update().get(user_id=user_id)
        wallet.balance += code.credit_amount
        wallet.save(update_fields=["balance", "updated_at"])

    # Track usage
    code.times_used += 1
    code.save(update_fields=["times_used", "updated_at"])
    PromoCodeUsage.objects.create(
        promo_code=code, user_id=user_id,
    )
    return {"code": code.code, "type": code.code_type, "applied": True}
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Sequential codes (PROMO001, PROMO002) | Guessable, abuse risk | Use `secrets.choice()` |
| No expiry on codes | Codes live forever | Always set `expires_at` |
| Redeem without `select_for_update()` | Race: same code used twice | Lock the code row |

## Red Flags

- Predictable code patterns
- Missing `PromoCodeUsage` tracking
- No expiry date on promo code model

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
