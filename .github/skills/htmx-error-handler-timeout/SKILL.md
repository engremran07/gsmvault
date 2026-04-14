---
name: htmx-error-handler-timeout
description: "Timeout configuration and handling. Use when: configuring HTMX request timeouts, handling slow responses, showing timeout error messages."
---

# HTMX Timeout Configuration and Handling

## When to Use

- Configuring max wait time for HTMX requests
- Handling slow server responses gracefully
- Preventing indefinite loading states

## Rules

1. Set `htmx.config.timeout` globally in milliseconds (default: 0 = no timeout)
2. Use `htmx:timeout` event to handle timeout-specific errors
3. Show user-friendly timeout messages with retry options
4. Set reasonable timeouts: 10s for normal, 30s for uploads, 60s for heavy reports

## Patterns

### Global Timeout Configuration

```html
{# templates/base/base.html #}
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('DOMContentLoaded', function() {
  htmx.config.timeout = 15000;  // 15 seconds
});
</script>
```

### Per-Element Timeout

```html
{# Long-running report — higher timeout #}
<button hx-get="{% url 'analytics:generate_report' %}"
        hx-target="#report-area"
        hx-timeout="60000">
  Generate Report
</button>

{# Quick search — short timeout #}
<input hx-get="{% url 'forum:search' %}"
       hx-target="#results"
       hx-trigger="keyup changed delay:300ms"
       hx-timeout="5000"
       name="q">
```

### Timeout Event Handler

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:timeout', function(event) {
  Alpine.store('notify').show(
    'Request timed out. The server may be busy — please try again.',
    'warning',
    8000
  );
  // Remove loading state from the triggering element
  event.detail.elt.classList.remove('htmx-request');
});
</script>
```

### Combined Timeout + Retry

```html
<div x-data="{ attempts: 0 }">
  <button hx-get="{% url 'firmwares:check_status' fw.pk %}"
          hx-target="#status"
          hx-timeout="10000"
          @htmx:timeout.window="attempts++"
          x-show="attempts < 3">
    Check Status
  </button>
  <p x-show="attempts >= 3" x-cloak class="text-[var(--color-text-error)]">
    Server not responding. Please try later.
  </p>
</div>
```

## Anti-Patterns

```javascript
// WRONG — no timeout (infinite loading possible)
htmx.config.timeout = 0;  // user waits forever

// WRONG — too short timeout for file uploads
// <form hx-post="/upload/" hx-timeout="3000">  // 3s for upload = always fails
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No timeout configured | Requests hang indefinitely | Set `htmx.config.timeout` |
| Same timeout for all request types | Uploads always time out | Use per-element `hx-timeout` |
| No `htmx:timeout` handler | Timeout shows as generic error | Add specific timeout handler |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
