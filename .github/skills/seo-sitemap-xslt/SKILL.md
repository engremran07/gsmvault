---
name: seo-sitemap-xslt
description: "XSLT stylesheet for human-readable sitemaps. Use when: making XML sitemaps browseable, adding XSLT processing instruction, styling sitemap output."
---

# XSLT Stylesheet for Sitemaps

## When to Use

- Making XML sitemaps human-readable in browser
- Adding `<?xml-stylesheet?>` processing instruction to sitemaps
- Styling sitemap index and child sitemaps with tables

## Rules

### Processing Instruction

```xml
{# At top of every sitemap XML template, after XML declaration #}
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="/static/xsl/sitemap.xsl"?>
```

### XSLT File Location

```text
static/xsl/
  sitemap.xsl           # For child sitemaps (URL list)
  sitemap-index.xsl     # For sitemap index
```

### Minimal XSLT Structure

```xml
{# static/xsl/sitemap.xsl #}
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9">
<xsl:output method="html" encoding="UTF-8" indent="yes"/>
<xsl:template match="/">
<html><head>
  <title>XML Sitemap</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 2rem; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background: #1a1a2e; color: #fff; }
    tr:nth-child(even) { background: #f8f9fa; }
    a { color: #0066cc; }
  </style>
</head><body>
  <h1>XML Sitemap</h1>
  <p>URLs: <xsl:value-of select="count(sitemap:urlset/sitemap:url)"/></p>
  <table>
    <tr><th>URL</th><th>Last Modified</th><th>Priority</th></tr>
    <xsl:for-each select="sitemap:urlset/sitemap:url">
    <tr>
      <td><a href="{sitemap:loc}"><xsl:value-of select="sitemap:loc"/></a></td>
      <td><xsl:value-of select="sitemap:lastmod"/></td>
      <td><xsl:value-of select="sitemap:priority"/></td>
    </tr>
    </xsl:for-each>
  </table>
</body></html>
</xsl:template>
</xsl:stylesheet>
```

### Theme Awareness

Style the XSLT table to match the platform's dark theme if rendered in-site:

```css
/* Inside XSLT <style> block */
@media (prefers-color-scheme: dark) {
  body { background: #0f0f23; color: #e0e0e0; }
  th { background: #16213e; }
  tr:nth-child(even) { background: #1a1a2e; }
  a { color: #64b5f6; }
}
```

## Anti-Patterns

- Missing namespace declaration `xmlns:sitemap` — XSLT won't match elements
- XSLT referencing CDN resources — keep self-contained in static files
- Different XSLT for index vs child sitemaps using same filename

## Red Flags

- `<?xml-stylesheet?>` href points to non-existent file
- XSLT uses XSL 3.0 features not supported by browsers
- Missing URL count display — always show total

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
