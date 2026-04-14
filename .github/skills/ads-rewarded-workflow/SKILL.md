---
name: ads-rewarded-workflow
description: "Rewarded ad flow: watch→verify→credit. Use when: implementing rewarded video ads, granting rewards after ad completion, enforcing cooldowns and daily limits."
---

# Rewarded Ad Workflow

## When to Use
- Implementing watch-to-earn ad flow (download credits, points, premium access)
- Configuring `RewardedAdConfig` reward types and limits
- Enforcing cooldown periods and daily caps via `RewardedAdView`
- Server-side verification of video completion before granting rewards

## Rules
- Flow: User clicks → `RewardedAdView(status="started")` → Video plays →
  Client reports completion → Server verifies duration → Grant reward
- `RewardedAdConfig.cooldown_minutes` enforced between views
- `RewardedAdConfig.daily_limit_per_user` caps daily reward count
- Reward granted ONLY after server-side verification — never trust client
- `select_for_update()` on wallet operations if reward is credits

## Patterns

### Full Rewarded Flow
```python
# apps/ads/services.py
from django.db import transaction
from apps.ads.models import RewardedAdConfig, RewardedAdView

def start_rewarded_view(
    *, user, config_id: int, ip_address: str, page_url: str
) -> RewardedAdView | None:
    """Start a rewarded ad view. Returns None if rate limited."""
    config = RewardedAdConfig.objects.get(pk=config_id, is_enabled=True)

    # Check daily limit
    today_count = RewardedAdView.objects.filter(
        user=user, config=config,
        created_at__date=timezone.now().date(),
        status="completed",
    ).count()
    if today_count >= config.daily_limit_per_user:
        return None

    # Check cooldown
    last_view = RewardedAdView.objects.filter(
        user=user, config=config,
    ).order_by("-created_at").first()
    if last_view:
        elapsed = (timezone.now() - last_view.created_at).total_seconds() / 60
        if elapsed < config.cooldown_minutes:
            return None

    return RewardedAdView.objects.create(
        user=user, config=config,
        ip_address=ip_address, page_url=page_url,
    )

@transaction.atomic
def complete_rewarded_view(*, view_id: int, watch_seconds: int) -> bool:
    """Verify completion and grant reward."""
    view = RewardedAdView.objects.select_for_update().get(pk=view_id)
    if view.reward_granted or view.status == "completed":
        return False

    config = view.config
    min_seconds = config.min_watch_seconds if config else 30
    if watch_seconds < min_seconds:
        view.status = "skipped"
        view.save(update_fields=["status"])
        return False

    view.status = "completed"
    view.completed_at = timezone.now()
    view.watch_duration_seconds = watch_seconds
    view.reward_granted = True
    view.reward_type = config.reward_type
    view.reward_amount = config.reward_amount
    view.save()

    # Dispatch reward via EventBus
    from apps.core.events.bus import event_bus, EventTypes
    event_bus.emit(EventTypes.WALLET_CREDITED, user_id=view.user_id,
                   amount=config.reward_amount, source="rewarded_ad")
    return True
```

## Anti-Patterns
- Granting rewards on client-side `onended` event only — easily spoofed
- No cooldown enforcement — users farm unlimited rewards
- Missing `select_for_update()` on credit operations — race condition
- Hardcoding reward amounts instead of using `RewardedAdConfig`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
