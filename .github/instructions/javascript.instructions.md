---
applyTo: 'static/js/**/*.js'
---

# JavaScript Coding Instructions

## File Organization

- Source modules in `static/js/src/` — one module per concern
- Minified/bundled output in `static/js/dist/`
- Vendor libraries in `static/vendor/` (local CDN fallbacks)
- Never commit unminified code to `dist/`

## Technology Constraints

- **Vanilla JS + Alpine.js v3** — no jQuery, no React, no Vue, no Angular
- Alpine.js handles all client-side reactivity via `x-data`, `x-show`, `x-bind`, `x-on`
- Use ES6+ features: `const`/`let`, arrow functions, template literals, destructuring, `async`/`await`
- No `var` declarations — always `const` (preferred) or `let`

## CSRF Token Handling

All mutating fetch/XHR requests MUST include the CSRF token:

```javascript
function getCookie(name) {
  let cookieValue = null;
  if (document.cookie && document.cookie !== '') {
    const cookies = document.cookie.split(';');
    for (let i = 0; i < cookies.length; i++) {
      const cookie = cookies[i].trim();
      if (cookie.substring(0, name.length + 1) === (name + '=')) {
        cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
        break;
      }
    }
  }
  return cookieValue;
}

fetch(url, {
  method: 'POST',
  headers: {
    'X-CSRFToken': getCookie('csrftoken'),
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(data),
});
```

Global HTMX CSRF is handled via `<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>` in `base.html` — do NOT duplicate this in JS for HTMX requests.

## Security — MANDATORY

- **Never** use `eval()`, `Function()`, or `setTimeout`/`setInterval` with string arguments
- **Never** use `innerHTML` with user-supplied content — use `textContent` or sanitize first
- **Never** use `document.write()`
- **Never** construct HTML strings from user input — use DOM APIs (`createElement`, `appendChild`)
- **Never** embed secrets, API keys, or tokens in JS source files
- All user input displayed in the DOM must be escaped or set via `textContent`

## Theme Switcher

The theme switcher stores user preference in `localStorage` and applies `data-theme` attribute:

```javascript
// Read preference
const theme = localStorage.getItem('theme') || 'dark';
document.documentElement.setAttribute('data-theme', theme);

// Save preference
function setTheme(newTheme) {
  localStorage.setItem('theme', newTheme);
  document.documentElement.setAttribute('data-theme', newTheme);
}
```

Three themes: `dark` (default), `light`, `contrast`.

**Critical**: `--color-accent-text` is WHITE in dark/light but BLACK in contrast — never hardcode colors on accent backgrounds.

## Multi-CDN Fallback Chain

Load order: jsDelivr → cdnjs → unpkg → local vendor. Implemented in `base.html` with sequential `<script>` fallbacks:

```javascript
// Pattern for checking if library loaded
if (typeof Alpine === 'undefined') {
  // Load from next CDN in chain
  const script = document.createElement('script');
  script.src = '/static/vendor/alpine/alpine.min.js';
  document.head.appendChild(script);
}
```

Vendor fallback files live in `static/vendor/` — always keep local copies current with CDN versions.

## Alpine.js Patterns

- Define components with `x-data` — keep state close to the DOM element
- Use `x-cloak` on ALL `x-show` / `x-if` elements to prevent FOUC
- Never combine CSS `animate-*` classes with `x-show` (animation overrides `display:none`)
- Use `$dispatch` for sibling component communication
- Use `Alpine.store()` for global state (theme, notifications, auth status)
- Use `$nextTick` when accessing DOM after reactive updates

## Module Pattern

```javascript
// static/js/src/notifications.js
const NotificationManager = {
  init() {
    // Setup logic
  },
  show(message, type = 'info') {
    // Display notification
  },
  dismiss(id) {
    // Remove notification
  },
};

// Initialize when DOM ready
document.addEventListener('DOMContentLoaded', () => {
  NotificationManager.init();
});
```

## Error Handling

- Wrap async operations in try/catch
- Log errors to console in development, suppress in production
- Show user-friendly error messages via the notification system
- Never expose stack traces or internal error details to users
