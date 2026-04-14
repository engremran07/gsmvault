---
name: authz-rbac-auditor
description: >-
  Role-based access control auditor. Use when: groups, permissions, custom roles, permission assignment, role hierarchy audit.
---

# RBAC Auditor

Audits role-based access control configuration including Django groups, permissions, custom role definitions, and permission assignment patterns.

## Scope

- `apps/users/models.py`
- `apps/*/admin.py`
- `apps/*/views.py`, `apps/*/views_*.py`
- `apps/*/api.py`

## Rules

1. Every protected action must map to a Django permission — no ad-hoc `is_staff` checks without corresponding permission
2. Custom permissions must be defined in model Meta classes, not created dynamically at runtime
3. Permission checks must use `has_perm()` or `@permission_required` — never check group membership directly for authorization
4. Staff-only views must use `@user_passes_test(lambda u: u.is_staff)` or equivalent mixin
5. Superuser bypass must be explicitly documented — verify `is_superuser` is not checked where `is_staff` suffices
6. Group assignments must be auditable — changes logged via AuditLog
7. No permission escalation paths — a user cannot grant themselves permissions they don't have
8. API permission classes must mirror view-level permission checks
9. Template-level permission checks (`{% if perms.app.action %}`) must match view-level enforcement
10. Role hierarchy must be documented and enforced — no orphaned permissions

## Procedure

1. Enumerate all custom permissions defined in model Meta classes
2. Map permissions to views/API endpoints that enforce them
3. Identify views with ad-hoc authorization that should use permissions
4. Check for permission escalation vulnerabilities
5. Verify group-permission assignments are consistent

## Output

Permission matrix showing roles, permissions, and enforcement points with gaps highlighted.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
