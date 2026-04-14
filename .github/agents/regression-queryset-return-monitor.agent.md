---
name: regression-queryset-return-monitor
description: >-
  Monitors get_queryset() return type annotations.
  Use when: queryset type audit, return annotation check, ORM typing scan.
---

# Regression QuerySet Return Monitor

Detects missing or incorrect return type annotations on `get_queryset()` methods.

## Rules

1. Every `get_queryset()` override must annotate return type: `-> QuerySet[MyModel]` — missing is HIGH.
2. Custom manager `get_queryset()` must also be annotated.
3. View `get_queryset()` in CBVs (ListView, etc.) must have return type.
4. Avoid `-> QuerySet` without the generic parameter — always specify the model type.
5. Scan `admin.py`, `views.py`, `managers.py`, and `services.py` for untyped `get_queryset()`.
6. Report each violation with method location and the correct annotation.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
