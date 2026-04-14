---
name: tw-responsive-mobile-first
description: "Mobile-first responsive design with Tailwind breakpoints. Use when: building page layouts, creating responsive components, designing for mobile devices first."
---

# Mobile-First Responsive Design

## When to Use

- Building any new page template or component
- Converting desktop-first CSS to mobile-first
- Adding responsive behaviour to existing templates

## Rules

1. **Always start with mobile styles** — unbreakpointed classes are the mobile base
2. **Add complexity upward** — `sm:`, `md:`, `lg:` add desktop enhancements
3. **Never use `max-width` media queries** — Tailwind is min-width only
4. **Test on 320px viewport minimum** — smallest supported width

## Patterns

### Mobile-First Card Layout

```html
<!-- Mobile: single column → md: 2 columns → lg: 3 columns -->
<div class="grid grid-cols-1 gap-4 px-4
            md:grid-cols-2 md:gap-6 md:px-6
            lg:grid-cols-3 lg:gap-8 lg:px-8">
  <div class="rounded-lg p-4 bg-[var(--color-bg-secondary)]">
    <h3 class="text-base md:text-lg lg:text-xl font-semibold
               text-[var(--color-text-primary)]">Card Title</h3>
    <p class="mt-2 text-sm md:text-base text-[var(--color-text-secondary)]">
      Card content scales with viewport.
    </p>
  </div>
</div>
```

### Mobile-First Navigation

```html
<!-- Mobile: hamburger → lg: horizontal nav -->
<nav class="flex flex-col lg:flex-row lg:items-center lg:gap-6">
  <a href="#" class="py-2 px-4 lg:py-0 lg:px-0
                     text-[var(--color-text-primary)]
                     hover:text-[var(--color-accent)]">Home</a>
  <a href="#" class="py-2 px-4 lg:py-0 lg:px-0
                     text-[var(--color-text-primary)]
                     hover:text-[var(--color-accent)]">Devices</a>
</nav>
```

### Responsive Text Sizing

```html
<h1 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl
           font-bold text-[var(--color-text-primary)]">
  Page Title
</h1>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `lg:hidden block` | Desktop-first thinking | `block lg:hidden` (mobile-first) |
| `@media (max-width: 768px)` in SCSS | Not mobile-first | Use Tailwind breakpoints or `@media (min-width:)` |
| Hiding content on mobile with `hidden sm:block` without alternative | Lost content on mobile | Provide mobile-appropriate alternative |
| Fixed pixel widths without responsive | Breaks on small screens | Use `w-full max-w-[value]` |

## Red Flags

- Any custom CSS using `max-width` media queries
- Templates with no breakpoint classes at all
- Large fixed-width containers without `w-full`
- Images without responsive sizing (`w-full` or `max-w-full`)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/base/base.html` — viewport meta tag
- `static/css/src/main.scss` — custom responsive overrides
- `.claude/rules/responsive-design.md` — responsive design rules
