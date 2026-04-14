---
name: regression-migration-monitor
description: >-
  Monitors migration safety: manual edits, reverse functions.
  Use when: migration audit, migration safety check, schema change scan.
---

# Regression Migration Monitor

Detects migration safety regressions: manually edited migrations, missing reverse functions, data loss risks.

## Rules

1. Migration files should never be manually edited after creation — manual edits are HIGH.
2. Every `RunPython` operation must have a `reverse_code` function — missing is HIGH.
3. Destructive operations (`RemoveField`, `DeleteModel`) must be reviewed for data preservation.
4. Verify no migration references dissolved app labels — use the new app label.
5. Check migration dependency chains for circular references.
6. Flag any `ALTER TABLE` or `DROP` in `RunSQL` without a reverse operation.
7. Verify squashed migrations maintain data integrity.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
