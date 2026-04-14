---
name: htmx-search-live
description: "Live search implementation pattern. Use when: real-time search with results dropdown, search-as-you-type, live filtering of lists, autocomplete search."
---

# HTMX Live Search

## When to Use

- Real-time search with results appearing as the user types
- Search-as-you-type with dropdown results
- Live filtering a table or list
- Autocomplete suggestions

## Rules

1. Use `hx-trigger="input changed delay:300ms"` — debounce is mandatory
2. Add minimum character threshold (3+) to avoid excessive requests
3. Return fragments, not full pages
4. Show loading indicator during search
5. Handle empty query state (clear results)
6. Escape and sanitize query parameter server-side

## Patterns

### Complete Live Search

```html
{# templates/firmwares/includes/search.html #}
<div x-data="{ query: '' }" class="relative">
  <input type="search"
         name="q"
         x-model="query"
         hx-get="{% url 'firmwares:search' %}"
         hx-trigger="input changed delay:300ms, search"
         hx-target="#search-results"
         hx-indicator="#search-spinner"
         hx-params="q"
         placeholder="Search firmware..."
         autocomplete="off"
         class="input w-full">

  <span id="search-spinner"
        class="htmx-indicator absolute right-3 top-3">
    {% include "components/_loading.html" with size="sm" %}
  </span>

  {# Results dropdown #}
  <div id="search-results"
       x-show="query.length >= 2"
       x-cloak
       @click.outside="query = ''"
       class="absolute top-full mt-1 w-full bg-[var(--color-bg-secondary)] border border-[var(--color-border)] rounded-lg shadow-lg z-40 max-h-80 overflow-y-auto">
  </div>
</div>
```

### Django Search View

```python
from django.db.models import Q

def firmware_search(request):
    query = request.GET.get("q", "").strip()

    if len(query) < 2:
        return HttpResponse("")  # Empty results for short queries

    results = Firmware.objects.filter(
        Q(name__icontains=query) | Q(brand__name__icontains=query),
        is_active=True,
    ).select_related("brand")[:20]

    return render(request, "firmwares/fragments/search_results.html", {
        "results": results,
        "query": query,
    })
```

### Search Results Fragment

```html
{# templates/firmwares/fragments/search_results.html #}

{% if results %}
  {% for fw in results %}
  <a href="{% url 'firmwares:detail' fw.pk %}"
     class="block px-4 py-2 hover:bg-[var(--color-bg-tertiary)]" data-result>
    <span class="font-medium text-[var(--color-text-primary)]">{{ fw.name }}</span>
    <span class="text-sm text-[var(--color-text-muted)]">{{ fw.brand.name }}</span>
  </a>
  {% endfor %}
{% else %}
  <div class="px-4 py-3 text-sm text-[var(--color-text-muted)]">
    No firmware found for "{{ query }}"
  </div>
{% endif %}
```

### Keyboard Navigation

```html
<div id="search-results"
     @keydown.arrow-down.prevent="$el.querySelector('a:first-child')?.focus()"
     @keydown.escape="query = ''">
  {# Each result link handles arrows #}
  <a @keydown.arrow-down.prevent="$el.nextElementSibling?.focus()"
     @keydown.arrow-up.prevent="$el.previousElementSibling?.focus()"
     href="...">Result</a>
</div>
```

## Anti-Patterns

```html
<!-- WRONG — no debounce (fires on every keystroke) -->
<input hx-get="/search/" hx-trigger="input">

<!-- WRONG — no minimum character length -->
<input hx-get="/search/" hx-trigger="input changed delay:300ms">
<!-- Sends request for 1-char queries -->
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No debounce on search input | Excessive requests per keystroke | Add `delay:300ms` to trigger |
| No minimum query length | 1-char searches overload server | Check `len(query) < 2` server-side |
| Search results not escaped | XSS from search term | Django auto-escaping handles this |
| No keyboard navigation | Inaccessible for keyboard users | Add arrow key handlers |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
