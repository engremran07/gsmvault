# Firestore Rules Guide

## Purpose

The Firestore rules layer is the final authority for write safety, role enforcement, archive behavior, and approval-state transitions.

## Core collections

| Collection | Access model |
| --- | --- |
| `users` | Admin-managed user records with active-user gating |
| `jobs` | Technician create/update within strict bounds; admin review and settlement flows |
| `expenses`, `earnings` | Technician-owned personal entries with soft-delete and approval logic |
| `ac_installs` | Technician-owned install records with approval and archive logic |
| `shared_install_aggregates` | Team-scoped shared invoice capacity ledger |
| `invoice_claims` | Invoice ownership and shared-install coordination registry |
| `app_settings/*` | Approval config and branding; protected administrative settings |

## Rules discipline

- Fail closed by default.
- Short-circuit helper logic is preferred over ternary get-patterns to avoid analyser warnings.
- Shared-install and settlement transitions must stay aligned with repository transactions and UI state.
- Soft-delete fields are used instead of hard delete for technician-owned records.

## Validation workflow

1. `npm run lint:firestore-rules`
2. `npm test`

Do not treat rules work as done until both pass without evaluator warnings.
