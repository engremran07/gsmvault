---
name: regression-tailwind-token-monitor
description: >-
  Monitors CSS token usage: hardcoded colors vs variables.
  Use when: design token audit, hardcoded color scan, CSS variable compliance check.
---

# Regression Tailwind Token Monitor

Detects Tailwind CSS token regressions: hardcoded color values instead of CSS custom properties, bypassed design tokens.

## Rules

1. No hardcoded hex colors (`#fff`, `#000`, `#1a1a2e`) in templates — use CSS custom properties via `var(--color-*)`.
2. No hardcoded `text-white` or `text-black` on accent backgrounds — use `text-[var(--color-accent-text)]`.
3. Verify all theme-aware colors use the token system defined in `_variables.scss` and `_themes.scss`.
4. Check that `bg-*`, `text-*`, `border-*` classes use semantic tokens, not raw Tailwind palette colors.
5. Flag any inline `style=""` with hardcoded color values.
6. Verify no Tailwind `dark:` prefix is used — the project uses `data-theme` attribute switching.
7. Report violations with file path, line number, and suggested token replacement.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
