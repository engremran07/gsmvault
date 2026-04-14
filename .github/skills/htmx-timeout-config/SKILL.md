---
name: htmx-timeout-config
description: "Request timeout configuration. Use when: setting global or per-request timeouts, handling slow endpoints, configuring timeout behavior for different request types."
---

# HTMX Timeout Configuration

## When to Use

- Setting default timeout for all HTMX requests
- Overriding timeout for specific slow endpoints (reports, uploads)
- Preventing requests from hanging indefinitely

## Rules

1. Set `htmx.config.timeout` globally (milliseconds, 0 = no timeout)
2. Use per-element `hx-request='{"timeout": 30000}'` for overrides
3. Handle `htmx:timeout` event for user feedback
4. Recommended defaults: 15s normal, 30s forms, 60s uploads/reports

## Patterns

### Global Configuration

```html
{# templates/base/base.html #}
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('DOMContentLoaded', function() {
  htmx.config.timeout = 15000; // 15s default for all requests
});
</script>
```

### Per-Request Override

```html
{# Quick API call — short timeout #}
<button hx-get="{% url 'api:status' %}"
        hx-request='{"timeout": 5000}'
        hx-target="#status">
  Check Status
</button>

{# Report generation — long timeout #}
<button hx-post="{% url 'analytics:generate_report' %}"
        hx-request='{"timeout": 120000}'
        hx-target="#report-output"
        hx-indicator="#report-spinner">
  Generate Report
</button>

{# File upload — extended timeout #}
<form hx-post="{% url 'firmwares:upload' %}"
      hx-encoding="multipart/form-data"
      hx-request='{"timeout": 300000}'
      hx-target="#upload-result">
  <input type="file" name="file">
  <button type="submit">Upload</button>
</form>
```

### Timeout Handler with Retry

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:timeout', function(event) {
  const elt = event.detail.elt;
  Alpine.store('notify').show(
    'Request timed out. Please try again.',
    'warning', 8000
  );
  // Re-enable the element
  elt.removeAttribute('disabled');
  elt.classList.remove('htmx-request');
});
</script>
```

### Table of Recommended Timeouts

| Request Type | Timeout | Example |
|-------------|---------|---------|
| Quick API check | 5s | Status ping, validation |
| Standard page load | 15s | List pages, search |
| Form submission | 30s | Create/update forms |
| File upload | 300s | Firmware upload |
| Report generation | 120s | Analytics export |

## Anti-Patterns

```javascript
// WRONG — no timeout (requests hang forever)
htmx.config.timeout = 0;

// WRONG — same timeout for upload and quick checks
htmx.config.timeout = 5000; // uploads always fail
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No timeout configured | Requests can hang forever | Set `htmx.config.timeout` |
| Upload times out | Timeout too short for file size | Use per-element `hx-request` |
| No timeout event handler | Silent failure on timeout | Add `htmx:timeout` listener |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
