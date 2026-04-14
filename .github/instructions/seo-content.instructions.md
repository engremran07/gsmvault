---
applyTo: 'apps/seo/**, apps/blog/**, apps/pages/**'
---

# SEO & Content Instructions

## SEO Engine Architecture (`apps.seo`)

The SEO engine is a full-featured, self-contained app with its own admin panel section.

### Core Models

| Model | Purpose |
|---|---|
| `Metadata` | Per-page meta tags (title, description, keywords, og:image, canonical) |
| `SchemaEntry` | JSON-LD structured data per page (BlogPosting, Product, FAQPage, etc.) |
| `SitemapEntry` | XML sitemap entries with priority, changefreq, lastmod |
| `Redirect` | 301/302 redirects with source path and target URL |
| `LinkableEntity` | Pages eligible for internal linking (URL, title, keywords) |
| `LinkSuggestion` | AI/TF-IDF suggested internal links between pages |
| `SEOSettings` | Global SEO configuration |
| `SeoAutomationSettings` | AI-powered meta generation toggles |

### 7 Admin Toggles (`SeoAutomationSettings`)

1. `auto_generate_meta_titles` — AI generates missing page titles
2. `auto_generate_meta_descriptions` — AI generates missing descriptions
3. `auto_generate_keywords` — AI extracts keywords from content
4. `auto_generate_schema` — AI creates JSON-LD structured data
5. `auto_internal_linking` — Engine suggests internal links
6. `auto_canonical_urls` — Auto-set canonical URLs
7. `auto_sitemap_update` — Auto-add new content to sitemap

## Metadata Management

Every public-facing page SHOULD have a `Metadata` record:

```python
from apps.seo.models import Metadata

# In a view or service
meta = Metadata.objects.filter(path=request.path).first()
# Template receives: meta.title, meta.description, meta.og_image, meta.canonical_url
```

Template usage:

```html
{% if meta %}
<title>{{ meta.title }}</title>
<meta name="description" content="{{ meta.description }}">
<link rel="canonical" href="{{ meta.canonical_url }}">
{% endif %}
```

## JSON-LD Structured Data

Use `SchemaEntry` for per-page structured data:

```python
schema_entry = SchemaEntry.objects.filter(page_path=request.path).first()
# schema_entry.schema_type: "BlogPosting", "Product", "FAQPage", "SoftwareApplication", etc.
# schema_entry.json_data: validated JSON-LD payload
```

Template injection:

```html
{% if schema_entry %}
<script type="application/ld+json">{{ schema_entry.json_data|safe }}</script>
{% endif %}
```

Supported schema types: `BlogPosting`, `Product`, `FAQPage`, `HowTo`, `Organization`, `WebSite`, `SoftwareApplication`, `BreadcrumbList`, `SearchAction`.

## XML Sitemaps

- Sitemaps served from `SitemapEntry` model via Django view
- XSLT stylesheet (`static/xsl/sitemap.xsl`) for human-readable rendering
- Sitemap index at `/sitemap.xml` aggregating per-content-type sitemaps
- Auto-update: new blog posts, firmware pages, forum topics added to sitemap

## Canonical URLs

- Every page MUST have a canonical URL (prevents duplicate content)
- Blog posts: canonical = full post URL
- Paginated pages: canonical = first page (not `?page=2`)
- Search results: no canonical (or self-referencing)

## Internal Linking Engine

`LinkableEntity` + `LinkSuggestion` power the internal linking engine:

1. `LinkableEntity`: registers pages with keywords they're relevant for
2. `LinkSuggestion`: AI/TF-IDF suggests links between related pages
3. Admin reviews and approves/rejects suggestions
4. Approved links injected into content via template tag or service

## Blog Post SEO

Every blog post should have:
- Meta title (≤60 chars) and description (≤160 chars)
- Open Graph tags (title, description, image, type)
- JSON-LD `BlogPosting` schema
- Canonical URL
- Internal links to related posts
- Sitemap entry with `lastmod` = post's `updated_at`

## Redirect Management

```python
from apps.seo.models import Redirect

# 301 permanent redirect (URL changed forever)
Redirect.objects.create(source_path="/old-url/", target_url="/new-url/", redirect_type=301)

# 302 temporary redirect
Redirect.objects.create(source_path="/temp/", target_url="/landing/", redirect_type=302)
```

Redirects are enforced via middleware — always check for redirect BEFORE returning 404.

## robots.txt

Dynamic `robots.txt` generated from Django view:
- Production: allow all crawlers, link to sitemap
- Staging: `Disallow: /` (block all crawlers)
- Always include: `Sitemap: https://domain.com/sitemap.xml`

## Content Pages (`apps.pages`)

Static CMS pages (about, terms, privacy, contact) use the same SEO infrastructure:
- Each page gets a `Metadata` record
- JSON-LD `WebPage` schema
- Included in sitemap with appropriate priority
