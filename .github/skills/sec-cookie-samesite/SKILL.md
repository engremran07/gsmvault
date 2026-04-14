---
name: sec-cookie-samesite
description: "SameSite cookie attribute: Lax, Strict, None. Use when: configuring cookie SameSite policy, cross-origin cookie behavior."
---

# SameSite Cookie Attribute

## When to Use

- Configuring CSRF protection via cookie policy
- Handling cross-origin cookie scenarios
- Choosing between Lax, Strict, and None

## Rules

| Value | Behavior | Use Case |
|-------|----------|----------|
| `Lax` | Sent on top-level navigations + same-site | Default — good balance |
| `Strict` | Only same-site requests | Maximum protection, breaks external links |
| `None` | Sent on all requests (requires `Secure`) | Cross-origin APIs, embeds |

## Patterns

### Recommended Configuration
```python
# settings.py
SESSION_COOKIE_SAMESITE = "Lax"    # Default — secure and usable
CSRF_COOKIE_SAMESITE = "Lax"       # Prevents CSRF from cross-site
```

### Strict for Sensitive Cookies
```python
def set_admin_session_cookie(response, value):
    response.set_cookie(
        key="admin_session",
        value=value,
        samesite="Strict",  # Never sent cross-site — max security
        secure=True,
        httponly=True,
    )
```

### None for Cross-Origin (Rare)
```python
# Only for legitimate cross-origin needs (e.g., embedded widgets)
def set_widget_cookie(response, value):
    response.set_cookie(
        key="widget_pref",
        value=value,
        samesite="None",    # Cross-origin allowed
        secure=True,        # MANDATORY with SameSite=None
        httponly=True,
    )
```

### Decision Matrix

| Scenario | SameSite Value |
|----------|---------------|
| Standard web app | `Lax` |
| Admin panel | `Strict` |
| API consumed by external SPA | `None` + `Secure` |
| OAuth callback cookies | `Lax` |
| Download token cookies | `Strict` |
| Consent cookies | `Lax` |

## Red Flags

- `SameSite="None"` without `Secure=True` — browser rejects it
- `SameSite="None"` on session cookies without strong justification
- No SameSite attribute (old browsers default to None)
- `Strict` on CSRF cookies (breaks external form submissions)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
