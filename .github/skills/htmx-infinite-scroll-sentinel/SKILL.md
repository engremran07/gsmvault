---
name: htmx-infinite-scroll-sentinel
description: "Infinite scroll with sentinel element. Use when: loading more items automatically as user scrolls, paginated lists with auto-load, forum topic lists, firmware catalogs."
---

# HTMX Infinite Scroll with Sentinel

## When to Use

- Auto-loading next page of results as user scrolls to bottom
- Forum topic/reply lists, firmware catalogs, blog post feeds
- Any paginated list where load-more should be automatic

## Rules

1. Place a sentinel `<div>` at the end of the list with `hx-trigger="revealed"`
2. The sentinel loads the next page and replaces itself with new items + a new sentinel
3. Stop when there are no more pages — don't render a sentinel
4. Use `hx-swap="outerHTML"` on the sentinel so it replaces itself
5. Handle the empty/end state gracefully

## Patterns

### Sentinel Element in List

```html
{# templates/forum/fragments/topic_rows.html #}
{% for topic in page_obj %}
<div class="topic-card border-b p-4">
  <a href="{{ topic.get_absolute_url }}">{{ topic.title }}</a>
  <span class="text-sm text-[var(--color-text-muted)]">{{ topic.created_at|timesince }} ago</span>
</div>
{% endfor %}

{% if page_obj.has_next %}
<div hx-get="?page={{ page_obj.next_page_number }}"
     hx-trigger="revealed"
     hx-target="this"
     hx-swap="outerHTML"
     hx-indicator="#scroll-loader">
  <div id="scroll-loader" class="htmx-indicator py-4 text-center">
    {% include "components/_loading.html" with size="sm" %}
  </div>
</div>
{% endif %}
```

### Django View for Infinite Scroll

```python
from django.core.paginator import Paginator

def topic_list(request, category_slug):
    topics = ForumTopic.objects.filter(
        category__slug=category_slug
    ).select_related("author", "category").order_by("-created_at")

    paginator = Paginator(topics, 20)
    page = paginator.get_page(request.GET.get("page", 1))
    context = {"page_obj": page}

    if request.headers.get("HX-Request"):
        return render(request, "forum/fragments/topic_rows.html", context)
    return render(request, "forum/topic_list.html", context)
```

### Full Page Template

```html
{# templates/forum/topic_list.html #}
{% extends "layouts/default.html" %}
{% block content %}
<h1>Topics</h1>
<div id="topic-list">
  {% include "forum/fragments/topic_rows.html" %}
</div>
{% endblock %}
```

## Anti-Patterns

```html
<!-- WRONG — sentinel inside the target (causes nested targets) -->
<div id="list" hx-target="#list">
  <div hx-get="?page=2" hx-trigger="revealed" hx-target="#list" hx-swap="beforeend">

<!-- WRONG — sentinel doesn't replace itself (duplicates appear) -->
<div hx-get="?page=2" hx-trigger="revealed" hx-swap="innerHTML">
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Sentinel still present on last page | Infinite loop of empty requests | Only render sentinel if `has_next` |
| `hx-swap="innerHTML"` on sentinel | Content nests instead of appending | Use `hx-swap="outerHTML"` |
| No loading indicator | User doesn't know more is loading | Add `hx-indicator` on sentinel |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
