---
name: regression-url-namespace-monitor
description: >-
  Monitors URL namespace integrity: app_name conflicts.
  Use when: URL audit, namespace check, routing conflict scan.
---

# Regression URL Namespace Monitor

Detects URL namespace regressions: conflicting `app_name` values, broken `reverse()` calls, missing namespaces.

## Rules

1. Every app's `urls.py` must define `app_name` matching the app's identity — missing is HIGH.
2. No two apps may share the same `app_name` — conflict is CRITICAL.
3. Every `reverse()` call must use the namespace prefix: `reverse("appname:viewname")`.
4. Every `{% url %}` tag in templates must use the namespace prefix.
5. Verify no URL pattern shadows another due to ordering in `app/urls.py`.
6. Check that removed or renamed URL patterns have corresponding redirects.
7. Flag any `NoReverseMatch` risk from renamed views without updated `reverse()` calls.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
