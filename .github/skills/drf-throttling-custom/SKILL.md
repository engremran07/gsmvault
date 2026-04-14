---
name: drf-throttling-custom
description: "Custom throttle classes: per-user, per-endpoint, tier-based limits. Use when: adding rate limiting to API endpoints, creating tiered rate limits, custom throttle scopes."
---

# DRF Custom Throttling

## When to Use
- Adding rate limits to specific API endpoints
- Creating tier-based limits (free=10/hr, premium=1000/hr)
- Per-endpoint throttle scopes (upload vs download vs browse)

## Rules
- Use DRF throttle classes for API-level rate limiting
- WAF/IP-level rate limiting is in `apps.security` — separate system, never conflate
- Throttle classes go in `apps/core/throttling.py` (shared) or `apps/<app>/api.py`
- Configure rates in settings via `DEFAULT_THROTTLE_RATES`
- Always set `scope` on custom throttle classes

## Patterns

### Settings Configuration
```python
# app/settings.py
REST_FRAMEWORK = {
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "100/hour",
        "user": "1000/hour",
        "upload": "10/hour",
        "download": "50/hour",
        "api_burst": "60/minute",
    },
}
```

### Scoped Throttle Class
```python
from rest_framework.throttling import UserRateThrottle

class UploadRateThrottle(UserRateThrottle):
    scope = "upload"

class DownloadRateThrottle(UserRateThrottle):
    scope = "download"

class APIBurstThrottle(UserRateThrottle):
    scope = "api_burst"
```

### Tier-Based Throttle
```python
from rest_framework.throttling import UserRateThrottle

class TieredRateThrottle(UserRateThrottle):
    """Rate limit varies by user subscription tier."""

    TIER_RATES = {
        "free": "10/hour",
        "registered": "100/hour",
        "subscriber": "500/hour",
        "premium": "5000/hour",
    }

    def get_rate(self) -> str:
        user = self.request.user  # type: ignore[attr-defined]
        if not user.is_authenticated:
            return "10/hour"
        tier = getattr(getattr(user, "profile", None), "tier", "free")
        return self.TIER_RATES.get(tier, "10/hour")
```

### Per-ViewSet Throttle
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    throttle_classes = [UploadRateThrottle]

    # Or per-action:
    def get_throttles(self):
        if self.action == "create":
            return [UploadRateThrottle()]
        if self.action == "retrieve":
            return [DownloadRateThrottle()]
        return [APIBurstThrottle()]
```

### Anonymous vs Authenticated
```python
from rest_framework.throttling import AnonRateThrottle, UserRateThrottle

class PublicSearchViewSet(viewsets.ReadOnlyModelViewSet):
    throttle_classes = [AnonRateThrottle, UserRateThrottle]
    # anon: 100/hour, user: 1000/hour (from settings)
```

### Custom Throttle with Cache Key
```python
from rest_framework.throttling import SimpleRateThrottle

class PerEndpointThrottle(SimpleRateThrottle):
    scope = "per_endpoint"
    rate = "30/minute"

    def get_cache_key(self, request, view) -> str | None:
        if request.user.is_authenticated:
            ident = request.user.pk
        else:
            ident = self.get_ident(request)
        return f"throttle_{view.__class__.__name__}_{ident}"
```

## Anti-Patterns
- Conflating DRF throttle with WAF rate limiting (`apps.security.RateLimitRule`)
- No throttle on upload/download endpoints → abuse vector
- Same rate for all tiers → no incentive to upgrade
- Missing `scope` on custom throttle → uses default rate

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/core/throttling.py` — platform throttle classes
- Skill: `services-rate-limiting` — rate limiting architecture
