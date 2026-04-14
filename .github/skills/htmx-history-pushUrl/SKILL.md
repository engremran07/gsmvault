---
name: htmx-history-pushUrl
description: "URL push with hx-push-url for browser history. Use when: updating the URL bar during HTMX navigation, enabling back/forward button support, making HTMX pages bookmarkable."
---

# HTMX History Push URL

## When to Use

- Tab navigation where each tab should have a unique URL
- Filtering/search where the URL should reflect current filters
- Paginated lists where page changes update the URL
- Any HTMX interaction that should be bookmarkable

## Rules

1. Use `hx-push-url="true"` to push the request URL to browser history
2. Use `hx-push-url="/custom/path/"` to push a custom URL
3. The server MUST be able to serve the full page at that URL (for direct navigation)
4. Combine with request branching — full page on direct visit, fragment on HTMX

## Patterns

### Tab Navigation with URL Push

```html
<nav class="flex gap-2">
  <a hx-get="{% url 'firmwares:list' %}?type=official"
     hx-target="#firmware-content"
     hx-push-url="true"
     class="tab-link">Official</a>
  <a hx-get="{% url 'firmwares:list' %}?type=modified"
     hx-target="#firmware-content"
     hx-push-url="true"
     class="tab-link">Modified</a>
</nav>
<div id="firmware-content">
  {% include "firmwares/fragments/firmware_list.html" %}
</div>
```

### Paginated List with URL Push

```html
{# templates/firmwares/fragments/firmware_list.html #}
{% for fw in page_obj %}
<div class="card">{{ fw.name }}</div>
{% endfor %}

{% if page_obj.has_next %}
<a hx-get="?page={{ page_obj.next_page_number }}"
   hx-target="#firmware-list"
   hx-swap="innerHTML"
   hx-push-url="true">
  Next Page
</a>
{% endif %}
```

### View Supporting Both Modes

```python
def firmware_list(request):
    fw_type = request.GET.get("type", "official")
    firmwares = Firmware.objects.filter(file_type=fw_type)
    paginator = Paginator(firmwares, 20)
    page = paginator.get_page(request.GET.get("page", 1))
    context = {"page_obj": page, "fw_type": fw_type}

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/firmware_list.html", context)
    return render(request, "firmwares/firmware_list.html", context)
```

## Anti-Patterns

```html
<!-- WRONG — push URL on a DELETE action -->
<button hx-delete="/api/item/5/" hx-push-url="true">  {# URL to deleted item = 404 #}

<!-- WRONG — push URL without full-page fallback -->
<div hx-get="/fragment-only/" hx-push-url="true">  {# direct visit = broken page #}
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| `hx-push-url` on POST/DELETE | Pushes URL to non-GET endpoint | Only use on GET requests |
| No full-page fallback for pushed URL | Direct navigation breaks | Ensure view serves full page |
| Every request pushes URL | History pollution | Only push on meaningful navigation |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
