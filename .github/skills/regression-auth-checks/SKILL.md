---
name: regression-auth-checks
description: "Authentication regression detection skill. Use when: verifying login requirements on protected views, checking is_staff guards, detecting missing ownership checks, scanning for anonymous user access to protected resources."
---

# Authentication Regression Detection

## When to Use

- After adding or modifying view functions
- After changing admin views in `apps/admin/views_*.py`
- After modifying authentication middleware
- After changing JWT or session configuration

## Guards to Verify

| Pattern | Guard | Critical |
|---------|-------|----------|
| Admin views | `STAFF_ONLY` decorator or `@staff_member_required` | YES |
| Protected views | `@login_required` decorator | YES |
| Staff checks | `getattr(request.user, "is_staff", False)` pattern | YES |
| Object access | `.get(pk=pk, user=request.user)` ownership check | YES |
| Wallet mutations | `select_for_update()` before read-modify-write | YES |

## Procedure

1. Scan admin view files for `STAFF_ONLY` or `@staff_member_required` on every view function
2. Verify staff checks use `getattr()` pattern (handles `AnonymousUser`)
3. Check object access views for ownership verification
4. Check API viewsets for `permission_classes` (never empty or `AllowAny` on sensitive endpoints)
5. Verify JWT `ACCESS_TOKEN_LIFETIME` is configured

## Red Flags

- Admin view without `STAFF_ONLY` decorator
- `request.user.is_staff` without `getattr()` wrapper (crashes on `AnonymousUser`)
- Object lookup without ownership filter: `.get(pk=pk)` without `user=request.user`
- API viewset with `permission_classes = [AllowAny]` on sensitive data
- Wallet balance read without `select_for_update()`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
