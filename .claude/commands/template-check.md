# /template-check â€” Validate Django templates

Check all Django templates for syntax errors, broken extends/include chains, missing variables, and component usage violations.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Validate Template Syntax

- [ ] Run Django template validation: `& .\.venv\Scripts\python.exe manage.py validate_templates --settings=app.settings_dev` (if available)

- [ ] Scan for broken `{% extends %}` references â€” every template must point to an existing base

- [ ] Scan for broken `{% include %}` references â€” every included template must exist

- [ ] Verify `{% load %}` tags reference installed templatetags modules

### Step 2: Check HTMX Fragment Rules

- [ ] HTMX fragments in `templates/*/fragments/` must NOT use `{% extends %}`

- [ ] HTMX fragments are standalone HTML snippets only

- [ ] Verify `hx-target`, `hx-swap`, `hx-get`/`hx-post` attributes point to valid URLs

### Step 3: Check Alpine.js Rules

- [ ] All `x-show` / `x-if` elements must have `x-cloak` attribute

- [ ] No CSS `animate-*` classes on elements with `x-show` (animation conflict)

- [ ] No inline `<script>` blocks that duplicate Alpine component definitions

### Step 4: Verify Component Usage

- [ ] No inline KPI cards â€” must use `{% include "components/_admin_kpi_card.html" %}`

- [ ] No inline pagination â€” must use `{% include "components/_pagination.html" %}`

- [ ] No inline modals â€” must use `{% include "components/_modal.html" %}`

- [ ] No inline search bars â€” must use `{% include "components/_admin_search.html" %}` or `_search_bar.html`

- [ ] Check all 23 components in `templates/components/` for consistent usage

### Step 5: Check Theme Compatibility

- [ ] No hardcoded `text-white` on accent backgrounds â€” use `--color-accent-text` token

- [ ] CSS custom properties used for all theme-dependent colours

- [ ] Verify all three themes render correctly: dark, light, contrast
