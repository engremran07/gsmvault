---
paths: ["templates/**/*.html", "static/css/**"]
---

# Tailwind CSS Design Tokens

Rules for using Tailwind CSS v4 with CSS custom property-based theming.

## Color Tokens

- All colors MUST use CSS custom properties: `var(--color-*)` — never raw hex, RGB, or Tailwind palette colours.
- NEVER hardcode `text-white` or `text-black` on accent-coloured backgrounds.
- CRITICAL: `--color-accent-text` is WHITE in dark/light themes but BLACK in contrast theme — always use the token.
- When adding a new colour, define it in ALL three theme blocks (`dark`, `light`, `contrast`) in `_themes.scss`.
- Use semantic token names (`--color-surface`, `--color-text-primary`, `--color-border`) — never raw palette names.

## Utility Usage

- Use Tailwind utility classes for spacing (`p-4`, `mx-auto`), layout (`flex`, `grid`), and typography (`text-lg`, `font-semibold`).
- Prefer `gap-*` over margin hacks for flex/grid spacing: `flex gap-4` not `flex [&>*]:mr-4`.
- Use `space-y-*` and `space-x-*` only for simple stacked layouts — `gap-*` is preferred for flex/grid.
- Responsive design: mobile-first with `sm:`, `md:`, `lg:`, `xl:` breakpoint prefixes.
- NEVER use arbitrary values (`w-[317px]`) when a Tailwind scale value exists (`w-80`).

## Theming Integration

- Theme-dependent styles MUST use CSS custom properties, not Tailwind's `dark:` modifier.
- The `dark:` prefix MUST only be used if also supporting system preference detection alongside the manual theme switcher.
- Theme switching is handled by `<html data-theme="dark|light|contrast">` — styles cascade through CSS variables.
- NEVER apply theme-specific classes directly in templates — let the CSS custom properties handle it.

## Layout Patterns

- Container queries: use `@container` where available for component-level responsiveness.
- Use `max-w-screen-xl mx-auto` for page-width containers.
- Grid: prefer `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3` for responsive card layouts.
- Sticky elements: `sticky top-0 z-[var(--z-header)]` — use z-index tokens from the defined scale.

## Forbidden Patterns

- NEVER use `@apply` in SCSS to compose Tailwind utilities — use utilities directly in templates.
- NEVER create custom CSS classes that duplicate Tailwind utilities.
- NEVER use inline `style` attributes for layout or colours — use Tailwind classes or CSS variables.
