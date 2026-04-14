---
name: tw-responsive-container
description: "Container patterns: max-width, padding, centering. Use when: creating page wrappers, content width constraints, centered layouts."
---

# Responsive Container Patterns

## When to Use

- Wrapping page content in a max-width container
- Setting consistent horizontal padding across pages
- Centering content on wide screens

## Rules

1. **Use `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`** — standard container pattern
2. **Never nest containers** — one container per page section
3. **Full-bleed sections break out of container** — use negative margins or separate sections
4. **Consistent padding scale** — `px-4` mobile → `px-6` tablet → `px-8` desktop

## Patterns

### Standard Page Container

```html
<main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <h1 class="text-2xl font-bold text-[var(--color-text-primary)]">Page Title</h1>
  <div class="mt-6">Content here</div>
</main>
```

### Narrow Content Container (articles, forms)

```html
<div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
  <article class="prose text-[var(--color-text-primary)]">
    Long-form content reads better at narrower widths.
  </article>
</div>
```

### Full-Width Hero + Contained Content

```html
<!-- Full-bleed hero -->
<section class="w-full bg-[var(--color-bg-secondary)] py-16">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <h1 class="text-4xl font-bold text-[var(--color-text-primary)]">Hero</h1>
  </div>
</section>

<!-- Contained content -->
<main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
  <p class="text-[var(--color-text-secondary)]">Regular content</p>
</main>
```

### Container Width Reference

| Class | Max Width | Use Case |
|-------|-----------|----------|
| `max-w-sm` | 24rem (384px) | Login forms, small modals |
| `max-w-xl` | 36rem (576px) | Settings forms, alerts |
| `max-w-3xl` | 48rem (768px) | Blog posts, articles |
| `max-w-5xl` | 64rem (1024px) | Dashboard content |
| `max-w-7xl` | 80rem (1280px) | Standard page container |
| `max-w-full` | 100% | Full-width tables, admin panels |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `container` class without `mx-auto` | Not centered | Use `max-w-7xl mx-auto` |
| Nested `max-w-7xl` containers | Double padding, narrower content | Single container at page level |
| Fixed `width: 1200px` | Not responsive | Use `max-w-7xl w-full` |
| No padding on container | Content touches screen edges | Add `px-4 sm:px-6 lg:px-8` |

## Red Flags

- Pages without any max-width constraint (content stretches to 4K width)
- Inconsistent container widths across pages (some `max-w-6xl`, others `max-w-7xl`)
- Missing horizontal padding on mobile

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/layouts/default.html` — standard page layout container
- `templates/base/base.html` — base template structure
