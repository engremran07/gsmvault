---
name: dist-rate-limit-per-platform
description: "Per-platform rate limiting for distribution. Use when: enforcing API rate limits per channel, throttling outbound requests, preventing API bans."
---

# Per-Platform Rate Limiting

## When to Use
- Enforcing outbound API rate limits per social platform
- Throttling `ShareJob` execution to stay within API quotas
- Preventing account suspension from excessive API calls
- Configuring `DistributionSettings.distribution_frequency_hours`

## Rules

### Platform Rate Limits
| Platform | Rate Limit | Window |
|----------|-----------|--------|
| Twitter | 300 tweets | 3 hours |
| Facebook | 200 calls | 1 hour |
| LinkedIn | 100 calls | 1 day |
| Telegram | 30 messages | 1 second |
| Reddit | 60 requests | 1 minute |
| Discord | 5 requests | 2 seconds |
| Pinterest | 1000 calls | 1 day |

- `DistributionSettings.distribution_frequency_hours` = minimum gap between shares
- Per-account tracking in `SocialAccount.config["rate_limit_state"]`
- Jobs exceeding rate limit → reschedule with backoff, not fail

## Patterns

### Rate Limiter
```python
# apps/distribution/services/rate_limiter.py
from django.core.cache import cache

PLATFORM_LIMITS = {
    "twitter": (300, 10800),    # 300 per 3h
    "facebook": (200, 3600),    # 200 per 1h
    "linkedin": (100, 86400),   # 100 per day
    "telegram": (30, 1),        # 30 per second
    "reddit": (60, 60),         # 60 per minute
    "discord": (5, 2),          # 5 per 2s
    "pinterest": (1000, 86400), # 1000 per day
}

def check_rate_limit(*, channel: str, account_id: int) -> bool:
    """Return True if request is within rate limit."""
    limit, window = PLATFORM_LIMITS.get(channel, (100, 3600))
    cache_key = f"dist:rate:{channel}:{account_id}"
    current = cache.get(cache_key, 0)
    if current >= limit:
        return False
    cache.set(cache_key, current + 1, timeout=window)
    return True

def get_retry_after(*, channel: str, account_id: int) -> int:
    """Return seconds to wait before retrying."""
    _, window = PLATFORM_LIMITS.get(channel, (100, 3600))
    cache_key = f"dist:rate:{channel}:{account_id}"
    ttl = cache.ttl(cache_key)  # type: ignore[attr-defined]
    return max(ttl, 0) if ttl else window
```

### Rate-Limited Job Execution
```python
def execute_with_rate_limit(*, job: ShareJob) -> dict:
    if not check_rate_limit(channel=job.channel, account_id=job.account_id):
        retry_after = get_retry_after(channel=job.channel, account_id=job.account_id)
        job.schedule_at = timezone.now() + timedelta(seconds=retry_after)
        job.status = "pending"
        job.save(update_fields=["schedule_at", "status"])
        return {"status": "rate_limited", "retry_after": retry_after}
    return dispatch_to_connector(job=job)
```

## Anti-Patterns
- No rate limiting — API calls burst and get banned
- Global rate limit instead of per-channel — Twitter throttles LinkedIn jobs
- Hard-failing on rate limit instead of rescheduling
- Not accounting for all API calls (auth, media upload, post) in limit count

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
