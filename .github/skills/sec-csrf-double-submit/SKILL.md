---
name: sec-csrf-double-submit
description: "Double-submit cookie pattern implementation. Use when: implementing CSRF for stateless APIs, cookie+header verification."
---

# Double-Submit Cookie Pattern

## When to Use

- Protecting stateless API endpoints that use cookie auth
- Implementing CSRF without server-side token storage
- Hybrid session + API architecture

## Rules

| Step | Action |
|------|--------|
| 1 | Server sets random CSRF token in cookie |
| 2 | Client reads cookie value via JavaScript |
| 3 | Client sends same value in `X-CSRFToken` header |
| 4 | Server compares cookie value with header value |

## Patterns

### Django Built-In (Already Double-Submit)
```python
# Django's CsrfViewMiddleware implements double-submit by default:
# 1. Sets csrftoken cookie
# 2. Expects X-CSRFToken header (or csrfmiddlewaretoken form field)
# 3. Compares the two values

# settings.py — correct configuration
CSRF_COOKIE_HTTPONLY = False   # JS must read cookie
CSRF_COOKIE_SECURE = True     # HTTPS only
CSRF_COOKIE_SAMESITE = "Lax"  # Lax is default and secure
CSRF_USE_SESSIONS = False     # Use cookie-based (double-submit)
```

### Client-Side Implementation
```javascript
function getCsrfToken() {
    const match = document.cookie.match(/csrftoken=([^;]+)/);
    return match ? match[1] : null;
}

async function apiCall(url, method, body) {
    return fetch(url, {
        method,
        headers: {
            'X-CSRFToken': getCsrfToken(),
            'Content-Type': 'application/json',
        },
        credentials: 'same-origin',
        body: body ? JSON.stringify(body) : undefined,
    });
}
```

### Ensuring Cookie Exists on First Load
```python
from django.views.decorators.csrf import ensure_csrf_cookie

@ensure_csrf_cookie
def app_shell(request: HttpRequest) -> HttpResponse:
    """Render SPA shell — ensures CSRF cookie is set."""
    return render(request, "base/app.html")
```

## Red Flags

- `CSRF_USE_SESSIONS = True` — switches to session-based (not double-submit)
- `CSRF_COOKIE_HTTPONLY = True` — prevents JS from reading the cookie
- Missing `credentials: 'same-origin'` in fetch calls
- Custom CSRF implementation instead of Django's built-in

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
