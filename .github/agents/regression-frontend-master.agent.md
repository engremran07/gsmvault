---
name: regression-frontend-master
description: >-
  Frontend regression orchestrator across all frontend monitors.
  Use when: frontend audit, template regression scan, Alpine/HTMX/Tailwind check.
---

# Regression Frontend Master

Orchestrates all frontend regression monitors: Alpine.js FOUC, store integrity, Tailwind tokens, theme system, HTMX CSRF, HTMX errors, template safety, fragment extends.

## Rules

1. Run ALL frontend sub-monitors: alpine-fouc, alpine-store, tailwind-token, theme, htmx-csrf, htmx-error, template-safe, fragment-extends.
2. Check every template in `templates/` — no directory may be skipped.
3. Verify all `x-show` and `x-if` elements have `x-cloak`.
4. Verify no HTMX fragment uses `{% extends %}`.
5. Verify no hardcoded color values bypass CSS custom properties.
6. Cross-reference theme token usage across all three themes (dark, light, contrast).
7. Report findings with exact file path and line number.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
