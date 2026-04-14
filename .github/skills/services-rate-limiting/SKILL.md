---
name: services-rate-limiting
description: "Rate limiting patterns: DRF throttle classes, custom rate logic. Use when: adding API rate limits, configuring DRF throttling, per-user/per-IP rate limits."
---

# Rate Limiting Patterns

## When to Use
- Protecting API endpoints from abuse
- Per-user rate limits on authenticated endpoints
- Per-IP rate limits on anonymous endpoints
- Custom rate logic for specific resources (downloads, uploads)

## Rules
- DRF throttle classes live in `apps.core.throttling` — use those first
- WAF rate limiting (`apps.security.RateLimitRule`) is for middleware-level protection
- Download quotas (`apps.firmwares.DownloadToken` + `apps.devices.QuotaTier`) are separate
- NEVER conflate WAF rate limits with download quotas — two completely separate systems
- Custom throttle classes inherit from DRF's `BaseThrottle` or `SimpleRateThrottle`

## Patterns

### Using Built-in Throttle Classes
```python
# apps/core/throttling.py provides 6 classes:
# UploadRateThrottle, DownloadRateThrottle, APIRateThrottle,
# BurstRateThrottle, SustainedRateThrottle, AnonRateThrottle

# In DRF views:
from apps.core.throttling import APIRateThrottle, UploadRateThrottle
from rest_framework.views import APIView

class FirmwareUploadView(APIView):
    throttle_classes = [UploadRateThrottle]

    def post(self, request):
        ...
```

### Custom Throttle Class
```python
from rest_framework.throttling import SimpleRateThrottle

class DownloadRateThrottle(SimpleRateThrottle):
    scope = "downloads"
    rate = "10/hour"

    def get_cache_key(self, request, view):
        if request.user.is_authenticated:
            return f"throttle_download_{request.user.pk}"
        return f"throttle_download_{self.get_ident(request)}"
```

### Per-View Throttle Configuration
```python
from rest_framework.decorators import api_view, throttle_classes
from apps.core.throttling import BurstRateThrottle

@api_view(["POST"])
@throttle_classes([BurstRateThrottle])
def submit_comment(request):
    ...
```

### Settings-Based Rate Configuration
```python
# app/settings.py
REST_FRAMEWORK = {
    "DEFAULT_THROTTLE_CLASSES": [
        "apps.core.throttling.AnonRateThrottle",
        "apps.core.throttling.APIRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "100/hour",
        "user": "1000/hour",
        "uploads": "5/hour",
        "downloads": "20/hour",
        "burst": "10/minute",
    },
}
```

### Service-Level Rate Check
```python
from django.core.cache import cache

def check_download_rate(*, user_id: int, max_per_hour: int = 10) -> bool:
    """Check if user has exceeded download rate limit."""
    cache_key = f"download_rate:{user_id}"
    current = cache.get(cache_key, 0)
    if current >= max_per_hour:
        return False
    cache.set(cache_key, current + 1, timeout=3600)  # 1 hour window
    return True
```

## Anti-Patterns
- Importing `RateLimitRule` from `apps.security` in firmware/download code
- Importing `DownloadToken` in security code
- Hardcoding rate limits instead of using settings
- No differentiation between authenticated and anonymous users

## Red Flags
- API endpoint without any throttle class → abuse risk
- `RateLimitRule` used in firmware views → wrong system
- Rate limit > 1000/hour for write endpoints → too permissive

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
