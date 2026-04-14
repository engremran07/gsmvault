---
applyTo: 'static/css/src/**'
---

# SCSS Architecture Conventions

## Directory Structure

```
static/css/
  src/                    ← SCSS source files (edit these)
    main.scss             ← Entry point — imports all partials
    _variables.scss       ← CSS custom properties (design tokens)
    _themes.scss          ← Dark / light / contrast theme definitions
    _animations.scss      ← @keyframes and animation utilities
    _typography.scss      ← Font families, sizes, line heights
    _utilities.scss       ← Custom utility classes
    _components.scss      ← Component-level styles
    _print.scss           ← Print stylesheet (@media print)
    _forms.scss           ← Form element styling
    _admin.scss           ← Admin panel overrides
  dist/                   ← Compiled output (DO NOT edit)
    main.css              ← Compiled CSS + Tailwind output
```

## main.scss Import Order

```scss
// 1. Variables and tokens (must be first)
@import 'variables';

// 2. Theme definitions
@import 'themes';

// 3. Typography
@import 'typography';

// 4. Component styles
@import 'components';

// 5. Form styles
@import 'forms';

// 6. Animation keyframes
@import 'animations';

// 7. Utility classes
@import 'utilities';

// 8. Admin overrides
@import 'admin';

// 9. Print styles (must be last)
@import 'print';
```

## _variables.scss — Design Tokens

Define all design tokens as CSS custom properties on `:root`:

```scss
:root {
  // Spacing
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;

  // Border radius
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-full: 9999px;

  // Z-index scale
  --z-dropdown: 100;
  --z-sticky: 200;
  --z-modal-backdrop: 300;
  --z-modal: 400;
  --z-toast: 500;
  --z-tooltip: 600;

  // Transitions
  --transition-fast: 150ms ease;
  --transition-normal: 200ms ease;
  --transition-slow: 300ms ease;
}
```

## _themes.scss — Three Themes

Define color tokens per theme using `[data-theme]` attribute selector:

```scss
[data-theme="dark"] {
  --color-bg: #0f0f23;
  --color-surface: #1a1a2e;
  --color-text: #e2e8f0;
  --color-text-secondary: #94a3b8;
  --color-accent: #06b6d4;
  --color-accent-hover: #22d3ee;
  --color-accent-text: #ffffff;  // WHITE on dark
  --color-border: #334155;
}

[data-theme="light"] {
  --color-bg: #f8fafc;
  --color-surface: #ffffff;
  --color-text: #1e293b;
  --color-text-secondary: #64748b;
  --color-accent: #2563eb;
  --color-accent-hover: #3b82f6;
  --color-accent-text: #ffffff;  // WHITE on light
  --color-border: #e2e8f0;
}

[data-theme="contrast"] {
  --color-bg: #000000;
  --color-surface: #1a1a1a;
  --color-text: #ffffff;
  --color-text-secondary: #d4d4d4;
  --color-accent: #ffdd00;
  --color-accent-hover: #ffe44d;
  --color-accent-text: #000000;  // BLACK in contrast!
  --color-border: #666666;
}
```

## _animations.scss — Keyframes

```scss
@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slide-up {
  from { transform: translateY(0.5rem); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@keyframes pulse-subtle {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

// Utility classes
.animate-fade-in { animation: fade-in var(--transition-normal) both; }
.animate-slide-up { animation: slide-up var(--transition-normal) both; }
```

## Rules

1. **Never use `!important`** — if specificity is an issue, restructure selectors
2. **Never hardcode colors** — always use `var(--color-*)` tokens
3. **Never edit files in `dist/`** — only edit `src/` files
4. **Use nesting sparingly** — max 3 levels deep
5. **Prefer Tailwind utilities** over custom SCSS for layout, spacing, typography
6. **Use SCSS only for** — theme variables, animations, complex component styles, print
7. **Keep static files minimal** — do not create new SCSS/CSS files unless existing modules cannot be safely extended
8. **Split only for proven need** — large-file split is allowed when performance or maintainability requires it; otherwise in-place extension is mandatory
9. **Preserve load order and contracts** — any split must retain deterministic import order and avoid regressions in themed rendering

## Build Pipeline

- **Development**: CDN for Tailwind, local SCSS compiled with Tailwind CLI
- **Production**: `tailwindcss -i static/css/src/main.scss -o static/css/dist/main.css --minify`
- WhiteNoise serves static files in production
