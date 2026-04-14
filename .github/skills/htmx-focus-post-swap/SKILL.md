---
name: htmx-focus-post-swap
description: "Focus management after content swap. Use when: restoring focus after form re-render, focusing first error field, focusing new content after HTMX swap."
---

# HTMX Focus Management After Swap

## When to Use

- Auto-focusing the first error field after form validation swap
- Restoring focus to the correct element after content replacement
- Moving focus to newly loaded content for keyboard users
- Preventing focus loss when swapped content removes the focused element

## Rules

1. Use `htmx:afterSwap` to manage focus programmatically
2. Focus the first error field after form validation failure
3. When replacing a focused element, re-focus the equivalent new element
4. Use `tabindex="-1"` to make non-interactive containers focusable

## Patterns

### Focus First Error Field

```html
<form hx-post="{% url 'firmwares:create' %}"
      hx-target="#form-container"
      hx-swap="innerHTML">
  {% csrf_token %}
  {{ form.as_div }}
  <button type="submit" class="btn btn-primary">Create</button>
</form>

<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:afterSwap', function(event) {
  // Focus the first input with an error class
  const firstError = event.detail.target.querySelector('.is-invalid, [aria-invalid="true"]');
  if (firstError) {
    firstError.focus();
  }
});
</script>
```

### Focus New Content After Load

```html
{# After loading more content, focus the first new item #}
<div id="content-list"
     hx-get="{% url 'firmwares:list' %}?page={{ next_page }}"
     hx-target="this"
     hx-swap="beforeend">
</div>

<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:afterSwap', function(event) {
  if (event.detail.target.id === 'content-list') {
    const newItems = event.detail.target.querySelectorAll('[data-new-item]');
    if (newItems.length > 0) {
      newItems[0].setAttribute('tabindex', '-1');
      newItems[0].focus();
    }
  }
});
</script>
```

### Focus Restoration on Replace

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:beforeSwap', function(event) {
  // Save the focused element's data attribute
  const focused = document.activeElement;
  if (focused && event.detail.target.contains(focused)) {
    event.detail.target.dataset.focusRestore = focused.getAttribute('name')
      || focused.id || '';
  }
});

document.addEventListener('htmx:afterSwap', function(event) {
  const restoreId = event.detail.target.dataset.focusRestore;
  if (restoreId) {
    const el = event.detail.target.querySelector(
      `[name="${restoreId}"], #${restoreId}`
    );
    if (el) el.focus();
    delete event.detail.target.dataset.focusRestore;
  }
});
</script>
```

### Skip to New Content (Accessible)

```html
{# After swap, announce and focus the new section #}
<div id="results" tabindex="-1" aria-label="Search results">
  {# HTMX swaps content here #}
</div>

<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:afterSwap', function(event) {
  if (event.detail.target.id === 'results') {
    event.detail.target.focus();
  }
});
</script>
```

## Anti-Patterns

```html
<!-- WRONG — autofocus attribute on server-rendered fragment -->
<!-- This only works on initial page load, not HTMX swap -->
<input autofocus name="search">

<!-- WRONG — focusing without tabindex on non-interactive element -->
<div id="results">...</div>
<script>document.getElementById('results').focus();</script>
<!-- Won't work without tabindex="-1" -->
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Focus lost after swap | Keyboard user thrown to `<body>` | Restore focus in `htmx:afterSwap` |
| `autofocus` in fragment | No effect on HTMX swap | Use JS `.focus()` after swap |
| Focus on non-focusable element | `.focus()` silently fails | Add `tabindex="-1"` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
