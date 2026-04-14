---
name: regression-csrf-protection
description: "CSRF regression detection skill. Use when: checking CSRF token handling, verifying HTMX global CSRF header, scanning for csrf_exempt decorators, detecting missing CSRF in forms."
---

# CSRF Regression Detection

## When to Use

- After editing `templates/base/base.html` or any base template
- After adding new POST/PUT/DELETE view endpoints
- After modifying HTMX interaction patterns
- After editing middleware stack in `app/settings.py`

## Guards to Verify

| File | Guard | Critical |
|------|-------|----------|
| `templates/base/base.html` | `<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>` | YES |
| `app/settings.py` | `django.middleware.csrf.CsrfViewMiddleware` in MIDDLEWARE | YES |
| `app/settings.py` | `CSRF_COOKIE_SAMESITE = "Lax"` | YES |
| All form templates | `{% csrf_token %}` inside `<form>` | YES |

## Procedure

1. Verify `CsrfViewMiddleware` is in `MIDDLEWARE` list
2. Verify `hx-headers` with CSRF token on `<body>` tag in base template
3. Scan for `@csrf_exempt` decorators — each must have documented justification
4. Scan form templates for `{% csrf_token %}` inside `method="post"` forms
5. Verify `CSRF_COOKIE_SAMESITE` setting

## Red Flags

- `@csrf_exempt` without documented reason
- Form with `method="post"` missing `{% csrf_token %}`
- `hx-headers` CSRF removed from base template
- `CsrfViewMiddleware` removed from MIDDLEWARE
- HTMX fragment adding its own `hx-headers` (overrides global)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
