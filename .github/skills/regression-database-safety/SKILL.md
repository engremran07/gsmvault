---
name: regression-database-safety
description: "Database safety regression detection skill. Use when: checking for raw SQL, verifying select_for_update on financial ops, detecting missing transaction.atomic, scanning for N+1 query patterns."
---

# Database Safety Regression Detection

## When to Use

- After modifying service layer code with ORM queries
- After changing wallet/financial operations
- After editing models with dissolved app `db_table`
- After adding new queryset operations in views

## Guards to Verify

| Rule | Guard | Critical |
|------|-------|----------|
| No raw SQL | Django ORM exclusively | YES |
| Wallet safety | `select_for_update()` on balance mutations | YES |
| Atomic transactions | `@transaction.atomic` on multi-model writes | YES |
| Dissolved db_table | `db_table = "original_app_tablename"` preserved | YES |
| N+1 prevention | `select_related()`/`prefetch_related()` on FK traversals | MEDIUM |

## Procedure

1. Grep for `raw(`, `cursor()`, `execute(` — must NOT be in application code
2. Grep for wallet/credit balance changes — must have `select_for_update()`
3. Verify multi-model service functions have `@transaction.atomic`
4. Check dissolved models still have original `db_table` in Meta
5. Scan view loops for queryset access without prefetch

## Red Flags

- `connection.cursor()` or `.raw()` in any app code
- `Wallet.objects.get(user=user)` without `.select_for_update()`
- Service function writing to 2+ models without `@transaction.atomic`
- Dissolved model with changed `db_table` (data loss risk)
- `for item in queryset: item.related_fk.name` without prefetch

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
