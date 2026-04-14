---
name: sec-csp-nonce
description: "CSP nonce generation and injection for inline scripts. Use when: adding inline scripts, configuring CSP middleware, fixing CSP violations."
---

# CSP Nonce Generation

## When to Use

- Adding inline `<script>` tags to templates
- Configuring CSP middleware for nonce injection
- Fixing CSP violation errors for inline scripts

## Rules

| Rule | Implementation |
|------|----------------|
| Generate per-request | Middleware creates unique nonce per request |
| Inject into template | `{{ csp_nonce }}` context variable |
| Apply to scripts | `<script nonce="{{ csp_nonce }}">` |
| CSP header | `script-src 'nonce-{value}' 'strict-dynamic'` |

## Patterns

### CSP Nonce Middleware
```python
# app/middleware/csp_nonce.py
import secrets
from django.http import HttpRequest, HttpResponse

class CSPNonceMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        nonce = secrets.token_urlsafe(32)
        request.csp_nonce = nonce
        response = self.get_response(request)
        csp = f"script-src 'nonce-{nonce}' 'strict-dynamic'; object-src 'none'; base-uri 'self';"
        response["Content-Security-Policy"] = csp
        return response
```

### Context Processor
```python
# apps/core/context_processors.py
def csp_nonce(request):
    return {"csp_nonce": getattr(request, "csp_nonce", "")}
```

### Template Usage
```html
<!-- CORRECT: nonce on every inline script -->
<script nonce="{{ csp_nonce }}">
    document.addEventListener('DOMContentLoaded', function() {
        // Safe inline script
    });
</script>

<!-- FORBIDDEN: inline script without nonce -->
<script>
    alert('This will be blocked by CSP');
</script>
```

### HTMX + Alpine with Nonce
```html
<!-- External scripts loaded via strict-dynamic inherit trust -->
<script nonce="{{ csp_nonce }}" src="{% static 'vendor/alpine.min.js' %}" defer></script>
<script nonce="{{ csp_nonce }}" src="{% static 'vendor/htmx.min.js' %}"></script>
```

## Red Flags

- Inline `<script>` without `nonce="{{ csp_nonce }}"` attribute
- Hardcoded nonce value (must be random per request)
- `script-src 'unsafe-inline'` in CSP header — defeats the purpose
- Nonce not generated with `secrets.token_urlsafe()`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
