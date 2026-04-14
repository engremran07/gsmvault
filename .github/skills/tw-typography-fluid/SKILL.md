---
name: tw-typography-fluid
description: "Fluid typography: clamp(), viewport-relative sizing. Use when: creating text that scales smoothly between breakpoints, responsive headings, hero text."
---

# Fluid Typography

## When to Use

- Hero headings that scale smoothly with viewport
- Avoiding abrupt text size jumps between breakpoints
- Large display text that adapts to any screen size

## Rules

1. **Use `clamp()` for fluid sizing** — `clamp(min, preferred, max)`
2. **Preferred value uses `vw` units** — scales with viewport width
3. **Always set min and max bounds** — prevents unreadable extremes
4. **Body text stays fixed** — fluid sizing for headings/display text only
5. **Test at 320px and 2560px** — verify both extremes

## Patterns

### Fluid Hero Heading

```html
<h1 class="font-bold tracking-tight text-[var(--color-text-primary)]"
    style="font-size: clamp(1.875rem, 4vw + 1rem, 3.75rem)">
  GSM Firmware Distribution
</h1>
```

### Fluid Scale Reference

| Element | clamp() Value | 320px | 768px | 1440px |
|---------|---------------|-------|-------|--------|
| Hero H1 | `clamp(1.875rem, 4vw + 1rem, 3.75rem)` | 30px | ~42px | 60px |
| Page H1 | `clamp(1.5rem, 2.5vw + 0.75rem, 2.25rem)` | 24px | ~30px | 36px |
| Section H2 | `clamp(1.25rem, 1.5vw + 0.75rem, 1.75rem)` | 20px | ~24px | 28px |
| Large body | `clamp(1rem, 0.5vw + 0.875rem, 1.125rem)` | 16px | ~17px | 18px |

### Using CSS Custom Properties

```scss
/* static/css/src/_typography.scss */
:root {
  --text-fluid-hero: clamp(1.875rem, 4vw + 1rem, 3.75rem);
  --text-fluid-h1: clamp(1.5rem, 2.5vw + 0.75rem, 2.25rem);
  --text-fluid-h2: clamp(1.25rem, 1.5vw + 0.75rem, 1.75rem);
}
```

```html
<h1 class="font-bold text-[var(--text-fluid-hero)]
           text-[var(--color-text-primary)]">
  Fluid Hero Title
</h1>
```

### With Tailwind Arbitrary Values

```html
<!-- Fluid without inline style -->
<h1 class="text-[clamp(1.5rem,3vw+0.5rem,3rem)]
           font-bold text-[var(--color-text-primary)]">
  Scales Smoothly
</h1>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `font-size: 5vw` without clamp | Too small on mobile, too large on 4K | Wrap in `clamp()` |
| Fluid body text | Unnecessary, confusing | Keep body at `text-base` (1rem) |
| `clamp(0.5rem, ...)` | Minimum too small to read | Min at least `1rem` for body, `1.25rem` for headings |
| Only using breakpoint classes for headings | Abrupt size jumps | Use `clamp()` for smooth scaling |

## Red Flags

- Viewport-relative units (`vw`, `vh`) without `clamp()` bounds
- Fluid sizing on body paragraph text (keep fixed)
- Min value below readable threshold

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_variables.scss` — typography variables
- `templates/base/base.html` — viewport meta tag
