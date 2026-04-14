---
name: regression-type-safety
description: "Type safety regression detection skill. Use when: checking type hints on public APIs, verifying ModelAdmin typing, detecting blanket type:ignore, scanning for missing return type annotations."
---

# Type Safety Regression Detection

## When to Use

- After adding or modifying public functions/methods
- After creating or modifying `ModelAdmin` classes
- After adding `# type: ignore` comments
- After changing model `get_queryset()` return types

## Guards to Verify

| Rule | Guard | Critical |
|------|-------|----------|
| ModelAdmin typed | `admin.ModelAdmin[MyModel]` | YES |
| get_queryset return | `-> QuerySet[MyModel]` | YES |
| No blanket ignore | `# type: ignore[specific-code]` only | YES |
| Public API hints | All params + return typed | MEDIUM |
| Reverse FK managers | `# type: ignore[attr-defined]` | LOW |

## Procedure

1. Scan new `ModelAdmin` classes for type parameter
2. Scan `get_queryset()` methods for return type annotation
3. Search for `# type: ignore` without error code specifier
4. Check new public functions for type hints on parameters and return
5. Verify Django reverse FK access uses `[attr-defined]` ignore

## Red Flags

- `class MyAdmin(admin.ModelAdmin):` — missing `[MyModel]` type parameter
- `def get_queryset(self, request):` — missing `-> QuerySet[MyModel]`
- `# type: ignore` without specifier (e.g., not `[attr-defined]`)
- Public function with `def foo(x, y):` — no type hints
- `mypy: ignore-errors` or `pyright: ignore` blanket suppressions

## Pyright Authoritative Rules

Pyright is the authoritative type checker. When Pyright and mypy conflict, follow Pyright.

Common fixes:
- `solo.models` → `# type: ignore[import-untyped]`
- Reverse FK managers → `# type: ignore[attr-defined]`
- QuerySet.first() returns Optional → narrow before use

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
