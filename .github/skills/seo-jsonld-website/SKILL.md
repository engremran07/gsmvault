---
name: seo-jsonld-website
description: "JSON-LD WebSite schema with SearchAction. Use when: adding site-wide WebSite structured data, enabling sitelinks search box in Google."
---

# JSON-LD WebSite Schema

## When to Use

- Adding WebSite schema to homepage for sitelinks search box
- Combining with SearchAction for Google site search
- Site-level structured data alongside Organization schema

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_website_schema(site_url: str, search_path: str = "/search/") -> dict:
    """Build JSON-LD WebSite with SearchAction for sitelinks search box."""
    from apps.site_settings.models import SiteSettings
    settings = SiteSettings.get_solo()
    return {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": settings.site_name or "GSMFWs",
        "url": site_url,
        "potentialAction": {
            "@type": "SearchAction",
            "target": {
                "@type": "EntryPoint",
                "urlTemplate": f"{site_url}{search_path}?q={{search_term_string}}",
            },
            "query-input": "required name=search_term_string",
        },
    }
```

### Homepage Placement

```html
{# templates/base/base.html — homepage only #}
{% if is_homepage %}
<script type="application/ld+json">{{ website_schema|safe }}</script>
<script type="application/ld+json">{{ organization_schema|safe }}</script>
{% endif %}
```

### Context Processor

```python
# apps/seo/context_processors.py
import json

def homepage_schemas(request):
    if request.path != "/":
        return {}
    from apps.seo.services import build_website_schema, build_organization_schema
    site_url = request.build_absolute_uri("/").rstrip("/")
    return {
        "is_homepage": True,
        "website_schema": json.dumps(build_website_schema(site_url)),
        "organization_schema": json.dumps(build_organization_schema(site_url)),
    }
```

### Google Requirements

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Site name |
| `url` | Yes | Homepage URL |
| `potentialAction` | Recommended | Enables sitelinks search box |
| `query-input` | Required with SearchAction | Must be `required name=search_term_string` |

## Anti-Patterns

- WebSite schema on every page — homepage only
- Missing `query-input` with SearchAction — Google ignores without it
- Search URL template that doesn't actually work — must resolve to valid search

## Red Flags

- `urlTemplate` placeholder mismatch with `query-input` name
- WebSite and Organization schemas merged — keep separate
- No actual search page at the `search_path` URL

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
