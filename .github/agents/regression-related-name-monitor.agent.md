---
name: regression-related-name-monitor
description: >-
  Monitors FK/M2M related_name presence.
  Use when: related_name audit, FK check, M2M relationship scan.
---

# Regression Related Name Monitor

Detects missing `related_name` on ForeignKey and ManyToManyField declarations.

## Rules

1. Every `ForeignKey` must have an explicit `related_name` — missing is HIGH.
2. Every `ManyToManyField` must have an explicit `related_name` — missing is HIGH.
3. Every `OneToOneField` must have an explicit `related_name` — missing is HIGH.
4. Related name pattern should be descriptive: `"<appname>_<field>"` or a unique descriptive name.
5. No two related_names on the same target model may clash — duplicates are CRITICAL.
6. Scan all `apps/*/models.py` files for FK/M2M without `related_name`.
7. Report as a table: model, field name, field type, target model, status.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
