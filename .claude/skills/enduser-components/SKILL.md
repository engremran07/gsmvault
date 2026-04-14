---
name: enduser-components
description: "Reusable public/enduser frontend components. Use when: building public pages, cards, modals, alerts, badges, pagination, search, forms, loading states, tooltips, breadcrumbs, empty states, progress bars, theme switcher."
user-invocable: true
---

# End-User Components Skill

> Full reference: @.github/skills/enduser-components/SKILL.md

## 19 Components — ALWAYS use `{% include %}`, NEVER inline

| Component | File | Use For |
|---|---|---|
| Alert | `_alert.html` | Status messages: success/warning/error/info |
| Badge | `_badge.html` | Status badges, tags, labels |
| Breadcrumb | `_breadcrumb.html` | Navigation trail |
| Card | `_card.html` | Content cards: header/body/footer |
| Confirm Dialog | `_confirm_dialog.html` | Destructive action confirmation |
| Empty State | `_empty_state.html` | No-data placeholder with CTA |
| Field Error | `_field_error.html` | Form field-level error |
| Form Errors | `_form_errors.html` | Form-level error summary |
| Form Field | `_form_field.html` | Styled form field wrapper |
| Icon | `_icon.html` | Lucide SVG icon wrapper |
| Loading | `_loading.html` | Spinner / skeleton |
| Modal | `_modal.html` | Modal dialog overlay |
| Pagination | `_pagination.html` | Page navigation controls |
| Progress Bar | `_progress_bar.html` | Progress indicator |
| Search Bar | `_search_bar.html` | Public search input |
| Section Header | `_section_header.html` | Page section titles |
| Stat Card | `_stat_card.html` | Public statistics display |
| Theme Switcher | `_theme_switcher.html` | Dark/light/contrast toggle |
| Tooltip | `_tooltip.html` | Hover tooltip |

## Usage Pattern

```django
{% include "components/_alert.html" with type="success" message="Saved!" %}
{% include "components/_pagination.html" with page_obj=page_obj %}
{% include "components/_empty_state.html" with icon="inbox" title="No results" %}
```

## Never

- Inline KPI cards, pagination, or alert banners — use the component
- Duplicate a component pattern in two different templates
