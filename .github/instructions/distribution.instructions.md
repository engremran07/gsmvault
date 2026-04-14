---
applyTo: 'apps/distribution/**'
---

# Distribution (Content Syndication) Instructions

## Important Distinction

`apps.distribution` handles **blog/social content syndication** — NOT firmware distribution. Firmware downloads are managed by `apps.firmwares`.

## Supported Platforms

Twitter/X, LinkedIn, Facebook, Discord, Telegram, Reddit, Pinterest, WhatsApp, RSS/Atom, WebSub (PubSubHubbub), Email Newsletter.

## Pipeline Architecture

```
SharePlan → ShareJob → Connector → ConnectorResult
```

1. **SharePlan**: Defines what content to distribute, to which platforms, with what schedule
2. **ShareJob**: Individual distribution task (one per platform per content piece)
3. **Connector**: Platform-specific adapter that handles API calls
4. **ConnectorResult**: Outcome of each distribution attempt (success/fail, platform post ID, error)

## Connector Pattern

Each connector implements a standard interface with three safety layers:

### 1. Circuit Breaker

Protects against cascading failures when a platform API is down:

```python
class ConnectorCircuitBreaker:
    # States: CLOSED (normal) → OPEN (failing) → HALF_OPEN (testing)
    # After N consecutive failures → OPEN (stop trying)
    # After cooldown period → HALF_OPEN (try one request)
    # If HALF_OPEN succeeds → CLOSED (resume normal)
    # If HALF_OPEN fails → OPEN (extend cooldown)
    pass
```

### 2. Rate Limiting

Per-platform rate limits to prevent API bans:

```python
# Each platform has different limits:
# Twitter: 300 tweets/3 hours
# LinkedIn: 100 shares/day
# Discord: 5 webhooks/second
# Telegram: 30 messages/second per bot
```

### 3. Retry Logic

Exponential backoff for transient failures:

```python
# Retry with exponential backoff:
# Attempt 1: immediate
# Attempt 2: 30 seconds
# Attempt 3: 2 minutes
# Attempt 4: 10 minutes
# Attempt 5: 1 hour (max)
# After max retries: mark as FAILED, log error
```

## UTM Parameter Injection — MANDATORY

All outbound links MUST include UTM parameters for attribution:

```python
def inject_utm(url, platform, campaign_name):
    params = {
        "utm_source": platform,        # "twitter", "linkedin", etc.
        "utm_medium": "social",         # Always "social" for distribution
        "utm_campaign": campaign_name,  # SharePlan name or auto-generated
    }
    # Append to URL without duplicating existing params
    return add_query_params(url, params)
```

## Credential Validation — Pre-Flight Check

Before any distribution attempt, validate that credentials are still valid:

```python
def validate_credentials(social_account):
    """
    Check that API tokens are still valid before attempting distribution.
    Returns: (is_valid: bool, error_message: str | None)
    """
    # 1. Check token expiry
    if social_account.token_expires_at < now():
        return False, "Token expired"
    # 2. Make lightweight API call (e.g., /me or /verify)
    try:
        response = platform_api.verify(social_account.access_token)
        return True, None
    except AuthError:
        return False, "Token revoked or invalid"
```

## Content Adaptation

Each platform has different constraints — messages must be adapted:

| Platform | Max Length | Media | Links |
|---|---|---|---|
| Twitter/X | 280 chars | 4 images or 1 video | Shortened |
| LinkedIn | 3000 chars | 1 image or document | Full URL |
| Discord | 2000 chars | Embeds | Full URL |
| Telegram | 4096 chars | 1 media | Full URL |
| Reddit | Title: 300, Body: 40000 | 1 link or image | In body |

## Auto-Publish on Blog Post Creation

Signal-driven distribution when new content is published:

```python
# apps/distribution/signals.py
@receiver(post_save, sender="blog.Post")
def auto_distribute_post(sender, instance, created, **kwargs):
    if created and instance.status == "published":
        # Queue distribution jobs for configured platforms
        trigger_share_plan(instance)
```

## Deduplication

Prevent duplicate posts to the same channel:

```python
# Before creating ShareJob, check for existing:
existing = ShareJob.objects.filter(
    content_type=content_type,
    object_id=object_id,
    platform=platform,
    status__in=["pending", "completed"],
).exists()
if existing:
    return  # Skip — already distributed
```

## Forbidden Practices

- Never send distribution requests without credential validation
- Never bypass rate limits — platform bans are permanent
- Never auto-distribute without UTM parameters
- Never store OAuth tokens in source code — use encrypted database fields
- Never retry indefinitely — cap at 5 attempts with exponential backoff
- Never distribute content that hasn't been published (draft posts)
