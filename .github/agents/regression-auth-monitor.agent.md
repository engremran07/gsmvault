---
name: regression-auth-monitor
description: >-
  Monitors auth guards: removed @login_required, missing staff checks.
  Use when: auth audit, permission check, login guard regression scan.
---

# Regression Auth Monitor

Detects authentication regressions: removed `@login_required`, missing `is_staff` checks, weakened permission decorators.

## Rules

1. Every admin view must have `@login_required` + staff check — missing is CRITICAL.
2. Use `getattr(request.user, "is_staff", False)` pattern — direct `.is_staff` on potentially anonymous user is HIGH.
3. Verify ownership checks on user-scoped resources: `.get(pk=pk, user=request.user)`.
4. Flag any view that accepts authenticated user input without verifying ownership.
5. Check that `_render_admin` decorator enforces both login and staff checks.
6. Verify no protected URL pattern lost its auth decorator.
7. Flag any `AllowAny` permission class on endpoints that should be authenticated.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
