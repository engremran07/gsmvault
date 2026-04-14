---
name: htmx-error-handler-network
description: "Network error handling for HTMX requests. Use when: handling connection failures, offline scenarios, DNS errors during HTMX requests."
---

# HTMX Network Error Handling

## When to Use

- Handling connection failures (user goes offline)
- Showing retry options when the server is unreachable
- Graceful degradation during network issues

## Rules

1. Use `htmx:sendError` for network-level failures (no HTTP response at all)
2. Use `htmx:responseError` for HTTP errors (server responded with error status)
3. Show a retry-friendly message with `$store.notify.show()`
4. Consider adding a retry button for critical actions

## Patterns

### Global Network Error Handler

```html
{# templates/base/base.html #}
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:sendError', function(event) {
  Alpine.store('notify').show(
    'Network error. Check your connection and try again.',
    'error',
    10000
  );
});
</script>
```

### Offline Detection + HTMX Pausing

```html
<script nonce="{{ request.csp_nonce }}">
window.addEventListener('offline', () => {
  Alpine.store('notify').show('You are offline. Requests paused.', 'warning', 0);
  document.body.setAttribute('hx-disable', 'true');
});
window.addEventListener('online', () => {
  Alpine.store('notify').show('Connection restored.', 'success', 3000);
  document.body.removeAttribute('hx-disable');
});
</script>
```

### Retry Pattern for Failed Requests

```html
<div x-data="{ retryUrl: '', retryTarget: '' }">
  <script nonce="{{ request.csp_nonce }}">
  document.addEventListener('htmx:sendError', function(event) {
    const elt = event.detail.elt;
    const url = elt.getAttribute('hx-get') || elt.getAttribute('hx-post');
    Alpine.store('notify').show(
      'Request failed. <button onclick="htmx.trigger(document.body, \'retry\')" class="underline">Retry</button>',
      'error', 15000
    );
  });
  </script>
</div>
```

## Anti-Patterns

```javascript
// WRONG — no distinction between network and HTTP errors
document.addEventListener('htmx:responseError', (e) => {
  // This won't fire on network errors — use htmx:sendError
});

// WRONG — auto-retrying without user consent (can hammer a down server)
document.addEventListener('htmx:sendError', () => setTimeout(retry, 1000));
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No `htmx:sendError` handler | Network errors silently fail | Add handler to base template |
| Auto-retry loop | Hammers server on outage | Show retry button, let user decide |
| No offline indicator | User confused why nothing works | Add `offline`/`online` event listeners |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
