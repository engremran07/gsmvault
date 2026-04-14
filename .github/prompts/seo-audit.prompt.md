---
agent: 'agent'
description: 'Audit SEO health including meta tags, JSON-LD, sitemaps, robots.txt, canonical URLs, and internal linking'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search']
---

# SEO Quality Audit

Audit all SEO infrastructure in the GSMFWs platform for completeness, correctness, and best-practice compliance.

## 1 — Meta Tags

### Title Tags
Scan all page templates (not fragments) in `templates/` for `<title>` or `{% block title %}`. Every public page must have a unique, descriptive title.

### Meta Descriptions
Scan for `<meta name="description"` or equivalent block. Every public page should have a meta description between 120-160 characters.

### Keyword Meta
Check if `<meta name="keywords"` is used. While less important for SEO, consistency matters if the pattern exists.

### SEO App Integration
Verify `apps/seo/models.py` `Metadata` model is used for dynamic per-page meta. Check if templates load meta from the SEO app.

## 2 — JSON-LD Structured Data

### Required Schemas
Verify `SchemaEntry` records or template-level JSON-LD exists for:

| Page Type | Schema | Priority |
|-----------|--------|----------|
| Homepage | `WebSite` + `Organization` | CRITICAL |
| Blog posts | `BlogPosting` | HIGH |
| Firmware pages | `SoftwareApplication` | HIGH |
| Forum FAQs | `FAQPage` | MEDIUM |
| Shop products | `Product` | MEDIUM |
| How-to guides | `HowTo` | LOW |
| Breadcrumbs | `BreadcrumbList` | HIGH |
| Search | `SearchAction` (sitelinks) | MEDIUM |

### Schema Validation
Check JSON-LD snippets in templates for valid structure. Verify `@context`, `@type`, required properties per schema type.

## 3 — Sitemap Completeness

### Sitemap Index
Check `templates/sitemap_index.xml` references all content sitemaps:
- Blog posts
- Firmware pages
- Device pages
- Forum topics
- CMS pages
- Shop products

### Sitemap Entries
Verify `SitemapEntry` model in `apps/seo/` covers all public URLs. Check `<lastmod>` dates are accurate.

### XSLT Stylesheet
Verify sitemaps reference an XSLT stylesheet for human-readable display. Check `static/xsl/` for the stylesheet file.

## 4 — robots.txt

Read `templates/robots.txt` and verify:
- `User-agent: *` with appropriate `Disallow` rules
- Admin, API, and auth paths disallowed
- `Sitemap:` directive pointing to sitemap index
- No accidental blocking of public content
- Development/staging environments fully blocked

## 5 — Canonical URLs

### Template Tags
Grep templates for `<link rel="canonical"`. Every public page template should set a canonical URL to prevent duplicate content.

### Pagination
Paginated pages must have canonical pointing to page 1 or self (depending on strategy). Check for `rel="next"` and `rel="prev"` on paginated sequences.

### Query Parameters
Pages with sort/filter query params should either:
- Set canonical to the base URL (without params)
- Or use `<meta name="robots" content="noindex">` for filtered views

## 6 — Open Graph Tags

Check all public page templates for:
```html
<meta property="og:title" content="...">
<meta property="og:description" content="...">
<meta property="og:image" content="...">
<meta property="og:url" content="...">
<meta property="og:type" content="website|article|product">
```

Verify `og:image` has a valid fallback default image for pages without specific images.

## 7 — Breadcrumbs

### Template Usage
Every public page (except homepage) should include breadcrumb navigation via `{% include "components/_breadcrumb.html" %}`.

### JSON-LD Breadcrumbs
Verify `BreadcrumbList` JSON-LD matches the visible breadcrumb trail.

### Consistency
Breadcrumb hierarchy must match URL structure and navigation tree.

## 8 — Internal Linking Engine

Check `apps/seo/models.py` for:
- `LinkableEntity` — entities eligible for internal linking
- `LinkSuggestion` — AI/algorithm-suggested link opportunities

Verify the internal linking engine:
1. Scans content for keyword matches
2. Suggests relevant cross-links
3. Doesn't over-link (max links per page)
4. Excludes nofollow/noindex pages from suggestions

## 9 — Redirect Management

### Redirect Chains
Scan `apps/seo` `Redirect` model for chains (A → B → C). These should be collapsed to A → C.

### Status Codes
Verify permanent redirects use 301 and temporary use 302. No 307/308 unless specifically needed.

### Broken Links
Check for redirects pointing to non-existent URLs (redirect → 404).

## 10 — Heading Hierarchy

Scan public page templates:
- Exactly one `<h1>` per page
- No skipped heading levels (h1 → h3 without h2)
- `<h1>` contains the page's primary keyword
- Subheadings use `<h2>` through `<h6>` in proper nesting order

## SEO Settings Audit

Check `apps/seo/models.py` for:
- `SEOSettings` — global SEO configuration toggles
- `SeoAutomationSettings` — AI meta generation, auto-tags, auto-schema toggles (7 admin toggles)

Verify each toggle's effect is properly implemented.

## Report

```
[CRITICAL/HIGH/MEDIUM/LOW] Category — Finding
  Page/Template: path/to/template.html
  Issue: What's wrong
  Impact: SEO penalty or missed opportunity
  Fix: Specific remediation
```

Summary: Overall SEO health score with counts per severity level.
