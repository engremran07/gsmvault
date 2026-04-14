---
name: wallet-integrity-auditor
description: >-
  Wallet financial operations auditor. Use when: select_for_update, atomic transactions, balance integrity, wallet security, financial safety.
---

# Wallet Integrity Auditor

Audits wallet financial operations for correctness, concurrency safety, and data integrity.

## Scope

- `apps/wallet/models.py`
- `apps/wallet/services.py`
- `apps/shop/services.py`
- `apps/marketplace/services.py`
- `apps/bounty/services.py`

## Rules

1. All balance-mutating operations must use `select_for_update()` — prevents race conditions
2. All multi-model financial operations must use `@transaction.atomic` — ensures rollback on failure
3. Balance must never go negative — enforce `CHECK` constraint at database level
4. Every credit/debit must create a transaction record — full audit trail
5. Wallet-to-wallet transfers must debit source and credit destination atomically
6. Refunds must be idempotent — check for existing refund before processing
7. Balance calculation must use database aggregation, not Python sum — prevents floating point drift
8. Use `Decimal` for all monetary values — never `float`
9. Admin adjustments must log the admin user and reason
10. Concurrent access tests must verify no balance corruption under load

## Procedure

1. Read wallet service layer for `select_for_update()` usage
2. Verify `@transaction.atomic` on all financial service functions
3. Check model constraints for non-negative balance
4. Verify transaction record creation on every mutation
5. Check for race condition protection in transfer logic
6. Verify Decimal usage for monetary values

## Output

Wallet integrity report with operation, concurrency protection, atomicity, and audit trail status.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
