---
name: htmx-csrf-meta-tag
description: "CSRF via meta tag for dynamic pages. Use when: CSRF token needs refresh without full page reload, SPA-like pages, pages with long-lived sessions."
---

# HTMX CSRF Meta Tag Pattern

## When to Use

- Pages where the CSRF token may expire before the user submits (long forms)
- Dynamic pages that need to refresh the token via JavaScript
- As a fallback when the global `hx-headers` approach is impractical

## Rules

1. Prefer the global `<body hx-headers>` pattern — this is the alternative
2. Place the meta tag in `<head>` so JavaScript can read it
3. Use `htmx:configRequest` event to inject the token on every request
4. Token rotation: re-read from meta tag on each request (handles rotation)

## Patterns

### Meta Tag in Head

```html
{# templates/base/base.html — in <head> #}
<meta name="csrf-token" content="{{ csrf_token }}">
```

### JavaScript CSRF Injection

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:configRequest', function(event) {
  const token = document.querySelector('meta[name="csrf-token"]')?.content;
  if (token) {
    event.detail.headers['X-CSRFToken'] = token;
  }
});
</script>
```

### Token Refresh via HTMX Response Header

```python
# views.py — include fresh token in response
from django.middleware.csrf import get_token

def my_view(request):
    response = render(request, "fragment.html", context)
    # Trigger meta tag update in client
    response["HX-Trigger"] = json.dumps({"csrfRefresh": get_token(request)})
    return response
```

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('csrfRefresh', function(event) {
  const meta = document.querySelector('meta[name="csrf-token"]');
  if (meta && event.detail.value) {
    meta.content = event.detail.value;
  }
});
</script>
```

## Anti-Patterns

```html
<!-- WRONG — hardcoded token that never refreshes -->
<script>const CSRF = "abc123";</script>

<!-- WRONG — reading from cookie directly (HttpOnly blocks this) -->
<script>const token = document.cookie.match(/csrftoken=([^;]+)/)</script>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Using both meta tag AND body hx-headers | Double injection, confusing | Pick one approach per project |
| Token never refreshed on long sessions | Stale token → 403 | Use `htmx:configRequest` to re-read meta |
| Reading CSRF from cookie | HttpOnly may block access | Use meta tag or template variable |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
