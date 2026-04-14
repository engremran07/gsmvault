---
name: regression-htmx-csrf-monitor
description: >-
  Monitors HTMX CSRF: global hx-headers, form tokens.
  Use when: HTMX CSRF audit, hx-headers check, HTMX form security scan.
---

# Regression HTMX CSRF Monitor

Detects HTMX-specific CSRF regressions: removed global `hx-headers` CSRF injection, missing tokens in HTMX forms.

## Rules

1. Verify `<body hx-headers='{"X-CSRFToken": "..."}'>` exists in `base.html` — removal is CRITICAL.
2. Verify the CSRF token in `hx-headers` uses `{% csrf_token %}` or `{{ csrf_token }}` correctly.
3. Check all HTMX POST/PUT/DELETE/PATCH forms include CSRF protection.
4. Verify no HTMX request bypasses CSRF via custom JavaScript overrides.
5. Flag any `htmx.config.getCsrfToken` override that weakens CSRF protection.
6. Ensure HTMX meta tag pattern is consistent across all base templates.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
