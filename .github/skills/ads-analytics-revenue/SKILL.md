---
name: ads-analytics-revenue
description: "Revenue tracking: eCPM, fill rate, ARPU. Use when: calculating ad revenue metrics, building revenue dashboards, comparing network performance."
---

# Revenue Tracking

## When to Use
- Calculating eCPM (effective cost per mille) per network/placement
- Tracking fill rate (impressions served / impressions requested)
- Computing ARPU (average revenue per user)
- Comparing network performance for waterfall optimization

## Rules
- Revenue data derived from `AdEvent` aggregation — use `aggregate_events` task
- eCPM = (total_revenue / impressions) × 1000
- Fill rate = filled_impressions / total_requests × 100
- `AdUnit.estimated_cpm` and `AdUnit.fill_rate` are historical averages
- Revenue attributed per `AdNetwork` via `AdUnit → AdNetwork` FK chain
- `AdNetwork.revenue_share_percent` = platform's cut after network takes theirs

## Patterns

### Revenue Calculation Service
```python
# apps/ads/services/analytics.py
from decimal import Decimal
from django.db.models import Count, Sum, F
from apps.ads.models import AdEvent

def calculate_ecpm(*, network_id: int, days: int = 30) -> Decimal:
    """Calculate eCPM for a network over the given period."""
    cutoff = timezone.now() - timedelta(days=days)
    stats = AdEvent.objects.filter(
        ad_unit__network_id=network_id,
        event_type="impression",
        created_at__gte=cutoff,
    ).aggregate(
        total_impressions=Count("id"),
        total_revenue=Sum("revenue"),
    )
    impressions = stats["total_impressions"] or 0
    revenue = stats["total_revenue"] or Decimal("0")
    if impressions == 0:
        return Decimal("0")
    return (revenue / impressions) * 1000

def calculate_fill_rate(*, network_id: int, days: int = 30) -> Decimal:
    """Calculate fill rate percentage for a network."""
    cutoff = timezone.now() - timedelta(days=days)
    events = AdEvent.objects.filter(
        ad_unit__network_id=network_id, created_at__gte=cutoff,
    )
    requested = events.filter(event_type="requested").count()
    filled = events.filter(event_type="impression").count()
    if requested == 0:
        return Decimal("0")
    return Decimal(filled) / Decimal(requested) * 100
```

### Network Performance Dashboard Data
```python
def get_network_performance_summary(*, days: int = 30) -> list[dict]:
    """Summary for admin dashboard."""
    from apps.ads.models import AdNetwork
    networks = AdNetwork.objects.filter(is_enabled=True)
    return [
        {
            "network": n.name,
            "ecpm": calculate_ecpm(network_id=n.pk, days=days),
            "fill_rate": calculate_fill_rate(network_id=n.pk, days=days),
            "revenue_share": n.revenue_share_percent,
        }
        for n in networks
    ]
```

## Anti-Patterns
- Calculating eCPM in real-time per request — use cached aggregations
- Ignoring `revenue_share_percent` when comparing networks
- No time-window on metrics — stale historical data skews comparisons

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
