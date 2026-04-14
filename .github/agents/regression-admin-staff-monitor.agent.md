---
name: regression-admin-staff-monitor
description: >-
  Monitors admin staff checks: getattr pattern.
  Use when: admin auth audit, staff check pattern, anonymous user safety scan.
---

# Regression Admin Staff Monitor

Detects admin staff check regressions: direct `.is_staff` access on potentially anonymous users, missing staff guards.

## Rules

1. Use `getattr(request.user, "is_staff", False)` — direct `request.user.is_staff` on anonymous user raises AttributeError — wrong pattern is HIGH.
2. Every admin view must enforce both `@login_required` and staff check — missing either is CRITICAL.
3. The `_render_admin` decorator must enforce both checks — weakening is CRITICAL.
4. Verify no admin URL pattern is accessible without authentication.
5. Check that `user_passes_test(lambda u: u.is_staff)` is used correctly.
6. Flag any admin view that uses `AllowAny` or `IsAuthenticated` without staff check.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
