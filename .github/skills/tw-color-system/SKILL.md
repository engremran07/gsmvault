---
name: tw-color-system
description: "Color system: theme-aware colors, accent, neutral, semantic colors. Use when: choosing colors for UI elements, defining status colors, building theme-safe color palettes."
---

# Color System

## When to Use

- Choosing colours for any UI element
- Adding status indicators (success, error, warning, info)
- Ensuring colour choices work across all 3 themes

## Rules

1. **Always use CSS custom properties** — never raw Tailwind colour classes
2. **`--color-accent-text` is WHITE in dark/light but BLACK in contrast** — always use the token
3. **Semantic colour roles** — bg-primary, text-primary, accent, status-error, etc.
4. **All colours must pass WCAG AA** — 4.5:1 minimum contrast ratio for text
5. **Contrast theme must pass WCAG AAA** — 7:1 minimum

## Patterns

### Colour Role Map

| Role | Token | Dark | Light | Contrast |
|------|-------|------|-------|----------|
| Page background | `--color-bg-primary` | `#0f0f23` | `#ffffff` | `#000000` |
| Card background | `--color-bg-secondary` | `#1a1a2e` | `#f8fafc` | `#1a1a1a` |
| Primary text | `--color-text-primary` | `#e2e8f0` | `#1e293b` | `#ffffff` |
| Secondary text | `--color-text-secondary` | `#94a3b8` | `#64748b` | `#e0e0e0` |
| Accent | `--color-accent` | `#06b6d4` | `#0891b2` | `#ffcc00` |
| Accent text | `--color-accent-text` | `#ffffff` | `#ffffff` | `#000000` |
| Border | `--color-border` | `#334155` | `#e2e8f0` | `#ffffff` |

### Status Colour Usage

```html
<!-- Success -->
<span class="text-[var(--color-status-success)]">✓ Approved</span>
<div class="bg-[var(--color-status-success)]/10 border border-[var(--color-status-success)]/30
            text-[var(--color-status-success)] rounded-lg p-3">
  Operation completed successfully.
</div>

<!-- Error -->
<span class="text-[var(--color-status-error)]">✗ Failed</span>

<!-- Warning -->
<div class="bg-[var(--color-status-warning)]/10 border border-[var(--color-status-warning)]/30
            text-[var(--color-status-warning)] rounded-lg p-3">
  Quota almost exhausted.
</div>

<!-- Info -->
<span class="text-[var(--color-status-info)]">ⓘ Note:</span>
```

### Accent Background (contrast-safe)

```html
<button class="bg-[var(--color-accent)] text-[var(--color-accent-text)]
               hover:bg-[var(--color-accent-hover)] px-4 py-2 rounded-lg">
  Primary Action
</button>
```

### Opacity Variants

```html
<!-- 10% opacity background for subtle highlights -->
<div class="bg-[var(--color-accent)]/10 text-[var(--color-accent)]">
  Highlighted row
</div>

<!-- 20% opacity border -->
<div class="border border-[var(--color-accent)]/20">Soft border</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `text-white` on accent elements | Breaks contrast theme | `text-[var(--color-accent-text)]` |
| `bg-red-500` for errors | Not theme-aware | `text-[var(--color-status-error)]` |
| `text-gray-400` | Theme-blind | `text-[var(--color-text-muted)]` |
| Colour with insufficient contrast | Accessibility violation | Check with contrast ratio tool |

## Red Flags

- Any `text-white`, `text-black`, `bg-gray-*` in templates (except utility/debug)
- `--color-accent-text` missing on accent-background elements
- Status colours not using the `--color-status-*` tokens

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_themes.scss` — colour definitions
- `.claude/rules/tailwind-tokens.md` — token usage rules
