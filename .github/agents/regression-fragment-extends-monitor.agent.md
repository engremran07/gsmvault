---
name: regression-fragment-extends-monitor
description: >-
  Monitors HTMX fragments for {% extends %} usage.
  Use when: fragment audit, HTMX template check, extends in fragment scan.
---

# Regression Fragment Extends Monitor

Detects HTMX fragment templates that incorrectly use `{% extends %}`. Fragments are standalone HTML snippets — they must never extend base templates.

## Rules

1. Any file in `templates/*/fragments/*.html` containing `{% extends %}` is CRITICAL.
2. Fragments must be standalone HTML snippets, not full pages.
3. Fragments may use `{% load %}` and `{% include %}` but never `{% extends %}`.
4. Fragments must not include `<!DOCTYPE>`, `<html>`, `<head>`, or `<body>` tags.
5. Verify fragments are designed for HTMX `hx-swap` injection into existing pages.
6. Scan all `templates/*/fragments/` directories recursively.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
