---
name: tailwind-theming
description: "Tailwind CSS setup, theme switching, dark mode, light mode, high contrast, CSS custom properties, responsive design. Use when: styling pages, creating themes, configuring Tailwind, building responsive layouts, adding CSS variables, switching between display styles."
---

# Tailwind CSS & Theming

## When to Use

- Styling pages and components with Tailwind utility classes
- Creating or modifying theme variables (CSS custom properties)
- Building responsive layouts (mobile-first)
- Configuring Tailwind (content paths, custom colors, fonts)
- Implementing theme switching (dark/light/contrast)
- Adding custom utility classes
- Debugging color drift, visual inconsistencies, or theme-breaking issues

## Rules

1. **Use Tailwind utility classes first** — avoid custom CSS unless truly needed
2. **Theme colors via CSS custom properties** — `bg-[var(--color-bg-primary)]` not `bg-slate-900`
3. **Three themes always supported**: dark (default), light, contrast — every new variable must go in ALL three
4. **Mobile-first responsive** — `sm:`, `md:`, `lg:`, `xl:` breakpoints
5. **No `!important`** — fix specificity properly (exception: `[x-cloak]` rule)
6. **Custom styles in SCSS only** — `static/css/src/` directory, compiled to `static/css/dist/main.css`
7. **Theme stored in localStorage** — persists across visits
8. **HTML `data-theme` attribute** — on `<html>` element, switched by `$store.theme`
9. **Production: Tailwind CLI build** — not browser script
10. **CDN in development only** — `@tailwindcss/browser@4` for instant feedback
11. **Body must have `antialiased`** — for consistent font rendering across browsers
12. **`[x-cloak]` CSS rule in `_head.html`** — `display: none !important` to prevent FOUC

## CRITICAL: Preventing Color Drift

Color drift happens when:
- A new CSS variable is added to the dark theme but not to light/contrast
- A template uses a hardcoded color instead of a CSS variable
- A compiled CSS file (`main.css`) is out of sync with SCSS sources
- **`text-white` is hardcoded on accent-colored backgrounds** — contrast theme uses `#ffff00` (yellow) as accent, making white text unreadable. Always use `text-[var(--color-accent-text)]` on any element with `bg-[var(--color-accent)]`

### Prevention checklist
1. Every new `--color-*` variable must be added to ALL THREE themes:
   - `_variables.scss` (dark/default)
   - `themes/_light.scss`
   - `themes/_contrast.scss`
   - `css/dist/main.css` (compiled output)
2. Search all templates for hardcoded colors: `grep -r "#[0-9a-fA-F]\{3,6\}" templates/`
3. Verify compiled CSS matches SCSS sources — rebuild after any SCSS change
4. **NEVER use `text-white` on accent backgrounds** — always use `text-[var(--color-accent-text)]`
5. **NEVER use `hover:opacity-90` on buttons** — use `hover:bg-[var(--color-accent-hover)]` for proper theming

### `--color-accent-text` Token (MANDATORY)

This token defines the text color for elements on accent-colored backgrounds:
- **Dark theme**: `#ffffff` (white text on blue accent)
- **Light theme**: `#ffffff` (white text on blue accent)
- **Contrast theme**: `#000000` (black text on yellow accent)

Use it everywhere accent background + text coexist:
```html
{# CORRECT #}
<button class="bg-[var(--color-accent)] text-[var(--color-accent-text)]">

{# WRONG — invisible in contrast theme #}
<button class="bg-[var(--color-accent)] text-white">
```

## Theme System

### CSS Custom Properties — Complete Token Set

All theme colors defined in `static/css/src/_variables.scss`. **Every token below must exist in ALL 3 themes.**

