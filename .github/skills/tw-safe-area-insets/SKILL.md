---
name: tw-safe-area-insets
description: "Safe area insets for mobile notches/rounded corners. Use when: supporting iPhone notch, dynamic island, Android display cutouts, edge-to-edge mobile layouts."
---

# Safe Area Insets

## When to Use

- Building edge-to-edge mobile layouts
- Handling iPhone notch / Dynamic Island
- Supporting Android display cutouts
- Fixed bars (navigation, tab bars) on modern mobile devices

## Rules

1. **Set `viewport-fit=cover`** in viewport meta tag to enable safe areas
2. **Use `env(safe-area-inset-*)` for padding** — notch-safe spacing
3. **Fixed bottom bars need bottom inset** — prevent content behind home indicator
4. **Fixed top bars need top inset** — clear the notch/Dynamic Island
5. **Fallback to 0px** — `env(safe-area-inset-top, 0px)` for non-notch devices

## Patterns

### Viewport Meta Tag

```html
<!-- templates/base/base.html -->
<meta name="viewport"
      content="width=device-width, initial-scale=1, viewport-fit=cover">
```

### Fixed Top Navigation (notch-safe)

```html
<nav class="fixed top-0 left-0 right-0 z-40
            bg-[var(--color-bg-primary)] border-b border-[var(--color-border)]"
     style="padding-top: env(safe-area-inset-top, 0px)">
  <div class="max-w-7xl mx-auto px-4 py-3
              flex items-center justify-between">
    <span class="font-bold text-[var(--color-text-primary)]">GSMFWs</span>
  </div>
</nav>
```

### Fixed Bottom Tab Bar

```html
<div class="fixed bottom-0 left-0 right-0 z-40
            bg-[var(--color-bg-primary)] border-t border-[var(--color-border)]
            md:hidden"
     style="padding-bottom: env(safe-area-inset-bottom, 0px)">
  <div class="flex items-center justify-around py-2">
    <a href="#" class="flex flex-col items-center gap-1 text-xs
                       text-[var(--color-text-secondary)]">
      <i data-lucide="home" class="w-5 h-5"></i>
      <span>Home</span>
    </a>
    <a href="#" class="flex flex-col items-center gap-1 text-xs
                       text-[var(--color-accent)]">
      <i data-lucide="search" class="w-5 h-5"></i>
      <span>Search</span>
    </a>
  </div>
</div>
```

### SCSS Custom Properties for Safe Areas

```scss
/* static/css/src/_variables.scss */
:root {
  --safe-top: env(safe-area-inset-top, 0px);
  --safe-bottom: env(safe-area-inset-bottom, 0px);
  --safe-left: env(safe-area-inset-left, 0px);
  --safe-right: env(safe-area-inset-right, 0px);
}
```

```html
<!-- Use as Tailwind arbitrary values -->
<nav class="pt-[var(--safe-top)] pb-[var(--safe-bottom)]">
  Content safe from notch and home indicator
</nav>
```

### Full Body Safe Area

```scss
/* Ensure main content clears notch and home indicator */
body {
  padding-top: env(safe-area-inset-top, 0px);
  padding-bottom: env(safe-area-inset-bottom, 0px);
  padding-left: env(safe-area-inset-left, 0px);
  padding-right: env(safe-area-inset-right, 0px);
}
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Missing `viewport-fit=cover` | `env()` values all return 0 | Add to viewport meta |
| Fixed bottom bar without bottom inset | Hidden behind home indicator | Add `env(safe-area-inset-bottom)` |
| `padding-top: 44px` for notch | Hardcoded, wrong on most devices | `env(safe-area-inset-top, 0px)` |
| No fallback value in `env()` | May be undefined on older browsers | `env(safe-area-inset-top, 0px)` |

## Red Flags

- Fixed navigation touching the notch area
- Fixed bottom elements hidden behind home indicator
- Missing `viewport-fit=cover` in viewport meta tag
- Hardcoded pixel values instead of `env(safe-area-inset-*)`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/base/base.html` — viewport meta tag
- `static/css/src/_variables.scss` — safe area custom properties
