---
applyTo: 'templates/**/*.html'
---

# Django Template Conventions

## Template Hierarchy

```
templates/
  base/base.html              → Root: DOCTYPE, <head>, CDN fallback, theme init
  layouts/default.html         → Standard page: nav + content + footer
  layouts/dashboard.html       → Sidebar + content
  layouts/auth.html            → Auth pages (login, register)
  layouts/minimal.html         → Error pages
  components/                  → 23 reusable partials
  <app>/                       → Per-app templates
  <app>/fragments/             → HTMX fragments
```

All page templates MUST extend a layout:

```html
{% extends "layouts/default.html" %}

{% block title %}Firmware List{% endblock %}

{% block content %}
  <!-- Page content -->
{% endblock %}
```

## Reusable Components — MANDATORY

ALWAYS use `{% include %}` for UI components. NEVER inline these patterns:

```html
<!-- Cards -->
{% include "components/_card.html" with title="Downloads" body_class="p-4" %}

<!-- Modals -->
{% include "components/_modal.html" with id="confirm-delete" title="Confirm Delete" %}

<!-- Alerts -->
{% include "components/_alert.html" with type="success" message="Saved!" %}

<!-- Pagination -->
{% include "components/_pagination.html" with page_obj=page_obj %}

<!-- Empty State -->
{% include "components/_empty_state.html" with icon="inbox" message="No firmwares found" %}

<!-- Search Bar -->
{% include "components/_search_bar.html" with placeholder="Search..." %}

<!-- Admin KPI Cards -->
{% include "components/_admin_kpi_card.html" with title="Total" value=count icon="box" %}

<!-- Breadcrumbs -->
{% include "components/_breadcrumb.html" with items=breadcrumbs %}

<!-- Loading Spinner -->
{% include "components/_loading.html" %}

<!-- Tooltips -->
{% include "components/_tooltip.html" with text="Help text" %}
```

Creating duplicate component markup is forbidden when an equivalent component exists.
Extend existing component parameters/slots before introducing new template fragments.

## Alpine.js Rules

All Alpine.js conditional elements MUST have `x-cloak` to prevent FOUC:

```html
<!-- CORRECT -->
<div x-show="isOpen" x-cloak>Content</div>

<!-- WRONG — causes flash of unstyled content -->
<div x-show="isOpen">Content</div>
```

NEVER use CSS animation classes on elements with `x-show` — they conflict:

```html
<!-- WRONG — animation overrides display:none -->
<div x-show="isOpen" class="animate-fade-in">Content</div>

<!-- CORRECT — no animation class -->
<div x-show="isOpen" x-cloak x-transition>Content</div>
```

## Theming

Use CSS custom properties — NEVER hardcode colors:

```html
<!-- CORRECT -->
<div style="color: var(--color-accent-text);">Accent text</div>
<div class="text-[var(--color-accent)]">Accent</div>

<!-- WRONG — breaks in contrast theme -->
<div class="text-white">White text</div>
```

`--color-accent-text` is WHITE in dark/light themes but BLACK in contrast theme.

## HTMX Global CSRF

CSRF is handled globally in `base.html`:

```html
<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>
```

Never add per-request CSRF for HTMX — it is already handled.

## HTMX Fragments

Fragments in `templates/<app>/fragments/` are standalone snippets:

```html
<!-- CORRECT — standalone fragment -->
<div id="firmware-list">
  {% for fw in firmwares %}
    <div class="card">{{ fw.name }}</div>
  {% endfor %}
</div>

<!-- WRONG — fragment must NOT extend a base template -->
{% extends "layouts/default.html" %}  {# FORBIDDEN in fragments #}
```

## Static + Regression Policy

- Do not create new static CSS/JS files for minor template tweaks; prefer existing static modules.
- If a split is required for performance/maintainability, keep it cohesive and remove dead style/script paths.
- Template completion requires no-regression verification: backend contract mapping, UX behavior, and quality gate checks must stay clean.

## Lucide Icons

Use the icon component or direct SVG references:

```html
{% include "components/_icon.html" with name="download" size="20" %}
```

## Template Variable Safety

All variables are auto-escaped by Django. Only use `|safe` on content that has been
sanitized with `sanitize_html_content()` in the service layer. Never use `|safe` on
raw user input.
