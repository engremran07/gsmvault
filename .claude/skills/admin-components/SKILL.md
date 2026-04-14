---
name: admin-components
description: "Reusable admin panel components. Use when: building admin pages, KPI cards, data tables, search bars, bulk actions, admin CRUD templates. MANDATORY: always use these components instead of inline HTML."
user-invocable: true
---

# Admin Components Skill

## 4 Admin Components — NEVER Inline These

| Component | File | When to Use |
|---|---|---|
| KPI Stat Card | `_admin_kpi_card.html` | Every metric/stat on admin pages |
| Search + Sort Bar | `_admin_search.html` | Every admin list page |
| Sortable Data Table | `_admin_table.html` | Tabular data with pagination |
| Bulk Actions Bar | `_admin_bulk_actions.html` | Multi-select action toolbars |

## Quick Usage

```html
{# KPI grid #}
<div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6 stagger-children">
  {% include "components/_admin_kpi_card.html" with icon="file-text" color="blue" value=stats.total label="Total" stagger=0 %}
</div>

{# Search bar #}
{% include "components/_admin_search.html" with placeholder="Search…" q=q sort=sort dir=dir %}

{# Data table — requires columns, rows, sort, dir, page_obj context #}
{% include "components/_admin_table.html" with columns=columns rows=rows sort=sort dir=dir page_obj=page_obj %}

{# Bulk actions #}
{% include "components/_admin_bulk_actions.html" with actions=bulk_actions selected_count=0 %}
```

Full detail: @.github/skills/admin-components/SKILL.md
