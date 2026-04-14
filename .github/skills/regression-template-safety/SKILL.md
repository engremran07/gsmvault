---
name: regression-template-safety
description: "Template regression detection skill. Use when: checking HTMX fragments for extends usage, verifying x-cloak on Alpine conditionals, detecting inline duplicates of reusable components, scanning for animation conflicts."
---

# Template Safety Regression Detection

## When to Use

- After editing or creating HTML templates
- After modifying HTMX fragments
- After adding Alpine.js interactivity to templates
- After modifying reusable components

## Guards to Verify

| Rule | Guard | Critical |
|------|-------|----------|
| Fragments standalone | No `{% extends %}` in `fragments/` templates | YES |
| FOUC prevention | `x-cloak` on every `x-show`/`x-if` element | YES |
| Animation conflict | No CSS `animate-*` on `x-show` elements | YES |
| Component reuse | No inline duplicates of `templates/components/` | MEDIUM |
| Theme tokens | No hardcoded `text-white` on accent backgrounds | MEDIUM |

## Procedure

1. Scan `templates/*/fragments/` for `{% extends %}` — FORBIDDEN
2. Scan for `x-show=` without `x-cloak` on the same element
3. Scan for `x-show=` with `animate-` class on the same element
4. Scan admin templates for inline KPI cards (should use component)
5. Scan for hardcoded `text-white` on elements with accent backgrounds

## Red Flags

- `{% extends "base/base.html" %}` in a fragment file
- `x-show="..."` without `x-cloak` attribute
- `x-show="..." class="animate-fadeIn"` (animation overrides display:none)
- Inline `<div class="bg-... p-4 rounded-lg">` in admin (should be KPI card component)
- `text-white` hardcoded where `text-[var(--color-accent-text)]` should be used

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
