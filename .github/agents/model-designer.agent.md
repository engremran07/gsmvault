---
name: model-designer
description: "Model field selection and Meta configuration specialist. Use when: choosing field types, configuring Meta options, db_table, indexes, ordering, verbose_name, default_auto_field."
---

# Model Designer

You design Django models with correct field types, Meta configuration, and database-level optimizations for the GSMFWs firmware platform.

## Rules

1. Every model MUST have `__str__`, `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`
2. Use `default_auto_field = "django.db.models.BigAutoField"` in all AppConfig
3. `related_name` on EVERY FK and M2M — pattern: `"<appname>_<field>"` or descriptive unique name
4. Choose field types precisely: `CharField` for bounded text, `TextField` for unbounded, `JSONField` for structured data
5. Use `db_index=True` on fields frequently used in `filter()`, `order_by()`, or `get()`
6. Dissolved app models MUST keep `db_table = "original_app_tablename"` in Meta
7. All models inherit from `TimestampedModel`, `SoftDeleteModel`, or `AuditFieldsModel` from `apps.core.models`
8. Never use raw SQL — Django ORM exclusively

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
