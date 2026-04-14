---
paths: ["templates/**"]
---

# Frontend Template Rules

These rules apply to all Django HTML templates in the `templates/` directory.

## Template Inheritance

- All full-page templates MUST extend `templates/base/base.html` (via `layouts/` intermediaries).
- **HTMX fragments MUST NOT use `{% extends %}`** — they are standalone HTML snippets injected into the DOM. A fragment that extends a base template will render the entire page layout inside the target element.
- Use layout templates: `layouts/default.html`, `layouts/dashboard.html`, `layouts/auth.html`, `layouts/minimal.html`.
- HTMX fragments live in `templates/<app>/fragments/` subdirectory.

## Alpine.js Rules

- **All** `x-show` and `x-if` elements MUST have `x-cloak` to prevent flash of unstyled content.
  ```html
  <div x-show="open" x-cloak>...</div>
  ```
- **Alpine.js `x-show` + CSS `animate-*` / `transition-*` classes conflict** — never add Tailwind animation utility classes to elements that use `x-show`. The animation class overrides Alpine's `display:none`, causing flicker. Use Alpine's built-in `x-transition` directives instead.
- Store theme preference in `localStorage`, apply `data-theme` on `<html>` for instant rendering without server round-trip.

## Theming — CSS Custom Properties

- The platform has 3 themes: `dark` (default), `light`, `contrast`.
- **NEVER hardcode `text-white` or `text-black` on accent-background elements.**
- **Always** use `var(--color-accent-text)` — it is WHITE in dark/light themes but BLACK in contrast theme. Hardcoding white text on an accent background breaks WCAG AAA in contrast mode.
- All colors MUST use CSS custom properties (`var(--color-*)`) or Tailwind tokens mapped to those properties.

## CSRF and Security

- Every HTML form that mutates state MUST include `{% csrf_token %}`.
- Inline `<script>` tags that need CSP compliance MUST include the nonce: `<script nonce="{{ request.csp_nonce }}">`.
- Never hardcode secrets, API keys, or internal paths in templates.

## Reusable Components — MANDATORY

Check `templates/components/` before writing any inline UI. The 23 components are:

**Admin**: `_admin_kpi_card`, `_admin_search`, `_admin_table`, `_admin_bulk_actions`
**Enduser**: `_card`, `_modal`, `_alert`, `_confirm_dialog`, `_tooltip`, `_badge`, `_breadcrumb`, `_empty_state`, `_field_error`, `_form_errors`, `_form_field`, `_icon`, `_loading`, `_pagination`, `_progress_bar`, `_search_bar`, `_section_header`, `_stat_card`, `_theme_switcher`

- Never inline a KPI card, pagination widget, search bar, or alert that should use the component.
- Use `{% include "components/_component_name.html" with param=value %}`.

## HTMX Patterns

- Views that serve both full pages and HTMX fragments:
  ```python
  if request.headers.get("HX-Request"):
      return render(request, "app/fragments/list.html", ctx)
  return render(request, "app/list.html", ctx)
  ```
- HTMX swap targets must have stable IDs (use `hx-target="#element-id"`).
- Use `hx-boost` only on navigation links — **never** on forms or action buttons (see `hx-boost-prohibition` repo memory).

## Multi-CDN Fallback

CDN libraries load in this order: jsDelivr → cdnjs → unpkg → local vendor. This is configured in `base/base.html`. Never add a raw CDN `<script>` link without the appropriate fallback chain.
