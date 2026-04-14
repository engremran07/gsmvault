---
name: sec-rate-limit-ip
description: "IP-based rate limiting: RateLimitRule in apps.security. Use when: configuring WAF rate limits, blocking abusive IPs, path-based limits."
---

# IP-Based Rate Limiting (WAF)

## When to Use

- Protecting against DDoS and brute-force attacks
- Configuring per-path rate limits
- Blocking abusive IP addresses

**IMPORTANT**: This is the WAF system in `apps.security` — NOT download quotas.

## Rules

| Model | Purpose |
|-------|---------|
| `RateLimitRule` | Per-path IP rate limits |
| `BlockedIP` | Permanent/timed IP blocks |
| `SecurityEvent` | Audit log of rate limit triggers |

## Patterns

### RateLimitRule Configuration
```python
# Via admin or fixture
RateLimitRule.objects.create(
    path_pattern="/api/v1/auth/login/",
    limit=5,                    # 5 requests
    window_seconds=300,         # per 5 minutes
    action="block",             # throttle | block | log
    description="Brute-force login protection",
)

RateLimitRule.objects.create(
    path_pattern="/api/v1/",
    limit=100,
    window_seconds=60,
    action="throttle",
    description="General API rate limit",
)
```

### Middleware Enforcement
```python
from apps.core.utils import get_client_ip

class WAFRateLimitMiddleware:
    def __call__(self, request):
        ip = get_client_ip(request)
        # Check blocked IPs first
        if BlockedIP.objects.filter(ip_address=ip, is_active=True).exists():
            return HttpResponse("Forbidden", status=403)
        # Check rate limit rules
        for rule in RateLimitRule.objects.filter(is_active=True):
            if self._path_matches(request.path, rule.path_pattern):
                if self._is_rate_limited(ip, rule):
                    SecurityEvent.objects.create(
                        event_type="rate_limited",
                        ip_address=ip,
                        path=request.path,
                    )
                    if rule.action == "block":
                        return HttpResponse("Rate limit exceeded", status=429)
        return self.get_response(request)
```

### IP Blocking
```python
from django.utils import timezone
from datetime import timedelta

# Temporary block (24 hours)
BlockedIP.objects.create(
    ip_address="1.2.3.4",
    reason="Repeated brute-force attempts",
    expires_at=timezone.now() + timedelta(hours=24),
    is_active=True,
)

# Permanent block
BlockedIP.objects.create(
    ip_address="5.6.7.8",
    reason="Confirmed malicious bot",
    expires_at=None,
    is_active=True,
)
```

## Red Flags

- Importing `RateLimitRule` in firmware code (wrong system)
- Rate limiting in views instead of middleware
- No logging of rate limit events
- Hardcoded IP addresses in code instead of `BlockedIP` model

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
