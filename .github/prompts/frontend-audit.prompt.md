---
agent: 'agent'
description: 'Audit frontend templates for Alpine.js, HTMX, Tailwind, accessibility, and component usage compliance'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search']
---

# Frontend Quality Audit

Perform a comprehensive audit of all frontend templates, static files, and component usage in the GSMFWs platform.

## 1 — Alpine.js Compliance

### x-cloak Enforcement
Grep all `templates/**/*.html` for elements with `x-show` or `x-if`. Every such element MUST also have `x-cloak` to prevent FOUC (Flash of Unstyled Content).

```
PASS: <div x-show="open" x-cloak>
FAIL: <div x-show="open">        ← missing x-cloak
```

### Animation Conflict Detection
Elements with `x-show` must NOT have CSS `animate-*` classes. The animation overrides `display:none`, causing flicker.

```
FAIL: <div x-show="open" class="animate-fade-in">
FIX:  Remove animate-fade-in, use x-transition instead
```

### Component Encapsulation
Every `x-data` must define a complete, self-contained scope. Check for global variable leaks or undeclared reactive properties.

### Event Dispatch
Cross-component communication must use `$dispatch` / `@custom-event` pattern, not global variables or DOM manipulation.

## 2 — HTMX Fragment Isolation

### No Extends in Fragments
Scan all files in `templates/*/fragments/*.html`. NONE may contain `{% extends %}`. Fragments are injected into existing pages — they must be standalone HTML snippets.

```
FAIL: templates/forum/fragments/reply_item.html contains {% extends "base/base.html" %}
FIX:  Remove extends, fragment should be a bare HTML snippet
```

### CSRF Global Injection
Verify `templates/base/base.html` includes `<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>` so all HTMX requests automatically include the CSRF token.

### HX-Request Branching
Views serving both full pages and HTMX fragments must check `request.headers.get("HX-Request")` and return the correct template.

## 3 — Theme Token Usage

### No Hardcoded Colors
Grep templates for hardcoded color classes that should use theme tokens:

| Forbidden | Replacement |
|-----------|-------------|
| `text-white` on accent bg | `text-[var(--color-accent-text)]` |
| `text-black` | `text-[var(--color-text-primary)]` |
| `bg-white` | `bg-[var(--color-bg-primary)]` |
| `bg-gray-900` | `bg-[var(--color-bg-primary)]` |
| `border-gray-*` | `border-[var(--color-border)]` |

Critical: `--color-accent-text` is WHITE in dark/light themes but BLACK in high-contrast. Never hardcode.

### CSS Custom Properties
Verify `static/css/src/_themes.scss` defines all three themes (dark, light, contrast) with complete variable sets. Check `static/css/src/_variables.scss` for the base token definitions.

## 4 — Lucide Icon Compliance

### Icon Component Usage
Icons must use `{% include "components/_icon.html" %}` with `name` parameter, not inline SVG or `<i>` tags.

```
PASS: {% include "components/_icon.html" with name="download" size="20" %}
FAIL: <i data-lucide="download"></i>  ← should use component
```

### Version Pinning
Check `base.html` that Lucide is pinned at v0.460+ (pin major version in CDN URL).

## 5 — Responsive Design

### Mobile-First
Verify templates use mobile-first responsive classes: base styles for mobile, then `sm:`, `md:`, `lg:`, `xl:`, `2xl:` for larger screens.

### No Fixed Widths
Grep for `w-[NNNpx]` or `width: NNNpx` in templates/static that don't have responsive overrides. Flag containers that break on mobile.

### Container Consistency
Verify page content wraps in responsive containers: `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`.

## 6 — CDN Fallback Chain

Verify `templates/base/base.html` implements the 4-tier fallback:
1. **jsDelivr** (primary)
2. **cdnjs** (fallback 1)
3. **unpkg** (fallback 2)
4. **Local vendor** (fallback 3) — files in `static/vendor/`

Check each library (Tailwind, Alpine, HTMX, Lucide) has all 4 tiers configured.

## 7 — Print Stylesheet

Verify `static/css/src/_print.scss` exists and:
- Hides navigation, footer, sidebars, ads
- Uses white background, black text
- Removes decorative shadows and gradients
- Sets appropriate page margins
- Controls page breaks for content blocks

## 8 — Accessibility (WCAG 2.1 AA)

### Images
All `<img>` tags must have `alt` attributes. Decorative images use `alt=""` with `role="presentation"`.

### Form Labels
Every form input must have an associated `<label>` with `for=` matching the input `id`, or use `aria-label`.

### Heading Hierarchy
Each page must have exactly one `<h1>`. Headings must not skip levels (h1 → h3 without h2).

### Keyboard Navigation
Interactive elements must be keyboard-accessible. Check for `tabindex`, focus styles (`focus-visible:`), and skip links.

### Color Contrast
Text on colored backgrounds must meet WCAG AA contrast ratios:
- Normal text: 4.5:1
- Large text (18px+ or 14px+ bold): 3:1

## 9 — Component Reuse Enforcement

Grep for inline implementations that should use existing components from `templates/components/`:

| Inline Pattern | Required Component |
|---------------|-------------------|
| Inline KPI card HTML | `{% include "components/_admin_kpi_card.html" %}` |
| Inline modal HTML | `{% include "components/_modal.html" %}` |
| Inline pagination | `{% include "components/_pagination.html" %}` |
| Inline search bar | `{% include "components/_search_bar.html" %}` |
| Inline alert/toast | `{% include "components/_alert.html" %}` |
| Inline breadcrumb | `{% include "components/_breadcrumb.html" %}` |
| Inline empty state | `{% include "components/_empty_state.html" %}` |
| Inline loading spinner | `{% include "components/_loading.html" %}` |

## 10 — Static File Organization

Verify directory structure:
- `static/css/src/` — SCSS source files
- `static/css/dist/` — Compiled CSS
- `static/js/src/` — JS modules
- `static/js/dist/` — Minified JS
- `static/vendor/` — Local CDN fallbacks
- `static/img/` — Images and brand SVGs
- `static/fonts/` — WOFF2 fonts (Inter, JetBrains Mono)

## Report Format

```
[SEVERITY] CATEGORY — Description
  File: templates/path/to/file.html:LINE
  Fix: Specific remediation
```

Produce final summary with counts per category and overall frontend health score.
