---
name: views-pagination
description: "Pagination patterns: Paginator, page_obj, DRF cursor pagination. Use when: paginating lists, HTMX infinite scroll, API pagination, cursor-based pagination."
---

# Pagination Patterns

## When to Use
- Any list view showing more than ~20 items
- HTMX-powered infinite scroll or load-more
- DRF API endpoints returning collections
- Search result pages

## Rules
- Use Django's `Paginator` for template views — DRF pagination for API views
- Always use `{% include "components/_pagination.html" %}` — never inline pagination HTML
- HTMX pagination: fragment returns paginated items + pagination controls
- Cursor pagination for large API datasets (avoids COUNT query)
- Default page size: 20 items

## Patterns

### Basic Paginator in View
```python
from django.core.paginator import Paginator

@require_GET
def firmware_list(request: HttpRequest) -> HttpResponse:
    firmwares = Firmware.objects.filter(is_active=True).select_related("brand").order_by("-created_at")
    paginator = Paginator(firmwares, 20)  # 20 per page
    page_obj = paginator.get_page(request.GET.get("page"))

    context = {"page_obj": page_obj, "firmwares": page_obj}

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", context)
    return render(request, "firmwares/list.html", context)
```

### Template with Pagination Component
```html
<!-- firmwares/list.html -->
{% extends "layouts/default.html" %}
{% block content %}
<div id="firmware-list">
    {% include "firmwares/fragments/list.html" %}
</div>
{% endblock %}

<!-- firmwares/fragments/list.html -->
{% for firmware in page_obj %}
    {% include "firmwares/fragments/firmware_card.html" %}
{% endfor %}

{% include "components/_pagination.html" with page_obj=page_obj %}
```

### HTMX Infinite Scroll
```html
<!-- firmwares/fragments/list.html -->
{% for firmware in page_obj %}
<div class="firmware-card">{{ firmware.name }}</div>
{% endfor %}

{% if page_obj.has_next %}
<div hx-get="?page={{ page_obj.next_page_number }}"
     hx-trigger="revealed"
     hx-swap="afterend"
     hx-target="this">
    {% include "components/_loading.html" %}
</div>
{% endif %}
```

### HTMX Load-More Button
```html
{% if page_obj.has_next %}
<button hx-get="?page={{ page_obj.next_page_number }}"
        hx-target="#firmware-list"
        hx-swap="beforeend"
        class="btn btn-secondary">
    Load More
</button>
{% endif %}
```

### CBV Pagination
```python
class FirmwareListView(ListView):
    model = Firmware
    template_name = "firmwares/list.html"
    context_object_name = "firmwares"
    paginate_by = 20
    ordering = ["-created_at"]

    def get_queryset(self) -> QuerySet[Firmware]:
        return Firmware.objects.filter(is_active=True).select_related("brand")
```

### DRF Cursor Pagination (API)
```python
# apps/api/pagination.py
from rest_framework.pagination import CursorPagination

class FirmwareCursorPagination(CursorPagination):
    page_size = 20
    ordering = "-created_at"
    cursor_query_param = "cursor"

# In viewset:
class FirmwareViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Firmware.objects.filter(is_active=True)
    serializer_class = FirmwareSerializer
    pagination_class = FirmwareCursorPagination
```

### Paginator with Count Optimization
```python
# For very large tables, avoid COUNT(*):
from django.core.paginator import Paginator

class NoCOuntPaginator(Paginator):
    @property
    def count(self) -> int:
        return 999999  # Skip expensive COUNT query

# Or use cursor pagination (DRF) which avoids COUNT entirely
```

## Anti-Patterns
- Inline pagination HTML — always use `{% include "components/_pagination.html" %}`
- Missing `order_by()` on paginated querysets — results are nondeterministic
- Using offset pagination for large API datasets — use cursor pagination
- Not passing `page_obj` to the pagination component — nothing renders
- Paginating unsorted querysets — pages will have inconsistent results

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Paginator](https://docs.djangoproject.com/en/5.2/topics/pagination/)
- `templates/components/_pagination.html` — reusable pagination component
