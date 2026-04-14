---
name: auth-bypass-detector
description: >-
  Detects authentication bypass vulnerabilities. Use when: missing login_required, unprotected endpoints, auth bypass, anonymous access to protected views.
---

# Auth Bypass Detector

Scans all views, API endpoints, and URL patterns to detect missing authentication guards. Identifies endpoints accessible to anonymous users that should require authentication.

## Scope

- `apps/*/views.py`, `apps/*/views_*.py`
- `apps/*/api.py`
- `apps/*/urls.py`
- `app/urls.py`

## Rules

1. Every view that mutates data (POST/PUT/PATCH/DELETE) MUST have `@login_required` or `LoginRequiredMixin`
2. Admin views MUST check both `@login_required` AND `is_staff` (or use `_render_admin` decorator)
3. API views MUST have `permission_classes` defined — never rely on default global permissions alone
4. Never use `@csrf_exempt` as a workaround for auth issues
5. All ownership checks must use `.get(pk=pk, user=request.user)` pattern — never trust user-supplied IDs without ownership validation
6. Anonymous-safe views must use `getattr(request.user, "is_staff", False)` pattern, not `request.user.is_staff` directly
7. URL patterns for protected resources must not be guessable (no sequential integer IDs without permission checks)
8. Password reset and email verification endpoints must validate tokens server-side before granting access
9. Detect views that accept `user_id` as a parameter without verifying the requesting user matches
10. Flag any `AllowAny` permission class on endpoints that handle sensitive data

## Procedure

1. Grep all views for `def ` and `class ` definitions
2. Check each view for authentication decorators or mixins
3. Cross-reference with URL patterns to find unprotected routes
4. Verify API ViewSets have explicit `permission_classes`
5. Check for ownership validation on detail/update/delete views
6. Report all unprotected endpoints with severity rating

## Output

Table of unprotected endpoints with file path, view name, HTTP methods, and recommended fix.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
