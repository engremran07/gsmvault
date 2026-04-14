---
name: seo-jsonld-blogposting
description: "JSON-LD BlogPosting schema. Use when: adding structured data to blog posts, creating SchemaEntry for articles, blog post rich snippets."
---

# JSON-LD BlogPosting Schema

## When to Use

- Adding structured data to `apps.blog` posts
- Creating `SchemaEntry` records for blog articles
- Enabling rich snippets in search results

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_blogposting_schema(post: "Post", site_url: str) -> dict:
    """Build JSON-LD BlogPosting for a blog post."""
    return {
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        "headline": post.title[:110],
        "description": post.excerpt[:200] if post.excerpt else "",
        "image": f"{site_url}{post.featured_image.url}" if post.featured_image else None,
        "author": {
            "@type": "Person",
            "name": post.author.get_full_name() or post.author.username,
        },
        "publisher": _build_publisher(site_url),
        "datePublished": post.published_at.isoformat() if post.published_at else None,
        "dateModified": post.updated_at.isoformat() if post.updated_at else None,
        "mainEntityOfPage": {
            "@type": "WebPage",
            "@id": f"{site_url}/blog/{post.slug}/",
        },
        "wordCount": len(post.content.split()) if post.content else 0,
    }

def _build_publisher(site_url: str) -> dict:
    """Reusable publisher object for Organization."""
    return {
        "@type": "Organization",
        "name": "GSMFWs",
        "url": site_url,
        "logo": {
            "@type": "ImageObject",
            "url": f"{site_url}/static/img/logo.png",
        },
    }
```

### SchemaEntry Creation

```python
def create_blogposting_entry(post: "Post", site_url: str) -> "SchemaEntry":
    """Create or update SchemaEntry for a blog post."""
    import json
    from apps.seo.models import SchemaEntry
    schema_data = build_blogposting_schema(post, site_url)
    entry, _ = SchemaEntry.objects.update_or_create(
        path=f"/blog/{post.slug}/",
        schema_type="BlogPosting",
        defaults={"data": json.dumps(schema_data, ensure_ascii=False)},
    )
    return entry
```

### Template Injection

```html
{# templates/blog/post_detail.html #}
{% if schema_json %}
<script type="application/ld+json">{{ schema_json|safe }}</script>
{% endif %}
```

### Required Fields (Google)

| Field | Required | Max Length |
|-------|----------|-----------|
| `headline` | Yes | 110 chars |
| `image` | Recommended | URL |
| `datePublished` | Yes | ISO 8601 |
| `author.name` | Yes | — |
| `publisher.name` | Yes | — |
| `publisher.logo` | Recommended | URL |

## Anti-Patterns

- Building schema in templates — always generate in `services.py`
- Using `|safe` on user-supplied data without pre-serializing via `json.dumps`
- Hardcoding site URL — always pass as parameter or use `SiteSettings`

## Red Flags

- `headline` exceeds 110 characters
- Missing `datePublished` on published posts
- `image` URL is relative instead of absolute

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
