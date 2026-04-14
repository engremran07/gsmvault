---
name: regression-session-monitor
description: >-
  Monitors session security: cookie flags, timeout config.
  Use when: session audit, cookie security check, session fixation scan.
---

# Regression Session Monitor

Detects session security regressions: weakened cookie flags, extended timeouts, disabled session rotation.

## Rules

1. Verify `SESSION_COOKIE_HTTPONLY = True` in production settings — change to False is CRITICAL.
2. Verify `SESSION_COOKIE_SECURE = True` in production — change to False is CRITICAL.
3. Verify `SESSION_COOKIE_SAMESITE` is set to `"Lax"` or `"Strict"` — `None` without justification is HIGH.
4. Verify session timeout `SESSION_COOKIE_AGE` is not extended beyond security baseline.
5. Verify session rotation on login via `request.session.cycle_key()` or Django default behavior.
6. Flag any `SESSION_ENGINE` change without security review.
7. Verify `SESSION_EXPIRE_AT_BROWSER_CLOSE` setting matches security requirements.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
