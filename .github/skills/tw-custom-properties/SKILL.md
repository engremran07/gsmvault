---
name: tw-custom-properties
description: "CSS custom properties with Tailwind: var(), arbitrary values. Use when: using CSS variables in Tailwind classes, theming with custom properties, dynamic styling."
---

# CSS Custom Properties with Tailwind

## When to Use

- Referencing theme CSS variables in Tailwind utility classes
- Using `var()` for dynamic values that change with theme
- Bridging SCSS variables and Tailwind utilities

## Rules

1. **Use `var()` via arbitrary value syntax** — `bg-[var(--color-bg-primary)]`
2. **Never hardcode hex colours in templates** — always use CSS custom properties
3. **Critical: `--color-accent-text`** is WHITE in dark/light but BLACK in contrast — use the token
4. **Define all custom properties in SCSS** — `static/css/src/_themes.scss`
5. **Fallback values optional** — `var(--color-bg-primary, #1a1a2e)` for safety

## Patterns

### Theme-Aware Backgrounds and Text

```html
<div class="bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]">
  <h2 class="text-[var(--color-accent)]">Themed Heading</h2>
  <p class="text-[var(--color-text-secondary)]">Secondary text adapts to theme.</p>
</div>
```

### Accent Button (contrast-safe)

```html
<!-- CORRECT: uses --color-accent-text which switches per theme -->
<button class="bg-[var(--color-accent)] text-[var(--color-accent-text)]
               hover:bg-[var(--color-accent-hover)]
               px-4 py-2 rounded-lg font-medium">
  Download
</button>

<!-- WRONG: hardcoded text-white breaks on contrast theme -->
<button class="bg-[var(--color-accent)] text-white">Bad</button>
```

### Borders and Dividers

```html
<div class="border border-[var(--color-border)]
            divide-y divide-[var(--color-border)]">
  <div class="p-4">Row 1</div>
  <div class="p-4">Row 2</div>
</div>
```

### Shadows with Theme Variables

```html
<div class="shadow-[0_4px_12px_var(--color-shadow)]
            rounded-lg bg-[var(--color-bg-secondary)] p-6">
  Card with themed shadow
</div>
```

### Combining with Tailwind Utilities

```html
<input type="text"
       class="w-full rounded-md px-3 py-2
              bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
              border border-[var(--color-border)]
              focus:ring-2 focus:ring-[var(--color-accent)]
              focus:border-[var(--color-accent)]
              placeholder:text-[var(--color-text-muted)]" />
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `text-white` on accent bg | Invisible in contrast theme | `text-[var(--color-accent-text)]` |
| `bg-gray-800` | Not theme-aware | `bg-[var(--color-bg-secondary)]` |
| `border-gray-700` | Hardcoded | `border-[var(--color-border)]` |
| `hover:bg-blue-600` | Theme-blind | `hover:bg-[var(--color-accent-hover)]` |
| Inline `style="color: var(--x)"` | Violates Tailwind pattern | Use `text-[var(--x)]` |

## Red Flags

- Any hardcoded colour class (`text-white`, `bg-gray-900`, `border-blue-500`) except utility colours
- Missing `--color-accent-text` on elements with accent backgrounds
- CSS variables used in SCSS but not defined in `_themes.scss`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_themes.scss` — all CSS custom property definitions
- `static/css/src/_variables.scss` — SCSS variable definitions
- `.claude/rules/tailwind-tokens.md` — token usage rules
