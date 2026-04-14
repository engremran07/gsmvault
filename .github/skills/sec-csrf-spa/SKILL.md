---
name: sec-csrf-spa
description: "SPA CSRF: double-submit cookie pattern for API calls. Use when: building API-first frontends, JWT+CSRF hybrid, cross-origin API protection."
---

# SPA CSRF Protection

## When to Use

- API endpoints consumed by JavaScript frontends
- JWT authentication with CSRF protection
- Cross-origin API requests with cookie auth

## Rules

| Scenario | Pattern |
|----------|---------|
| Same-origin with session auth | Standard Django CSRF cookie + header |
| JWT API (no cookies) | CSRF not needed — no cookie-based auth |
| JWT + session hybrid | CSRF required for cookie-authenticated endpoints |

## Patterns

### DRF SessionAuthentication (CSRF Required)
```python
# api.py
from rest_framework.authentication import SessionAuthentication
from rest_framework.permissions import IsAuthenticated

class FirmwareViewSet(viewsets.ModelViewSet):
    authentication_classes = [SessionAuthentication]  # CSRF enforced
    permission_classes = [IsAuthenticated]
```

### DRF JWT-Only (No CSRF Needed)
```python
from rest_framework_simplejwt.authentication import JWTAuthentication

class FirmwareViewSet(viewsets.ModelViewSet):
    authentication_classes = [JWTAuthentication]  # No cookies = no CSRF
    permission_classes = [IsAuthenticated]
```

### Double-Submit Cookie Pattern
```python
# settings.py
CSRF_COOKIE_HTTPONLY = False  # JS must read the cookie
CSRF_COOKIE_SAMESITE = "Lax"
CSRF_COOKIE_SECURE = True
```

```javascript
// Frontend reads CSRF cookie and sends as header
const csrfToken = getCookie('csrftoken');
fetch('/api/v1/firmware/', {
    method: 'POST',
    headers: {
        'X-CSRFToken': csrfToken,
        'Content-Type': 'application/json',
    },
    credentials: 'include',
    body: JSON.stringify(payload),
});
```

### Ensure CSRF Cookie Is Set
```python
from django.views.decorators.csrf import ensure_csrf_cookie

@ensure_csrf_cookie
def get_csrf_token(request: HttpRequest) -> JsonResponse:
    """Endpoint to set CSRF cookie for SPA frontends."""
    return JsonResponse({"detail": "CSRF cookie set"})
```

## Red Flags

- `SessionAuthentication` without CSRF enforcement
- `CSRF_COOKIE_HTTPONLY = True` when JS needs to read the cookie
- Missing `credentials: 'include'` on cross-origin fetch
- Disabling CSRF globally instead of per-authentication-class

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
