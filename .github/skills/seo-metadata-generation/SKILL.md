---
name: seo-metadata-generation
description: "Metadata generation: title, description, keywords. Use when: creating or updating page meta tags, building SEO metadata forms, generating meta from content."
---

# SEO Metadata Generation

## When to Use

- Creating `Metadata` records for new pages
- Building admin forms for SEO metadata editing
- Generating title/description from content fields

## Rules

### Metadata Model Usage

```python
# apps/seo/models.py — Metadata fields
# title: CharField(max_length=70)
# description: CharField(max_length=160)
# keywords: CharField(max_length=255, blank=True)
# canonical_url: URLField(blank=True)
# robots: CharField (index,follow | noindex,nofollow | etc.)
# og_title, og_description, og_image: Open Graph fields
```

### Title Generation Pattern

```python
# apps/seo/services.py
def generate_title(page_title: str, site_name: str = "GSMFWs") -> str:
    """Generate SEO title with site suffix. Max 60 chars."""
    separator = " — "
    max_page_len = 60 - len(separator) - len(site_name)
    truncated = page_title[:max_page_len].rstrip()
    return f"{truncated}{separator}{site_name}"
```

### Description Generation Pattern

```python
def generate_description(content: str, max_length: int = 155) -> str:
    """Extract first meaningful sentence(s) from content, strip HTML."""
    from apps.core.sanitizers import sanitize_html_content
    clean = sanitize_html_content(content)  # Strip all HTML
    # Take first 155 chars at word boundary
    if len(clean) <= max_length:
        return clean
    truncated = clean[:max_length].rsplit(" ", 1)[0]
    return f"{truncated}…"
```

### Template Output

```html
{# templates/base/base.html — meta block #}
{% block meta %}
<title>{{ seo_title|default:page_title }}</title>
<meta name="description" content="{{ seo_description|default:'' }}">
{% if seo_keywords %}<meta name="keywords" content="{{ seo_keywords }}">{% endif %}
{% if seo_canonical %}<link rel="canonical" href="{{ seo_canonical }}">{% endif %}
<meta name="robots" content="{{ seo_robots|default:'index,follow' }}">
{% endblock %}
```

### Service Layer

```python
def get_or_create_metadata(path: str, defaults: dict[str, str]) -> "Metadata":
    """Get existing metadata or create with generated defaults."""
    from apps.seo.models import Metadata
    metadata, created = Metadata.objects.get_or_create(
        path=path,
        defaults=defaults,
    )
    return metadata
```

## Anti-Patterns

- Generating meta in views — use `services.py`
- Exceeding max lengths without truncation — always enforce limits
- Duplicating title logic in templates — use context processor or service
- Using `|safe` on user-edited meta without sanitization

## Red Flags

- Title > 70 chars or description > 160 chars
- Missing canonical URL on paginated pages
- `robots: noindex` on pages that should be indexed

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
