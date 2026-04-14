---
name: drf-error-handling
description: "Consistent error responses: custom exception handler, error codes. Use when: standardizing API error format, adding custom exception classes, error response middleware."
---

# DRF Error Handling

## When to Use
- Standardizing error response format across all API endpoints
- Adding custom exception classes with error codes
- Overriding DRF's default exception handler

## Rules
- Error format: `{"error": "human message", "code": "ERROR_CODE"}`
- Register custom exception handler in `REST_FRAMEWORK` settings
- Never expose stack traces or internal details in production
- Use `apps.core.exceptions.json_error_response()` for non-DRF views
- Map Django exceptions (404, PermissionDenied) to standard format

## Patterns

### Custom Exception Handler
```python
# apps/core/exception_handler.py
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.http import Http404
from django.core.exceptions import PermissionDenied
import logging

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    """Standardize all API error responses."""
    response = exception_handler(exc, context)

    if response is not None:
        error_data = _format_drf_error(response, exc)
        response.data = error_data
        return response

    # Handle non-DRF exceptions
    if isinstance(exc, Http404):
        return Response(
            {"error": "Not found", "code": "NOT_FOUND"},
            status=status.HTTP_404_NOT_FOUND,
        )

    if isinstance(exc, PermissionDenied):
        return Response(
            {"error": "Permission denied", "code": "PERMISSION_DENIED"},
            status=status.HTTP_403_FORBIDDEN,
        )

    # Unexpected error — log and return generic message
    logger.exception("Unhandled API exception", exc_info=exc)
    return Response(
        {"error": "Internal server error", "code": "INTERNAL_ERROR"},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


def _format_drf_error(response, exc) -> dict:
    """Convert DRF error data to standard format."""
    data = response.data

    # Validation errors (dict of field errors)
    if isinstance(data, dict) and not data.get("error"):
        if "detail" in data:
            return {
                "error": str(data["detail"]),
                "code": getattr(exc, "default_code", "ERROR"),
            }
        # Field validation errors
        return {
            "error": "Validation failed",
            "code": "VALIDATION_ERROR",
            "fields": {
                field: [str(e) for e in errors]
                for field, errors in data.items()
            },
        }

    # List of errors
    if isinstance(data, list):
        return {"error": str(data[0]), "code": "ERROR"}

    return data
```

### Settings Registration
```python
REST_FRAMEWORK = {
    "EXCEPTION_HANDLER": "apps.core.exception_handler.custom_exception_handler",
}
```

### Custom Exception Classes
```python
# apps/core/exceptions.py
from rest_framework.exceptions import APIException
from rest_framework import status

class QuotaExceeded(APIException):
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_detail = "Download quota exceeded."
    default_code = "QUOTA_EXCEEDED"

class PaymentRequired(APIException):
    status_code = status.HTTP_402_PAYMENT_REQUIRED
    default_detail = "Subscription required for this feature."
    default_code = "PAYMENT_REQUIRED"

class ResourceLocked(APIException):
    status_code = status.HTTP_423_LOCKED
    default_detail = "This resource is currently locked."
    default_code = "RESOURCE_LOCKED"
```

### Usage in Views/Services
```python
from apps.core.exceptions import QuotaExceeded

class DownloadViewSet(viewsets.ViewSet):
    def retrieve(self, request, pk=None):
        firmware = get_object_or_404(Firmware, pk=pk)
        from apps.firmwares.services import check_download_quota
        if not check_download_quota(request.user):
            raise QuotaExceeded()
        # ... proceed with download
```

### Consistent Manual Error Responses
```python
from rest_framework.response import Response
from rest_framework import status

# In a view:
return Response(
    {"error": "Invalid firmware format", "code": "INVALID_FORMAT"},
    status=status.HTTP_400_BAD_REQUEST,
)
```

### Response Examples
```json
// Validation error
{"error": "Validation failed", "code": "VALIDATION_ERROR",
 "fields": {"name": ["This field is required."], "version": ["Invalid format."]}}

// Auth error
{"error": "Authentication credentials were not provided.", "code": "NOT_AUTHENTICATED"}

// Custom error
{"error": "Download quota exceeded.", "code": "QUOTA_EXCEEDED"}
```

## Anti-Patterns
- Inconsistent error formats across endpoints → use the handler everywhere
- Exposing `traceback` or internal paths in error responses
- Catching exceptions silently → always log unexpected errors
- Using HTTP 200 for errors with `{"success": false}` → use proper status codes

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/core/exceptions.py` — platform exception classes
- Skill: `api-design` — API design conventions
