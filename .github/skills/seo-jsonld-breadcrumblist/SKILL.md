---
name: seo-jsonld-breadcrumblist
description: "JSON-LD BreadcrumbList schema. Use when: adding breadcrumb structured data, navigation path rich snippets, hierarchical page trails."
---

# JSON-LD BreadcrumbList Schema

## When to Use

- Adding breadcrumb rich snippets to all pages with navigation trails
- Matching visible `_breadcrumb.html` component with structured data
- Hierarchical navigation (Category → Subcategory → Page)

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_breadcrumb_schema(
    breadcrumbs: list[dict[str, str]],
    site_url: str,
) -> dict:
    """Build JSON-LD BreadcrumbList.
    breadcrumbs: [{'name': 'Home', 'url': '/'}, {'name': 'Blog', 'url': '/blog/'}]
    """
    return {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
            {
                "@type": "ListItem",
                "position": i + 1,
                "name": crumb["name"],
                "item": f"{site_url}{crumb['url']}" if not crumb["url"].startswith("http") else crumb["url"],
            }
            for i, crumb in enumerate(breadcrumbs)
        ],
    }
```

### View Integration

```python
# In any view with breadcrumbs
import json
from apps.seo.services import build_breadcrumb_schema

def firmware_detail(request, pk):
    firmware = get_object_or_404(Firmware, pk=pk)
    breadcrumbs = [
        {"name": "Home", "url": "/"},
        {"name": "Firmwares", "url": "/firmwares/"},
        {"name": str(firmware.model.brand), "url": f"/firmwares/?brand={firmware.model.brand.slug}"},
        {"name": str(firmware), "url": f"/firmwares/{pk}/"},
    ]
    site_url = request.build_absolute_uri("/").rstrip("/")
    context = {
        "breadcrumbs": breadcrumbs,
        "breadcrumb_schema": json.dumps(build_breadcrumb_schema(breadcrumbs, site_url)),
    }
    return render(request, "firmwares/detail.html", context)
```

### Template Pattern

```html
{# Visible breadcrumb using component #}
{% include "components/_breadcrumb.html" with items=breadcrumbs %}

{# Structured data must match visible breadcrumb #}
{% if breadcrumb_schema %}
<script type="application/ld+json">{{ breadcrumb_schema|safe }}</script>
{% endif %}
```

### Google Requirements

| Constraint | Rule |
|-----------|------|
| `position` | Sequential starting from 1 |
| `name` | Required, visible text |
| `item` | Absolute URL (except last item — optional) |
| Match visible | Schema must match visible breadcrumb |

## Anti-Patterns

- BreadcrumbList without visible breadcrumb component — must match
- Relative URLs in `item` — always absolute
- Position not sequential — must be 1, 2, 3...

## Red Flags

- Last breadcrumb item has a link to current page (should be text-only)
- Empty `name` in any breadcrumb item
- Breadcrumb trail doesn't start with Home

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
