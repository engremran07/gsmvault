---
name: enduser-components
description: "Reusable public/enduser frontend components. Use when: building public pages, cards, modals, alerts, badges, pagination, search, forms, loading states, tooltips, breadcrumbs, empty states, progress bars, theme switcher."
---

# End-User Components Skill

## MANDATORY Rule

**NEVER duplicate UI patterns inline on public-facing pages.** Always use the reusable components in `templates/components/`. If a pattern does not have a component, create one first, then include it.

---

## Component Inventory (19 End-User Components)

### Layout Components

#### `_card.html` — Content Card

Content card for firmware, blog posts, products. Optional image, badge, and description.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `image` | string | No | Image URL for card header |
| `title` | string | Yes | Card title text |
| `url` | string | No | Link URL for the card |
| `description` | string | No | Body text (auto-truncated) |
| `badge` | string | No | Optional badge text (top corner) |

```html
{% include "components/_card.html" with title="Samsung A54" url="/firmware/123/" description="Latest stock ROM" badge="New" %}
```

#### `_section_header.html` — Section Header

Section heading with optional subtitle and right-aligned action link.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Section title |
| `subtitle` | string | No | Subtitle text below title |
| `action_url` | string | No | URL for "View All" link |
| `action_label` | string | No | Action link text (default: "View All") |

```html
{% include "components/_section_header.html" with title="Latest Firmware" subtitle="Recently added" action_url="/browse/" action_label="View All" %}
```

#### `_stat_card.html` — Public Stat Card

Stat card for enduser pages (downloads, devices, brands count).

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `icon` | string | Yes | Lucide icon name |
| `color` | string | Yes | Tailwind color name |
| `value` | int/string | Yes | Display value |
| `label` | string | Yes | Label text |

```html
<div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
  {% include "components/_stat_card.html" with icon="download" color="cyan" value="1,234" label="Downloads" %}
  {% include "components/_stat_card.html" with icon="smartphone" color="blue" value="456" label="Devices" %}
</div>
```

#### `_empty_state.html` — Empty State Placeholder

Centered empty state with icon, message, and optional CTA.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `icon` | string | No | Lucide icon name |
| `message` | string | Yes | Empty state message |
| `action_url` | string | No | CTA button URL |
| `action_text` | string | No | CTA button text |

```html
{% include "components/_empty_state.html" with icon="search" message="No firmware found" action_url="/browse/" action_text="Browse All" %}
```

---

### Feedback Components

#### `_alert.html` — Alert Banner

Inline alert with auto-icon per type and optional dismiss.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `success`, `error`, `warning`, `info` |
| `message` | string | Yes | Alert message text |
| `title` | string | No | Bold title text |
| `dismissible` | bool | No | Show close button |
| `icon` | string | No | Override auto-icon |

```html
{% include "components/_alert.html" with type="success" message="Download started!" dismissible=True %}
```

#### `_badge.html` — Status Badge

Small colored pill for status display.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `variant` | string | Yes | `success`, `warning`, `error`, `info` |
| `label` | string | Yes | Badge text |

```html
{% include "components/_badge.html" with variant="success" label="Active" %}
```

#### `_loading.html` — Loading Indicator

4 variants: spinner, dots, skeleton, overlay.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `size` | string | No | `xs`, `sm`, `md`, `lg` |
| `variant` | string | No | `spinner` (default), `dots`, `skeleton`, `overlay` |
| `text` | string | No | Loading message |

```html
{% include "components/_loading.html" with variant="spinner" text="Loading firmware..." %}
```

#### `_progress_bar.html` — Progress Bar

Animated bar with optional label and percentage.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `percent` | int | Yes | Fill percentage (0-100) |
| `label` | string | No | Display label |
| `variant` | string | No | `default`, `success`, `warning`, `error` |
| `size` | string | No | `sm`, `md` |
| `striped` | bool | No | Striped shimmer effect |

```html
{% include "components/_progress_bar.html" with percent=75 label="Download progress" variant="success" striped=True %}
```

---

### Navigation Components

#### `_breadcrumb.html` — Breadcrumb Navigation

Multi-level breadcrumb with home icon.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `items` | list[dict] | Yes | `[{"label": "Home", "url": "/"}, {"label": "Firmware", "url": "/fw/"}]` |
| `label` | string | Yes | Current page label (leaf) |

