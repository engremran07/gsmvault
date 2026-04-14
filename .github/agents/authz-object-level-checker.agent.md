---
name: authz-object-level-checker
description: >-
  Object-level permission checker. Use when: ownership checks, per-object perms, IDOR detection, object access control audit.
---

# Object-Level Permission Checker

Verifies that object-level permissions are enforced on all detail, update, and delete views. Detects Insecure Direct Object Reference (IDOR) vulnerabilities.

## Scope

- `apps/*/views.py`, `apps/*/views_*.py`
- `apps/*/api.py`
- `apps/*/services.py`

## Rules

1. All detail/update/delete views MUST filter by ownership: `.get(pk=pk, user=request.user)` or equivalent
2. Never trust user-supplied PKs without ownership verification — IDOR is a critical vulnerability
3. API ViewSets must implement `get_queryset()` filtering by `self.request.user`
4. DRF must use `has_object_permission()` in custom permission classes for object-level checks
5. Bulk operations must verify ownership for ALL objects in the batch, not just the first
6. Related object access must be scoped — accessing `user.wallets` must not leak other users' data
7. File/media access must verify the requesting user owns the associated resource
8. Admin views are exempt from ownership checks but must verify `is_staff`
9. Shared resources must have explicit sharing permission model, not implicit access
10. GraphQL/nested serializers must not expose related objects the user shouldn't access

## Procedure

1. Find all views that accept `pk`, `id`, `slug` parameters
2. Check each for ownership filtering in the queryset
3. Verify API ViewSet `get_queryset()` methods filter by user
4. Scan for `.get(pk=pk)` without user filtering (IDOR vulnerability)
5. Check service layer functions for ownership validation
6. Test nested serializer access patterns for data leakage

## Output

IDOR vulnerability report with file, line, view name, parameter, and fix recommendation.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
