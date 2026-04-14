---
name: regression-modeladmin-typing-monitor
description: >-
  Monitors ModelAdmin generic typing.
  Use when: ModelAdmin type audit, admin typing check, admin class annotation scan.
---

# Regression ModelAdmin Typing Monitor

Detects ModelAdmin classes missing the generic type parameter required by Pyright/Pylance.

## Rules

1. Every `ModelAdmin` must be typed: `class MyAdmin(admin.ModelAdmin[MyModel]):` — untyped is HIGH.
2. Every `TabularInline` must be typed: `class MyInline(admin.TabularInline[MyModel, ParentModel]):`.
3. Every `StackedInline` must be typed similarly.
4. `get_queryset()` must annotate return type: `def get_queryset(self, request) -> QuerySet[MyModel]:`.
5. Scan all `apps/*/admin.py` files for untyped ModelAdmin subclasses.
6. Report each violation with class name, file, and the correct typed form.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
