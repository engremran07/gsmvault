---
name: fin-affiliate-commission-calculation
description: "Commission calculation: tiers, rates, attribution. Use when: calculating affiliate earnings, applying tiered commission rates, attributing revenue to affiliates."
---

# Affiliate Commission Calculation

## When to Use

- Calculating commission on a converted sale
- Applying tiered commission rates based on affiliate performance
- Determining which affiliate gets credit for a multi-touch conversion

## Rules

1. **Tiered rates** — higher performers earn higher percentages
2. **Use `Decimal`** for all rate and amount calculations
3. **Attribution**: last-click wins within 30-day window
4. **Commission on net amount** — after discounts, before platform fees
5. **Record calculation details** for audit trail

## Pattern: Tiered Commission Rates

```python
from decimal import Decimal

COMMISSION_TIERS = [
    {"min_sales": 0, "rate": Decimal("0.05")},     # 5% for 0-9 sales
    {"min_sales": 10, "rate": Decimal("0.08")},     # 8% for 10-49
    {"min_sales": 50, "rate": Decimal("0.10")},     # 10% for 50-99
    {"min_sales": 100, "rate": Decimal("0.12")},    # 12% for 100+
]

def get_commission_rate(affiliate_user_id: int) -> Decimal:
    """Get commission rate based on affiliate's total conversions."""
    total_sales = AffiliateClick.objects.filter(
        affiliate_link__user_id=affiliate_user_id,
        conversion_order_id__isnull=False,
        status="approved",
    ).count()
    rate = COMMISSION_TIERS[0]["rate"]
    for tier in COMMISSION_TIERS:
        if total_sales >= tier["min_sales"]:
            rate = tier["rate"]
    return rate
```

## Pattern: Commission Calculation

```python
from decimal import Decimal
from django.db import transaction

@transaction.atomic
def calculate_commission(
    click_id: int,
    order_total: Decimal,
    discount_amount: Decimal = Decimal("0"),
) -> dict:
    """Calculate and record commission for a conversion."""
    click = AffiliateClick.objects.select_for_update().get(pk=click_id)
    affiliate_user_id = click.affiliate_link.user_id

    net_amount = order_total - discount_amount
    rate = get_commission_rate(affiliate_user_id)
    commission = (net_amount * rate).quantize(Decimal("0.01"))

    # Record commission
    from apps.ads.models import AffiliateCommission
    AffiliateCommission.objects.create(
        affiliate_click=click,
        affiliate_user_id=affiliate_user_id,
        order_total=order_total,
        net_amount=net_amount,
        commission_rate=rate,
        commission_amount=commission,
        status="pending",
    )
    return {
        "commission": commission,
        "rate": rate,
        "net_amount": net_amount,
    }
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| `float(rate) * float(amount)` | Precision loss | Use `Decimal` throughout |
| Commission on gross before discounts | Inflates commission | Calculate on net amount |
| Flat rate for all affiliates | No incentive to perform | Tiered rates |
| No commission record | Can't audit calculations | Create `AffiliateCommission` |

## Red Flags

- Float arithmetic on commission amounts
- Missing commission audit records
- No tiered rate structure
- Commission calculated on gross instead of net

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
