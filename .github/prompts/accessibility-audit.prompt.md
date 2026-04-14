---
agent: 'agent'
description: 'Run a WCAG 2.1 AA accessibility audit on templates, forms, navigation, and interactive elements'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search']
---

# WCAG 2.1 AA Accessibility Audit

Audit the GSMFWs frontend for compliance with Web Content Accessibility Guidelines 2.1 at AA level.

## 1 — ARIA Roles & Landmarks

### Page Landmarks
Verify all page templates have proper ARIA landmark roles:
- `<nav>` or `role="navigation"` for navigation bars
- `<main>` or `role="main"` for primary content area
- `<aside>` or `role="complementary"` for sidebars
- `<footer>` or `role="contentinfo"` for footer
- `<header>` or `role="banner"` for site header

### Widget Roles
Interactive components must have appropriate roles:
- Modals: `role="dialog"` with `aria-modal="true"` and `aria-labelledby`
- Tabs: `role="tablist"`, `role="tab"`, `role="tabpanel"`
- Dropdowns: `role="menu"`, `role="menuitem"`
- Alerts/toasts: `role="alert"` or `aria-live="polite"`
- Progress bars: `role="progressbar"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax`

### ARIA State Management
Alpine.js components with toggleable states must manage ARIA:
```html
<!-- Required -->
<button @click="open = !open" :aria-expanded="open">Toggle</button>
<div x-show="open" role="region" :aria-hidden="!open">Content</div>
```

## 2 — Keyboard Navigation

### Tab Order
All interactive elements must be reachable via Tab key in logical order. Check for:
- `tabindex` values > 0 (avoid — use natural DOM order instead)
- `tabindex="-1"` on elements that should be programmatically focusable only
- Missing `tabindex="0"` on custom interactive elements that aren't native buttons/links

### Focus Trapping
Modals (`_modal.html`) must trap focus:
- Tab cycles within the modal while open
- Focus moves to first focusable element on open
- Focus returns to trigger element on close

### Skip Links
Verify `templates/base/base.html` includes a skip-to-main-content link as the first focusable element:
```html
<a href="#main-content" class="sr-only focus:not-sr-only ...">Skip to main content</a>
```

### Escape Key
All overlays (modals, dropdowns, menus) must close on Escape key press.

## 3 — Focus Management

### Focus Visible
All focusable elements must have visible focus styles. Grep templates and CSS for:
- `focus:` or `focus-visible:` Tailwind classes on interactive elements
- `outline-none` without a replacement focus indicator is FORBIDDEN

### Focus After HTMX Swap
After HTMX content swaps, focus should be managed:
- Form errors: focus moves to first error field
- Content updates: focus moves to updated region or announces via `aria-live`
- Deletion: focus moves to logical next element

### Focus Restoration
After modal/dialog close, focus must return to the element that opened it.

## 4 — Color Contrast

### Normal Text
All text must meet 4.5:1 contrast ratio against its background. Check:
- Light theme: dark text on white/light backgrounds
- Dark theme: light text on dark backgrounds
- Contrast theme: maximum contrast (WCAG AAA target)

### Large Text
Text at 18px+ (or 14px+ bold) must meet 3:1 contrast ratio.

### Critical Token Check
`--color-accent-text` is WHITE in dark/light themes but BLACK in contrast theme. Verify templates use the CSS custom property, never hardcode `text-white` or `text-black` on accent backgrounds.

### Non-Text Contrast
UI components (borders, icons, form controls) must have 3:1 contrast against adjacent colors.

## 5 — Alt Text

### Images
All `<img>` tags must have `alt` attributes:
- Informative images: descriptive alt text
- Decorative images: `alt=""` with `role="presentation"` or `aria-hidden="true"`
- Complex images (charts, diagrams): detailed alt text or adjacent description

### Icons
Lucide icons used as standalone actions need `aria-label`:
```html
<!-- Icon button needs label -->
<button aria-label="Download firmware">
  {% include "components/_icon.html" with name="download" %}
</button>

<!-- Decorative icon alongside text is fine -->
<span>{% include "components/_icon.html" with name="download" %} Download</span>
```

### Background Images
Meaningful content must not be conveyed solely through `background-image` CSS.

## 6 — Form Labels

### Label Association
Every form input must have a visible `<label>` with `for=` matching the input `id`:
```html
<label for="email">Email</label>
<input type="email" id="email" name="email">
```

Or use `aria-label` for visually hidden labels:
```html
<input type="search" aria-label="Search firmware" placeholder="Search...">
```

### Error Messages
Form validation errors must be:
- Associated with the field via `aria-describedby`
- Announced to screen readers (use `role="alert"` or `aria-live="assertive"`)
- Visible (not just placeholder color change)

### Required Fields
Required fields must indicate their required state:
- `required` attribute on the input
- `aria-required="true"` if visual indicator differs
- Visual indicator (asterisk) with accessible label

## 7 — Heading Hierarchy

### Single H1
Each page must have exactly one `<h1>` containing the page's primary topic.

### No Skipping
Heading levels must not skip: `h1` → `h2` → `h3`, never `h1` → `h3`.

### Logical Nesting
Headings must reflect content structure, not just visual styling. Don't use `<h3>` for small text — use CSS instead.

## 8 — Skip Links

Verify the first focusable element on every page is a skip link:
```html
<a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:bg-white focus:px-4 focus:py-2 focus:rounded focus:shadow">
  Skip to main content
</a>
```

The target `#main-content` must exist on the `<main>` element.

## 9 — Reduced Motion

### prefers-reduced-motion
Verify animations respect user preference:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

Check `static/css/src/` for reduced motion media query. Verify Alpine.js transitions are suppressed when reduced motion is preferred.

### Auto-Playing Content
No auto-playing video, audio, or carousels without user control. Verify any auto-advancing content has pause/stop controls.

## 10 — Language Attribute

### html lang
Verify `templates/base/base.html` has `<html lang="en">` (or appropriate language code).

### Language Changes
Content in a different language than the page default must have `lang` attribute:
```html
<span lang="ar" dir="rtl">محتوى بالعربية</span>
```

## Report Format

```
[CRITICAL/HIGH/MEDIUM/LOW] WCAG SC X.X.X — Finding
  Criterion: Success Criterion name (e.g., "1.1.1 Non-text Content")
  File: templates/path/file.html:LINE
  Issue: What fails the criterion
  Impact: Who is affected (screen reader users, keyboard users, etc.)
  Fix: Specific remediation with code example
```

Summary: Compliance percentage per WCAG principle (Perceivable, Operable, Understandable, Robust) and overall AA compliance status.
