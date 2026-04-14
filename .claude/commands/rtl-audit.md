# /rtl-audit â€” Audit templates for RTL language support

Audit HTML templates for right-to-left (RTL) language compatibility: dir attributes, logical CSS properties, bidirectional text handling.

## Scope

$ARGUMENTS

## Checklist

### Step 1: HTML dir Attribute

- [ ] Check `<html>` tag in `templates/base/base.html` supports `dir="rtl"` dynamically

- [ ] Verify `lang` attribute is set dynamically based on active language

- [ ] Check for hardcoded `dir="ltr"` that would block RTL

### Step 2: CSS Logical Properties

- [ ] Scan `static/css/src/` for physical properties that should be logical:
  - `margin-left/right` â†’ `margin-inline-start/end`
  - `padding-left/right` â†’ `padding-inline-start/end`
  - `text-align: left/right` â†’ `text-align: start/end`
  - `float: left/right` â†’ `float: inline-start/end`
  - `border-left/right` â†’ `border-inline-start/end`

- [ ] Verify Tailwind classes use logical variants where available (`ms-*`, `me-*`, `ps-*`, `pe-*`)

### Step 3: Template Bidirectional Text

- [ ] Check for hardcoded left/right positioning in templates

- [ ] Verify icon placement (arrows, chevrons) can flip for RTL

- [ ] Check navigation menus support RTL layout

- [ ] Verify form labels and inputs align correctly in RTL

### Step 4: Component Audit

- [ ] Audit all 23 components in `templates/components/` for RTL compatibility

- [ ] Check `_breadcrumb.html` separator direction

- [ ] Check `_pagination.html` prev/next arrow direction

- [ ] Check `_search_bar.html` icon placement

### Step 5: JavaScript/Alpine.js

- [ ] Verify Alpine.js components don't assume LTR text direction

- [ ] Check any JS-driven positioning respects `document.dir`

### Step 6: Report

- [ ] List all RTL-incompatible patterns found

- [ ] Categorize by severity: blocking, moderate, cosmetic

- [ ] Provide fix recommendations for each issue
