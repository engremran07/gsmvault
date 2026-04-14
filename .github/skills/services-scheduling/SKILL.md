---
name: services-scheduling
description: "Task scheduling: Celery beat, periodic tasks, cron expressions. Use when: scheduling recurring tasks, configuring Celery beat, periodic cleanup, scheduled reports."
---

# Task Scheduling Patterns

## When to Use
- Running tasks on a schedule (hourly cleanup, daily reports, weekly digests)
- Configuring Celery beat periodic tasks
- Cron-like scheduling for maintenance operations
- Database-driven dynamic schedules

## Rules
- Celery config lives in `app/celery.py` — beat schedule in `app/settings.py`
- Periodic tasks defined in `tasks.py` per app
- Use `crontab()` for fixed schedules, `timedelta` for intervals
- All scheduled tasks MUST be idempotent — they may run twice on restart
- Use `django-celery-beat` for admin-configurable schedules
- Log start/end of scheduled tasks for monitoring

## Patterns

### Celery Beat Schedule in Settings
```python
# app/settings.py
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    "cleanup-expired-tokens": {
        "task": "apps.firmwares.tasks.cleanup_expired_tokens",
        "schedule": crontab(minute=0, hour="*/6"),  # Every 6 hours
    },
    "aggregate-ad-events": {
        "task": "apps.ads.tasks.aggregate_events",
        "schedule": crontab(minute=15, hour=0),  # Daily at 00:15
    },
    "process-email-queue": {
        "task": "apps.notifications.tasks.process_email_queue",
        "schedule": 60.0,  # Every 60 seconds
    },
    "weekly-analytics-report": {
        "task": "apps.analytics.tasks.generate_weekly_report",
        "schedule": crontab(hour=6, minute=0, day_of_week=1),  # Monday 6 AM
    },
}
```

### Periodic Task Implementation
```python
# apps/firmwares/tasks.py
import logging
from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)

@shared_task
def cleanup_expired_tokens() -> dict:
    """Clean up expired download tokens. Runs every 6 hours."""
    from .models import DownloadToken
    cutoff = timezone.now()
    expired = DownloadToken.objects.filter(
        status="active", expires_at__lt=cutoff
    )
    count = expired.update(status="expired")
    logger.info("Cleaned up %d expired download tokens", count)
    return {"expired_count": count}
```

### Idempotent Task Pattern
```python
@shared_task
def generate_daily_stats(date_str: str | None = None) -> dict:
    """Generate daily statistics. Idempotent — safe to re-run."""
    from datetime import date, datetime
    target_date = (
        datetime.strptime(date_str, "%Y-%m-%d").date()
        if date_str
        else date.today()
    )
    # Delete existing stats for this date (idempotent)
    DailyStat.objects.filter(date=target_date).delete()
    # Regenerate
    stats = _compile_stats(target_date)
    DailyStat.objects.create(date=target_date, **stats)
    return {"date": str(target_date), "stats": stats}
```

### Dynamic Schedule with django-celery-beat
```python
# Managed via admin panel — no code changes needed for new schedules
# Admin: Periodic Tasks → Add → Select task, set interval/crontab
# Tasks are auto-discovered from CELERY_BEAT_SCHEDULE + admin entries
```

### Task with Lock (Prevent Overlap)
```python
from django.core.cache import cache

@shared_task
def heavy_report_generation() -> str:
    """Generate heavy report — prevent concurrent runs."""
    lock_key = "lock:heavy_report"
    if not cache.add(lock_key, "1", timeout=3600):
        logger.warning("Heavy report already running, skipping")
        return "skipped"
    try:
        result = _do_heavy_work()
        return result
    finally:
        cache.delete(lock_key)
```

## Anti-Patterns
- Non-idempotent scheduled tasks — duplicate data on re-run
- No logging in scheduled tasks — invisible failures
- Overlapping long-running tasks — use locks
- Hardcoded schedules in task code — use settings

## Red Flags
- Scheduled task without `logger.info()` start/end logging
- Task that creates records without checking for duplicates
- `timedelta(seconds=1)` schedule — too aggressive, likely a mistake

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
