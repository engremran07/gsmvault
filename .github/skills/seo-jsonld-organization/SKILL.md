---
name: seo-jsonld-organization
description: "JSON-LD Organization schema. Use when: adding site-wide organization structured data, homepage schema, knowledge panel data."
---

# JSON-LD Organization Schema

## When to Use

- Adding site-wide Organization schema (homepage)
- Building knowledge panel data for Google
- Linking social profiles to organization entity

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_organization_schema(site_url: str) -> dict:
    """Build JSON-LD Organization for the site. Use on homepage."""
    from apps.site_settings.models import SiteSettings
    settings = SiteSettings.get_solo()
    schema: dict = {
        "@context": "https://schema.org",
        "@type": "Organization",
        "name": settings.site_name or "GSMFWs",
        "url": site_url,
        "description": settings.site_description or "",
    }
    if settings.logo:
        schema["logo"] = {
            "@type": "ImageObject",
            "url": f"{site_url}{settings.logo.url}",
        }
    # Social profiles
    social_links = _get_social_links(settings)
    if social_links:
        schema["sameAs"] = social_links
    # Contact
    if settings.contact_email:
        schema["contactPoint"] = {
            "@type": "ContactPoint",
            "email": settings.contact_email,
            "contactType": "customer support",
        }
    return schema

def _get_social_links(settings: "SiteSettings") -> list[str]:
    """Extract non-empty social links from SiteSettings."""
    links = []
    for field in ("twitter_url", "facebook_url", "youtube_url", "github_url", "telegram_url"):
        url = getattr(settings, field, "")
        if url:
            links.append(url)
    return links
```

### Placement

```html
{# templates/base/base.html — only on homepage #}
{% if is_homepage and organization_schema %}
<script type="application/ld+json">{{ organization_schema|safe }}</script>
{% endif %}
```

### Context Processor Pattern

```python
# apps/seo/context_processors.py
def seo_schemas(request):
    """Add organization schema to homepage context."""
    if request.path == "/":
        from apps.seo.services import build_organization_schema
        site_url = request.build_absolute_uri("/").rstrip("/")
        return {"organization_schema": json.dumps(build_organization_schema(site_url))}
    return {}
```

### Required Fields

| Field | Required | Source |
|-------|----------|--------|
| `name` | Yes | `SiteSettings.site_name` |
| `url` | Yes | Site URL |
| `logo` | Recommended | `SiteSettings.logo` |
| `sameAs` | Recommended | Social URLs |
| `contactPoint` | Optional | Contact email |

## Anti-Patterns

- Organization schema on every page — only homepage
- Hardcoding organization data — always read from `SiteSettings`
- Missing `sameAs` when social links exist in settings

## Red Flags

- Multiple Organization schemas on same page
- Logo URL is relative instead of absolute
- Social links contain empty strings in `sameAs` array

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
