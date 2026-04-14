---
name: views-decorators
description: "Decorator patterns: @login_required, @permission_required, @require_http_methods. Use when: adding auth guards, method restrictions, caching to function-based views."
---

# View Decorators

## When to Use
- Restricting access to authenticated users
- Enforcing staff/superuser permissions
- Limiting allowed HTTP methods
- Adding per-view caching
- Rate limiting specific endpoints

## Rules
- Decorator order matters — outermost executes first
- `@require_http_methods` should be outermost (reject bad methods before auth)
- Use `getattr(request.user, "is_staff", False)` — never bare `request.user.is_staff`
- For CBVs, use mixins instead of decorators (or `method_decorator`)
- Never use `@csrf_exempt` unless building a webhook endpoint with alternative auth

## Patterns

### Standard Decorator Stack
```python
from django.contrib.auth.decorators import login_required, user_passes_test
from django.views.decorators.http import require_http_methods, require_GET, require_POST

# Order: method check → auth → permission
@require_POST
@login_required
@user_passes_test(lambda u: getattr(u, "is_staff", False))
def approve_firmware(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = get_object_or_404(Firmware, pk=pk)
    approve_firmware_submission(firmware, approved_by=request.user)
    return redirect("admin:firmwares_list")
```

### Method Restriction
```python
# Single method:
@require_GET
def firmware_list(request: HttpRequest) -> HttpResponse: ...

@require_POST
def firmware_delete(request: HttpRequest, pk: int) -> HttpResponse: ...

# Multiple methods:
@require_http_methods(["GET", "POST"])
def firmware_edit(request: HttpRequest, pk: int) -> HttpResponse: ...
```

### Custom Staff-Required Decorator
```python
from functools import wraps
from django.http import HttpResponseForbidden

def staff_required(view_func):
    """Decorator: requires authenticated staff user."""
    @wraps(view_func)
    def wrapper(request: HttpRequest, *args: Any, **kwargs: Any) -> HttpResponse:
        if not request.user.is_authenticated:
            return redirect(f"/login/?next={request.path}")
        if not getattr(request.user, "is_staff", False):
            return HttpResponseForbidden("Staff access required.")
        return view_func(request, *args, **kwargs)
    return wrapper

@staff_required
def admin_dashboard(request: HttpRequest) -> HttpResponse: ...
```

### Cache Decorator
```python
from django.views.decorators.cache import cache_page, never_cache

@cache_page(60 * 15)  # Cache for 15 minutes
@require_GET
def firmware_list(request: HttpRequest) -> HttpResponse:
    """Public list page — safe to cache."""
    ...

@never_cache
@login_required
def user_dashboard(request: HttpRequest) -> HttpResponse:
    """User-specific page — never cache."""
    ...
```

### Applying Decorators to CBVs
```python
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page

@method_decorator(cache_page(60 * 15), name="dispatch")
class FirmwareListView(ListView):
    model = Firmware
```

### HTMX-Only Endpoint Guard
```python
def htmx_required(view_func):
    """Only allow HTMX requests."""
    @wraps(view_func)
    def wrapper(request: HttpRequest, *args: Any, **kwargs: Any) -> HttpResponse:
        if not request.headers.get("HX-Request"):
            return HttpResponseBadRequest("HTMX request required.")
        return view_func(request, *args, **kwargs)
    return wrapper

@htmx_required
@require_GET
def search_fragment(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "")
    results = search_firmwares(query)
    return render(request, "firmwares/fragments/search_results.html", {"results": results})
```

### Decorator Execution Order
```
@require_POST       ← 1st: reject non-POST immediately
@login_required     ← 2nd: redirect unauthenticated
@staff_required     ← 3rd: check staff permission
def my_view(request): ...  ← 4th: actual view logic
```

## Anti-Patterns
- `@csrf_exempt` without alternative auth — CSRF bypass is a security vulnerability
- Decorators on CBVs without `method_decorator` — they won't work
- `@login_required` after `@require_POST` — check method first, then auth
- Using `@permission_required` without `login_url` — defaults to settings.LOGIN_URL
- Stacking too many decorators (5+) — consider a CBV with mixins

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django View Decorators](https://docs.djangoproject.com/en/5.2/topics/http/decorators/)
