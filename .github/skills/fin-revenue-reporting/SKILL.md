---
name: fin-revenue-reporting
description: "Revenue reporting: daily/monthly aggregation, dashboards. Use when: building financial dashboards, aggregating revenue data, generating financial reports."
---

# Revenue Reporting

## When to Use

- Building admin financial dashboards
- Aggregating daily/monthly revenue metrics
- Generating financial reports for stakeholders
- Tracking revenue by source (subscriptions, marketplace, ads)

## Rules

1. **Pre-aggregate** via Celery tasks — never compute on dashboard load
2. **Revenue sources**: subscriptions, marketplace_fees, ad_revenue, bounty_fees, shop_sales
3. **Store snapshots** — aggregated data as materialized records
4. **UTC timestamps** — all financial aggregation in UTC
5. **Immutable snapshots** — regenerate, never update

## Pattern: Daily Revenue Aggregation

```python
from decimal import Decimal
from django.db.models import Sum, Count
from django.utils import timezone
from datetime import date, timedelta
from django.db import transaction

@transaction.atomic
def aggregate_daily_revenue(target_date: date) -> dict:
    """Aggregate revenue for a specific date. Idempotent."""
    from apps.analytics.models import DailyRevenue
    from apps.wallet.models import Transaction

    # Delete existing snapshot (idempotent regeneration)
    DailyRevenue.objects.filter(date=target_date).delete()

    start = timezone.datetime.combine(target_date, timezone.datetime.min.time())
    end = start + timedelta(days=1)

    sources = {
        "subscription": Transaction.objects.filter(
            transaction_type="subscription_payment",
            created_at__gte=start, created_at__lt=end,
        ).aggregate(total=Sum("amount"))["total"] or Decimal("0"),

        "marketplace_fees": Transaction.objects.filter(
            transaction_type="platform_fee",
            created_at__gte=start, created_at__lt=end,
        ).aggregate(total=Sum("amount"))["total"] or Decimal("0"),

        "shop_sales": Transaction.objects.filter(
            transaction_type="shop_purchase",
            created_at__gte=start, created_at__lt=end,
        ).aggregate(total=Sum("amount"))["total"] or Decimal("0"),
    }
    total = sum(sources.values())

    DailyRevenue.objects.create(
        date=target_date, total=total, **sources,
    )
    return {"date": str(target_date), "total": total, **sources}
```

## Pattern: Dashboard Data Service

```python
from django.core.cache import cache

def get_revenue_dashboard(days: int = 30) -> dict:
    """Get dashboard data. Cached for 15 minutes."""
    cache_key = f"revenue_dashboard:{days}"
    cached = cache.get(cache_key)
    if cached:
        return cached

    from apps.analytics.models import DailyRevenue
    end = date.today()
    start = end - timedelta(days=days)

    records = DailyRevenue.objects.filter(
        date__gte=start, date__lte=end,
    ).order_by("date")

    data = {
        "period_total": sum(r.total for r in records),
        "daily_average": (
            sum(r.total for r in records) / max(len(records), 1)
        ).quantize(Decimal("0.01")),
        "by_date": [
            {"date": str(r.date), "total": r.total}
            for r in records
        ],
        "by_source": {
            "subscriptions": sum(r.subscription for r in records),
            "marketplace": sum(r.marketplace_fees for r in records),
            "shop": sum(r.shop_sales for r in records),
        },
    }
    cache.set(cache_key, data, 900)
    return data
```

## Pattern: Celery Aggregation Task

```python
from celery import shared_task

@shared_task(name="analytics.aggregate_yesterday_revenue")
def aggregate_yesterday_revenue() -> dict:
    """Run daily at 00:15 UTC for yesterday's data."""
    yesterday = date.today() - timedelta(days=1)
    return aggregate_daily_revenue(yesterday)
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Computing revenue on dashboard load | Slow, DB-heavy | Pre-aggregate via Celery |
| Mutable revenue records | Can't audit changes | Immutable snapshots |
| Revenue in local timezone | Inconsistent across regions | Always UTC |
| No caching on dashboard | Repeated expensive queries | Cache 15 min |

## Red Flags

- Revenue queries running on every admin page view
- Missing daily aggregation Celery task
- Revenue calculations mixing timezones
- No breakdown by revenue source

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