```scss
:root,
[data-theme="dark"] {
  // Backgrounds
  --color-bg-primary: #0f172a;
  --color-bg-secondary: #1e293b;
  --color-bg-tertiary: #334155;

  // Text
  --color-text-primary: #f1f5f9;
  --color-text-secondary: #94a3b8;
  --color-text-muted: #64748b;

  // Accent
  --color-accent: #3b82f6;
  --color-accent-hover: #60a5fa;
  --color-accent-text: #ffffff;        // Text on accent backgrounds (black in contrast theme)
  --color-accent-soft: rgba(59, 130, 246, 0.1);
  --color-accent-muted: #1e3a5f;

  // Borders
  --color-border: #334155;
  --color-border-hover: #475569;

  // Status
  --color-success: #22c55e;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #06b6d4;

  // Surfaces
  --color-card: #1e293b;
  --color-input: #0f172a;
  --color-input-border: #475569;

  // Shadows
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.4);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.5);
  --shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.6);

  // Typography
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;

  // Spacing / Radius
  --radius-sm: 0.375rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
  --radius-full: 9999px;

  // Transitions
  --transition-fast: 150ms ease;
  --transition-base: 200ms ease;
  --transition-slow: 300ms ease;
}

[data-theme="light"] {
  --color-bg-primary: #ffffff;
  --color-bg-secondary: #f8fafc;
  --color-bg-tertiary: #f1f5f9;
  --color-text-primary: #0f172a;
  --color-text-secondary: #475569;
  --color-text-muted: #94a3b8;
  --color-accent: #2563eb;
  --color-accent-hover: #1d4ed8;
  --color-accent-text: #ffffff;
  --color-accent-soft: rgba(37, 99, 235, 0.1);
  --color-accent-muted: #dbeafe;
  --color-border: #e2e8f0;
  --color-border-hover: #cbd5e1;
  --color-success: #16a34a;
  --color-warning: #d97706;
  --color-error: #dc2626;
  --color-info: #0891b2;
  --color-card: #ffffff;
  --color-input: #ffffff;
  --color-input-border: #cbd5e1;
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
}

[data-theme="contrast"] {
  --color-bg-primary: #000000;
  --color-bg-secondary: #1a1a1a;
  --color-bg-tertiary: #333333;
  --color-text-primary: #ffffff;
  --color-text-secondary: #e0e0e0;
  --color-text-muted: #bdbdbd;
  --color-accent: #ffff00;
  --color-accent-hover: #ffff66;
  --color-accent-text: #000000;        // BLACK text on YELLOW accent!
  --color-accent-soft: rgba(255, 255, 0, 0.15);
  --color-accent-muted: #333300;
  --color-border: #ffffff;
  --color-border-hover: #e0e0e0;
  --color-success: #00ff00;
  --color-warning: #ffff00;
  --color-error: #ff0000;
  --color-info: #00ffff;
  --color-card: #1a1a1a;
  --color-input: #000000;
  --color-input-border: #ffffff;
  --shadow-sm: 0 1px 2px rgba(255, 255, 255, 0.1);
  --shadow-md: 0 4px 6px rgba(255, 255, 255, 0.15);
  --shadow-lg: 0 10px 15px rgba(255, 255, 255, 0.2);
}
```

### Required `_head.html` Tags for Theming

```html
<meta name="color-scheme" content="dark light">
<meta name="theme-color" content="#0f172a" media="(prefers-color-scheme: dark)">
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<link rel="stylesheet" href="{% static 'css/dist/main.css' %}">
<style>[x-cloak] { display: none !important; }</style>
<script nonce="{{ request.csp_nonce }}">
  (function(){ document.documentElement.setAttribute('data-theme', localStorage.getItem('theme') || 'dark'); })();
</script>
```

### Tailwind Usage Patterns

```html
<!-- Background -->
<div class="bg-[var(--color-bg-primary)]">

<!-- Text -->
<p class="text-[var(--color-text-secondary)]">

<!-- Border -->
<div class="border border-[var(--color-border)] rounded-[var(--radius-md)]">

<!-- Accent -->
<button class="bg-[var(--color-accent)] hover:bg-[var(--color-accent-hover)] text-[var(--color-accent-text)]">

<!-- Card -->
<div class="bg-[var(--color-card)] shadow-[var(--shadow-md)] rounded-[var(--radius-lg)] p-6">

<!-- Input -->
<input class="bg-[var(--color-input)] border border-[var(--color-input-border)] rounded-[var(--radius-md)]">
```

