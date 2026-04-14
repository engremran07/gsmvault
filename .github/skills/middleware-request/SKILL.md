---
name: middleware-request
description: "Request processing middleware: process_request patterns. Use when: adding pre-view request processing, IP blocking, request logging, header injection."
---

# Request Processing Middleware

## When to Use
- Adding pre-view request processing (before any view executes)
- Blocking requests by IP, path, or header
- Attaching computed attributes to `request` for downstream use
- Logging request metadata for analytics

## Rules
- Use class-based middleware with `__init__(self, get_response)` and `__call__(self, request)`
- Middleware runs on EVERY request — must be lightweight
- NEVER do heavy DB queries — cache lookups if needed
- Short-circuit early when middleware doesn't apply to current request
- NEVER modify request body — only attach new attributes
- Place in `app/middleware/` with one file per middleware

## Patterns

### Basic Request Middleware
```python
# app/middleware/request_id.py
import uuid
from collections.abc import Callable

from django.http import HttpRequest, HttpResponse


class RequestIDMiddleware:
    """Attach a unique request ID to every request."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        request.request_id = str(uuid.uuid4())  # type: ignore[attr-defined]
        response = self.get_response(request)
        response["X-Request-ID"] = request.request_id  # type: ignore[attr-defined]
        return response
```

### Early Short-Circuit (Path Filtering)
```python
# app/middleware/maintenance.py
from django.http import HttpRequest, HttpResponse, HttpResponseServiceUnavailable


class MaintenanceMiddleware:
    """Return 503 for non-admin paths during maintenance."""

    EXEMPT_PATHS = ("/admin-panel/", "/api/v1/health/")

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        from apps.site_settings.models import SiteSettings

        # Skip check for exempt paths
        if any(request.path.startswith(p) for p in self.EXEMPT_PATHS):
            return self.get_response(request)

        # Cache the setting to avoid per-request DB hit
        from django.core.cache import cache
        maintenance = cache.get("maintenance_mode")
        if maintenance is None:
            settings = SiteSettings.get_solo()
            maintenance = getattr(settings, "maintenance_mode", False)
            cache.set("maintenance_mode", maintenance, timeout=30)

        if maintenance:
            return HttpResponseServiceUnavailable("Site under maintenance.")

        return self.get_response(request)
```

### Attaching Request Attributes
```python
# app/middleware/client_info.py
from apps.core.utils import get_client_ip


class ClientInfoMiddleware:
    """Attach client IP and user-agent to request for downstream use."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        request.client_ip = get_client_ip(request)  # type: ignore[attr-defined]
        request.user_agent = request.META.get("HTTP_USER_AGENT", "")  # type: ignore[attr-defined]
        return self.get_response(request)
```

### Registration in Settings
```python
# app/settings.py
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    # Custom middleware — after auth, before views
    "app.middleware.csp_nonce.CSPNonceMiddleware",
    "app.middleware.htmx_auth.HtmxAuthMiddleware",
]
```

## Anti-Patterns
- NEVER call external APIs from middleware — blocks the entire request
- NEVER execute raw DB queries on every request — use caching
- NEVER modify `request.POST` or `request.body` — unexpected side effects
- NEVER log PII (passwords, tokens) in request middleware
- NEVER add middleware that duplicates existing Django middleware

## Red Flags
- Missing `get_response` call — middleware breaks the chain
- No early return for exempt paths — unnecessary processing
- Uncached database query inside `__call__`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/middleware/` — existing middleware implementations
- `.claude/rules/middleware-layer.md` — middleware layer rules
