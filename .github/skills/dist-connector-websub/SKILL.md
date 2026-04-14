---
name: dist-connector-websub
description: "WebSub (PubSubHubbub) distribution. Use when: real-time feed push notifications, hub subscription, instant content propagation to subscribers."
---

# WebSub Distribution Connector

## When to Use
- Pushing content updates to WebSub subscribers in real-time
- Configuring `SocialAccount(channel="websub")` with hub URL
- Notifying WebSub hubs when new content is published
- Setting up hub pings from blog post publish signals

## Rules
- Channel constant: `Channel.WEBSUB = "websub"`
- WebSub replaces PubSubHubbub — W3C standard
- Hub notification = HTTP POST to hub URL with `hub.mode=publish` + `hub.url`
- Trigger hub ping on `post_save` of published blog posts
- Common hubs: Google PubSubHubbub, Superfeedr, self-hosted
- `config["hub_url"]` stores the hub endpoint

## Patterns

### Pinging WebSub Hub
```python
# apps/distribution/connectors/websub.py
import httpx

def ping_hub(*, job) -> dict:
    account = job.account
    hub_url = account.config.get("hub_url", "")
    feed_url = job.payload.get("feed_url", "")

    resp = httpx.post(
        hub_url,
        data={
            "hub.mode": "publish",
            "hub.url": feed_url,
        },
        timeout=15,
    )
    resp.raise_for_status()
    job.status = "completed"
    job.save(update_fields=["status"])
    return {"status": resp.status_code}
```

### Auto-Ping on Blog Publish
```python
# apps/distribution/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender="blog.Post")
def notify_websub_on_publish(sender, instance, **kwargs):
    if instance.status != "published":
        return
    from apps.distribution.models import SocialAccount, ShareJob
    accounts = SocialAccount.objects.filter(channel="websub", is_active=True)
    for account in accounts:
        ShareJob.objects.create(
            post=instance,
            account=account,
            channel="websub",
            payload={"feed_url": "/feed/"},
        )
```

### Adding Hub Link to Feed
```html
{# In RSS feed template or <head> #}
<link rel="hub" href="{{ websub_hub_url }}" />
<link rel="self" href="{{ feed_url }}" />
```

## Anti-Patterns
- Pinging hub before content is actually published — subscribers get 404
- Not including `rel="hub"` link in feed — subscribers can't discover hub
- Pinging hub for draft/unpublished content changes
- No retry on hub ping failure — content update silently lost

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