### Common Component Classes

```html
<!-- Primary button -->
<button class="px-4 py-2 bg-[var(--color-accent)] hover:bg-[var(--color-accent-hover)]
               text-[var(--color-accent-text)] font-medium rounded-[var(--radius-md)] transition-colors">

<!-- Secondary button -->
<button class="px-4 py-2 border border-[var(--color-border)] hover:border-[var(--color-accent)]
               text-[var(--color-text-primary)] rounded-[var(--radius-md)] transition-colors">

<!-- Input field -->
<input class="w-full px-3 py-2 bg-[var(--color-input)] border border-[var(--color-input-border)]
              rounded-[var(--radius-md)] text-[var(--color-text-primary)]
              focus:border-[var(--color-accent)] focus:outline-none focus:ring-1 focus:ring-[var(--color-accent)]">

<!-- Card -->
<div class="bg-[var(--color-card)] border border-[var(--color-border)]
            rounded-[var(--radius-lg)] shadow-[var(--shadow-sm)] p-6">

<!-- Badge -->
<span class="inline-flex items-center px-2.5 py-0.5 rounded-[var(--radius-full)]
             text-xs font-medium bg-[var(--color-accent-muted)] text-[var(--color-accent)]">
```

## Responsive Design Patterns

### Required Approach: Mobile-First

Always start with mobile styles, then add larger breakpoints:

```html
<!-- Grid: 1 col mobile → 2 col tablet → 3 col desktop -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">

<!-- WRONG: desktop-first (breaks on mobile) -->
<div class="grid grid-cols-3 ...">

<!-- Text: small on mobile, larger on desktop -->
<h1 class="text-2xl md:text-3xl lg:text-4xl font-bold">

<!-- Stack on mobile, row on desktop -->
<div class="flex flex-col md:flex-row md:items-center gap-4">

<!-- Full width mobile, constrained desktop -->
<div class="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

<!-- Responsive image height -->
<img class="w-full h-40 sm:h-48 object-cover">

<!-- Wrap on mobile for pagination/tags -->
<nav class="flex flex-wrap gap-2">
```

### Cross-Browser Requirements

