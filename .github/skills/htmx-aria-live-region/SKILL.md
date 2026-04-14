---
name: htmx-aria-live-region
description: "ARIA live regions for accessibility. Use when: announcing content changes to screen readers after HTMX swaps, accessible status messages, form validation announcements."
---

# HTMX ARIA Live Regions

## When to Use

- Announcing dynamic content changes to screen readers
- Notifying assistive technology after HTMX content swaps
- Making form validation feedback accessible
- Status messages, toast notifications, search result counts

## Rules

1. Use `aria-live="polite"` for non-urgent updates (search results, content loads)
2. Use `aria-live="assertive"` for urgent updates (errors, form validation)
3. Place the live region in the DOM before the content changes
4. Don't place `aria-live` on the swapped element — put it on a stable parent
5. After HTMX swap, update a separate live region with status text

## Patterns

### Search Results Announcement

```html
{# Stable live region — always present in DOM #}
<div aria-live="polite" aria-atomic="true" class="sr-only"
     id="search-status">
</div>

<input type="search" name="q"
       hx-get="{% url 'firmwares:search' %}"
       hx-target="#results"
       hx-trigger="input changed delay:300ms"
       placeholder="Search firmware...">

<div id="results"></div>

<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:afterSwap', function(event) {
  if (event.detail.target.id === 'results') {
    const count = event.detail.target.querySelectorAll('[data-result]').length;
    document.getElementById('search-status').textContent =
      count + ' result' + (count !== 1 ? 's' : '') + ' found';
  }
});
</script>
```

### Form Validation Errors

```html
{# Server returns fragment with errors #}
{# templates/firmwares/fragments/form_errors.html #}

<div role="alert" aria-live="assertive">
  <ul>
    {% for field, errors in form.errors.items %}
      {% for error in errors %}
      <li>{{ field }}: {{ error }}</li>
      {% endfor %}
    {% endfor %}
  </ul>
</div>
```

### Loading State Announcement

```html
<div aria-live="polite" class="sr-only" id="loading-status"></div>

<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:beforeRequest', function(event) {
  document.getElementById('loading-status').textContent = 'Loading content...';
});
document.addEventListener('htmx:afterSwap', function(event) {
  document.getElementById('loading-status').textContent = 'Content loaded.';
});
</script>
```

### Status Update After Delete

```html
<div aria-live="polite" class="sr-only" id="action-status"></div>

<script nonce="{{ request.csp_nonce }}">
document.addEventListener('showToast', function(event) {
  document.getElementById('action-status').textContent = event.detail.message;
});
</script>
```

## Anti-Patterns

```html
<!-- WRONG — aria-live on the swapped target itself -->
<div id="results" aria-live="polite" hx-swap="innerHTML">
  <!-- content replaced, live region re-created each time -->
</div>

<!-- WRONG — assertive for non-urgent content -->
<div aria-live="assertive" id="search-results">
  <!-- interrupts current screen reader speech for routine updates -->
</div>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No live region for dynamic updates | Screen readers miss changes | Add `aria-live` region |
| `aria-live` on swapped element | Recreated each swap, unreliable | Use stable parent element |
| `assertive` for routine updates | Interrupts user | Use `polite` for non-urgent |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
