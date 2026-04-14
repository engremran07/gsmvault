---
name: sec-session-hijacking
description: "Session hijacking prevention: secure cookies, IP binding. Use when: hardening session security, configuring cookie flags."
---

# Session Hijacking Prevention

## When to Use

- Configuring session cookie security
- Adding IP-based session validation
- Detecting suspicious session reuse

## Rules

| Defense | Setting |
|---------|---------|
| HTTPS-only cookie | `SESSION_COOKIE_SECURE = True` |
| No JS access | `SESSION_COOKIE_HTTPONLY = True` |
| SameSite | `SESSION_COOKIE_SAMESITE = "Lax"` |
| Short lifetime | `SESSION_COOKIE_AGE = 1209600` (2 weeks max) |

## Patterns

### Complete Session Cookie Configuration
```python
# settings_production.py
SESSION_COOKIE_SECURE = True       # HTTPS only
SESSION_COOKIE_HTTPONLY = True      # No document.cookie access
SESSION_COOKIE_SAMESITE = "Lax"    # CSRF mitigation
SESSION_COOKIE_AGE = 1209600       # 2 weeks
SESSION_COOKIE_DOMAIN = ".yourdomain.com"
SESSION_COOKIE_NAME = "__Host-sessionid"  # Cookie prefix for extra security
```

### IP Binding Middleware (Optional Extra Security)
```python
from apps.core.utils import get_client_ip

class SessionIPBindingMiddleware:
    def __call__(self, request):
        if request.user.is_authenticated:
            current_ip = get_client_ip(request)
            stored_ip = request.session.get("bound_ip")
            if stored_ip is None:
                request.session["bound_ip"] = current_ip
            elif stored_ip != current_ip:
                # IP changed — log event, optionally invalidate
                from apps.security.models import SecurityEvent
                SecurityEvent.objects.create(
                    event_type="session_ip_change",
                    ip_address=current_ip,
                    user=request.user,
                    details=f"IP changed from {stored_ip} to {current_ip}",
                )
                # For strict security: request.session.flush()
        return self.get_response(request)
```

### User-Agent Fingerprint Check
```python
import hashlib

class SessionFingerprintMiddleware:
    def __call__(self, request):
        if request.user.is_authenticated:
            ua = request.META.get("HTTP_USER_AGENT", "")
            fingerprint = hashlib.sha256(ua.encode()).hexdigest()[:16]
            stored = request.session.get("ua_fingerprint")
            if stored is None:
                request.session["ua_fingerprint"] = fingerprint
            elif stored != fingerprint:
                request.session.flush()
                return redirect("users:login")
        return self.get_response(request)
```

## Red Flags

- `SESSION_COOKIE_SECURE = False` in production
- `SESSION_COOKIE_HTTPONLY = False` (allows JS theft)
- Session IDs in URL parameters
- No session expiry configured

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
