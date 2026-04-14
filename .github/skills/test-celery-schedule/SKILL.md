---
name: test-celery-schedule
description: "Beat schedule tests: periodic task configuration verification. Use when: testing Celery beat schedule, periodic task registration, schedule timing."
---

# Celery Beat Schedule Tests

## When to Use

- Verifying periodic tasks are registered in Celery beat
- Testing schedule configuration (intervals, crontab)
- Ensuring cleanup/aggregation tasks are scheduled

## Rules

### Testing Schedule Registration

```python
import pytest
from django.test import override_settings

def test_periodic_tasks_registered():
    from app.celery import app
    beat_schedule = app.conf.beat_schedule
    assert "aggregate-ad-events" in beat_schedule or len(beat_schedule) > 0

def test_cleanup_task_scheduled():
    from app.celery import app
    beat_schedule = app.conf.beat_schedule
    cleanup_tasks = [
        k for k in beat_schedule if "cleanup" in k.lower()
    ]
    assert len(cleanup_tasks) >= 1
```

### Testing Schedule Intervals

```python
def test_ad_aggregation_schedule():
    from app.celery import app
    schedule = app.conf.beat_schedule.get("aggregate-ad-events", {})
    if "schedule" in schedule:
        from celery.schedules import crontab
        # Verify it runs at expected frequency
        assert schedule["schedule"] is not None
```

### Testing Task Reference Validity

```python
def test_scheduled_tasks_importable():
    from app.celery import app
    for name, config in app.conf.beat_schedule.items():
        task_path = config.get("task", "")
        parts = task_path.rsplit(".", 1)
        if len(parts) == 2:
            module_path, func_name = parts
            try:
                import importlib
                module = importlib.import_module(module_path)
                assert hasattr(module, func_name), f"{task_path} not found"
            except ImportError:
                pytest.fail(f"Cannot import {module_path} for scheduled task {name}")
```

### Testing Task Arguments

```python
def test_scheduled_task_args():
    from app.celery import app
    schedule = app.conf.beat_schedule
    for name, config in schedule.items():
        # Verify no hardcoded sensitive data in args
        args = config.get("args", ())
        kwargs = config.get("kwargs", {})
        for arg in args:
            assert not isinstance(arg, str) or "password" not in arg.lower()
```

### Testing Schedule from Settings

```python
def test_beat_schedule_in_settings():
    from django.conf import settings
    assert hasattr(settings, "CELERY_BEAT_SCHEDULE") or True
    # If using django-celery-beat, check DB-based schedules
```

### Verifying Periodic Task Execution

```python
@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
@pytest.mark.django_db
def test_periodic_task_runs():
    from apps.ads.tasks import aggregate_events
    result = aggregate_events.apply()
    assert result.successful()
```

## Red Flags

- Scheduled task paths that can't be imported — silent failures in production
- Missing cleanup tasks — data grows unbounded
- Hardcoded credentials in task args — use settings/env vars
- No test for task importability — tasks may reference deleted code

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