In `_head.html`:
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
```

In `main.css`:
```css
html { -webkit-text-size-adjust: 100%; -moz-text-size-adjust: 100%; text-size-adjust: 100%; }
img, video { max-width: 100%; height: auto; }
```

## Theme Switcher

**CRITICAL: Use `x-show` not `<template x-if>` for toggling icons.** Lucide icons render SVG at DOMContentLoaded via `lucide.createIcons()`. If `<template x-if>` destroys/recreates DOM nodes, the new `<i data-lucide>` elements never get rendered because Lucide already ran. Using `x-show` keeps all icons in the DOM (rendered once by Lucide) and toggles visibility.

```html
{# templates/components/_theme_switcher.html #}
{# Uses $store.theme from theme-switcher.js — cycles dark → light → contrast #}
<div x-data class="relative">
  <button @click="$store.theme.cycle()"
          class="p-2 rounded-lg text-[var(--color-text-secondary)] hover:text-[var(--color-accent)] hover:bg-[var(--color-bg-primary)] transition-colors"
          :title="'Theme: ' + $store.theme.current">
    <i data-lucide="moon" class="w-5 h-5" x-show="$store.theme.current === 'dark'" x-cloak></i>
    <i data-lucide="sun" class="w-5 h-5" x-show="$store.theme.current === 'light'" x-cloak></i>
    <i data-lucide="eye" class="w-5 h-5" x-show="$store.theme.current === 'contrast'" x-cloak></i>
  </button>
</div>
```

**Mobile menu**: The theme switcher must also be included in the mobile navigation menu. Add `{% include "components/_theme_switcher.html" %}` inside the mobile menu `<div>`.

## Build Commands

```powershell
# Development (no build needed — CDN)
# _head.html loads: <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4">

# Production build
.\tailwindcss.exe -i static/css/src/main.scss -o static/css/dist/main.css --minify
python manage.py collectstatic --noinput
```

## Admin Theme Tokens

Admin components use semantic CSS classes backed by CSS custom properties. These ensure admin UI stays theme-consistent.

### `.admin-sidebar-link`

```css
.admin-sidebar-link {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 0.75rem;
  border-radius: var(--radius-md);
  color: var(--color-text-secondary);
  transition: all var(--transition-fast);
}
.admin-sidebar-link:hover {
  background: var(--color-bg-tertiary);
  color: var(--color-text-primary);
}
.admin-sidebar-link.active {
  background: var(--color-accent-soft);
  color: var(--color-accent);
  font-weight: 500;
}
```

### `.admin-stat-card`

```css
.admin-stat-card {
  background: var(--color-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: var(--shadow-sm);
}
.admin-stat-card .stat-value {
  font-size: 1.875rem;
  font-weight: 700;
  color: var(--color-text-primary);
}
.admin-stat-card .stat-label {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}
```

### `.admin-table`

```css
.admin-table {
  width: 100%;
  border-collapse: collapse;
}
.admin-table thead th {
  padding: 0.75rem 1rem;
  text-align: left;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text-muted);
  border-bottom: 1px solid var(--color-border);
}
.admin-table tbody td {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text-primary);
}
.admin-table tbody tr:hover {
  background: var(--color-bg-tertiary);
}
```

### `.admin-badge`

```css
.admin-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.125rem 0.625rem;
  border-radius: var(--radius-full);
  font-size: 0.75rem;
  font-weight: 500;
}
```

## Admin-Specific Utilities

### Badge Variants

```css
.admin-badge-success {
  background: rgba(var(--color-success-rgb, 34, 197, 94), 0.15);
  color: var(--color-success);
}
.admin-badge-danger {
  background: rgba(var(--color-error-rgb, 239, 68, 68), 0.15);
  color: var(--color-error);
}
.admin-badge-warning {
  background: rgba(var(--color-warning-rgb, 245, 158, 11), 0.15);
  color: var(--color-warning);
}
.admin-badge-info {
  background: rgba(var(--color-info-rgb, 6, 182, 212), 0.15);
  color: var(--color-info);
}
```

### `.admin-toggle`

Custom toggle switch for boolean settings:

```css
.admin-toggle {
  position: relative;
  width: 2.5rem;
  height: 1.375rem;
  background: var(--color-bg-tertiary);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-full);
  cursor: pointer;
  transition: background var(--transition-fast);
}
.admin-toggle.active {
  background: var(--color-accent);
  border-color: var(--color-accent);
}
.admin-toggle .toggle-dot {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 1rem;
  height: 1rem;
  background: var(--color-text-primary);
  border-radius: var(--radius-full);
  transition: transform var(--transition-fast);
}
.admin-toggle.active .toggle-dot {
  transform: translateX(1.125rem);
  background: var(--color-accent-text);
}
```

### `.admin-input`

Standard input styling for admin forms:

```css
.admin-input {
  width: 100%;
  padding: 0.5rem 0.75rem;
  background: var(--color-input);
  border: 1px solid var(--color-input-border);
  border-radius: var(--radius-md);
  color: var(--color-text-primary);
  font-size: 0.875rem;
  transition: border-color var(--transition-fast);
}
.admin-input:focus {
  border-color: var(--color-accent);
  outline: none;
  box-shadow: 0 0 0 2px var(--color-accent-soft);
}
```

## Procedure

1. Use CSS custom properties for ALL colors — never hardcode hex values in templates
2. When adding a new `--color-*` variable, add it to ALL 3 themes (`_variables.scss`, `_light.scss`, `_contrast.scss`) AND rebuild `main.css`
3. Apply Tailwind utility classes for layout and spacing
4. Follow mobile-first responsive design (`sm:` → `md:` → `lg:`)
5. Verify body has `antialiased` class
6. Verify `[x-cloak]` rule exists in `_head.html`
7. Test all three themes (dark, light, contrast) — check for missing variables and color drift
8. Verify WCAG AA contrast ratios (especially contrast theme = WCAG AAA)
9. Run quality gate
