---
name: tw-print-page-breaks
description: "Page break control for print layouts. Use when: controlling where pages break in print, keeping related content together, preventing orphaned headers."
---

# Print Page Break Control

## When to Use

- Preventing tables or cards from splitting across pages
- Keeping headings with their following content
- Forcing page breaks before major sections
- Firmware spec sheets and reports layout

## Rules

1. **`break-inside: avoid` on cards and images** — keeps them whole
2. **`break-after: avoid` on headings** — prevents orphaned headers
3. **`break-before: page` for major sections** — start new page
4. **Only in `@media print`** — no effect on screen layout
5. **Test by printing to PDF** — verify break behaviour

## Patterns

### Page Break CSS

```scss
/* static/css/src/_print.scss */
@media print {
  /* Prevent breaking inside these elements */
  .card, .firmware-card, figure, table, blockquote, pre {
    break-inside: avoid;
    page-break-inside: avoid; /* legacy fallback */
  }

  /* Keep headings with following content */
  h1, h2, h3, h4, h5, h6 {
    break-after: avoid;
    page-break-after: avoid;
  }

  /* Force new page before major sections */
  .page-break-before {
    break-before: page;
    page-break-before: always;
  }

  /* Orphan/widow control */
  p {
    orphans: 3;
    widows: 3;
  }
}
```

### Tailwind Print Utilities

```html
<!-- Keep card together on one page -->
<div class="print:break-inside-avoid rounded-lg
            bg-[var(--color-bg-secondary)] p-4">
  <h3 class="font-semibold text-[var(--color-text-primary)]">Device Specs</h3>
  <table class="w-full mt-2">
    <tr><td>OS</td><td>Android 14</td></tr>
    <tr><td>RAM</td><td>8 GB</td></tr>
  </table>
</div>

<!-- Force new page before this section -->
<section class="print:break-before-page mt-12">
  <h2 class="text-xl font-bold text-[var(--color-text-primary)]
             print:break-after-avoid">
    Changelog
  </h2>
  <div class="mt-4">Changelog content...</div>
</section>
```

### Print-Safe Table

```html
<table class="w-full print:break-inside-auto">
  <thead class="print:table-header-group">
    <tr class="border-b-2 border-[var(--color-border)] print:border-black">
      <th class="py-2 text-start">Model</th>
      <th class="py-2 text-start">Version</th>
      <th class="py-2 text-start">Date</th>
    </tr>
  </thead>
  <tbody>
    {% for fw in firmwares %}
    <tr class="border-b border-[var(--color-border)]
               print:border-gray-300 print:break-inside-avoid">
      <td class="py-2">{{ fw.model }}</td>
      <td class="py-2">{{ fw.version }}</td>
      <td class="py-2">{{ fw.date }}</td>
    </tr>
    {% endfor %}
  </tbody>
</table>
```

### Multi-Page Report Structure

```html
<!-- Cover page -->
<div class="print:break-after-page">
  <h1 class="text-4xl font-bold">Firmware Report</h1>
  <p class="mt-4">Generated: {{ now }}</p>
</div>

<!-- Summary section -->
<section class="print:break-after-page">
  <h2 class="text-2xl font-bold print:break-after-avoid">Summary</h2>
  <p>Overview content...</p>
</section>

<!-- Detail section -->
<section>
  <h2 class="text-2xl font-bold print:break-after-avoid">Details</h2>
  {% for item in items %}
  <div class="mt-4 print:break-inside-avoid">
    {{ item.content }}
  </div>
  {% endfor %}
</section>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No `break-inside: avoid` on cards | Cards split across pages | Add `print:break-inside-avoid` |
| Heading alone at bottom of page | Orphaned header | `print:break-after-avoid` on headings |
| No table header repeat | Can't read table on page 2 | `thead` with `print:table-header-group` |
| `break-before: page` without `@media print` | Breaks screen layout | Only in print context |

## Red Flags

- Tables spanning multiple pages without repeated headers
- Images cut in half across page breaks
- Section headings orphaned at the bottom of a page
- Page break styles applied outside `@media print`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_print.scss` — print stylesheet
- `.claude/rules/print-stylesheet.md` — print rules
