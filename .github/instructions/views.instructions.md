---
applyTo: 'apps/*/views.py, apps/*/views_*.py'
---

# Django View Conventions

## Views Are Orchestrators

Views wire data from multiple apps and render templates. They CAN import from multiple apps.
Business logic MUST live in `services.py` — views stay thin.

```python
# CORRECT — view calls service
def firmware_approve(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = get_object_or_404(Firmware, pk=pk)
    approve_firmware(firmware, approved_by=request.user)  # service function
    return redirect("firmwares:detail", pk=pk)

# WRONG — logic in view
def firmware_approve(request, pk):
    firmware = Firmware.objects.get(pk=pk)
    firmware.status = "approved"
    firmware.approved_by = request.user
    firmware.save()
    AuditLog.objects.create(...)  # Business logic leaked into view
```

## HTMX Detection

Serve both full pages and HTMX fragments from the same view:

```python
def firmware_list(request: HttpRequest) -> HttpResponse:
    firmwares = Firmware.objects.filter(is_active=True)
    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", {"firmwares": firmwares})
    return render(request, "firmwares/list.html", {"firmwares": firmwares})
```

HTMX fragments MUST be standalone snippets — no `{% extends %}`.

## Authentication & Authorization

Anonymous-safe staff check — never access `request.user.is_staff` directly:

```python
if not getattr(request.user, "is_staff", False):
    raise PermissionDenied
```

Ownership checks — always scope by user:

```python
firmware = get_object_or_404(Firmware, pk=pk, user=request.user)
```

Use decorators for protection:

```python
@login_required
@require_http_methods(["GET", "POST"])
def my_view(request: HttpRequest) -> HttpResponse:
    ...
```

## Admin Views

Admin views in `apps/admin/views_*.py` use the shared `_render_admin` helper:

```python
from .views_shared import *

@login_required
@user_passes_test(lambda u: u.is_staff)
def admin_dashboard(request: HttpRequest) -> HttpResponse:
    return _render_admin(request, "admin/dashboard.html", context, breadcrumbs)
```

Never call `render()` directly in admin views — always use `_render_admin()`.

## Status Codes

- `200` — successful GET/PUT/PATCH
- `201` — successful POST (created)
- `204` — successful DELETE (no content)
- `301/302` — redirects
- `400` — bad request / validation error
- `403` — permission denied
- `404` — not found
- `422` — validation error (HTMX form pattern)

## Consent Views

Consent form views (`accept_all`, `reject_all`, `accept`) NEVER return JSON.
Always return `HttpResponseRedirect` to `HTTP_REFERER`. Cookie set on redirect response.
For JSON API: use `consent/api/status/` and `consent/api/update/` (separate DRF endpoints).

## Type Hints

All view functions must have return type annotations:

```python
def firmware_detail(request: HttpRequest, pk: int) -> HttpResponse:
    ...
```

## CSRF

CSRF protection is global via `<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>`.
Never add per-view CSRF handling for HTMX — it is already handled globally.
All forms must include `{% csrf_token %}`.
