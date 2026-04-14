---
applyTo: 'app/middleware/*.py'
---

# Django Middleware Conventions

## Structure

Implement the ASGI/WSGI-compatible callable pattern:

```python
from django.http import HttpRequest, HttpResponse
import logging

logger = logging.getLogger(__name__)

class SecurityHeadersMiddleware:
    """Add security headers to all responses."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)
        response["X-Frame-Options"] = "DENY"
        response["X-Content-Type-Options"] = "nosniff"
        response["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response
```

## Middleware Ordering

Security middleware MUST be at the top of the `MIDDLEWARE` stack:

```python
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "app.middleware.csp_nonce.CSPNonceMiddleware",        # CSP nonce generation
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "apps.consent.middleware.ConsentMiddleware",           # Consent enforcement
    "apps.security.middleware.WAFMiddleware",              # WAF rate limiting
    # ...
]
```

## Error Handling

Log errors but do NOT raise exceptions — middleware must not break the request pipeline:

```python
def __call__(self, request: HttpRequest) -> HttpResponse:
    try:
        # Pre-processing
        self._check_rate_limit(request)
    except Exception:
        logger.exception("Middleware error in rate limit check")
        # Continue processing — don't block the request

    response = self.get_response(request)

    try:
        # Post-processing
        self._add_headers(response)
    except Exception:
        logger.exception("Middleware error in header addition")

    return response
```

## No External Blocking Calls

Never make synchronous external API calls in middleware — it blocks every request:

```python
# WRONG — blocks all requests
class AnalyticsMiddleware:
    def __call__(self, request):
        requests.post("https://analytics.example.com/track", ...)  # BLOCKS!
        return self.get_response(request)

# CORRECT — defer to async task
class AnalyticsMiddleware:
    def __call__(self, request):
        response = self.get_response(request)
        track_pageview.delay(request.path, request.user.pk)  # Celery task
        return response
```

## Process View Hook

Use `process_view` for view-specific middleware logic:

```python
def process_view(
    self,
    request: HttpRequest,
    view_func: Callable,
    view_args: tuple,
    view_kwargs: dict,
) -> HttpResponse | None:
    if getattr(view_func, "csrf_exempt", False):
        return None  # Skip for exempt views
    # Perform check...
    return None  # Return None to continue processing
```

## Process Exception Hook

Use `process_exception` for global error handling:

```python
def process_exception(
    self, request: HttpRequest, exception: Exception
) -> HttpResponse | None:
    logger.exception("Unhandled exception: %s", exception)
    if settings.DEBUG:
        return None  # Let Django's debug page handle it
    return json_error_response(
        error="Internal server error",
        code="INTERNAL_ERROR",
        status=500,
    )
```

## CSP Nonce Middleware

The existing `app/middleware/csp_nonce.py` generates CSP nonces for inline scripts.
All inline `<script>` tags must use `nonce="{{ csp_nonce }}"` in templates.

## Type Hints

Full type hints on all methods:

```python
from collections.abc import Callable

class MyMiddleware:
    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        ...
```
