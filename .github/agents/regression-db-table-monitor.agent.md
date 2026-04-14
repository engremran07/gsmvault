---
name: regression-db-table-monitor
description: >-
  Monitors dissolved app db_table preservation.
  Use when: db_table audit, dissolved model check, table name integrity scan.
---

# Regression DB Table Monitor

Detects broken `db_table` preservation on dissolved app models. Dissolved models must keep their original table names to preserve data.

## Rules

1. Every model migrated from a dissolved app must have `db_table = "original_app_tablename"` in Meta — missing is CRITICAL.
2. Dissolved app → target app mapping must be consistent with the documented migration table.
3. Changing a `db_table` value on a dissolved model causes data loss — change is CRITICAL.
4. Verify `db_table` format follows Django's default: `"appname_modelname"` using the original app name.
5. Scan all target apps for models that came from dissolved apps.
6. Cross-reference with the dissolved apps table in AGENTS.md.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
