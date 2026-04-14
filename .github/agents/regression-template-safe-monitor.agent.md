---
name: regression-template-safe-monitor
description: >-
  Monitors |safe usage in templates without sanitization.
  Use when: template XSS audit, safe filter check, unsanitized output scan.
---

# Regression Template Safe Monitor

Detects `|safe` filter usage in templates without verified upstream sanitization.

## Rules

1. Every `{{ variable|safe }}` must have a verified sanitization source — unsanitized is CRITICAL.
2. Sanitization must use `apps.core.sanitizers.sanitize_html_content()` or `sanitize_ad_code()`.
3. Check the view/context processor that provides the variable — verify it sanitizes before passing to template.
4. `|safe` on user-generated content without sanitization is an XSS vulnerability.
5. `|safe` on admin-only content is MEDIUM but still requires documentation.
6. Scan all `templates/**/*.html` files recursively.
7. Report each `|safe` usage with file, line, variable name, and sanitization status.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
