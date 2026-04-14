---
name: fin-gamification-badges
description: "Badge system: criteria, auto-award, display. Use when: defining badge criteria, auto-awarding badges on milestones, displaying earned badges."
---

# Gamification Badge System

## When to Use

- Defining badge criteria (e.g., "Downloaded 100 firmwares")
- Auto-awarding badges when criteria are met
- Displaying badge collections on user profiles

## Rules

1. **Criteria defined in database** — not hardcoded logic
2. **Auto-award check** runs after relevant actions (via signals/events)
3. **One badge per type per user** — prevent duplicate awards
4. **Badge tiers**: bronze, silver, gold, platinum
5. **Notification** on badge unlock

## Pattern: Badge Criteria Check

```python
from django.db import transaction
from apps.gamification.models import Badge, UserBadge

BADGE_CRITERIA = {
    "first_download": {"action": "download", "threshold": 1},
    "power_downloader": {"action": "download", "threshold": 100},
    "forum_contributor": {"action": "forum_post", "threshold": 10},
    "trusted_reviewer": {"action": "review", "threshold": 25},
    "referral_champion": {"action": "referral_signup", "threshold": 10},
    "bounty_hunter": {"action": "bounty_fulfilled", "threshold": 5},
}


@transaction.atomic
def check_and_award_badges(user_id: int, action: str) -> list[Badge]:
    """Check all badges for given action, award any newly earned."""
    from apps.gamification.models import PointTransaction

    awarded = []
    relevant = {
        k: v for k, v in BADGE_CRITERIA.items()
        if v["action"] == action
    }
    for badge_slug, criteria in relevant.items():
        # Skip if already awarded
        if UserBadge.objects.filter(
            user_id=user_id, badge__slug=badge_slug,
        ).exists():
            continue

        # Count user's actions
        count = PointTransaction.objects.filter(
            user_id=user_id, action=action,
        ).count()
        if count >= criteria["threshold"]:
            badge = Badge.objects.get(slug=badge_slug)
            UserBadge.objects.create(user_id=user_id, badge=badge)
            awarded.append(badge)

    return awarded
```

## Pattern: Signal-Triggered Check

```python
from apps.core.events.bus import event_bus, EventTypes

def on_points_earned(data: dict) -> None:
    """Auto-check badges after points are earned."""
    user_id = data["user_id"]
    action = data["action"]
    new_badges = check_and_award_badges(user_id, action)
    for badge in new_badges:
        event_bus.emit(EventTypes.BADGE_EARNED, {
            "user_id": user_id,
            "badge_slug": badge.slug,
            "badge_name": badge.name,
        })

# Register in apps.py ready()
event_bus.on(EventTypes.POINTS_EARNED, on_points_earned)
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Hardcoded badge logic in views | Can't add badges without deploy | Database-driven criteria |
| Duplicate badge awards | Cluttered profile | Unique constraint on user+badge |
| Synchronous badge check on every request | Performance hit | Event-driven, post-action |
| No notification on unlock | User misses achievement | Emit event for notification |

## Red Flags

- Missing unique constraint on `UserBadge(user, badge)`
- Badge checks in view layer instead of service/event
- No badge tiers or progression

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
