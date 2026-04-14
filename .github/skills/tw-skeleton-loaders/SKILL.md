---
name: tw-skeleton-loaders
description: "Skeleton loading patterns: animated placeholders. Use when: showing loading states, HTMX loading indicators, placeholder content before data loads."
---

# Skeleton Loading Patterns

## When to Use

- Showing placeholder content while HTMX loads data
- Pre-rendering page structure before API responses
- Improving perceived performance during data fetching

## Rules

1. **Match skeleton shape to loaded content** — same heights, widths, layout
2. **Use `animate-pulse` for subtle breathing effect** — Tailwind built-in
3. **Use `{% include "components/_loading.html" %}`** — for standard loading states
4. **Remove skeleton when content loads** — HTMX swap replaces it
5. **Theme-aware skeleton colours** — use `--color-bg-secondary`

## Patterns

### Basic Skeleton Card

```html
<div class="rounded-lg bg-[var(--color-bg-secondary)] p-4 animate-pulse">
  <!-- Image placeholder -->
  <div class="aspect-[4/3] w-full rounded-md bg-[var(--color-border)]"></div>

  <!-- Title placeholder -->
  <div class="mt-4 h-5 w-3/4 rounded bg-[var(--color-border)]"></div>

  <!-- Description placeholder -->
  <div class="mt-2 space-y-2">
    <div class="h-3 w-full rounded bg-[var(--color-border)]"></div>
    <div class="h-3 w-5/6 rounded bg-[var(--color-border)]"></div>
  </div>

  <!-- Button placeholder -->
  <div class="mt-4 h-9 w-28 rounded-lg bg-[var(--color-border)]"></div>
</div>
```

### Skeleton Table Rows

```html
<table class="w-full">
  <thead>
    <tr class="border-b border-[var(--color-border)]">
      <th class="py-3 text-start text-[var(--color-text-primary)]">Name</th>
      <th class="py-3 text-start text-[var(--color-text-primary)]">Status</th>
      <th class="py-3 text-start text-[var(--color-text-primary)]">Date</th>
    </tr>
  </thead>
  <tbody class="animate-pulse">
    {% for _ in "12345" %}
    <tr class="border-b border-[var(--color-border)]">
      <td class="py-3"><div class="h-4 w-32 rounded bg-[var(--color-border)]"></div></td>
      <td class="py-3"><div class="h-4 w-16 rounded bg-[var(--color-border)]"></div></td>
      <td class="py-3"><div class="h-4 w-24 rounded bg-[var(--color-border)]"></div></td>
    </tr>
    {% endfor %}
  </tbody>
</table>
```

### HTMX Loading Skeleton

```html
<!-- Container with skeleton as initial content -->
<div id="firmware-list"
     hx-get="/firmwares/list/"
     hx-trigger="load"
     hx-swap="innerHTML">
  <!-- Skeleton shown until HTMX replaces it -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    {% for _ in "123456" %}
    <div class="rounded-lg bg-[var(--color-bg-secondary)] p-4 animate-pulse">
      <div class="h-40 w-full rounded-md bg-[var(--color-border)]"></div>
      <div class="mt-3 h-5 w-2/3 rounded bg-[var(--color-border)]"></div>
      <div class="mt-2 h-3 w-full rounded bg-[var(--color-border)]"></div>
    </div>
    {% endfor %}
  </div>
</div>
```

### Profile Skeleton

```html
<div class="flex items-center gap-4 animate-pulse">
  <!-- Avatar -->
  <div class="w-12 h-12 rounded-full bg-[var(--color-border)]"></div>
  <!-- Name + subtitle -->
  <div class="flex-1">
    <div class="h-4 w-32 rounded bg-[var(--color-border)]"></div>
    <div class="mt-2 h-3 w-48 rounded bg-[var(--color-border)]"></div>
  </div>
</div>
```

### Skeleton with hx-indicator

```html
<button hx-get="/api/data/" hx-target="#results"
        class="bg-[var(--color-accent)] text-[var(--color-accent-text)]
               px-4 py-2 rounded-lg">
  <span class="htmx-indicator">
    {% include "components/_loading.html" with size="sm" %}
  </span>
  Load Data
</button>

<div id="results">
  <!-- Skeleton or empty state here -->
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Skeleton doesn't match content shape | Jarring layout shift on load | Match exact dimensions |
| Spinner instead of skeleton | Less informative | Use skeleton for content, spinner for actions |
| Skeleton stays after content loads | Broken swap | Ensure HTMX replaces skeleton container |
| `bg-gray-300` for skeleton | Not theme-aware | `bg-[var(--color-border)]` |

## Red Flags

- Layout shifts when skeleton replaces with real content (size mismatch)
- Skeleton using hardcoded colours instead of theme variables
- Missing loading state on HTMX-powered content areas

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/components/_loading.html` — loading component
- `.claude/rules/htmx-patterns.md` — HTMX loading patterns
