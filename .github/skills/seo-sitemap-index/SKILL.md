---
name: seo-sitemap-index
description: "Sitemap index: multiple sitemaps, lastmod. Use when: building sitemap index files, splitting sitemaps by content type, managing multi-sitemap architecture."
---

# Sitemap Index

## When to Use

- Building a sitemap index that references multiple child sitemaps
- Splitting sitemaps by content type (blog, firmwares, pages)
- Managing lastmod across sitemap entries

## Rules

### Sitemap Index Template

```xml
{# templates/sitemap_index.xml #}
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="{% static 'xsl/sitemap-index.xsl' %}"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{% for sitemap in sitemaps %}
  <sitemap>
    <loc>{{ site_url }}{{ sitemap.url }}</loc>
    {% if sitemap.lastmod %}<lastmod>{{ sitemap.lastmod|date:"Y-m-d" }}</lastmod>{% endif %}
  </sitemap>
{% endfor %}
</sitemapindex>
```

### View Pattern

```python
# apps/seo/views.py
from django.http import HttpResponse
from django.template.loader import render_to_string

def sitemap_index(request):
    site_url = request.build_absolute_uri("/").rstrip("/")
    sitemaps = [
        {"url": "/sitemap-pages.xml", "lastmod": _get_latest_page_date()},
        {"url": "/sitemap-blog.xml", "lastmod": _get_latest_blog_date()},
        {"url": "/sitemap-firmwares.xml", "lastmod": _get_latest_firmware_date()},
        {"url": "/sitemap-forum.xml", "lastmod": _get_latest_forum_date()},
    ]
    xml = render_to_string("sitemap_index.xml", {"sitemaps": sitemaps, "site_url": site_url})
    return HttpResponse(xml, content_type="application/xml")
```

### Lastmod Helper

```python
def _get_latest_blog_date():
    from apps.blog.models import Post
    latest = Post.objects.filter(status="published").order_by("-updated_at").first()
    return latest.updated_at if latest else None
```

### Sitemap Limits

| Constraint | Limit |
|-----------|-------|
| Max URLs per sitemap | 50,000 |
| Max file size | 50 MB uncompressed |
| Max sitemaps in index | 50,000 |
| URL format | Absolute URLs only |
| Encoding | UTF-8 |

## Anti-Patterns

- All URLs in a single sitemap — split by content type at 10K+ URLs
- Missing `lastmod` — always include when data has timestamps
- Relative URLs in `<loc>` — must be absolute

## Red Flags

- Sitemap index references non-existent child sitemaps
- Content-Type not `application/xml`
- Missing XML declaration or namespace

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
