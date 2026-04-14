---
name: seo-sitemap-dynamic
description: "Dynamic sitemap generation from model data. Use when: generating sitemaps from Django models, auto-including new content, queryset-based sitemap views."
---

# Dynamic Sitemap Generation

## When to Use

- Generating sitemaps directly from Django model querysets
- Auto-including newly published content in sitemaps
- Building per-model sitemap views

## Rules

### Model-Based Sitemap View

```python
# apps/seo/views.py
from django.http import HttpResponse
from django.template.loader import render_to_string

def sitemap_blog(request):
    """Dynamic sitemap for blog posts."""
    from apps.blog.models import Post
    site_url = request.build_absolute_uri("/").rstrip("/")
    posts = Post.objects.filter(status="published").only(
        "slug", "updated_at"
    ).order_by("-updated_at")
    urls = [
        {
            "loc": f"{site_url}/blog/{post.slug}/",
            "lastmod": post.updated_at.strftime("%Y-%m-%d"),
            "changefreq": "weekly",
            "priority": "0.7",
        }
        for post in posts
    ]
    xml = render_to_string("sitemap.xml", {"urls": urls})
    return HttpResponse(xml, content_type="application/xml")
```

### Sitemap XML Template

```xml
{# templates/sitemap.xml #}
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="/static/xsl/sitemap.xsl"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{% for url in urls %}
  <url>
    <loc>{{ url.loc }}</loc>
    {% if url.lastmod %}<lastmod>{{ url.lastmod }}</lastmod>{% endif %}
    {% if url.changefreq %}<changefreq>{{ url.changefreq }}</changefreq>{% endif %}
    {% if url.priority %}<priority>{{ url.priority }}</priority>{% endif %}
  </url>
{% endfor %}
</urlset>
```

### Priority Guidelines

| Content Type | Priority | Changefreq |
|-------------|----------|------------|
| Homepage | 1.0 | daily |
| Category pages | 0.8 | weekly |
| Blog posts | 0.7 | weekly |
| Firmware pages | 0.8 | monthly |
| Forum topics | 0.6 | daily |
| Static pages | 0.5 | monthly |

### Caching Pattern

```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 60)  # Cache for 1 hour
def sitemap_firmwares(request):
    # ... generate sitemap
```

### Using SitemapEntry Model

```python
def sitemap_from_entries(request, entry_type: str):
    """Generate sitemap from SitemapEntry model records."""
    from apps.seo.models import SitemapEntry
    site_url = request.build_absolute_uri("/").rstrip("/")
    entries = SitemapEntry.objects.filter(entry_type=entry_type, is_active=True)
    urls = [
        {"loc": f"{site_url}{e.path}", "lastmod": e.lastmod.strftime("%Y-%m-%d") if e.lastmod else None,
         "changefreq": e.changefreq, "priority": str(e.priority)}
        for e in entries
    ]
    xml = render_to_string("sitemap.xml", {"urls": urls})
    return HttpResponse(xml, content_type="application/xml")
```

## Anti-Patterns

- Using `.all()` without `.only()` — select only needed fields
- No caching on sitemap views — cache for at least 1 hour
- Including unpublished/draft content in sitemaps

## Red Flags

- Sitemap exceeds 50,000 URLs without pagination
- Missing `content_type="application/xml"` on response
- `lastmod` format not ISO 8601 (`YYYY-MM-DD`)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
