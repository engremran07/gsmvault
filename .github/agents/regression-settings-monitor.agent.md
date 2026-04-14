---
name: regression-settings-monitor
description: >-
  Monitors settings files: DEBUG in production, secret exposure.
  Use when: settings audit, production safety check, DEBUG flag scan.
---

# Regression Settings Monitor

Detects settings regressions: DEBUG enabled in production, secrets exposed in settings, weakened security settings.

## Rules

1. `DEBUG = True` in `settings_production.py` is CRITICAL — must always be `False`.
2. `SECRET_KEY` must not be hardcoded — must come from environment variable.
3. `ALLOWED_HOSTS = ["*"]` in production is CRITICAL — must be explicit domain list.
4. `SECURE_SSL_REDIRECT` must be `True` in production — `False` is HIGH.
5. `SECURE_HSTS_SECONDS` must be set in production — missing is HIGH.
6. Database credentials must come from environment variables, not hardcoded.
7. Verify `settings_dev.py` does not leak into production via incorrect `DJANGO_SETTINGS_MODULE`.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
