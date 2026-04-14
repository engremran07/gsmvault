---
name: fin-marketplace-fees
description: "Marketplace fee calculation: platform cut, seller payout. Use when: determining platform commission on P2P sales, calculating seller net proceeds."
---

# Marketplace Fee Calculation

## When to Use

- Calculating platform commission on marketplace trades
- Determining seller's net payout after fees
- Implementing tiered fee structures based on seller level

## Rules

1. **Use `Decimal`** for all fee calculations
2. **Fee deducted at escrow release** — not at listing time
3. **Transparent** — show buyer the total and seller the net before trade
4. **Tiered fees** — power sellers get lower rates
5. **Minimum fee** — floor to prevent zero-fee micro-transactions

## Pattern: Fee Calculation

```python
from decimal import Decimal

SELLER_FEE_TIERS = [
    {"min_sales": 0, "rate": Decimal("0.10")},    # 10% for new sellers
    {"min_sales": 10, "rate": Decimal("0.08")},    # 8% for 10+ sales
    {"min_sales": 50, "rate": Decimal("0.05")},    # 5% for 50+ sales
    {"min_sales": 200, "rate": Decimal("0.03")},   # 3% for power sellers
]

MINIMUM_FEE = Decimal("0.50")


def calculate_marketplace_fee(
    seller_id: int,
    sale_amount: Decimal,
) -> dict:
    """Calculate platform fee and seller net payout."""
    total_sales = get_seller_total_sales(seller_id)
    rate = SELLER_FEE_TIERS[0]["rate"]
    for tier in SELLER_FEE_TIERS:
        if total_sales >= tier["min_sales"]:
            rate = tier["rate"]

    fee = max(
        (sale_amount * rate).quantize(Decimal("0.01")),
        MINIMUM_FEE,
    )
    seller_net = sale_amount - fee

    return {
        "sale_amount": sale_amount,
        "fee_rate": rate,
        "platform_fee": fee,
        "seller_net": seller_net,
    }


def get_seller_total_sales(seller_id: int) -> int:
    """Count completed sales for tier calculation."""
    from apps.marketplace.models import Trade
    return Trade.objects.filter(
        seller_id=seller_id, status="completed",
    ).count()
```

## Pattern: Fee Preview (Pre-Trade)

```python
def preview_trade(seller_id: int, price: Decimal) -> dict:
    """Show both parties what they'll pay/receive."""
    fees = calculate_marketplace_fee(seller_id, price)
    return {
        "buyer_pays": price,
        "platform_fee": fees["platform_fee"],
        "seller_receives": fees["seller_net"],
        "fee_percentage": f"{fees['fee_rate'] * 100}%",
    }
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| `float(price) * 0.1` | Precision loss | `Decimal` arithmetic |
| No minimum fee | Zero-fee exploit on tiny amounts | Enforce `MINIMUM_FEE` |
| Hidden fees at checkout | Bad UX, trust issue | Show fee preview |
| Fixed rate for all sellers | No incentive for power sellers | Tiered rates |

## Red Flags

- Fee calculation using float
- No minimum fee floor
- Fee not shown to seller before listing
- Fee deducted from buyer instead of seller proceeds

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
