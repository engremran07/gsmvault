---
name: tw-design-tokens
description: "Design token system: colors, spacing, typography as CSS vars. Use when: defining new theme tokens, extending the design system, adding semantic colour names."
---

# Design Token System

## When to Use

- Adding new colour variables to the theme system
- Creating semantic token names for a new feature
- Auditing token consistency across templates

## Rules

1. **All tokens defined in `_themes.scss`** — one source of truth
2. **Semantic naming** — `--color-bg-primary` not `--color-dark-blue`
3. **Every token needs all 3 theme values** — dark, light, contrast
4. **Token categories** — bg, text, border, accent, shadow, status
5. **Never create tokens in component SCSS** — always in `_themes.scss`

## Patterns

### Token Naming Convention

```
--color-{category}-{modifier}

Categories: bg, text, border, accent, shadow, status
Modifiers:  primary, secondary, muted, hover, active, input
```

### Token Definition in SCSS

```scss
/* static/css/src/_themes.scss */
[data-theme="dark"] {
  --color-bg-primary: #0f0f23;
  --color-bg-secondary: #1a1a2e;
  --color-text-primary: #e2e8f0;
  --color-text-secondary: #94a3b8;
  --color-text-muted: #64748b;
  --color-accent: #06b6d4;
  --color-accent-hover: #22d3ee;
  --color-accent-text: #ffffff;  /* WHITE on dark */
  --color-border: #334155;
  --color-shadow: rgba(0, 0, 0, 0.3);
  --color-status-success: #22c55e;
  --color-status-warning: #f59e0b;
  --color-status-error: #ef4444;
  --color-status-info: #3b82f6;
}

[data-theme="contrast"] {
  --color-accent-text: #000000;  /* BLACK on contrast — critical */
}
```

### Spacing Tokens (if custom scale needed)

```scss
:root {
  --spacing-page-x: 1rem;    /* px-4 */
  --spacing-page-y: 2rem;    /* py-8 */
  --spacing-section: 3rem;   /* gap between sections */
  --spacing-card: 1.5rem;    /* internal card padding */
}

@media (min-width: 768px) {
  :root {
    --spacing-page-x: 1.5rem;  /* px-6 */
    --spacing-page-y: 3rem;    /* py-12 */
  }
}
```

### Typography Tokens

```scss
:root {
  --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
}
```

### Using Tokens in Templates

```html
<div class="bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]
            font-[var(--font-sans)]">
  <span class="text-[var(--color-status-success)]">✓ Verified</span>
  <span class="text-[var(--color-status-error)]">✗ Failed</span>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `--dark-bg` | Not semantic | `--color-bg-primary` |
| Token defined in component SCSS | Scattered definitions | Move to `_themes.scss` |
| Token without contrast theme value | Accessibility gap | Define all 3 theme values |
| Hardcoded `#06b6d4` in template | Not tokenized | Use `var(--color-accent)` |

## Red Flags

- CSS custom properties defined outside `_themes.scss` or `_variables.scss`
- Token names using colour names (`--blue`, `--dark-gray`)
- Missing token value for one of the 3 themes

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_themes.scss` — token definitions
- `static/css/src/_variables.scss` — SCSS variables
- `.claude/rules/theme-variables.md` — theme variable rules
