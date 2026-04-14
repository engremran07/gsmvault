---
paths: ["static/css/src/_print.scss"]
---

# Print Stylesheet

Rules for the `@media print` stylesheet ensuring clean printed output.

## Hidden Elements

- MUST hide: navigation, footer, sidebar, theme switcher, search bar, cookie consent banner.
- MUST hide: floating action buttons, tooltips, modals, dropdown menus, HTMX loading indicators.
- MUST hide: ad placements, social share buttons, back-to-top buttons.
- Use `.no-print` utility class for elements that should be hidden in print but are not covered by the above.

## Typography & Colour

- Force black text on white background: `color: #000 !important; background: #fff !important;`.
- Remove all background colours, gradients, and background images.
- Remove box shadows and text shadows.
- Use serif font stack for body text in print for better readability (optional, per brand guidelines).
- Ensure minimum 12pt font size for body text.

## Links & URLs

- Expand URLs after links: `a[href]:after { content: " (" attr(href) ")"; }`.
- Exclude internal/anchor links: `a[href^="#"]:after, a[href^="javascript:"]:after { content: ""; }`.
- Exclude navigation links — only expand URLs in content areas.
- Underline all links for visibility on printed paper.

## Page Breaks

- Use `break-inside: avoid` on cards, tables, code blocks, and image-caption groups.
- Use `break-before: page` on major section headers (h1, h2) when appropriate.
- Use `break-after: avoid` on headings to prevent orphaned headers.
- Tables: repeat `<thead>` on every printed page with `thead { display: table-header-group; }`.

## Layout Adjustments

- Remove `position: fixed` and `position: sticky` elements — they overlap content in print.
- Collapse multi-column grid layouts to single column for print.
- Set content width to 100% — remove max-width containers.
- Ensure images do not overflow the print area: `img { max-width: 100% !important; }`.
