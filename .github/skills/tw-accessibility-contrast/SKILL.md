---
name: tw-accessibility-contrast
description: "Contrast ratios: WCAG AA/AAA, contrast theme support. Use when: checking colour contrast, building the high-contrast theme, ensuring accessibility compliance."
---

# Accessibility Contrast

## When to Use

- Verifying colour combinations meet WCAG standards
- Building or modifying the contrast theme
- Auditing text readability across themes
- Adding new colour tokens

## Rules

1. **WCAG AA minimum: 4.5:1 for normal text, 3:1 for large text** — all themes
2. **Contrast theme must meet WCAG AAA: 7:1** — enhanced readability
3. **`--color-accent-text` is BLACK in contrast theme** — use the token, never hardcode
4. **Test with both light and dark backgrounds** — verify contrast in all themes
5. **Decorative-only elements exempt** — borders, shadows can be lower contrast

## Patterns

### Contrast Ratio Requirements

| Standard | Normal Text | Large Text (18pt+) | Non-Text (icons, borders) |
|----------|------------|---------------------|---------------------------|
| WCAG AA | 4.5:1 | 3:1 | 3:1 |
| WCAG AAA | 7:1 | 4.5:1 | 4.5:1 |

### Contrast Theme Token Values

```scss
/* static/css/src/_themes.scss */
[data-theme="contrast"] {
  --color-bg-primary: #000000;
  --color-bg-secondary: #1a1a1a;
  --color-bg-input: #111111;
  --color-text-primary: #ffffff;      /* 21:1 on black */
  --color-text-secondary: #e0e0e0;    /* 14:1 on black */
  --color-text-muted: #b0b0b0;        /* 8.5:1 on black */
  --color-accent: #ffcc00;            /* 10.5:1 on black */
  --color-accent-text: #000000;       /* CRITICAL: BLACK for contrast */
  --color-accent-hover: #ffe033;
  --color-border: #ffffff;            /* Maximum border visibility */
  --color-status-success: #00ff7f;    /* High visibility green */
  --color-status-error: #ff4444;      /* High visibility red */
  --color-status-warning: #ffaa00;    /* High visibility amber */
  --color-status-info: #44aaff;       /* High visibility blue */
}
```

### Accessible Button (all themes)

```html
<!-- This button works across all 3 themes -->
<button class="bg-[var(--color-accent)] text-[var(--color-accent-text)]
               px-4 py-2 rounded-lg font-semibold
               border-2 border-transparent
               hover:bg-[var(--color-accent-hover)]
               focus:outline-none focus:ring-2
               focus:ring-[var(--color-accent)] focus:ring-offset-2
               focus:ring-offset-[var(--color-bg-primary)]">
  Download Firmware
</button>
```

### High-Contrast Borders

```html
<!-- Contrast theme uses visible borders for element boundaries -->
<div class="rounded-lg p-4
            bg-[var(--color-bg-secondary)]
            border-2 border-[var(--color-border)]">
  <p class="text-[var(--color-text-primary)]">
    Strong borders help users identify element boundaries.
  </p>
</div>
```

### Testing Contrast Programmatically

```javascript
// Quick contrast ratio check
function contrastRatio(l1, l2) {
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

// Relative luminance calculation for sRGB
function luminance(r, g, b) {
  const [rs, gs, bs] = [r, g, b].map(c => {
    c = c / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}
```

### Common Colour Pair Contrast Ratios

| Foreground | Background | Ratio | Passes |
|-----------|-----------|-------|--------|
| `#e2e8f0` (text-primary dark) | `#0f0f23` (bg dark) | 12.8:1 | ✅ AAA |
| `#94a3b8` (text-secondary dark) | `#0f0f23` (bg dark) | 6.7:1 | ✅ AA |
| `#ffffff` (text-primary contrast) | `#000000` (bg contrast) | 21:1 | ✅ AAA |
| `#000000` (accent-text contrast) | `#ffcc00` (accent contrast) | 10.5:1 | ✅ AAA |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `text-white` on accent background | Invisible in contrast theme | `text-[var(--color-accent-text)]` |
| Light gray text on white bg | Below 4.5:1 | Use darker shade, test ratio |
| Relying on colour alone for status | Colour-blind users miss it | Add icon or text label |
| Contrast theme without border changes | Elements blend together | Use `border-[var(--color-border)]` |

## Red Flags

- Colour contrast below 4.5:1 for readable text
- Contrast theme missing high-visibility overrides
- Status indicated by colour alone (no icon/text fallback)
- `--color-accent-text` not used on accent backgrounds

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_themes.scss` — theme colour definitions
- `templates/components/_theme_switcher.html` — theme switcher
- `.claude/rules/tailwind-tokens.md` — token rules
