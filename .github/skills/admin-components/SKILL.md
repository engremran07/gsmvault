---
name: admin-components
description: "Reusable admin panel components. Use when: building admin pages, KPI cards, data tables, search bars, bulk actions, admin CRUD templates. MANDATORY: always use these components instead of inline HTML."
---

# Admin Components Skill

## MANDATORY Rule

**NEVER duplicate admin UI patterns inline.** Always use the reusable components in `templates/components/_admin_*.html`. If a pattern does not have a component, create one first, then include it.

---

## Component Inventory (4 Admin Components)

### 1. `_admin_kpi_card.html` — KPI Stat Card

Animated stat card with Lucide icon, color accent, counter animation, and staggered entrance.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `icon` | string | Yes | Lucide icon name (e.g., `file-text`, `users`, `download`) |
| `color` | string | Yes | Tailwind color (e.g., `blue`, `emerald`, `cyan`, `purple`, `amber`, `red`) |
| `value` | int/string | Yes | The number to display |
| `label` | string | Yes | Short text label below the number |
| `stagger` | int | Yes | Entrance animation delay index (0, 1, 2, …) |

**Usage:**

```html
<div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6 stagger-children">
  {% include "components/_admin_kpi_card.html" with icon="file-text" color="blue" value=stats.total label="Total Posts" stagger=0 %}
  {% include "components/_admin_kpi_card.html" with icon="check-circle" color="emerald" value=stats.published label="Published" stagger=1 %}
  {% include "components/_admin_kpi_card.html" with icon="eye-off" color="amber" value=stats.drafts label="Drafts" stagger=2 %}
  {% include "components/_admin_kpi_card.html" with icon="message-circle" color="cyan" value=stats.comments label="Comments" stagger=3 %}
</div>
```

**Grid recommendation:** Use `grid-cols-2 sm:grid-cols-3 lg:grid-cols-N` where N = number of cards (typically 4-6).

---

### 2. `_admin_search.html` — Search + Sort Bar

Search input with hidden sort/dir fields, filter button, and clear link. Extends via `{% block extra_filters %}`.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `placeholder` | string | No | Input placeholder text (default: "Search…") |
| `action` | string | No | Form action URL (default: current page) |
| `q` | string | No | Current search query (pre-fills input) |
| `sort` | string | No | Current sort field (hidden field) |
| `dir` | string | No | Current sort direction (hidden field) |

**Usage:**

```html
{% include "components/_admin_search.html" with placeholder="Search posts…" q=q sort=sort dir=dir %}
```

**With extra filters:**

```html
{% include "components/_admin_search.html" with placeholder="Search…" q=q sort=sort dir=dir %}
{# Override block extra_filters for dropdowns, date pickers, etc. #}
```

---

### 3. `_admin_table.html` — Sortable Data Table

Full-featured table with column sorting (HTMX), bulk-select checkboxes, pagination footer, and empty state.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `columns` | list[dict] | Yes | Column definitions: `field`, `label`, `sortable` (bool), `class` |
| `rows` | QuerySet/list | Yes | Data rows to display |
| `sort` | string | No | Current sort field |
| `dir` | string | No | Current sort direction (`asc`/`desc`) |
| `q` | string | No | Current search query (for sort links) |
| `page` | int | No | Current page number |
| `id_field` | string | No | Field name for row IDs (default: `id`) |
| `bulk` | bool | No | Show bulk-select checkboxes |
| `empty_icon` | string | No | Lucide icon for empty state |
| `empty_text` | string | No | Message for empty state |
| `page_obj` | Page | No | Django paginator page object for footer |

**Usage:**

```html
{% include "components/_admin_table.html" with columns=columns rows=posts sort=sort dir=dir q=q bulk=True empty_icon="file-text" empty_text="No posts found" page_obj=page_obj %}
```

**View setup:**

```python
columns = [
    {"field": "title", "label": "Title", "sortable": True},
    {"field": "status", "label": "Status", "sortable": True},
    {"field": "created_at", "label": "Created", "sortable": True, "class": "text-right"},
]
context = {"columns": columns, "posts": qs, "sort": sort, "dir": dir_}
```

**Custom row rendering:** Override `{% block table_row %}` for column-specific formatting.

---

### 4. `_admin_bulk_actions.html` — Bulk Action Toolbar

Toolbar that appears when checkboxes are selected. Dropdown with actions, optional danger confirmation.

**Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `actions` | list[dict] | Yes | Action options: `value`, `label`, `icon`, `danger` (bool) |

**Usage:**

```html
{% include "components/_admin_bulk_actions.html" with actions=bulk_actions %}
```

**View setup:**

```python
bulk_actions = [
    {"value": "publish", "label": "Publish", "icon": "check"},
    {"value": "archive", "label": "Archive", "icon": "archive"},
    {"value": "delete", "label": "Delete", "icon": "trash-2", "danger": True},
]
```

---

## Standard Admin Page Pattern

Every admin page MUST follow this structure:

```html
{% extends "layouts/admin.html" %}
{% load humanize %}

{% block title %}My Page — Admin Panel{% endblock %}

{% block page_header %}
<div class="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-6">
  <div>
    <h1 class="text-2xl font-bold text-[var(--color-text-primary)] tracking-tight">Page Title</h1>
    <p class="mt-1 text-sm text-[var(--color-text-muted)]">Description</p>
  </div>
</div>
{% endblock %}

{% block page_content %}
{# 1. KPI Cards — ALWAYS use _admin_kpi_card.html #}
<div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6 stagger-children">
  {% include "components/_admin_kpi_card.html" with icon="..." color="..." value=stats.x label="..." stagger=0 %}
</div>

{# 2. Search Bar — use _admin_search.html #}
{% include "components/_admin_search.html" with placeholder="Search..." q=q sort=sort dir=dir %}

{# 3. Data Table — use _admin_table.html or custom glass table #}
<div class="glass rounded-xl overflow-hidden mb-6">
  ...
</div>
{% endblock %}
```

---

## Design System Tokens

- Glass cards: `class="glass rounded-xl p-5 hover-lift animate-in"`
- Entrance animation: `x-data x-intersect.once="$el.classList.add('animate-in-visible')"`
- Stagger delay: `style="--stagger: N"` (0-indexed)
- Section spacing: `mb-6` between major sections
- Color accents: `bg-{color}-500/15 text-{color}-400` pattern
- Border accent: `border-l-4 border-[var(--color-accent)]` for highlight cards

---

## Anti-Patterns (NEVER DO)

1. **NEVER** inline KPI card HTML — always use `_admin_kpi_card.html`
2. **NEVER** build custom search bars — always use `_admin_search.html`
3. **NEVER** duplicate table sort logic — always use `_admin_table.html` or `_admin_sort` helper
4. **NEVER** build custom pagination — always use `_admin_paginate` helper + `_pagination.html`
5. **NEVER** hardcode empty states — always use `_empty_state.html` with appropriate icon/message
