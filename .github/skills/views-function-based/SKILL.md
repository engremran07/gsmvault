---
name: views-function-based
description: "Function-based view patterns with decorator stacking. Use when: creating simple views, decorator usage, request/response handling, template rendering."
---

# Function-Based Views

## When to Use
- Simple endpoints with one HTTP method or a clean GET/POST split
- Views that serve both full pages and HTMX fragments
- Endpoints requiring multiple stacked decorators
- Quick API endpoints that don't need full DRF

## Rules
- Views are thin orchestrators — delegate logic to `services.py`
- Every mutating view MUST have CSRF protection (default in Django)
- Use `@require_http_methods` to restrict allowed methods
- Views CAN import from multiple apps — they are orchestrators
- Always return `HttpResponse` or subclass — never bare strings
- HTMX detection: `request.headers.get("HX-Request")`

## Patterns

### Standard Page View
```python
from django.shortcuts import render, get_object_or_404
from django.views.decorators.http import require_GET

from .models import Firmware
from .services import get_firmware_with_stats

@require_GET
def firmware_detail(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = get_firmware_with_stats(pk)
    return render(request, "firmwares/detail.html", {"firmware": firmware})
```

### HTMX-Aware View (Full Page + Fragment)
```python
@require_GET
def firmware_list(request: HttpRequest) -> HttpResponse:
    firmwares = Firmware.objects.filter(is_active=True).select_related("brand")
    paginator = Paginator(firmwares, 20)
    page_obj = paginator.get_page(request.GET.get("page"))

    context = {"page_obj": page_obj, "firmwares": page_obj}

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", context)
    return render(request, "firmwares/list.html", context)
```

### Decorator Stacking Order
```python
from django.contrib.auth.decorators import login_required, user_passes_test
from django.views.decorators.http import require_POST

@require_POST
@login_required
@user_passes_test(lambda u: u.is_staff)
def approve_firmware(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = get_object_or_404(Firmware, pk=pk)
    approve_firmware_submission(firmware, approved_by=request.user)
    messages.success(request, f"Firmware {firmware.name} approved.")
    return redirect("admin:firmwares_list")
```

### Form Handling (GET + POST)
```python
from django.views.decorators.http import require_http_methods

@require_http_methods(["GET", "POST"])
@login_required
def create_topic(request: HttpRequest, category_slug: str) -> HttpResponse:
    category = get_object_or_404(ForumCategory, slug=category_slug)

    if request.method == "POST":
        form = TopicForm(request.POST)
        if form.is_valid():
            topic = create_new_topic(
                category=category,
                author=request.user,
                **form.cleaned_data,
            )
            return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)
    else:
        form = TopicForm()

    return render(request, "forum/create_topic.html", {"form": form, "category": category})
```

### JSON Response View
```python
from django.http import JsonResponse
from django.views.decorators.http import require_GET

@require_GET
def api_firmware_status(request: HttpRequest, pk: int) -> JsonResponse:
    firmware = get_object_or_404(Firmware, pk=pk)
    return JsonResponse({
        "id": firmware.pk,
        "name": firmware.name,
        "status": firmware.status,
    })
```

## Anti-Patterns
- Business logic in views — move to `services.py`
- Missing `@require_http_methods` — allows unintended methods
- Returning raw strings — always return `HttpResponse` objects
- Catching all exceptions in views — let Django handle 500s
- Querying without `select_related` / `prefetch_related` — causes N+1

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Views](https://docs.djangoproject.com/en/5.2/topics/http/views/)
