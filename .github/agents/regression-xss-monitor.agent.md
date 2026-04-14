---
name: regression-xss-monitor
description: >-
  Monitors for XSS regression: removed sanitization, |safe without source.
  Use when: XSS audit, sanitization check, template safe filter scan.
---

# Regression XSS Monitor

Detects XSS regressions: removed nh3 sanitization calls, `|safe` usage without upstream sanitization, inline HTML rendering without escaping.

## Rules

1. Scan all templates for `|safe` filter — each must have a verified sanitization source.
2. Scan all models and services for `sanitize_html_content()` or `sanitize_ad_code()` — removals are CRITICAL.
3. Verify `apps.core.sanitizers` is the sole sanitization provider — no inline sanitization.
4. Never use `bleach` — it is deprecated; only `nh3` is allowed.
5. Check Alpine.js `x-html` directives for unsanitized user content.
6. Verify HTMX swap targets do not render raw user input without server-side escaping.
7. Flag any `mark_safe()` usage without prior nh3 sanitization.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
