---
name: regression-cors-monitor
description: >-
  Monitors CORS policy: CORS_ALLOWED_ORIGINS configuration.
  Use when: CORS audit, origin check, cross-origin policy scan.
---

# Regression CORS Monitor

Detects CORS policy regressions: overly permissive origins, wildcard access, weakened CORS headers.

## Rules

1. `CORS_ALLOW_ALL_ORIGINS = True` is CRITICAL in production — must be `False`.
2. `CORS_ALLOWED_ORIGINS` must be an explicit list of trusted domains — wildcard is CRITICAL.
3. `CORS_ALLOW_CREDENTIALS = True` combined with permissive origins is CRITICAL.
4. Verify `django-cors-headers` middleware is in MIDDLEWARE at the correct position.
5. Check that `CORS_ALLOWED_ORIGIN_REGEXES` does not match overly broad patterns.
6. Flag any CORS configuration change that broadens access without security review.
7. Verify API endpoints that need CORS have it, and internal endpoints do not.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
