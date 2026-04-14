---
name: sec-rate-limit-user
description: "Per-user rate limiting: DRF throttle classes. Use when: limiting API requests per user, configuring DRF throttling."
---

# Per-User Rate Limiting (DRF)

## When to Use

- Limiting API requests per authenticated user
- Configuring DRF throttle scopes
- Tier-based rate limiting

## Rules

| Throttle Class | Scope | Source |
|----------------|-------|--------|
| `UploadRateThrottle` | File uploads | `apps.core.throttling` |
| `DownloadRateThrottle` | File downloads | `apps.core.throttling` |
| `APIRateThrottle` | General API | `apps.core.throttling` |
| `UserRateThrottle` | Per-user default | DRF built-in |
| `AnonRateThrottle` | Anonymous users | DRF built-in |

## Patterns

### DRF Settings
```python
# settings.py
REST_FRAMEWORK = {
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "30/minute",
        "user": "120/minute",
        "upload": "10/hour",
        "download": "50/hour",
    },
}
```

### Custom Throttle Class
```python
from rest_framework.throttling import UserRateThrottle

class UploadRateThrottle(UserRateThrottle):
    scope = "upload"
    rate = "10/hour"

class DownloadRateThrottle(UserRateThrottle):
    scope = "download"

    def get_rate(self) -> str:
        # Tier-based rate limiting
        user = self.request.user if hasattr(self, 'request') else None
        if user and getattr(user, "subscription_tier", "") == "premium":
            return "200/hour"
        return "50/hour"
```

### Per-View Throttle
```python
from rest_framework.decorators import api_view, throttle_classes

@api_view(["POST"])
@throttle_classes([UploadRateThrottle])
def upload_firmware(request):
    ...

class FirmwareViewSet(viewsets.ModelViewSet):
    throttle_classes = [DownloadRateThrottle]
    ...
```

### Throttle Response Headers
```python
# DRF automatically sets:
# Retry-After: <seconds>
# X-RateLimit-Limit: <max requests>
# X-RateLimit-Remaining: <remaining requests>
```

## Red Flags

- No throttle classes on upload/download endpoints
- Same rate limit for free and premium users
- Missing `AnonRateThrottle` on public endpoints
- Rate limits set too high (1000+/minute for authenticated)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
