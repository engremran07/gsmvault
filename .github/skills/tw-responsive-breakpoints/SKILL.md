---
name: tw-responsive-breakpoints
description: "Breakpoint management: sm, md, lg, xl, 2xl. Use when: choosing breakpoints, setting responsive thresholds, managing screen size transitions."
---

# Breakpoint Management

## When to Use

- Deciding which breakpoint to apply a style change at
- Building responsive layouts with multiple breakpoint tiers
- Debugging layout shifts at specific screen widths

## Rules

1. **Use standard Tailwind v4 breakpoints** — do not define custom breakpoints unless absolutely required
2. **Each breakpoint is min-width** — `md:` means 768px and up
3. **Maximum 3 breakpoint tiers per element** — avoid breakpoint sprawl
4. **Group related breakpoint changes** — keep responsive classes together per breakpoint

## Patterns

### Breakpoint Reference

| Prefix | Min Width | Typical Use |
|--------|-----------|-------------|
| (none) | 0px | Mobile base |
| `sm:` | 640px | Large phones, small tablets |
| `md:` | 768px | Tablets |
| `lg:` | 1024px | Laptops |
| `xl:` | 1280px | Desktops |
| `2xl:` | 1536px | Large monitors |

### Multi-Breakpoint Grid

```html
<div class="grid grid-cols-1 gap-4
            sm:grid-cols-2
            lg:grid-cols-3
            xl:grid-cols-4">
  {% for item in items %}
  <div class="rounded-lg border border-[var(--color-border)]
              bg-[var(--color-bg-secondary)] p-4">
    {{ item.name }}
  </div>
  {% endfor %}
</div>
```

### Breakpoint-Aware Visibility

```html
<!-- Show/hide based on screen size -->
<div class="block md:hidden">Mobile menu button</div>
<div class="hidden md:flex">Desktop navigation</div>

<!-- Different content per tier -->
<span class="inline sm:hidden">S</span>
<span class="hidden sm:inline lg:hidden">Small+</span>
<span class="hidden lg:inline">Full Label Text</span>
```

### Responsive Spacing

```html
<section class="py-8 px-4
                md:py-12 md:px-8
                lg:py-16 lg:px-12
                xl:py-20 xl:px-16">
  <div class="max-w-7xl mx-auto">Content</div>
</section>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `sm:text-sm md:text-base lg:text-lg xl:text-xl 2xl:text-2xl` | Over-breakpointed | Use 2-3 tiers: `text-sm md:text-base xl:text-lg` |
| Custom `@screen 600px` | Non-standard breakpoint | Use nearest standard: `sm:` (640px) |
| Breakpoints on every element | Maintenance burden | Use container/parent breakpoints, children inherit |

## Red Flags

- More than 4 breakpoint prefixes on a single element
- Custom breakpoint values in SCSS bypassing Tailwind
- Inconsistent breakpoint usage (some pages use `md:`, others use `lg:` for the same layout shift)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/main.scss` — custom breakpoint overrides if any
- `.claude/rules/responsive-design.md` — responsive design rules
