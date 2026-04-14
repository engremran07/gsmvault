---
name: middleware-response
description: "Response processing middleware: adding headers, modifying responses. Use when: adding security headers, setting cookies, modifying response metadata, CORS headers."
---

# Response Processing Middleware

## When to Use
- Adding security headers to all responses (CSP, HSTS, X-Frame-Options)
- Setting cookies after response processing
- Adding timing/performance headers
- Modifying response headers for HTMX compatibility

## Rules
- Process the response AFTER `self.get_response(request)` returns
- NEVER modify response body content — too broad and risks corruption
- Adding headers is safe; removing framework headers is dangerous
- Keep response processing lightweight — it runs on every response
- Check `response.status_code` before adding conditional headers

## Patterns

### Adding Security Headers
```python
# app/middleware/security_headers.py
from collections.abc import Callable

from django.http import HttpRequest, HttpResponse


class SecurityHeadersMiddleware:
    """Add security headers to all responses."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)
        response["X-Content-Type-Options"] = "nosniff"
        response["X-Frame-Options"] = "DENY"
        response["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
        return response
```

### CSP Nonce (Existing Pattern)
```python
# app/middleware/csp_nonce.py
import secrets

class CSPNonceMiddleware:
    """Generate CSP nonce for inline scripts."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        # Attach nonce to request for templates
        request.csp_nonce = secrets.token_urlsafe(32)  # type: ignore[attr-defined]
        response = self.get_response(request)
        # Add CSP header with the nonce
        response["Content-Security-Policy"] = (
            f"script-src 'nonce-{request.csp_nonce}' 'strict-dynamic';"  # type: ignore[attr-defined]
        )
        return response
```

### HTMX Auth Redirect (Existing Pattern)
```python
# app/middleware/htmx_auth.py
class HtmxAuthMiddleware:
    """Return HX-Redirect for expired sessions on HTMX requests."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)

        # HTMX can't follow 302 redirects to login — send HX-Redirect header
        is_htmx = request.headers.get("HX-Request") == "true"
        is_redirect_to_login = (
            response.status_code == 302
            and "/login" in response.get("Location", "")
        )

        if is_htmx and is_redirect_to_login:
            response["HX-Redirect"] = response["Location"]

        return response
```

### Response Timing Header
```python
import time


class ResponseTimingMiddleware:
    """Add X-Response-Time header for performance monitoring."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        start = time.perf_counter()
        response = self.get_response(request)
        duration_ms = (time.perf_counter() - start) * 1000
        response["X-Response-Time"] = f"{duration_ms:.1f}ms"
        return response
```

### Conditional Headers
```python
class CacheControlMiddleware:
    """Set cache headers based on response type."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)

        # Only cache successful GET responses
        if request.method == "GET" and response.status_code == 200:
            if not response.has_header("Cache-Control"):
                content_type = response.get("Content-Type", "")
                if "text/html" in content_type:
                    response["Cache-Control"] = "no-cache, no-store, must-revalidate"
                elif "application/json" in content_type:
                    response["Cache-Control"] = "no-store"

        return response
```

## Anti-Patterns
- NEVER modify `response.content` — risks corrupting binary responses or encoding
- NEVER remove Django's built-in security headers (CSRF token header, etc.)
- NEVER set `Cache-Control: public` on authenticated responses
- NEVER add headers with user-supplied values without sanitization

## Red Flags
- Response body modification in middleware
- Missing `Content-Type` check before header logic
- Overriding headers set by Django's SecurityMiddleware

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/middleware/csp_nonce.py` — CSP nonce implementation
- `app/middleware/htmx_auth.py` — HTMX auth redirect
