---
name: escrow-safety-checker
description: >-
  Escrow transaction safety auditor. Use when: escrow hold, escrow release, escrow dispute, marketplace payment safety.
---

# Escrow Safety Checker

Validates escrow transaction patterns for marketplace P2P trades including hold, release, and dispute workflows.

## Scope

- `apps/marketplace/models.py`
- `apps/marketplace/services.py`
- `apps/wallet/services.py`

## Rules

1. Escrow hold must debit buyer wallet atomically with `select_for_update()`
2. Escrow release must credit seller wallet only after buyer confirms delivery
3. Escrow dispute must freeze funds — neither party can withdraw during dispute
4. Admin dispute resolution must support: full refund, full release, or split
5. Escrow state machine must enforce valid transitions: `held` → `released` or `held` → `disputed` → `resolved`
6. Invalid state transitions must raise `ValueError` — not silently skip
7. All escrow operations must create audit trail entries
8. Escrow timeout must auto-release funds after configurable period if buyer doesn't confirm
9. Double-spend prevention: verify buyer has sufficient balance before escrow hold
10. Escrow amounts must use `Decimal` — never `float` for monetary operations

## Procedure

1. Read escrow service functions (hold, release, dispute, resolve)
2. Verify `select_for_update()` on all balance mutations
3. Check state machine transition validation
4. Verify audit trail creation
5. Check timeout/auto-release mechanism
6. Verify balance check before hold

## Output

Escrow safety report with state machine diagram, protection status, and gap analysis.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
