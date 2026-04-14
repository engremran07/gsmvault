---
name: regression-n-plus-one-monitor
description: >-
  Monitors for N+1 query patterns.
  Use when: query performance audit, N+1 check, select_related/prefetch_related scan.
---

# Regression N+1 Monitor

Detects N+1 query patterns: looped FK access without `select_related()` or `prefetch_related()`.

## Rules

1. QuerySets accessed in loops that traverse FK/M2M without `select_related()` or `prefetch_related()` are HIGH.
2. Template loops that access `{{ obj.fk_field.name }}` without the view pre-fetching are HIGH.
3. Serializer nested representations without `select_related()` in the viewset queryset are HIGH.
4. Scan views, services, and serializers for queryset construction patterns.
5. Verify admin `list_display` fields that traverse FKs have corresponding `list_select_related`.
6. Flag any queryset in a loop body (`.filter()` or `.get()` inside `for`) as a potential N+1.
7. Suggest the correct fix: `select_related()` for FK/O2O, `prefetch_related()` for M2M/reverse FK.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
