---
name: htmx-debounce-keyup
description: "Debounced keyup for search with hx-trigger='keyup changed delay:300ms'. Use when: adding search-as-you-type, autocomplete, live filtering with debounce."
---

# HTMX Debounced Keyup

## When to Use

- Search-as-you-type in search bars
- Autocomplete suggestions
- Live filtering of lists/tables
- Any text input that triggers server requests on each keystroke

## Rules

1. Use `hx-trigger="keyup changed delay:300ms"` — prevents request per keystroke
2. `changed` modifier ensures request only fires if value actually changed
3. 300ms is the sweet spot — fast enough to feel responsive, slow enough to avoid spam
4. Always add `hx-indicator` for loading feedback
5. Consider minimum character length for search efficiency

## Patterns

### Basic Debounced Search

```html
<input type="search" name="q"
       hx-get="{% url 'forum:search' %}"
       hx-target="#search-results"
       hx-trigger="keyup changed delay:300ms"
       hx-indicator="#search-spinner"
       placeholder="Search topics..."
       autocomplete="off">
<span id="search-spinner" class="htmx-indicator">
  <i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i>
</span>
<div id="search-results"></div>
```

### With URL Update

```html
<input type="search" name="q"
       hx-get="{% url 'firmwares:search' %}"
       hx-target="#results"
       hx-trigger="keyup changed delay:300ms"
       hx-replace-url="true"
       hx-indicator="#spinner"
       value="{{ request.GET.q|default:'' }}">
```

### Django View for Debounced Search

```python
def search_topics(request):
    query = request.GET.get("q", "").strip()
    results = []
    if len(query) >= 2:
        results = ForumTopic.objects.filter(
            title__icontains=query
        ).select_related("category", "author")[:20]

    context = {"results": results, "query": query}
    if request.headers.get("HX-Request"):
        return render(request, "forum/fragments/search_results.html", context)
    return render(request, "forum/search.html", context)
```

### Delay Variations

```html
{# Fast autocomplete (150ms) #}
<input hx-trigger="keyup changed delay:150ms" ...>

{# Standard search (300ms) #}
<input hx-trigger="keyup changed delay:300ms" ...>

{# Slow/expensive query (500ms) #}
<input hx-trigger="keyup changed delay:500ms" ...>
```

## Anti-Patterns

```html
<!-- WRONG — no delay (request per keystroke) -->
<input hx-get="/search/" hx-trigger="keyup">

<!-- WRONG — no changed modifier (fires even if value unchanged) -->
<input hx-get="/search/" hx-trigger="keyup delay:300ms">

<!-- WRONG — delay too long (feels unresponsive) -->
<input hx-get="/search/" hx-trigger="keyup changed delay:2000ms">
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No `delay` on keyup trigger | Floods server with requests | Add `delay:300ms` |
| No `changed` modifier | Fires on arrow keys, shift, etc. | Add `changed` |
| No minimum query length | Searches for 1 character | Check `len(query) >= 2` in view |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
