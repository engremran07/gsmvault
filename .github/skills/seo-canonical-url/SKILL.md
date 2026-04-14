---
name: seo-canonical-url
description: "Canonical URL management: deduplication, pagination, query param handling. Use when: setting canonical URLs, preventing duplicate content, managing paginated canonical chains."
---

# Canonical URL Management

## When to Use

- Setting `<link rel="canonical">` on pages to prevent duplicate content
- Handling canonical URLs for paginated lists
- Stripping tracking query parameters from canonical URLs
- Managing canonical across HTTP/HTTPS and www/non-www

## Rules

### Canonical URL in Metadata Model

```python
# apps/seo/models.py
class Metadata(TimestampedModel):
    path = models.CharField(max_length=500, unique=True, db_index=True)
    title = models.CharField(max_length=70, blank=True)
    description = models.CharField(max_length=160, blank=True)
    canonical_url = models.URLField(max_length=500, blank=True)
    no_index = models.BooleanField(default=False)
    # ...
```

### Canonical URL Resolution Service

```python
# apps/seo/services.py
from urllib.parse import urlparse, urlencode, parse_qs

STRIP_PARAMS = {"utm_source", "utm_medium", "utm_campaign", "utm_term",
                "utm_content", "fbclid", "gclid", "ref", "source"}

def resolve_canonical_url(
    request_path: str,
    query_string: str = "",
    base_url: str = "",
) -> str:
    """Resolve the canonical URL for a given path."""
    from apps.seo.models import Metadata
    # Check for explicit canonical override
    meta = Metadata.objects.filter(path=request_path).first()
    if meta and meta.canonical_url:
        return meta.canonical_url

    # Strip tracking parameters
    clean_path = _strip_tracking_params(request_path, query_string)

    # Build absolute URL
    if base_url:
        return f"{base_url.rstrip('/')}{clean_path}"
    return clean_path


def _strip_tracking_params(path: str, query_string: str) -> str:
    """Remove tracking query parameters from URL."""
    if not query_string:
        return path
    params = parse_qs(query_string)
    clean = {k: v for k, v in params.items() if k not in STRIP_PARAMS}
    if clean:
        return f"{path}?{urlencode(clean, doseq=True)}"
    return path
```

### Pagination Canonical Rules

| Page | Canonical | Rationale |
|------|-----------|-----------|
| Page 1 | `/firmwares/` (no `?page=1`) | Normalize to base URL |
| Page 2+ | `/firmwares/?page=2` | Each page has unique content |
| "View all" | `/firmwares/?page=1` (page 1) | Avoid duplicate of page 1 |

```python
def get_paginated_canonical(path: str, page: int) -> str:
    """Return canonical URL for a paginated page."""
    if page <= 1:
        return path  # Page 1 canonical = base path
    return f"{path}?page={page}"
```

### Template Tag for Canonical

```python
# apps/seo/templatetags/seo_tags.py
from django import template

register = template.Library()

@register.simple_tag(takes_context=True)
def canonical_url(context) -> str:
    """Output the canonical URL for the current page."""
    request = context.get("request")
    if not request:
        return ""
    from apps.seo.services import resolve_canonical_url
    from apps.site_settings.models import SiteSettings
    settings = SiteSettings.objects.first()
    base = f"https://{settings.domain}" if settings else ""
    return resolve_canonical_url(
        request.path,
        request.META.get("QUERY_STRING", ""),
        base_url=base,
    )
```

### Template Usage

```html
<!-- templates/base/base.html -->
{% load seo_tags %}
<link rel="canonical" href="{% canonical_url %}" />
```

### Duplicate Content Prevention Checklist

| Issue | Fix |
|-------|-----|
| HTTP + HTTPS both indexed | Force HTTPS redirect + canonical |
| www + non-www | 301 redirect to preferred + canonical |
| Trailing slash variants | APPEND_SLASH + canonical |
| Query param variations | Strip tracking params |
| Paginated duplicates | Per-page canonical |

## Anti-Patterns

- No canonical tag at all — Google guesses (often wrong)
- Canonical pointing to a 404 page — damages SEO
- All pages canonical to homepage — collapses site equity
- Canonical on noindex pages — contradictory signals

## Red Flags

- Missing `canonical_url` field in Metadata model
- Tracking params appearing in canonical URL
- Page 1 canonical includes `?page=1`
- Canonical URL is relative (not absolute)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