```html
{% include "components/_breadcrumb.html" with items=breadcrumb label="Samsung A54" %}
```

#### `_pagination.html` — Paginator

Prev/next with HTMX partial swap.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `page_obj` | Page | Yes | Django paginator page object |

```html
{% include "components/_pagination.html" with page_obj=page_obj %}
```

---

### Interaction Components

#### `_search_bar.html` — Live Search

HTMX-powered live search with debounce and dropdown results.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `search_url` | string | Yes | URL for HTMX search requests |

```html
{% include "components/_search_bar.html" with search_url="/api/v1/firmwares/search/" %}
```

#### `_modal.html` — Modal Dialog

Alpine.js modal with backdrop and escape-to-close. Extensible via blocks.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Modal header title |
| `content` | string | No | Modal body text |
| `size` | string | No | `sm`, `md`, `lg`, `xl`, `full` |
| `closable` | bool | No | Show close button (default: True) |

Blocks: `{% block modal_content %}`, `{% block modal_footer %}`

```html
{% include "components/_modal.html" with title="Confirm Download" size="md" %}
```

#### `_confirm_dialog.html` — Confirmation Dialog

Global dialog driven by `$store.confirm`. No parameters — include once in base template.

```html
{# In base.html — already included #}
{% include "components/_confirm_dialog.html" %}
```

JS usage:
```javascript
$store.confirm.show({
  title: 'Delete firmware?',
  message: 'This action cannot be undone.',
  danger: true,
  onConfirm: () => { /* delete logic */ }
});
```

#### `_tooltip.html` — Hover Tooltip

4-position tooltip with Alpine.js show/hide.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `text` | string | Yes | Tooltip content |
| `position` | string | No | `top`, `bottom`, `left`, `right` (default: `top`) |
| `trigger` | slot | Yes | Content that triggers tooltip |

```html
{% include "components/_tooltip.html" with text="Download firmware" position="top" %}
```

#### `_theme_switcher.html` — Theme Toggle

Cycles dark → light → contrast. No parameters — reads `$store.theme`.

```html
{% include "components/_theme_switcher.html" %}
```

---

### Form Components

#### `_form_field.html` — Complete Form Field

Full form field with label, input, error, and help text.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `label` | string | Yes | Field label |
| `name` | string | Yes | Input name attribute |
| `field_id` | string | No | Input id attribute |
| `type` | string | No | Input type (default: `text`) |
| `value` | string | No | Pre-fill value |
| `placeholder` | string | No | Placeholder text |
| `required` | bool | No | Required field |
| `error` | string | No | Error message |
| `help_text` | string | No | Help message |

```html
{% include "components/_form_field.html" with label="Email" name="email" type="email" required=True %}
```

#### `_field_error.html` — Per-Field Error

Renders validation errors for a Django form field.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `field` | BoundField | Yes | Django form field object |

```html
{% include "components/_field_error.html" with field=form.email %}
```

#### `_form_errors.html` — Non-Field Errors

Renders non-field errors at top of form.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `form` | Form | Yes | Django form object |

```html
{% include "components/_form_errors.html" with form=form %}
```

---

### Utility Components

#### `_icon.html` — Lucide Icon Helper

Renders a single Lucide icon element.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Lucide icon name |
| `size` | string | No | CSS size class (default: `w-5 h-5`) |
| `extra_class` | string | No | Additional CSS classes |

```html
{% include "components/_icon.html" with name="download" size="w-6 h-6" extra_class="text-cyan-400" %}
```

---

## Anti-Patterns (NEVER DO)

1. **NEVER** build custom alert banners — use `_alert.html`
2. **NEVER** inline empty state HTML — use `_empty_state.html`
3. **NEVER** create ad-hoc modals — use `_modal.html`
4. **NEVER** build custom pagination — use `_pagination.html`
5. **NEVER** duplicate stat cards — use `_stat_card.html`
6. **NEVER** hardcode breadcrumbs — use `_breadcrumb.html`
7. **NEVER** build custom form fields — use `_form_field.html` or Django form rendering
8. **NEVER** inline loading spinners — use `_loading.html`
