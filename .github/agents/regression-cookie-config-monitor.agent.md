---
name: regression-cookie-config-monitor
description: >-
  Monitors cookie configuration: HttpOnly, Secure, SameSite.
  Use when: cookie audit, cookie flag check, cookie security scan.
---

# Regression Cookie Config Monitor

Detects cookie configuration regressions: weakened flags on session, CSRF, and consent cookies.

## Rules

1. `SESSION_COOKIE_HTTPONLY = True` in production — change to `False` is CRITICAL (prevents XSS cookie theft).
2. `SESSION_COOKIE_SECURE = True` in production — change to `False` is CRITICAL (HTTPS-only).
3. `CSRF_COOKIE_HTTPONLY = True` — change to `False` is HIGH.
4. `CSRF_COOKIE_SECURE = True` in production — change to `False` is HIGH.
5. `SESSION_COOKIE_SAMESITE = "Lax"` — change to `None` without `Secure` is CRITICAL.
6. Consent cookies must also respect `Secure` and `SameSite` flags.
7. Scan all `settings*.py` files and any code that calls `response.set_cookie()`.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
