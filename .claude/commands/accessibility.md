# /accessibility â€” WCAG 2.1 AA compliance audit

Audit templates and components for WCAG 2.1 Level AA compliance: alt text, ARIA roles, keyboard navigation, focus management, and contrast ratios.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Images & Media

- [ ] Verify all `<img>` tags have meaningful `alt` attributes

- [ ] Check decorative images use `alt=""` and `role="presentation"`

- [ ] Verify SVG icons (Lucide) have `aria-hidden="true"` when decorative

- [ ] Check SVG icons have `aria-label` when interactive

### Step 2: ARIA Roles & Labels

- [ ] Verify landmark roles: `<nav>`, `<main>`, `<aside>`, `<footer>`

- [ ] Check `aria-label` on navigation regions when multiple navs exist

- [ ] Verify modal dialogs have `role="dialog"` and `aria-modal="true"`

- [ ] Check `_modal.html` component has proper ARIA attributes

- [ ] Verify live regions (`aria-live`) for dynamic content updates (HTMX swaps)

### Step 3: Keyboard Navigation

- [ ] Verify all interactive elements are focusable (`tabindex` where needed)

- [ ] Check `Escape` key closes modals and dropdowns

- [ ] Verify `Enter`/`Space` activates buttons and links

- [ ] Check tab order follows visual layout (no `tabindex > 0`)

- [ ] Verify skip-to-content link at top of page

### Step 4: Focus Management

- [ ] Check focus moves to modal content when opened

- [ ] Verify focus returns to trigger element when modal closes

- [ ] Check HTMX partial updates don't lose focus position

- [ ] Verify focus ring styles are visible in all 3 themes (dark, light, contrast)

### Step 5: Color & Contrast

- [ ] Verify text contrast ratios meet 4.5:1 minimum (AA)

- [ ] Check large text meets 3:1 ratio

- [ ] Verify contrast theme (`data-theme="contrast"`) meets WCAG AAA (7:1)

- [ ] Check `--color-accent-text` usage across all 3 themes

- [ ] Verify information is not conveyed by color alone (use icons/text too)

### Step 6: Forms

- [ ] Check all form fields have associated `<label>` elements

- [ ] Verify error messages are linked via `aria-describedby`

- [ ] Check `_form_field.html` and `_field_error.html` components for accessibility

- [ ] Verify required fields are marked with `aria-required="true"`

### Step 7: Report

- [ ] Categorize issues: Critical (blocks access), Major (significant barrier), Minor (enhancement)

- [ ] List affected templates and components

- [ ] Provide fix recommendations
