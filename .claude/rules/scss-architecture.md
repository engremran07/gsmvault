---
paths: ["static/css/src/**"]
---

# SCSS Architecture

Rules for organising and writing SCSS source files.

## File Structure

- Source files MUST live in `static/css/src/`.
- Compiled output goes to `static/css/dist/` — never edit files in `dist/` directly.
- Main entry point: `main.scss` — imports all partials.
- Partials MUST be prefixed with underscore: `_variables.scss`, `_themes.scss`, `_animations.scss`.
- Import order in `main.scss`: variables → themes → base → components → utilities → print.

## CSS Custom Properties

- All theme-dependent values MUST be defined as CSS custom properties in `:root` and `[data-theme]` selectors.
- `:root` defines the dark theme (default) values.
- `[data-theme="light"]` and `[data-theme="contrast"]` override the defaults.
- NEVER use SCSS variables (`$var`) for values that change per theme — use CSS custom properties (`var(--var)`).
- SCSS variables are acceptable for static values (breakpoints, z-index scale, spacing scale).

## Naming Conventions

- CSS custom properties: `--color-*`, `--font-*`, `--z-*`, `--shadow-*`, `--radius-*`.
- BEM naming for custom component classes: `.block__element--modifier` — but prefer Tailwind utilities.
- Utility classes: prefix with `u-` (e.g., `u-visually-hidden`).
- NEVER use generic class names (`.container`, `.title`, `.active`) that collide with Tailwind.

## Code Quality

- NEVER use `!important` except for utility overrides and `[x-cloak]`.
- z-index scale: use defined tokens (`--z-dropdown: 10`, `--z-modal: 50`, `--z-toast: 100`) — never arbitrary values.
- Nesting: maximum 3 levels deep — flatten with BEM or Tailwind utilities.
- NEVER use `@extend` — it produces unpredictable output. Use mixins or Tailwind utilities.
- Avoid vendor prefixes manually — rely on Autoprefixer in the build pipeline.

## Build Pipeline

- Development: CDN for vendor libraries, zero SCSS build step required for most work.
- Production: `tailwindcss -i static/css/src/main.scss -o static/css/dist/main.css --minify`.
- NEVER commit compiled `dist/` files — they are generated artifacts.
- WhiteNoise serves static files in production with cache headers.
