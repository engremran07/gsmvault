---
name: auth-session-checker
description: >-
  Audits session configuration for security. Use when: session fixation, session timeout, session rotation, cookie flags, session backend audit.
---

# Auth Session Checker

Audits Django session configuration for security vulnerabilities including fixation, timeout, rotation, and cookie flag misconfiguration.

## Scope

- `app/settings.py`, `app/settings_dev.py`, `app/settings_production.py`
- `apps/users/views.py`
- `app/middleware/*.py`

## Rules

1. `SESSION_COOKIE_HTTPONLY` MUST be `True` — prevents JavaScript access to session cookie
2. `SESSION_COOKIE_SECURE` MUST be `True` in production settings
3. `SESSION_COOKIE_SAMESITE` MUST be `"Lax"` or `"Strict"` — never `None` without explicit justification
4. Session must rotate on login — verify `request.session.cycle_key()` or Django's built-in rotation
5. `SESSION_EXPIRE_AT_BROWSER_CLOSE` should be configured appropriately per environment
6. `SESSION_COOKIE_AGE` must not exceed 86400 (24 hours) for sensitive applications
7. Session backend must be database or cache-backed — never use signed-cookie sessions for sensitive data
8. Verify session is invalidated on password change
9. Check that concurrent session limits are enforced for admin/staff users
10. Session data must never contain plaintext passwords, tokens, or API keys

## Procedure

1. Read all settings files and extract session-related configuration
2. Compare dev vs production settings for security gaps
3. Check login/logout views for proper session handling
4. Verify session rotation on authentication events
5. Scan for session data that may contain sensitive information

## Output

Configuration audit table with current values, expected values, and compliance status.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
