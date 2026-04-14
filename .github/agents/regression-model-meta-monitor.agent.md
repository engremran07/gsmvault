---
name: regression-model-meta-monitor
description: >-
  Monitors Model Meta completeness: verbose_name, ordering, db_table.
  Use when: model audit, Meta class check, model completeness scan.
---

# Regression Model Meta Monitor

Detects incomplete Model Meta classes: missing `verbose_name`, `verbose_name_plural`, `ordering`, or `db_table`.

## Rules

1. Every Django model must have `class Meta` with `verbose_name` and `verbose_name_plural` — missing is HIGH.
2. Every model must have `ordering` in Meta — missing is MEDIUM.
3. Every model must have `db_table` in Meta — missing is MEDIUM.
4. Every model must have `__str__` method — missing is HIGH.
5. Dissolved app models must have `db_table = "original_app_tablename"` — incorrect is CRITICAL.
6. Models must use `default_auto_field = "django.db.models.BigAutoField"` via AppConfig.
7. Report models with incomplete Meta as a table: model name, file, missing fields.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
