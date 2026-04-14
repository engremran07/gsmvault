---
applyTo: 'templates/**/*.html, static/css/**'
---

# Tailwind CSS & Design Token Conventions

## CSS Custom Properties — MANDATORY

NEVER hardcode hex colors or color names. Always use CSS custom properties:

```html
<!-- CORRECT -->
<div class="bg-[var(--color-surface)] text-[var(--color-text)]">
    <h1 class="text-[var(--color-accent)]">Title</h1>
    <p class="text-[var(--color-text-secondary)]">Description</p>
</div>

<!-- WRONG — breaks theme switching -->
<div class="bg-gray-900 text-white">
    <h1 class="text-cyan-400">Title</h1>
</div>
```

## Accent Text Color — CRITICAL GOTCHA

`--color-accent-text` is WHITE in dark/light themes but BLACK in contrast theme.
Never hardcode `text-white` on accent backgrounds:

```html
<!-- CORRECT — adapts to theme -->
<button class="bg-[var(--color-accent)] text-[var(--color-accent-text)]">
    Click Me
</button>

<!-- WRONG — invisible text in contrast theme -->
<button class="bg-[var(--color-accent)] text-white">
    Click Me
</button>
```

## Three Themes

Theme switching via `<html data-theme="dark|light|contrast">`:

| Theme | Slug | Description |
|-------|------|-------------|
| Dark Tech | `dark` | Default. Dark backgrounds, cyan/blue accents |
| Light Professional | `light` | White backgrounds, slate text, blue accents |
| High Contrast | `contrast` | WCAG AAA, maximum readability, strong borders |

## Core Design Tokens

```css
/* Backgrounds */
--color-bg           /* Page background */
--color-surface      /* Card/section background */
--color-surface-alt  /* Alternate surface */

/* Text */
--color-text           /* Primary text */
--color-text-secondary /* Secondary/muted text */
--color-text-muted     /* Disabled/placeholder text */

/* Accents */
--color-accent        /* Primary accent (buttons, links) */
--color-accent-hover  /* Accent hover state */
--color-accent-text   /* Text ON accent backgrounds */

/* Borders */
--color-border        /* Default borders */
--color-border-hover  /* Border on hover */

/* Status */
--color-success, --color-warning, --color-error, --color-info
```

## Responsive Design — Mobile First

Always design mobile-first and add breakpoints upward:

```html
<!-- Mobile: stack, Tablet: 2-col, Desktop: 3-col -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    ...
</div>

<!-- Mobile: full width, Desktop: fixed width -->
<div class="w-full lg:w-96">
    ...
</div>
```

Breakpoints: `sm` (640px), `md` (768px), `lg` (1024px), `xl` (1280px), `2xl` (1536px).

## Spacing Scale

Use Tailwind's spacing scale consistently:
- `p-2` (8px) for tight padding
- `p-4` (16px) for standard padding
- `p-6` (24px) for generous padding
- `gap-4` for grid/flex gaps
- `space-y-4` for vertical spacing between children

## Typography

- Body text: `text-sm` or `text-base`
- Headings: `text-lg`, `text-xl`, `text-2xl`, `text-3xl`
- Monospace: `font-mono` (JetBrains Mono)
- Line height: `leading-relaxed` for body content

## Utility Conventions

```html
<!-- Rounded corners -->
<div class="rounded-lg">Standard</div>
<div class="rounded-xl">Large</div>
<div class="rounded-full">Pill/circle</div>

<!-- Shadows -->
<div class="shadow-sm">Subtle</div>
<div class="shadow-md">Standard</div>
<div class="shadow-lg">Elevated</div>

<!-- Transitions -->
<button class="transition-colors duration-200 hover:bg-[var(--color-accent-hover)]">
    Button
</button>
```

## Forbidden Patterns

- Never use `!important` in utility classes
- Never use arbitrary hex values: `bg-[#1a1a2e]` — use tokens instead
- Never use `dark:` variant prefix — we use `data-theme` attribute, not `class="dark"`
