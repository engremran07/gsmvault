---
name: services-search-fulltext
description: "Full-text search: SearchVector, SearchQuery, SearchRank. Use when: implementing search, PostgreSQL full-text search, search ranking, search autocomplete."
---

# Full-Text Search Patterns

## When to Use
- Implementing search across firmware names, descriptions, forum topics
- PostgreSQL full-text search with ranking
- Search autocomplete / typeahead
- Multi-field weighted search

## Rules
- Use PostgreSQL native full-text search — no external search engine needed
- `SearchVector` for indexing, `SearchQuery` for user input, `SearchRank` for ordering
- Weight fields: A (most relevant) → D (least relevant)
- Use `GinIndex` on `SearchVectorField` for performance
- Always sanitize search input before building `SearchQuery`
- Use `websearch` search type for natural language queries

## Patterns

### Basic Full-Text Search
```python
from django.contrib.postgres.search import SearchVector, SearchQuery, SearchRank
from django.db.models import QuerySet
from .models import Firmware

def search_firmwares(*, query: str) -> QuerySet[Firmware]:
    """Full-text search across firmware fields."""
    if not query.strip():
        return Firmware.objects.none()
    search_vector = SearchVector("name", weight="A") + SearchVector("description", weight="B")
    search_query = SearchQuery(query, search_type="websearch")
    return (
        Firmware.objects
        .annotate(rank=SearchRank(search_vector, search_query))
        .filter(rank__gte=0.1, is_active=True)
        .order_by("-rank")
    )
```

### Stored SearchVectorField for Performance
```python
# models.py
from django.contrib.postgres.search import SearchVectorField
from django.contrib.postgres.indexes import GinIndex

class Firmware(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    search_vector = SearchVectorField(null=True)

    class Meta:
        indexes = [GinIndex(fields=["search_vector"])]
```

```python
# services.py — update search vector on save
from django.contrib.postgres.search import SearchVector

def update_search_vector(*, firmware_id: int) -> None:
    Firmware.objects.filter(pk=firmware_id).update(
        search_vector=SearchVector("name", weight="A")
        + SearchVector("description", weight="B")
    )
```

### Multi-Model Search
```python
from itertools import chain

def global_search(*, query: str, limit: int = 20) -> dict:
    """Search across multiple content types."""
    search_query = SearchQuery(query, search_type="websearch")
    firmwares = (
        Firmware.objects
        .annotate(rank=SearchRank(SearchVector("name"), search_query))
        .filter(rank__gte=0.1)[:limit]
    )
    topics = (
        ForumTopic.objects
        .annotate(rank=SearchRank(SearchVector("title", "body"), search_query))
        .filter(rank__gte=0.1)[:limit]
    )
    return {"firmwares": firmwares, "topics": topics}
```

### Trigram Similarity for Fuzzy Search
```python
from django.contrib.postgres.search import TrigramSimilarity

def fuzzy_search_brands(*, query: str) -> QuerySet:
    """Fuzzy search for brand names (handles typos)."""
    return (
        Brand.objects
        .annotate(similarity=TrigramSimilarity("name", query))
        .filter(similarity__gt=0.3)
        .order_by("-similarity")
    )
```

### Search Autocomplete
```python
def autocomplete_firmware(*, query: str, limit: int = 10) -> list[dict]:
    """Fast autocomplete for firmware names."""
    return list(
        Firmware.objects
        .filter(name__icontains=query, is_active=True)
        .values("pk", "name")
        .order_by("name")[:limit]
    )
```

## Anti-Patterns
- Using `__icontains` for complex search — no ranking, no stemming
- Building `SearchQuery` from unsanitized user input
- Missing `GinIndex` on `SearchVectorField` — full table scan
- Searching without minimum rank threshold — too many irrelevant results

## Red Flags
- Full-text search without `SearchRank` ordering — unranked results
- `SearchVector` built on every query instead of stored `SearchVectorField`
- No `pg_trgm` extension for trigram search → `CREATE EXTENSION pg_trgm`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
