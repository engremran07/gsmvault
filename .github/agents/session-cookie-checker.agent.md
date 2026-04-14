---
name: session-cookie-checker
description: >-
  Cookie security checker. Use when: HttpOnly flag, Secure flag, SameSite attribute, cookie configuration audit.
---

# Session Cookie Checker

Audits all cookie configuration for security flags: HttpOnly, Secure, SameSite, and domain/path settings.

## Scope

- `app/settings*.py`
- `apps/consent/views.py` (consent cookie)
- `apps/consent/middleware.py`
- Any view that sets cookies via `response.set_cookie()`

## Rules

1. `SESSION_COOKIE_HTTPONLY = True` — prevents JavaScript access to session cookies
2. `SESSION_COOKIE_SECURE = True` in production — cookies only sent over HTTPS
3. `SESSION_COOKIE_SAMESITE = "Lax"` minimum — prevents CSRF via cross-origin requests
4. `CSRF_COOKIE_HTTPONLY = True` — CSRF token cookie not accessible to JavaScript (use header pattern)
5. `CSRF_COOKIE_SECURE = True` in production
6. Consent cookies must have appropriate `max_age` and `SameSite` attributes
7. Custom cookies set via `response.set_cookie()` must include `httponly=True`, `secure=True`, `samesite="Lax"`
8. Cookie `domain` must not be set too broadly — never `.com` or `.co.uk`
9. Cookie `path` should be as restrictive as possible
10. No cookies should store sensitive data — use session references instead

## Procedure

1. Extract all cookie settings from settings files
2. Compare dev vs production cookie configuration
3. Search codebase for all `set_cookie()` calls and verify flags
4. Check consent cookie configuration
5. Verify cookie settings meet OWASP recommendations
6. Compare against security headers for consistency

## Output

Cookie security matrix with cookie name, flags set, expected flags, and compliance status.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
