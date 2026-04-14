---
name: middleware-exception
description: "Exception handling middleware: process_exception patterns. Use when: adding global error handling, logging unhandled exceptions, custom error responses."
---

# Exception Handling Middleware

## When to Use
- Adding global exception logging without changing every view
- Returning custom error responses for specific exception types
- Logging exceptions to `SecurityEvent` or external monitoring
- Converting exceptions to JSON for API endpoints

## Rules
- Use `process_exception(self, request, exception)` method
- Return `None` to let Django's default exception handling continue
- Return `HttpResponse` to replace the default error page
- NEVER expose exception details in production — check `settings.DEBUG`
- ALWAYS log the exception with `exc_info=True` for traceback
- Wrap all middleware in try/except — middleware must never crash the cycle

## Patterns

### Global Exception Logger
```python
# app/middleware/exception_logger.py
import logging
from collections.abc import Callable

from django.conf import settings
from django.http import HttpRequest, HttpResponse

logger = logging.getLogger("django.request")


class ExceptionLoggingMiddleware:
    """Log all unhandled exceptions with request context."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        return self.get_response(request)

    def process_exception(self, request: HttpRequest, exception: Exception) -> None:
        logger.error(
            "Unhandled exception on %s %s",
            request.method,
            request.path,
            exc_info=True,
            extra={
                "request_path": request.path,
                "request_method": request.method,
                "user_id": getattr(request.user, "pk", None),
            },
        )
        # Return None — let Django handle the error response
        return None
```

### API Exception Handler
```python
import json

from django.http import JsonResponse


class APIExceptionMiddleware:
    """Return JSON errors for API endpoints instead of HTML error pages."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        return self.get_response(request)

    def process_exception(
        self, request: HttpRequest, exception: Exception
    ) -> JsonResponse | None:
        # Only handle API paths
        if not request.path.startswith("/api/"):
            return None

        logger.error("API exception: %s", exception, exc_info=True)

        if settings.DEBUG:
            detail = str(exception)
        else:
            detail = "An internal error occurred."

        return JsonResponse(
            {"error": detail, "code": "INTERNAL_ERROR"},
            status=500,
        )
```

### Security Exception Handler
```python
from django.core.exceptions import PermissionDenied, SuspiciousOperation
from django.http import HttpResponseForbidden


class SecurityExceptionMiddleware:
    """Log and handle security-related exceptions."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        return self.get_response(request)

    def process_exception(
        self, request: HttpRequest, exception: Exception
    ) -> HttpResponse | None:
        if isinstance(exception, SuspiciousOperation):
            logger.warning(
                "Suspicious operation from %s: %s",
                getattr(request, "client_ip", "unknown"),
                exception,
            )
            return HttpResponseForbidden("Forbidden")

        if isinstance(exception, PermissionDenied):
            logger.info("Permission denied: %s %s", request.method, request.path)
            # Return None — let Django's 403 handler take over
            return None

        return None
```

### Safe Middleware Wrapper
```python
class SafeMiddleware:
    """Middleware must never crash — wrap in try/except."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        try:
            # Pre-processing
            self._attach_metadata(request)
        except Exception:
            logger.exception("Middleware pre-processing failed")
            # Continue normally — don't break the request

        return self.get_response(request)

    def _attach_metadata(self, request: HttpRequest) -> None:
        # Potentially risky operation
        pass
```

## Anti-Patterns
- NEVER expose exception tracebacks in production responses
- NEVER swallow exceptions silently — always log with `exc_info=True`
- NEVER return `HttpResponse` for exceptions you don't fully understand
- NEVER import view-specific exceptions in generic middleware

## Red Flags
- `except Exception: pass` — swallowing errors
- `str(exception)` returned to client without `DEBUG` check
- `process_exception` returning `HttpResponse` for all exception types

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/middleware/` — existing middleware
- `apps/core/exceptions.py` — `json_error_response()` helper
