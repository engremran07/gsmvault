---
name: frontend-templates
description: "Create Django HTML templates with Tailwind CSS, Alpine.js, HTMX. Use when: building page templates, base layouts, component partials, HTMX fragments, template inheritance, includes, blocks, Django template tags, context processors."
---

# Frontend Templates

## When to Use

- Creating new page templates (blog, firmware, user dashboard, etc.)
- Building reusable component partials (`_card.html`, `_modal.html`, etc.)
- Setting up template inheritance (`{% extends %}`, `{% block %}`)
- Creating HTMX fragment endpoints (partial HTML responses)
- Adding Django template tags and filters
- Fixing visual bugs, layout issues, or empty-state rendering

## Rules

1. **All templates live in `templates/`** — never inside app directories
2. **Use template inheritance** — every page extends a layout, every layout extends `base/_base.html`
3. **Partials start with underscore** — `_nav.html`, `_card.html`, `_pagination.html`
4. **HTMX fragments are separate files** — `firmwares/fragments/list.html` (partial), `firmwares/list.html` (full page)
5. **Always include CSP nonce** — `<script nonce="{{ request.csp_nonce }}">` on every inline `<script>`
6. **Use `{% load static %}` once per template** — at the top, after `{% extends %}`
7. **Theme-aware styling** — use CSS custom properties (`var(--color-*)`) not hardcoded colors
8. **Lucide icons via data-lucide** — `<i data-lucide="download" class="w-5 h-5"></i>`
9. **CSRF on all forms** — `{% csrf_token %}` in every `<form method="post">`
10. **No inline styles** — use Tailwind classes or SCSS; exception: `[x-cloak]` in `_head.html`
11. **`x-cloak` on every Alpine conditional element** — any element with `x-show`, `x-if`, or Alpine toggle must have `x-cloak` to prevent FOUC (flash of unstyled content)
12. **Never render empty containers** — wrap sections in `{% if data %}...{% endif %}` so empty `<section>`/`<div>` elements with padding/margin don't show as visible blank rectangles
13. **Never rely on `|default` for missing context variables in DEBUG mode** — Django's `string_if_invalid` setting produces a truthy warning string that bypasses the `|default` filter. Use `{% now "Y" %}` for dates, hardcode placeholder text, or use `{% if var %}{{ var }}{% else %}fallback{% endif %}` instead
14. **NEVER use `text-white` on accent backgrounds** — always use `text-[var(--color-accent-text)]` (contrast theme has yellow accent where white text is invisible)
15. **NEVER use `hover:opacity-90` on buttons** — always use `hover:bg-[var(--color-accent-hover)]` for proper theme-aware hover
16. **Use `x-show` not `<template x-if>` for Lucide icon toggling** — Lucide renders SVG at DOMContentLoaded; if `x-if` destroys/recreates DOM, the new icons never render. `x-show` keeps all icons in DOM and toggles visibility.

## CRITICAL: Anti-FOUC (Flash of Unstyled Content)

Templates MUST prevent visual flashes on page load. Three mechanisms:

### 1. Theme flash prevention (in `_head.html`)
```html
<script nonce="{{ request.csp_nonce }}">
  (function(){ document.documentElement.setAttribute('data-theme', localStorage.getItem('theme') || 'dark'); })();
</script>
```

### 2. Alpine x-cloak (in `_head.html` as inline `<style>`)
```html
<style>[x-cloak] { display: none !important; }</style>
```
Then on EVERY Alpine conditional element:
```html
<div x-show="open" x-cloak>...</div>     <!-- hidden until Alpine initializes -->
<div x-show="focused" x-cloak>...</div>  <!-- search results dropdown -->
<div x-show="mobileOpen" x-cloak>...</div> <!-- mobile menu -->
```

### 3. Empty container prevention
```html
{# WRONG — renders a visible empty rectangle when data is missing #}
<section class="py-8">
  {% if items %}...{% endif %}
</section>

{# CORRECT — entire section hidden when empty #}
{% if items %}
<section class="py-8">
  ...
</section>
{% endif %}
```

## CRITICAL: `string_if_invalid` Gotcha

