---
name: cors-policy-checker
description: >-
  CORS configuration auditor. Use when: CORS_ALLOWED_ORIGINS, preflight requests, cross-origin API access, CORS policy review.
---

# CORS Policy Checker

Audits CORS (Cross-Origin Resource Sharing) configuration to prevent overly permissive cross-origin access.

## Scope

- `app/settings.py`, `app/settings_dev.py`, `app/settings_production.py`
- `requirements.txt` (django-cors-headers)

## Rules

1. `CORS_ALLOW_ALL_ORIGINS` must be `False` in production — never allow all origins
2. `CORS_ALLOWED_ORIGINS` must list specific trusted origins, not wildcards
3. `CORS_ALLOW_CREDENTIALS = True` requires explicit origin list — cannot combine with wildcard
4. `CORS_ALLOWED_METHODS` should be restricted to methods actually used by the API
5. `CORS_ALLOWED_HEADERS` should not include unnecessary custom headers
6. `CORS_EXPOSE_HEADERS` should only expose headers the client needs
7. `CORS_PREFLIGHT_MAX_AGE` should be set to reduce preflight request frequency
8. Development settings may use `localhost` origins but must not leak to production
9. CORS middleware must be placed before `CommonMiddleware` in MIDDLEWARE pipeline
10. Private/internal APIs must have more restrictive CORS than public APIs

## Procedure

1. Read CORS settings from all settings files
2. Check for `CORS_ALLOW_ALL_ORIGINS = True`
3. Verify `CORS_ALLOWED_ORIGINS` list is specific and minimal
4. Check middleware pipeline ordering
5. Compare dev vs production CORS settings
6. Verify django-cors-headers is in requirements.txt

## Output

CORS configuration report with settings, compliance status, and recommendations.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
