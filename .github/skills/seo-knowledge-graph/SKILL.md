---
name: seo-knowledge-graph
description: "Knowledge graph: entities, relationships, structured data mapping. Use when: building entity relationships for JSON-LD, connecting brands/models/firmware for rich results."
---

# Knowledge Graph for SEO

## When to Use

- Mapping entity relationships (Brand → Model → Firmware) for structured data
- Building a knowledge graph to power JSON-LD generation
- Connecting related entities across apps for Google Knowledge Panel eligibility

## Rules

### Entity Relationship Map

```text
Organization (SiteSettings)
  └─ Brand
       └─ Model
            └─ Variant
                 └─ Firmware (SoftwareApplication)
                      ├─ VerificationReport
                      └─ DownloadToken
```

### Entity → Schema Type Mapping

| Django Model | schema.org Type | Key Properties |
|-------------|----------------|----------------|
| `SiteSettings` | `Organization` | name, url, logo, sameAs |
| `Brand` | `Brand` | name, logo, url |
| `Model` | `Product` | name, brand, model, image |
| `Firmware` | `SoftwareApplication` | name, operatingSystem, fileSize |
| `Post` (blog) | `BlogPosting` | headline, author, datePublished |
| `ForumTopic` | `DiscussionForumPosting` | headline, author, dateCreated |

### Building the Graph in Service Layer

```python
# apps/seo/services.py
def build_entity_graph(brand_slug: str) -> dict:
    """Build a knowledge graph for a brand and its models."""
    from apps.firmwares.models import Brand, Model, Firmware
    brand = Brand.objects.get(slug=brand_slug)
    graph = {
        "@context": "https://schema.org",
        "@type": "Brand",
        "name": brand.name,
        "url": brand.get_absolute_url(),
        "product": [],
    }
    for model in Model.objects.filter(brand=brand).prefetch_related("firmwares"):
        model_node = {
            "@type": "Product",
            "name": model.name,
            "brand": {"@type": "Brand", "name": brand.name},
            "offers": {
                "@type": "Offer",
                "price": "0",
                "priceCurrency": "USD",
                "availability": "https://schema.org/InStock",
            },
        }
        graph["product"].append(model_node)
    return graph
```

### Registering Entities as LinkableEntity

```python
def register_entity_for_linking(
    path: str,
    title: str,
    entity_type: str,
) -> None:
    """Register a model instance as a linkable entity."""
    from apps.seo.models import LinkableEntity
    LinkableEntity.objects.update_or_create(
        path=path,
        defaults={
            "title": title,
            "entity_type": entity_type,
            "is_linkable": True,
        },
    )
```

### Knowledge Graph Admin View

Display entity relationship trees in the admin panel for visualization. Use the `apps.admin` views infrastructure.

## Anti-Patterns

- Building the graph on every page load — cache with `DistributedCacheManager`
- Hardcoding schema.org URLs — use constants or config
- Mixing entity registration across multiple apps — centralize in `apps.seo`

## Red Flags

- No caching on graph generation — expensive query per request
- Entity types don't match schema.org vocabulary
- Missing `@context` in JSON-LD output
- Cross-app model imports in `apps/seo/models.py` — use signals or EventBus

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
