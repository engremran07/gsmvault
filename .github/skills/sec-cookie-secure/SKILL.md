---
name: sec-cookie-secure
description: "Secure cookie flag: HTTPS-only transmission. Use when: configuring cookies for production, auditing cookie security."
---

# Secure Cookie Flag

## When to Use

- Configuring cookies for production deployment
- Auditing cookie transmission security
- Setting custom cookies in views

## Rules

| Cookie | Secure Flag | Environment |
|--------|-------------|-------------|
| Session | `True` in prod | `SESSION_COOKIE_SECURE` |
| CSRF | `True` in prod | `CSRF_COOKIE_SECURE` |
| Custom cookies | `True` in prod | `set_cookie(secure=True)` |
| Dev override | `False` ok in dev | Only in `settings_dev.py` |

## Patterns

### Production Settings
```python
# settings_production.py
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

### Development Override
```python
# settings_dev.py
SESSION_COOKIE_SECURE = False  # HTTP in development
CSRF_COOKIE_SECURE = False
SECURE_SSL_REDIRECT = False
```

### Custom Secure Cookie
```python
def set_download_cookie(response: HttpResponse, token: str) -> HttpResponse:
    from django.conf import settings
    response.set_cookie(
        key="download_token",
        value=token,
        max_age=3600,
        secure=not settings.DEBUG,  # Secure in prod, not in dev
        httponly=True,
        samesite="Strict",
    )
    return response
```

### Cookie Prefix (Extra Protection)
```python
# __Secure- prefix: browser enforces Secure flag
SESSION_COOKIE_NAME = "__Secure-sessionid"
# __Host- prefix: enforces Secure + no Domain + Path=/
SESSION_COOKIE_NAME = "__Host-sessionid"
```

## Red Flags

- `SESSION_COOKIE_SECURE = False` in production settings
- `CSRF_COOKIE_SECURE = False` in production
- Custom cookies without `secure=True` in production code
- Missing `SECURE_SSL_REDIRECT = True` in production

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
