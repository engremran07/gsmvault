---
name: sec-rate-limit-endpoint
description: "Endpoint-specific rate limits: path-based rules. Use when: different limits for login vs API vs upload endpoints."
---

# Endpoint-Specific Rate Limits

## When to Use

- Setting different rate limits for different API endpoints
- Protecting login and registration endpoints
- Configuring search and heavy endpoint limits

## Rules

| Endpoint | Rate | Reason |
|----------|------|--------|
| `/api/v1/auth/login/` | 5/5min | Brute-force prevention |
| `/api/v1/auth/register/` | 3/hour | Spam prevention |
| `/api/v1/firmware/upload/` | 10/hour | Resource protection |
| `/api/v1/search/` | 30/minute | Query cost |
| `/api/v1/firmware/` | 120/minute | General browsing |

## Patterns

### WAF Path Rules (apps.security)
```python
# RateLimitRule entries for specific paths
rules = [
    {"path_pattern": "/api/v1/auth/login/", "limit": 5, "window_seconds": 300, "action": "block"},
    {"path_pattern": "/api/v1/auth/register/", "limit": 3, "window_seconds": 3600, "action": "block"},
    {"path_pattern": "/api/v1/auth/password-reset/", "limit": 3, "window_seconds": 3600, "action": "throttle"},
    {"path_pattern": "/api/v1/firmware/upload/", "limit": 10, "window_seconds": 3600, "action": "throttle"},
    {"path_pattern": "/api/v1/search/", "limit": 30, "window_seconds": 60, "action": "throttle"},
]
for rule in rules:
    RateLimitRule.objects.get_or_create(
        path_pattern=rule["path_pattern"],
        defaults=rule,
    )
```

### DRF Scoped Throttles
```python
class LoginThrottle(AnonRateThrottle):
    scope = "login"
    rate = "5/5min"

class RegisterThrottle(AnonRateThrottle):
    scope = "register"
    rate = "3/hour"

class SearchThrottle(UserRateThrottle):
    scope = "search"
    rate = "30/minute"

# Apply per-view
class LoginView(APIView):
    throttle_classes = [LoginThrottle]
    ...

class RegisterView(APIView):
    throttle_classes = [RegisterThrottle]
    ...
```

### Wildcard Path Matching
```python
# WAF rule with wildcard
RateLimitRule.objects.create(
    path_pattern="/api/v1/admin/*",
    limit=60,
    window_seconds=60,
    action="log",
    description="Monitor admin API usage",
)
```

## Red Flags

- Login endpoint without strict rate limiting (< 10/min)
- Upload endpoint without rate limiting
- Same rate limit for all endpoints
- WAF rules and DRF throttles conflicting on same endpoint

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
