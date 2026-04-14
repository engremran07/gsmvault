---
name: htmx-request-branching
description: "HX-Request header detection for dual-mode views. Use when: serving both full pages and HTMX fragments from the same view, detecting HTMX requests, branching view logic."
---

# HTMX Request Branching

## When to Use

- A view must return a full page for direct navigation AND a fragment for HTMX requests
- Building progressive enhancement where pages work without JavaScript
- Any endpoint that HTMX calls via `hx-get`, `hx-post`, etc.

## Rules

1. Check `request.headers.get("HX-Request")` — returns `"true"` string or `None`
2. Fragment templates go in `templates/<app>/fragments/` — NEVER use `{% extends %}`
3. Full-page templates extend a layout — `{% extends "layouts/default.html" %}`
4. Never return JSON from an HTMX view — return rendered HTML fragments
5. Share the same queryset/context between both branches

## Patterns

### Standard Dual-Mode View

```python
def firmware_list(request):
    firmwares = Firmware.objects.filter(is_active=True).select_related("brand")
    context = {"firmwares": firmwares}

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/firmware_list.html", context)
    return render(request, "firmwares/firmware_list.html", context)
```

### With Pagination

```python
from django.core.paginator import Paginator

def topic_list(request, category_slug):
    topics = ForumTopic.objects.filter(category__slug=category_slug)
    paginator = Paginator(topics, 20)
    page = paginator.get_page(request.GET.get("page", 1))
    context = {"page_obj": page, "category_slug": category_slug}

    if request.headers.get("HX-Request"):
        return render(request, "forum/fragments/topic_rows.html", context)
    return render(request, "forum/fragments/../topic_list.html", context)
```

### Fragment Template (NO extends)

```html
{# templates/firmwares/fragments/firmware_list.html #}
{% for fw in firmwares %}
<div class="card" id="fw-{{ fw.pk }}">
  <h3>{{ fw.name }}</h3>
  <span class="badge">{{ fw.get_file_type_display }}</span>
</div>
{% empty %}
{% include "components/_empty_state.html" with message="No firmware found" %}
{% endfor %}
```

## Anti-Patterns

```python
# WRONG — checking META instead of headers
if request.META.get("HTTP_HX_REQUEST"):  # fragile, use headers

# WRONG — returning JSON for HTMX
if request.headers.get("HX-Request"):
    return JsonResponse({"items": list(qs.values())})  # HTMX expects HTML

# WRONG — fragment extends a layout
{% extends "layouts/default.html" %}  {# FORBIDDEN in fragments #}
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| `{% extends %}` in fragments/ | Fragment wraps full page | Remove extends, make standalone |
| `JsonResponse` in HTMX branch | HTMX expects HTML | Return `render()` with template |
| No `select_related` on queryset | N+1 queries on fragment reload | Add `select_related`/`prefetch_related` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
