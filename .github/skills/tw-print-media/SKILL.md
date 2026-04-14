---
name: tw-print-media
description: "Print stylesheet: @media print, hiding nav/footer, page breaks. Use when: making pages print-friendly, hiding interactive elements in print, optimizing print layout."
---

# Print Stylesheet

## When to Use

- Making firmware detail pages print-friendly
- Hiding navigation, footer, and interactive elements in print
- Optimizing page layout for paper output

## Rules

1. **Hide non-essential elements** — nav, footer, sidebar, buttons, theme switcher
2. **Remove backgrounds and shadows** — save ink, improve readability
3. **Force dark text on white background** — regardless of theme
4. **Show URLs after links** — `a::after { content: " (" attr(href) ")"; }`
5. **Print styles in `static/css/src/_print.scss`** — not inline

## Patterns

### Print Stylesheet in SCSS

```scss
/* static/css/src/_print.scss */
@media print {
  /* Reset to readable defaults */
  body {
    color: #000 !important;
    background: #fff !important;
    font-size: 12pt;
    line-height: 1.5;
  }

  /* Hide non-printable elements */
  nav, footer, .no-print, .theme-switcher,
  button:not(.print-include), .sidebar,
  [x-data], .toast-container {
    display: none !important;
  }

  /* Remove decorative styles */
  * {
    box-shadow: none !important;
    text-shadow: none !important;
  }

  /* Show link URLs */
  a[href]::after {
    content: " (" attr(href) ")";
    font-size: 0.8em;
    color: #666;
  }

  /* Don't show URLs for internal/anchor links */
  a[href^="#"]::after,
  a[href^="javascript:"]::after {
    content: "";
  }

  /* Ensure images don't overflow */
  img {
    max-width: 100% !important;
    page-break-inside: avoid;
  }
}
```

### Print-Only / Print-Hidden Utility Classes

```html
<!-- Hidden on screen, visible in print -->
<div class="hidden print:block">
  <p>Printed on: <span id="print-date"></span></p>
</div>

<!-- Visible on screen, hidden in print -->
<button class="print:hidden bg-[var(--color-accent)]
               text-[var(--color-accent-text)] px-4 py-2 rounded-lg">
  Download
</button>

<!-- Or use no-print class from SCSS -->
<nav class="no-print">Navigation</nav>
```

### Print-Friendly Content Area

```html
<main class="max-w-7xl mx-auto px-4 print:max-w-full print:px-0">
  <h1 class="text-2xl font-bold text-[var(--color-text-primary)]
             print:text-black print:text-xl">
    Firmware Details
  </h1>

  <table class="w-full print:text-sm print:border-collapse">
    <thead>
      <tr class="border-b border-[var(--color-border)] print:border-black">
        <th class="text-start py-2">Property</th>
        <th class="text-start py-2">Value</th>
      </tr>
    </thead>
    <tbody>
      <tr class="border-b border-[var(--color-border)] print:border-gray-300">
        <td class="py-2">Version</td>
        <td class="py-2">{{ firmware.version }}</td>
      </tr>
    </tbody>
  </table>
</main>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No print styles at all | Pages print with dark backgrounds | Add `_print.scss` |
| `display: none` in print without `!important` | Theme styles override | Use `!important` in print |
| Printing interactive elements (buttons, toggles) | Useless on paper | `print:hidden` |
| Background images/gradients in print | Wastes ink, may not render | Force white background |

## Red Flags

- Pages with dark themes printing black backgrounds
- Navigation and footer appearing in print output
- Links without visible URLs in print
- Tables breaking across pages without headers repeating

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_print.scss` — print stylesheet
- `.claude/rules/print-stylesheet.md` — print rules
