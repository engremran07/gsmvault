---
paths: ["static/css/src/_themes.scss", "static/css/src/_variables.scss"]
---

# Theme Variables

Rules for the 3-theme CSS custom property system.

## Theme Architecture

- 3 themes: **dark** (default), **light**, **contrast**.
- Theme switching: Alpine.js store sets `data-theme` attribute on `<html>`.
- `:root` / `[data-theme="dark"]` defines the dark theme (default fallback).
- `[data-theme="light"]` overrides for the light theme.
- `[data-theme="contrast"]` overrides for the high contrast theme.
- User preference is stored in `localStorage` and applied before first paint to prevent flash.

## Critical Token: `--color-accent-text`

- In **dark** and **light** themes: `--color-accent-text` is WHITE (`#ffffff` or near-white).
- In **contrast** theme: `--color-accent-text` is BLACK (`#000000` or near-black).
- ALWAYS use `color: var(--color-accent-text)` on accent-coloured backgrounds — never hardcode `text-white`.
- This single gotcha causes the most visual bugs when missed — test every accent element in all 3 themes.

## Adding New Colours

- Every new colour MUST be defined in ALL three theme blocks — never define in only one.
- Use semantic names: `--color-surface-elevated`, `--color-text-muted`, `--color-border-subtle`.
- NEVER use raw colour values in templates or component SCSS — always reference the token.
- Group related tokens: `--color-success`, `--color-success-text`, `--color-success-bg`.

## Contrast Theme Requirements

- High contrast theme MUST target WCAG AAA compliance (7:1 contrast ratio for normal text).
- Borders MUST be visible: use `--color-border` with sufficient contrast against `--color-surface`.
- Focus indicators MUST be prominent: minimum 3px solid outline with high-contrast colour.
- NEVER rely solely on colour to convey information — use icons, text, or borders as well.

## Testing

- Test every UI element in all 3 themes before considering work complete.
- Use browser DevTools to toggle `data-theme` attribute for quick switching.
- Automated check: search for hardcoded `text-white`, `text-black`, `bg-white`, `bg-black` in templates — these are almost always bugs.
- The theme switcher component (`_theme_switcher.html`) MUST work without JS by falling back to the dark theme.
