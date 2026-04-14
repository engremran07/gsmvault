---
name: sec-cookie-httponly
description: "HttpOnly cookie flag: prevents JavaScript access. Use when: setting cookies, configuring session/CSRF cookies."
---

# HttpOnly Cookie Flag

## When to Use

- Setting any cookie containing sensitive data
- Configuring session and authentication cookies
- Auditing cookie security flags

## Rules

| Cookie | HttpOnly | Reason |
|--------|----------|--------|
| Session (`sessionid`) | `True` | No JS access needed |
| CSRF (`csrftoken`) | `False` | JS must read for AJAX headers |
| Consent (`consent_accepted`) | `True` | No JS access needed |
| Theme preference | `False` | JS reads for immediate theme apply |

## Patterns

### Django Settings
```python
SESSION_COOKIE_HTTPONLY = True   # ALWAYS True — session ID never needs JS access
CSRF_COOKIE_HTTPONLY = False     # Must be False — JS needs to read for X-CSRFToken header
```

### Setting Custom HttpOnly Cookie
```python
def set_consent_cookie(response: HttpResponse, consent: dict) -> HttpResponse:
    response.set_cookie(
        key="consent_accepted",
        value="1",
        max_age=365 * 24 * 60 * 60,  # 1 year
        httponly=True,     # JS cannot access
        secure=True,       # HTTPS only
        samesite="Lax",
    )
    return response
```

### Non-HttpOnly Cookie (When JS Needs Access)
```python
def set_theme_cookie(response: HttpResponse, theme: str) -> HttpResponse:
    response.set_cookie(
        key="theme",
        value=theme,
        max_age=365 * 24 * 60 * 60,
        httponly=False,    # JS reads this for immediate theme application
        secure=True,
        samesite="Lax",
    )
    return response
```

## Red Flags

- `SESSION_COOKIE_HTTPONLY = False` — session ID exposed to XSS
- Sensitive data in non-HttpOnly cookies (tokens, user IDs)
- `httponly=False` on cookies that JS doesn't need

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
