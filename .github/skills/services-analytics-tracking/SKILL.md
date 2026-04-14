---
name: services-analytics-tracking
description: "Analytics event tracking: pageviews, downloads, conversions. Use when: tracking user actions, recording analytics events, building dashboards, measuring KPIs."
---

# Analytics Tracking Patterns

## When to Use
- Recording pageviews, downloads, clicks, conversions
- Tracking firmware download counts and patterns
- Ad impression and click tracking
- Revenue and affiliate conversion tracking
- Building admin dashboards with KPI data

## Rules
- Analytics events tracked in `apps.analytics` models
- Use lightweight tracking — never block the request for analytics
- Batch-insert events or use Celery for high-volume tracking
- Aggregate raw events into summary tables daily (via Celery beat)
- Respect consent — check user consent before tracking (use `apps.consent`)
- Use `apps.core.utils.get_client_ip()` for IP extraction

## Patterns

### Event Tracking Service
```python
# apps/analytics/services.py
import logging
from django.utils import timezone
from .models import AnalyticsEvent

logger = logging.getLogger(__name__)

def track_event(
    *,
    event_type: str,
    user_id: int | None = None,
    ip_address: str = "",
    page_url: str = "",
    metadata: dict | None = None,
) -> None:
    """Record an analytics event. Non-blocking."""
    AnalyticsEvent.objects.create(
        event_type=event_type,
        user_id=user_id,
        ip_address=ip_address,
        page_url=page_url,
        metadata=metadata or {},
        created_at=timezone.now(),
    )
```

### Lightweight View Tracking
```python
from apps.core.utils import get_client_ip

def firmware_detail(request, pk: int):
    firmware = get_object_or_404(Firmware, pk=pk, is_active=True)
    # Track pageview asynchronously
    from apps.analytics.tasks import track_event_async
    track_event_async.delay(
        event_type="pageview",
        user_id=request.user.pk if request.user.is_authenticated else None,
        ip_address=get_client_ip(request),
        page_url=request.path,
        metadata={"firmware_id": pk},
    )
    return render(request, "firmwares/detail.html", {"firmware": firmware})
```

### Async Event Tracking Task
```python
# apps/analytics/tasks.py
from celery import shared_task

@shared_task
def track_event_async(
    event_type: str,
    user_id: int | None = None,
    ip_address: str = "",
    page_url: str = "",
    metadata: dict | None = None,
) -> None:
    from . import services
    services.track_event(
        event_type=event_type,
        user_id=user_id,
        ip_address=ip_address,
        page_url=page_url,
        metadata=metadata,
    )
```

### Download Tracking
```python
def track_download(*, firmware_id: int, user_id: int, ip_address: str) -> None:
    """Track firmware download for analytics."""
    track_event(
        event_type="download",
        user_id=user_id,
        ip_address=ip_address,
        metadata={"firmware_id": firmware_id},
    )
    # Also increment download counter on firmware
    Firmware.objects.filter(pk=firmware_id).update(
        download_count=models.F("download_count") + 1
    )
```

### Daily Aggregation Task
```python
@shared_task
def aggregate_daily_analytics() -> dict:
    """Aggregate raw events into daily summary. Runs daily via Celery beat."""
    from datetime import date, timedelta
    from django.db.models import Count, Q

    yesterday = date.today() - timedelta(days=1)
    events = AnalyticsEvent.objects.filter(created_at__date=yesterday)

    summary = {
        "date": str(yesterday),
        "pageviews": events.filter(event_type="pageview").count(),
        "downloads": events.filter(event_type="download").count(),
        "unique_visitors": events.values("ip_address").distinct().count(),
        "registered_users": events.filter(user_id__isnull=False).values("user_id").distinct().count(),
    }
    DailySummary.objects.update_or_create(
        date=yesterday, defaults=summary,
    )
    logger.info("Daily analytics aggregated for %s: %s", yesterday, summary)
    return summary
```

### KPI Query for Admin Dashboard
```python
from django.utils import timezone
from datetime import timedelta

def get_dashboard_kpis() -> dict:
    """Get KPI data for admin dashboard."""
    now = timezone.now()
    today = now.date()
    last_30 = today - timedelta(days=30)
    return {
        "downloads_today": AnalyticsEvent.objects.filter(
            event_type="download", created_at__date=today
        ).count(),
        "downloads_30d": AnalyticsEvent.objects.filter(
            event_type="download", created_at__date__gte=last_30
        ).count(),
        "active_users_today": AnalyticsEvent.objects.filter(
            created_at__date=today, user_id__isnull=False
        ).values("user_id").distinct().count(),
        "new_firmwares_30d": Firmware.objects.filter(
            created_at__date__gte=last_30
        ).count(),
    }
```

## Anti-Patterns
- Tracking events synchronously in the request cycle — slows every page
- Storing raw IPs without consent — privacy violation
- Never aggregating raw events — analytics table grows unbounded
- Tracking everything — define meaningful events, not mouse movements

## Red Flags
- `AnalyticsEvent.objects.create()` in view without Celery → blocks request
- No daily aggregation task → raw event table grows forever
- Missing consent check before tracking → GDPR violation
- `count()` on raw event table for dashboard → slow query on large tables

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
