---
name: htmx-loading-indicator-target
description: "Per-element loading indicators. Use when: showing a spinner inside a specific button, card, or section during its HTMX request."
---

# HTMX Per-Element Loading Indicators

## When to Use

- Showing a spinner inside a button that triggered the request
- Replacing content area with a skeleton loader during fetch
- Indicating which specific section is loading in a multi-section page

## Rules

1. Use `hx-indicator` attribute to point to the indicator element
2. HTMX adds `htmx-request` class to the indicator target during the request
3. The indicator element should have class `htmx-indicator` (hidden by default)
4. Use `{% include "components/_loading.html" %}` for the spinner component

## Patterns

### Button with Inline Spinner

```html
<button hx-post="{% url 'forum:toggle_like' topic.pk %}"
        hx-target="#like-count-{{ topic.pk }}"
        hx-swap="outerHTML"
        hx-indicator="#spinner-{{ topic.pk }}">
  <span>Like</span>
  <span id="spinner-{{ topic.pk }}" class="htmx-indicator">
    <i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i>
  </span>
</button>
```

### Card with Skeleton Loader

```html
<div id="firmware-detail" hx-get="{% url 'firmwares:detail_fragment' fw.pk %}"
     hx-trigger="revealed" hx-indicator="#skeleton-{{ fw.pk }}">
  <div id="skeleton-{{ fw.pk }}" class="htmx-indicator">
    {% include "components/_loading.html" with size="lg" %}
  </div>
</div>
```

### Disable Button During Request

```html
<button hx-post="{% url 'shop:checkout' %}"
        hx-disabled-elt="this"
        hx-indicator="#checkout-spinner">
  <span class="htmx-indicator" id="checkout-spinner">
    <i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i>
  </span>
  <span>Complete Purchase</span>
</button>
```

### CSS for htmx-indicator

```css
.htmx-indicator { display: none; }
.htmx-request .htmx-indicator, .htmx-request.htmx-indicator { display: inline-flex; }
```

## Anti-Patterns

```html
<!-- WRONG — no indicator, user clicks multiple times -->
<button hx-post="/api/submit/">Submit</button>

<!-- WRONG — indicator references nonexistent element -->
<button hx-indicator="#does-not-exist" hx-post="/api/">Go</button>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No `hx-indicator` on slow requests | User clicks repeatedly | Add indicator + `hx-disabled-elt` |
| Indicator ID mismatch | Spinner never shows | Verify `#id` matches element |
| Missing `htmx-indicator` class | Element always visible | Add the class for default hidden state |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
