---
name: regression-alpine-fouc-monitor
description: >-
  Monitors x-cloak presence on x-show/x-if elements.
  Use when: FOUC audit, Alpine.js cloak check, flash of unstyled content scan.
---

# Regression Alpine FOUC Monitor

Detects Alpine.js FOUC regressions: missing `x-cloak` on conditional elements, animation conflicts with `x-show`.

## Rules

1. Every element with `x-show` must also have `x-cloak` — missing is HIGH.
2. Every element with `x-if` (via `<template>`) must have `x-cloak` on the parent — missing is HIGH.
3. Elements with both `x-show` and CSS `animate-*` classes are forbidden — animation overrides display:none.
4. Verify `[x-cloak] { display: none !important; }` exists in the base CSS — removal is CRITICAL.
5. Scan all templates in `templates/` recursively for violations.
6. Report exact file, line number, and the offending element tag.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
