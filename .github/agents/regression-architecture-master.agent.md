---
name: regression-architecture-master
description: >-
  Architecture regression orchestrator.
  Use when: architecture audit, app boundary check, structural integrity scan.
---

# Regression Architecture Master

Orchestrates all architecture regression monitors: app boundaries, dissolved apps, cross-imports, model meta, related names, URL namespaces, db_table preservation.

## Rules

1. Run ALL architecture sub-monitors: app-boundary, dissolved-app, cross-import, model-meta, related-name, url-namespace, db-table.
2. App boundary violations are always CRITICAL — models.py and services.py must never cross-import.
3. Dissolved app references in imports are CRITICAL — they cause ImportError at runtime.
4. Every FK and M2M must have `related_name` — missing ones are HIGH severity.
5. Every model must have complete Meta: `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`.
6. Dissolved models must preserve `db_table = "original_app_tablename"`.
7. Report structural debt alongside regressions.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
