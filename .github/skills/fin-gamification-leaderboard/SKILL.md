---
name: fin-gamification-leaderboard
description: "Leaderboard: ranking, caching, time windows. Use when: displaying top users by points, caching leaderboard data, implementing time-windowed rankings."
---

# Gamification Leaderboard

## When to Use

- Displaying top users by points/contributions
- Caching leaderboard for performance
- Weekly/monthly/all-time ranking windows

## Rules

1. **Cache aggressively** — leaderboard doesn't need real-time accuracy
2. **Time windows**: weekly, monthly, all-time
3. **Limit results** — top 50-100, not full user list
4. **Include current user's rank** even if not in top N
5. **Rebuild via Celery** — not computed on every page view

## Pattern: Leaderboard Service

```python
from django.core.cache import cache
from django.db.models import Sum
from apps.gamification.models import PointTransaction

LEADERBOARD_CACHE_TTL = 300  # 5 minutes

def get_leaderboard(
    window: str = "all_time",
    limit: int = 50,
) -> list[dict]:
    """Get cached leaderboard for time window."""
    cache_key = f"leaderboard:{window}:{limit}"
    cached = cache.get(cache_key)
    if cached:
        return cached

    result = build_leaderboard(window, limit)
    cache.set(cache_key, result, LEADERBOARD_CACHE_TTL)
    return result


def build_leaderboard(window: str, limit: int) -> list[dict]:
    """Build leaderboard from database."""
    from django.utils import timezone
    from datetime import timedelta

    qs = PointTransaction.objects.filter(transaction_type="earn")
    if window == "weekly":
        qs = qs.filter(created_at__gte=timezone.now() - timedelta(days=7))
    elif window == "monthly":
        qs = qs.filter(created_at__gte=timezone.now() - timedelta(days=30))

    entries = (
        qs.values("user_id", "user__username")
        .annotate(total=Sum("points"))
        .order_by("-total")[:limit]
    )
    return [
        {"rank": i + 1, "user_id": e["user_id"],
         "username": e["user__username"], "points": e["total"]}
        for i, e in enumerate(entries)
    ]


def get_user_rank(user_id: int, window: str = "all_time") -> int | None:
    """Get a specific user's rank. Returns None if no points."""
    board = get_leaderboard(window, limit=1000)
    for entry in board:
        if entry["user_id"] == user_id:
            return entry["rank"]
    return None
```

## Pattern: Celery Refresh Task

```python
from celery import shared_task

@shared_task(name="gamification.refresh_leaderboards")
def refresh_leaderboards() -> None:
    """Rebuild and cache all leaderboard windows."""
    for window in ("weekly", "monthly", "all_time"):
        result = build_leaderboard(window, limit=100)
        cache.set(f"leaderboard:{window}:100", result, 600)
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Computing leaderboard on every page view | DB-heavy, slow | Cache with TTL |
| No time windows | All-time board dominated by old users | Weekly/monthly windows |
| Returning full user table | Performance, privacy | Limit to top N |
| `.order_by("-points")` on main user table | Full table scan | Aggregate from transactions |

## Red Flags

- Uncached leaderboard queries
- Missing Celery task for periodic refresh
- No option to view current user's rank
- Leaderboard showing all users instead of top N

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
