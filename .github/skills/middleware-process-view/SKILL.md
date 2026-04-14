---
name: middleware-process-view
description: "View-level middleware: process_view for auth/perm checking. Use when: adding view-level checks, pre-view validation, conditional view bypassing."
---

# View-Level Middleware (process_view)

## When to Use
- Running checks after URL resolution but before the view executes
- Enforcing permissions based on the resolved view function
- Attaching view-specific metadata to the request
- Conditionally bypassing views (e.g., redirect before view runs)

## Rules
- `process_view(request, view_func, view_args, view_kwargs)` runs after URL resolving
- Return `None` to continue to the view normally
- Return `HttpResponse` to short-circuit (view never executes)
- Access the resolved view function and its kwargs for conditional logic
- This is more targeted than `__call__` — use when view identity matters

## Patterns

### View-Level Permission Check
```python
# app/middleware/staff_pages.py
from collections.abc import Callable
from typing import Any

from django.http import HttpRequest, HttpResponse, HttpResponseForbidden


class StaffPageMiddleware:
    """Enforce staff-only access for admin panel views."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        return self.get_response(request)

    def process_view(
        self,
        request: HttpRequest,
        view_func: Callable[..., HttpResponse],
        view_args: tuple[Any, ...],
        view_kwargs: dict[str, Any],
    ) -> HttpResponse | None:
        # Check if view has staff_required marker
        if getattr(view_func, "_staff_required", False):
            if not getattr(request.user, "is_staff", False):
                return HttpResponseForbidden("Staff access required.")
        return None
```

### Consent Enforcement
```python
class ConsentCheckMiddleware:
    """Check consent status before views that require it."""

    CONSENT_EXEMPT_PATHS = ("/consent/", "/api/v1/consent/", "/accounts/login/")

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        return self.get_response(request)

    def process_view(
        self,
        request: HttpRequest,
        view_func: Callable[..., HttpResponse],
        view_args: tuple[Any, ...],
        view_kwargs: dict[str, Any],
    ) -> HttpResponse | None:
        # Skip exempt paths
        if any(request.path.startswith(p) for p in self.CONSENT_EXEMPT_PATHS):
            return None

        # Skip if view is decorated as consent-exempt
        if getattr(view_func, "_consent_exempt", False):
            return None

        # Check if user needs consent prompt
        from apps.consent.utils import needs_consent_prompt
        if needs_consent_prompt(request):
            from django.shortcuts import redirect
            return redirect("consent:prompt")

        return None
```

### View Decorator Marker Pattern
```python
# Used with process_view middleware
from functools import wraps
from typing import Any


def staff_required(view_func: Callable[..., Any]) -> Callable[..., Any]:
    """Mark a view as requiring staff access — enforced by middleware."""
    @wraps(view_func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        return view_func(*args, **kwargs)
    wrapper._staff_required = True  # type: ignore[attr-defined]
    return wrapper


# Usage
@staff_required
def admin_dashboard(request: HttpRequest) -> HttpResponse:
    return render(request, "admin/dashboard.html")
```

### Rate Limit per View
```python
class ViewRateLimitMiddleware:
    """Apply rate limits based on view function metadata."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        return self.get_response(request)

    def process_view(
        self,
        request: HttpRequest,
        view_func: Callable[..., HttpResponse],
        view_args: tuple[Any, ...],
        view_kwargs: dict[str, Any],
    ) -> HttpResponse | None:
        rate_limit = getattr(view_func, "_rate_limit", None)
        if rate_limit is None:
            return None

        from apps.core.utils import get_client_ip
        from django.core.cache import cache

        ip = get_client_ip(request)
        cache_key = f"rl:{view_func.__name__}:{ip}"
        count = cache.get(cache_key, 0)

        if count >= rate_limit:
            from django.http import HttpResponseTooManyRequests
            return HttpResponseTooManyRequests("Rate limit exceeded.")

        cache.set(cache_key, count + 1, timeout=60)
        return None
```

## Anti-Patterns
- NEVER do expensive DB queries in `process_view` — runs on every view
- NEVER modify `view_kwargs` — pass data via `request` attributes instead
- NEVER re-implement Django's decorators (`@login_required`) in middleware
- NEVER use `process_view` when `__call__` path-check is sufficient

## Red Flags
- `process_view` without `return None` fallthrough — blocks all views
- Heavy computation in `process_view` on every request
- Duplicating `@login_required` logic that Django handles natively

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/middleware/` — existing middleware implementations
- `.claude/rules/middleware-layer.md` — middleware conventions
