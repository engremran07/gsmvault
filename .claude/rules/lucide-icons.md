---
paths: ["templates/**/*.html"]
---

# Lucide Icons

Rules for using Lucide Icons in templates.

## Usage Pattern

- ALWAYS use the reusable component: `{% include "components/_icon.html" with name="icon-name" %}`.
- NEVER inline raw SVG markup — the component handles sizing, accessibility, and consistency.
- NEVER use icon fonts (Font Awesome, Material Icons) — Lucide SVG icons are the only icon system.
- Pin Lucide to v0.460+ major version — never use `@latest` in CDN URLs.

## Accessibility

- Decorative icons (next to text labels) MUST have `aria-hidden="true"` — the component handles this by default.
- Meaningful icons (standalone, conveying information) MUST have `role="img"` and `aria-label="description"`.
- Pass accessibility attributes via the component: `{% include "components/_icon.html" with name="check" label="Success" %}`.
- NEVER use an icon as the sole indicator of state without a text alternative or `aria-label`.

## Sizing & Styling

- Use the component's `size` parameter for consistent sizing — default is `24`.
- Common sizes: `16` (inline/badge), `20` (buttons), `24` (default), `32` (feature cards), `48` (empty states).
- Icon colour inherits from `currentColor` — set colour on the parent element with CSS custom properties.
- NEVER apply `fill` to Lucide icons — they use `stroke` only by design.

## Performance

- Icons are loaded via the Lucide CDN with fallback to `static/vendor/lucide/`.
- The `lucide.createIcons()` call in `base.html` initialises all icons on page load.
- For HTMX fragments that inject new icons, call `lucide.createIcons()` in the `htmx:afterSwap` handler.
- NEVER load the entire Lucide sprite sheet — use individual icon references.

## Icon Naming

- Use kebab-case names matching the Lucide catalog: `arrow-right`, `chevron-down`, `file-text`.
- Search the Lucide catalog at lucide.dev before creating custom SVGs — most icons already exist.
- If a custom icon is absolutely needed, add it to `static/img/icons/` as an SVG file with consistent viewBox.
