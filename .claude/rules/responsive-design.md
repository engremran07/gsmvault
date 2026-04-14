---
paths: ["templates/**/*.html", "static/css/**"]
---

# Responsive Design

Rules for mobile-first responsive design across the platform.

## Mobile-First Approach

- Base styles MUST target mobile (320px+) — add complexity at larger breakpoints, never subtract.
- Tailwind breakpoints: `sm:640px`, `md:768px`, `lg:1024px`, `xl:1280px`, `2xl:1536px`.
- ALWAYS write mobile styles first, then layer on `sm:`, `md:`, `lg:`, `xl:` overrides.
- NEVER use `max-width` media queries — they fight the mobile-first paradigm.

## Touch Targets

- Interactive elements (buttons, links, form controls) MUST have a minimum touch target of 44×44px on mobile.
- Use `min-h-11 min-w-11` (44px) on clickable elements that might be too small.
- Spacing between adjacent touch targets MUST be at least 8px to prevent mis-taps.
- Icon-only buttons MUST have sufficient padding: `p-2.5` minimum with a 20px icon.

## Navigation

- NEVER use `position: fixed` navigation on mobile without an escape mechanism (close button, overlay dismiss).
- Mobile navigation MUST be a slide-out drawer or collapsible menu — never a persistent fixed bar that consumes viewport.
- Hamburger menu: use Alpine.js `x-show` with `x-transition` for smooth open/close.
- Sticky headers: use `sticky top-0` with `z-[var(--z-header)]` — ensure content scrolls beneath.

## Images & Media

- All images MUST use `loading="lazy"` except above-the-fold hero images.
- Use responsive `srcset` and `sizes` attributes for images that vary by viewport.
- Set explicit `width` and `height` attributes to prevent layout shift (CLS).
- Videos and iframes: wrap in `aspect-ratio` container (`aspect-video`) for responsive scaling.

## Testing Breakpoints

- Test at minimum: 320px (small mobile), 768px (tablet), 1024px (laptop), 1440px (desktop).
- Verify no horizontal scroll at any breakpoint — content MUST fit within viewport width.
- Tables on mobile: use horizontal scroll wrapper (`overflow-x-auto`) or card-based layout.
- Forms on mobile: inputs MUST be full-width (`w-full`) and stacked vertically.
