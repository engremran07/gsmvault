---
name: dist-auto-publish
description: "Auto-publish on blog post creation. Use when: automatically distributing new content, auto-fanout on publish, signal-driven distribution."
---

# Auto-Publish Distribution

## When to Use
- Automatically distributing new blog posts on publish
- `DistributionSettings.auto_fanout_on_publish = True` flow
- Creating `SharePlan` + `ShareJob` records from publish signal
- Respecting `default_channels` and `max_platforms_per_content`

## Rules
- Auto-fanout triggered by `post_save` signal when post status → `published`
- `DistributionSettings.auto_fanout_on_publish` must be True
- `DistributionSettings.default_channels` JSON list controls which channels
- `DistributionSettings.max_platforms_per_content` caps concurrent channels
- `DistributionSettings.require_admin_approval` — if True, plans start as `pending`
- Only active `SocialAccount` records with valid credentials are used

## Patterns

### Auto-Fanout Signal Handler
```python
# apps/distribution/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender="blog.Post")
def auto_distribute_on_publish(sender, instance, **kwargs):
    """Auto-create distribution plan when a blog post is published."""
    if instance.status != "published":
        return

    from apps.distribution.models import DistributionSettings
    settings = DistributionSettings.get_solo()
    if not settings.distribution_enabled or not settings.auto_fanout_on_publish:
        return

    from apps.distribution.services import create_auto_plan
    create_auto_plan(post=instance, settings=settings)
```

### Creating the Distribution Plan
```python
# apps/distribution/services.py
from apps.distribution.models import (
    DistributionSettings, SharePlan, ShareJob, SocialAccount,
)

def create_auto_plan(*, post, settings: DistributionSettings) -> SharePlan:
    """Create a SharePlan with jobs for all default channels."""
    channels = settings.default_channels or []
    max_platforms = settings.max_platforms_per_content or 5

    # Get active accounts for default channels
    accounts = SocialAccount.objects.filter(
        channel__in=channels, is_active=True,
    )[:max_platforms]

    plan = SharePlan.objects.create(
        post=post,
        channels=[a.channel for a in accounts],
        status="pending" if settings.require_admin_approval else "approved",
    )

    for account in accounts:
        ShareJob.objects.create(
            post=post,
            plan=plan,
            account=account,
            channel=account.channel,
            status="pending",
        )

    return plan
```

## Anti-Patterns
- Auto-publishing without checking `auto_fanout_on_publish` setting
- Creating jobs for inactive or expired accounts
- Ignoring `max_platforms_per_content` — spamming all channels
- No admin approval option — all content goes out immediately

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
