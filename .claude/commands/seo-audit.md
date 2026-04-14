# /seo-audit â€” SEO compliance audit

Audit SEO implementation: meta tags, sitemaps, robots.txt, structured data (JSON-LD), canonical URLs, Open Graph tags, and internal linking engine.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Meta Tags

- [ ] Verify `<title>` tag is set on all page templates

- [ ] Check `<meta name="description">` on all public pages

- [ ] Verify meta tags come from `apps.seo.models.Metadata` or template defaults

- [ ] Check for duplicate or missing title/description patterns

### Step 2: Open Graph & Social

- [ ] Verify `og:title`, `og:description`, `og:image`, `og:url` on public pages

- [ ] Check Twitter Card meta tags (`twitter:card`, `twitter:title`, etc.)

- [ ] Verify social sharing images meet minimum dimensions (1200x630)

### Step 3: Sitemaps

- [ ] Verify `templates/sitemap.xml` and `templates/sitemap_index.xml` exist

- [ ] Check `apps.seo.models.SitemapEntry` covers all public URL patterns

- [ ] Verify XSLT stylesheet for human-readable sitemap view

- [ ] Test sitemap URL is accessible and valid XML

### Step 4: robots.txt

- [ ] Verify `templates/robots.txt` exists and is served correctly

- [ ] Check Sitemap directive points to sitemap index

- [ ] Verify admin, API, and private paths are disallowed

- [ ] Check User-agent directives are appropriate

### Step 5: Structured Data (JSON-LD)

- [ ] Verify `apps.seo.models.SchemaEntry` generates valid JSON-LD

- [ ] Check schema types: Organization, WebSite, BreadcrumbList, Product, Article

- [ ] Validate JSON-LD output format

### Step 6: Canonical URLs

- [ ] Verify `<link rel="canonical">` on all public pages

- [ ] Check canonical URLs are absolute (include domain)

- [ ] Verify no duplicate content without canonical resolution

### Step 7: Internal Linking

- [ ] Check `apps.seo.models.LinkableEntity` and `LinkSuggestion` coverage

- [ ] Verify internal linking engine suggests relevant cross-links

- [ ] Check for orphan pages (no internal links pointing to them)

### Step 8: Redirects

- [ ] Verify `apps.seo.models.Redirect` handles 301/302 redirects

- [ ] Check for redirect chains (Aâ†’Bâ†’C should be Aâ†’C)

- [ ] Verify no redirect loops

### Step 9: Report

- [ ] Categorize issues by impact: Critical, High, Medium, Low

- [ ] Provide specific fix for each finding
