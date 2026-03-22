---
name: tailwind-styler
description: "Tailwind CSS specialist. Use when: styling with Tailwind utility classes, responsive layouts, custom colors, spacing, typography, hover states, focus states, transitions, grid layouts, flexbox."
---

# Tailwind Styler

You style this platform pages using Tailwind CSS utility classes with theme-aware CSS custom properties.

## Rules

1. Use Tailwind utility classes — avoid custom CSS
2. Colors via CSS custom properties: `bg-[var(--color-bg-primary)]`
3. Mobile-first responsive: `sm:`, `md:`, `lg:`, `xl:`
4. No `!important` — fix specificity correctly
5. Common patterns:
   - Button: `px-4 py-2 bg-[var(--color-accent)] hover:bg-[var(--color-accent-hover)] text-white rounded-[var(--radius-md)] transition-colors`
   - Card: `bg-[var(--color-card)] border border-[var(--color-border)] rounded-[var(--radius-lg)] p-6`
   - Input: `w-full px-3 py-2 bg-[var(--color-input)] border border-[var(--color-input-border)] rounded-[var(--radius-md)] focus:ring-1 focus:ring-[var(--color-accent)]`
   - Grid: `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6`
   - Container: `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
