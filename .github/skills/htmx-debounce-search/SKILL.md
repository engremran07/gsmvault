---
name: htmx-debounce-search
description: "Live search with debounce and minimum characters. Use when: building full-featured live search with minimum character enforcement, empty state, result counts."
---

# HTMX Live Search with Debounce

## When to Use

- Full-featured search with minimum character enforcement
- Search with result counts and empty states
- Inline search in admin panels, forums, firmware catalogs
- Any search that needs to be both fast and efficient

## Rules

1. Enforce minimum characters (2-3) to avoid overly broad queries
2. Show placeholder text when query is too short
3. Use `hx-trigger="keyup changed delay:300ms, search"` — includes clear button
4. Cancel in-flight requests with `hx-sync="this:replace"` to avoid race conditions
5. Use `{% include "components/_empty_state.html" %}` for no-results state

## Patterns

### Complete Live Search Component

```html
<div class="relative">
  <input type="search" name="q" id="firmware-search"
         hx-get="{% url 'firmwares:search' %}"
         hx-target="#search-results"
         hx-trigger="keyup changed delay:300ms, search"
         hx-sync="this:replace"
         hx-indicator="#search-indicator"
         hx-params="q"
         placeholder="Search firmware (min 2 chars)..."
         autocomplete="off"
         class="w-full px-4 py-2 rounded-lg bg-[var(--color-bg-secondary)]">
  <div id="search-indicator" class="htmx-indicator absolute right-3 top-3">
    <i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i>
  </div>
</div>
<div id="search-results" class="mt-4"></div>
```

### Django View with Min-Length Check

```python
def firmware_search(request):
    query = request.GET.get("q", "").strip()

    if len(query) < 2:
        if request.headers.get("HX-Request"):
            return HttpResponse(
                '<p class="text-sm text-[var(--color-text-muted)]">'
                'Type at least 2 characters to search</p>'
            )
        return render(request, "firmwares/search.html", {"query": query})

    results = Firmware.objects.filter(
        Q(name__icontains=query) | Q(description__icontains=query),
        is_active=True,
    ).select_related("brand", "model")[:25]

    context = {"results": results, "query": query, "count": results.count()}
    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/search_results.html", context)
    return render(request, "firmwares/search.html", context)
```

### Search Results Fragment

```html
{# templates/firmwares/fragments/search_results.html #}
{% if results %}
<p class="text-sm text-[var(--color-text-muted)] mb-2">
  {{ count }} result{{ count|pluralize }} for "{{ query }}"
</p>
{% for fw in results %}
<a href="{{ fw.get_absolute_url }}" class="block p-3 rounded hover:bg-[var(--color-bg-tertiary)]">
  <strong>{{ fw.name }}</strong>
  <span class="badge">{{ fw.brand.name }}</span>
</a>
{% endfor %}
{% else %}
{% include "components/_empty_state.html" with message="No firmware found" icon="search-x" %}
{% endif %}
```

## Anti-Patterns

```python
# WRONG — no minimum length check (searches for "a")
results = Firmware.objects.filter(name__icontains=query)  # query could be 1 char

# WRONG — no hx-sync (race condition: old request returns after new one)
# <input hx-get="/search/" hx-trigger="keyup changed delay:300ms">
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No `hx-sync` on search input | Race conditions between requests | Add `hx-sync="this:replace"` |
| No min-length check | Queries like "a" return everything | Check `len(query) >= 2` |
| Missing `search` in trigger | Clear button doesn't trigger search | Add `search` to trigger list |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
