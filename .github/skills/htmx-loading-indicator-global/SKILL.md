---
name: htmx-loading-indicator-global
description: "Global loading indicator using htmx-indicator class. Use when: adding a site-wide loading spinner, progress bar, or overlay during any HTMX request."
---

# HTMX Global Loading Indicator

## When to Use

- Showing a site-wide progress bar or spinner during any HTMX request
- Adding a top-of-page loading bar (NProgress-style)
- Indicating background activity to the user globally

## Rules

1. HTMX adds `htmx-request` class to the element making the request (or its `hx-indicator` target)
2. Use CSS to show/hide the indicator based on `htmx-request` class
3. For a global indicator, listen to `htmx:beforeRequest` / `htmx:afterRequest` events
4. Always provide visual feedback — never leave the user guessing

## Patterns

### CSS-Only Global Progress Bar

```html
{# templates/base/base.html — inside <body>, before content #}
<div id="global-loader"
     class="htmx-indicator fixed top-0 left-0 w-full h-1 bg-[var(--color-accent)] z-[9999]">
</div>
```

```css
/* static/css/src/_htmx.scss */
.htmx-indicator { opacity: 0; transition: opacity 200ms ease-in; }
.htmx-request .htmx-indicator, .htmx-request.htmx-indicator { opacity: 1; }
```

### Body-Level Indicator (all requests trigger it)

```html
<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'
      hx-indicator="#global-loader">
  <div id="global-loader" class="htmx-indicator">
    <div class="loading-bar"></div>
  </div>
  {% block content %}{% endblock %}
</body>
```

### Event-Based Global Indicator

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:beforeRequest', () => {
  document.getElementById('global-loader')?.classList.add('active');
});
document.addEventListener('htmx:afterRequest', () => {
  document.getElementById('global-loader')?.classList.remove('active');
});
</script>
```

### Animated Progress Bar CSS

```css
#global-loader.active {
  opacity: 1;
  animation: loading-progress 2s ease-in-out infinite;
}
@keyframes loading-progress {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}
```

## Anti-Patterns

```html
<!-- WRONG — no loading feedback at all -->
<button hx-post="/api/process/">Process</button>

<!-- WRONG — blocking overlay with no way to cancel -->
<div class="fixed inset-0 bg-black/80 z-[99999]">Loading...</div>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No `htmx-indicator` anywhere | No loading feedback | Add global indicator to base template |
| Indicator never hides | Missing `htmx:afterRequest` handler | Ensure both show/hide are wired |
| Indicator blocks interaction | Overlay too aggressive | Use subtle top-bar, not full overlay |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