In `app/settings.py`, DEBUG mode sets `string_if_invalid = "⚠ Missing: %s ⚠"`. This means:
- `{{ undefined_var }}` renders as `"⚠ Missing: undefined_var ⚠"` (a truthy string)
- `{{ undefined_var|default:"fallback" }}` → still shows the warning (the string is truthy, so `|default` doesn't trigger)

**Safe patterns:**
```html
{% now "Y" %}                                    {# Current year — template tag, not variable #}
placeholder="Search firmware..."                 {# Hardcoded text — not a template variable #}
{% if my_var %}{{ my_var }}{% else %}fallback{% endif %}  {# Explicit check #}
{{ my_var|default_if_none:"fallback" }}          {# Only works for None, not missing vars #}
```

## Template Hierarchy

```text
base/_base.html                    # Root: DOCTYPE, <html>, <head>, <body>
  └─ layouts/default.html          # Nav + content + footer
      └─ blog/list.html            # Specific page
  └─ layouts/dashboard.html        # Sidebar + nav + content
      └─ user/dashboard.html       # Specific page
  └─ layouts/auth.html             # Centered card
      └─ auth/login.html           # Specific page
  └─ layouts/minimal.html          # Error pages
      └─ errors/404.html           # Specific page
```

## Reusable Components (23 components in `templates/components/`)

**Admin** (4): `_admin_kpi_card`, `_admin_search`, `_admin_table`, `_admin_bulk_actions`

**End-user** (19):

| Component | File | Purpose |
| --- | --- | --- |
| Card | `_card.html` | Content card (firmware, blog, product) |
| Modal | `_modal.html` | Modal dialog (Alpine.js, `x-cloak`) |
| Alert | `_alert.html` | Alert/notification banner |
| Confirm Dialog | `_confirm_dialog.html` | Async confirmation (`$store.confirm`, `x-cloak`) |
| Tooltip | `_tooltip.html` | Tooltip on hover (Alpine.js, `x-cloak`) |
| Form Field | `_form_field.html` | Styled form field wrapper |
| Form Errors | `_form_errors.html` | Form-level validation error list |
| Field Error | `_field_error.html` | Per-field inline error message |
| Progress Bar | `_progress_bar.html` | Animated progress bar (Alpine.js) |
| Loading | `_loading.html` | Loading spinner/skeleton |
| Search Bar | `_search_bar.html` | HTMX live search with Alpine dropdown (`x-cloak`) |
| Pagination | `_pagination.html` | Paginator with `flex-wrap` for mobile |
| Breadcrumb | `_breadcrumb.html` | Breadcrumb navigation |
| Badge | `_badge.html` | Status badge |
| Empty State | `_empty_state.html` | Empty state placeholder |
| Icon | `_icon.html` | Lucide SVG icon wrapper |
| Section Header | `_section_header.html` | Page section titles |
| Stat Card | `_stat_card.html` | Public statistics display |
| Theme Switcher | `_theme_switcher.html` | Dark/light/contrast toggle |

## Notification System

Two Alpine.js stores provide centralized notifications (defined in `notifications.js`):

```javascript
$store.notify.show('File uploaded', 'success', 5000)  // Toast notification
$store.confirm.ask('Delete?', 'This cannot be undone') // Returns Promise
```

- `_messages.html` auto-converts Django messages framework into `$store.notify` toasts
- `_confirm_dialog.html` renders the confirmation modal (included in `_base.html`)
- Never use browser `alert()` or `confirm()` — always use `$store.notify` / `$store.confirm`

## Base Template Pattern

```html
{# templates/base/_base.html #}
<!DOCTYPE html>
<html lang="{{ LANGUAGE_CODE|default:'en' }}" data-theme="dark">
<head>
  {% include "base/_head.html" %}
  {% block extra_css %}{% endblock %}
</head>
<body class="bg-[var(--color-bg-primary)] text-[var(--color-text-primary)] min-h-screen flex flex-col antialiased"
      hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>
  {% include "base/_nav.html" %}
  {% include "base/_messages.html" %}
  <main class="flex-1">
    {% block content %}{% endblock %}
  </main>
  {% include "base/_footer.html" %}
  {% include "components/_confirm_dialog.html" %}
  {% include "base/_scripts.html" %}
  {% block extra_js %}{% endblock %}
</body>
</html>
```

## `_head.html` Required Elements

```html
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="color-scheme" content="dark light">
<meta name="theme-color" content="#0f172a" media="(prefers-color-scheme: dark)">
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<link rel="stylesheet" href="{% static 'css/dist/main.css' %}">
<style>[x-cloak] { display: none !important; }</style>
<script nonce="{{ request.csp_nonce }}">
  (function(){ document.documentElement.setAttribute('data-theme', localStorage.getItem('theme') || 'dark'); })();
</script>
```

## Responsive Requirements

- All text: mobile-friendly sizing with responsive breakpoints (`text-2xl md:text-3xl`)
- All grids: mobile-first (`grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`)
- All images: responsive height (`h-40 sm:h-48`)
- Pagination: `flex-wrap` to prevent overflow on small screens
- Body: `antialiased` class for font smoothing across browsers

## HTMX Fragment Pattern

Views serve both full pages and HTMX fragments:

```python
def firmware_list(request):
    firmwares = Firmware.objects.select_related("device").all()
    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", {"firmwares": firmwares})
    return render(request, "firmwares/list.html", {"firmwares": firmwares})
```

## Admin Template Patterns

Admin pages use a separate layout and template structure from the public frontend.

### Inheritance Chain

```text
base/_base.html
  └─ layouts/admin.html              # Admin layout: sidebar + topbar + content area
      └─ admin_suite/<page>.html      # Specific admin page
```

### Required Blocks

Every admin page template must define:

```html
{% extends "layouts/admin.html" %}
{% load static %}

{% block page_header %}
  {% include "admin_suite/_page_header.html" with
    title="Dashboard"
    subtitle="Overview of platform metrics"
    breadcrumbs=breadcrumbs
  %}
{% endblock %}

{% block page_content %}
  {# Main page content here #}
{% endblock %}
```

### `_page_header.html` Component

Provides consistent breadcrumb + title + subtitle across all admin pages:

```html
{# templates/admin_suite/_page_header.html #}
<div class="mb-6">
  <nav class="flex items-center gap-2 text-sm text-[var(--color-text-muted)] mb-2">
    {% for crumb in breadcrumbs %}
      {% if not forloop.last %}
        <a href="{{ crumb.url }}" class="hover:text-[var(--color-accent)]">{{ crumb.label }}</a>
        <i data-lucide="chevron-right" class="w-4 h-4"></i>
      {% else %}
        <span class="text-[var(--color-text-primary)]">{{ crumb.label }}</span>
      {% endif %}
    {% endfor %}
  </nav>
  <h1 class="text-2xl md:text-3xl font-bold text-[var(--color-text-primary)]">{{ title }}</h1>
  {% if subtitle %}
    <p class="mt-1 text-[var(--color-text-secondary)]">{{ subtitle }}</p>
  {% endif %}
</div>
```

## Hybrid Navigation

The admin panel uses a sidebar for primary navigation (not the public navbar).

### Sidebar Template

`templates/admin_suite/_sidebar.html` renders the sidebar with navigation groups. The active link is determined by the `nav_active` context variable set in each view.

```python
# In admin views:
def dashboard(request):
    return render(request, "admin_suite/dashboard.html", {
        "nav_active": "dashboard",
    })
```

```html
{# In _sidebar.html — highlight active link #}
<a href="{% url 'admin_suite:dashboard' %}"
   class="admin-sidebar-link {% if nav_active == 'dashboard' %}active{% endif %}">
  <i data-lucide="layout-dashboard" class="w-5 h-5"></i>
  <span>Dashboard</span>
</a>
```

### Navigation Groups

Sidebar links are organized into collapsible groups (Content, Users, Security, etc.), each managed with Alpine.js `x-data` and `x-show` with `x-cloak`.

## HTMX Table Patterns

### Sortable Admin Tables

Admin data tables support server-side sorting via HTMX:

```html
<table class="admin-table w-full">
  <thead>
    <tr>
      <th>
        <a hx-get="?sort=name&order={% if sort == 'name' and order == 'asc' %}desc{% else %}asc{% endif %}"
           hx-target="#table-body"
           hx-indicator="#table-spinner"
           class="flex items-center gap-1 cursor-pointer">
          Name
          <i data-lucide="{% if sort == 'name' %}{% if order == 'asc' %}chevron-up{% else %}chevron-down{% endif %}{% else %}chevrons-up-down{% endif %}"
             class="w-4 h-4"></i>
        </a>
      </th>
    </tr>
  </thead>
  <tbody id="table-body">
    {% include "admin_suite/fragments/table_rows.html" %}
  </tbody>
</table>
```

### Inline Editing

Fields can be edited inline using HTMX `hx-put`:

```html
<td hx-get="{% url 'admin_suite:inline_edit' pk=obj.pk field='status' %}"
    hx-trigger="dblclick"
    hx-swap="innerHTML"
    class="cursor-pointer hover:bg-[var(--color-bg-tertiary)]">
  {{ obj.status }}
</td>
```

### Server-Sent Events for Live Updates

For real-time dashboard widgets, use HTMX SSE extension:

```html
<div hx-ext="sse" sse-connect="{% url 'admin_suite:sse_stats' %}">
  <div sse-swap="stats-update" hx-swap="innerHTML">
    {% include "admin_suite/fragments/live_stats.html" %}
  </div>
</div>
```

## Procedure

1. Determine template type: page, layout, component, or HTMX fragment
2. Place in correct directory (`templates/<section>/`)
3. Use proper inheritance chain (page → layout → base)
4. Add `x-cloak` to every element with `x-show`, `x-if`, or Alpine toggle
5. Wrap conditional sections so empty containers don't render visible blank space
6. Never use `|default` for context variables that may be undefined — use `{% if %}` or template tags
7. Include CSP nonce on any inline scripts
8. Use theme-aware CSS custom properties (never hardcoded colors)
9. Add CSRF token to all forms
10. Use responsive utility classes (mobile-first breakpoints)
11. Test both full-page and HTMX-fragment rendering
12. Run quality gate
