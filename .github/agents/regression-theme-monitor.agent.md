---
name: regression-theme-monitor
description: >-
  Monitors theme system: --color-accent-text edge case.
  Use when: theme audit, contrast theme check, accent color regression scan.
---

# Regression Theme Monitor

Detects theme system regressions: broken `--color-accent-text` handling across dark/light/contrast themes, missing theme variable definitions.

## Rules

1. `--color-accent-text` is WHITE in dark/light but BLACK in contrast — hardcoding `text-white` on accent is CRITICAL.
2. Verify all three themes (dark, light, contrast) define the same set of CSS custom properties.
3. Check `data-theme` attribute switching works correctly in the theme switcher component.
4. Verify theme preference persists in localStorage via Alpine.js store.
5. Flag any component that only works in one theme but breaks in others.
6. Verify contrast theme meets WCAG AAA contrast ratios.
7. Check that `_themes.scss` has no missing variable definitions across theme blocks.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
