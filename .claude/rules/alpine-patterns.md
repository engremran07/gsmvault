---
paths: ["templates/**/*.html", "static/js/**/*.js"]
---

# Alpine.js Patterns

Rules for Alpine.js v3 client-side reactivity in the Django-served frontend.

## FOUC Prevention

- All `x-show` and `x-if` elements MUST have the `x-cloak` attribute to prevent flash of unstyled content.
- The `[x-cloak]` CSS rule (`display: none !important`) MUST be present in the base stylesheet.
- NEVER rely on Alpine initialization timing — always assume a brief delay.

## Animation Safety

- NEVER combine `x-show` with CSS `animate-*` classes — the animation overrides `display: none` and causes flicker.
- Use `x-transition` directives for enter/leave animations on `x-show` elements.
- Use `x-transition.duration.300ms` for consistent timing across components.
- If an element needs both conditional visibility and animation, use `x-show` with `x-transition` exclusively.

## State Management

- Store global state (theme, auth status, sidebar toggle) in Alpine stores: `Alpine.store('theme', { ... })`.
- Theme preference MUST be stored in `localStorage` and applied via an Alpine store on page load.
- Component-local state lives in `x-data` — never pollute the global store with ephemeral state.
- Use `$dispatch` for sibling/parent component communication — never reach across DOM manually.

## DOM Access & Events

- Use `x-ref` for DOM references within a component — never use `document.querySelector` inside Alpine.
- Use `@click.prevent` on click handlers that should prevent default browser behaviour.
- Use `@click.stop` to stop event propagation when needed (e.g., dropdown inside clickable card).
- Use `@click.outside` for dismiss-on-outside-click patterns (dropdowns, modals).
- Use `x-init` for component initialization logic — never use inline `<script>` for Alpine setup.

## Conditional Rendering

- Use `x-show` for elements that toggle frequently (show/hide is cheaper than create/destroy).
- Use `x-if` with `<template>` for elements that are rarely shown (removes from DOM entirely).
- Use `x-bind:class` (or `:class`) for conditional CSS classes — never string-concatenate class attributes.
- Boolean class binding: `:class="{ 'active': isOpen, 'hidden': !isOpen }"`.

## Script Ordering

- Alpine.js MUST be loaded before any `x-data` attributes are parsed.
- Custom Alpine plugins and stores MUST be registered before `Alpine.start()`.
- NEVER call `Alpine.start()` more than once — it is called in `base.html`.
