---
name: regression-csrf-monitor
description: >-
  Monitors CSRF protection: missing tokens, exempt decorators.
  Use when: CSRF audit, form security check, exempt decorator scan.
---

# Regression CSRF Monitor

Detects CSRF regressions: missing `{% csrf_token %}` in forms, added `@csrf_exempt` decorators, weakened CSRF middleware.

## Rules

1. Every `<form method="post">` must contain `{% csrf_token %}` — missing is CRITICAL.
2. Every `@csrf_exempt` must have a documented security justification — unjustified is HIGH.
3. Verify `django.middleware.csrf.CsrfViewMiddleware` is in MIDDLEWARE — removal is CRITICAL.
4. Verify `CSRF_TRUSTED_ORIGINS` is not set to wildcard or overly broad domains.
5. Check that HTMX global CSRF injection in `base.html` `<body hx-headers>` is intact.
6. Verify no view accepts POST without CSRF validation unless explicitly API + token auth.
7. Flag any `CSRF_COOKIE_HTTPONLY = False` in settings.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
