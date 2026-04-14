---
name: htmx-error-handler-status
description: "HTTP status code error handling with htmx:responseError. Use when: handling 4xx/5xx errors from HTMX requests, showing error messages, preventing silent failures."
---

# HTMX HTTP Status Error Handling

## When to Use

- Handling 400, 403, 404, 500 errors from HTMX requests
- Showing user-friendly error messages instead of silent failures
- Logging client-side errors for debugging

## Rules

1. HTMX does NOT swap content on error status codes (4xx/5xx) by default
2. Use `htmx:responseError` event to catch and display errors
3. Use `$store.notify.show()` for toast error messages — never `alert()`
4. Return HTML error fragments from Django views for swap-on-error scenarios

## Patterns

### Global Error Handler

```html
{# templates/base/base.html #}
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:responseError', function(event) {
  const status = event.detail.xhr.status;
  const messages = {
    400: 'Invalid request. Please check your input.',
    403: 'Permission denied.',
    404: 'Resource not found.',
    422: 'Validation failed. Please correct errors.',
    429: 'Too many requests. Please slow down.',
    500: 'Server error. Please try again later.',
  };
  const msg = messages[status] || `Error (${status})`;
  Alpine.store('notify').show(msg, 'error', 8000);
});
</script>
```

### Per-Status Custom Handling

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:responseError', function(event) {
  const xhr = event.detail.xhr;
  if (xhr.status === 401) {
    window.location.href = '/accounts/login/?next=' + encodeURIComponent(window.location.pathname);
    return;
  }
  if (xhr.status === 429) {
    const retryAfter = xhr.getResponseHeader('Retry-After') || '60';
    Alpine.store('notify').show(`Rate limited. Retry in ${retryAfter}s`, 'warning');
    return;
  }
  Alpine.store('notify').show('Something went wrong', 'error');
});
</script>
```

### Django View Returning Error Fragment

```python
from django.http import HttpResponse

def delete_firmware(request, pk):
    fw = get_object_or_404(Firmware, pk=pk, user=request.user)
    if fw.is_locked:
        return HttpResponse(
            '<div class="text-red-500">Cannot delete locked firmware</div>',
            status=403,
        )
    fw.delete()
    return HttpResponse("", status=200)
```

## Anti-Patterns

```javascript
// WRONG — using alert() for errors
document.addEventListener('htmx:responseError', (e) => alert('Error!'));

// WRONG — ignoring errors entirely (silent failure)
// (no error handler registered at all)
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No `htmx:responseError` handler | Errors silently ignored | Add global handler in base template |
| `alert()` in error handler | Blocks UI, unprofessional | Use `$store.notify.show()` |
| No 401 handling | Expired session shows cryptic error | Redirect to login on 401 |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
