---
name: views-search
description: "Search implementation: icontains, SearchVector, full-text search. Use when: adding search to list views, PostgreSQL full-text search, search ranking."
---

# Search Implementation

## When to Use
- Adding search input to list views
- Simple `icontains` text matching
- PostgreSQL full-text search with ranking
- HTMX live search (search-as-you-type)

## Rules
- Simple search: `icontains` for basic substring matching
- Full-text search: use `SearchVector` + `SearchQuery` + `SearchRank` (PostgreSQL)
- Always sanitize search input — strip whitespace, limit length
- Minimum query length: 2 characters to prevent expensive single-char queries
- Search views should support both HTMX fragment and full-page rendering

## Patterns

### Simple icontains Search
```python
@require_GET
def firmware_search(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "").strip()[:200]  # Limit length
    results = Firmware.objects.none()

    if len(query) >= 2:
        results = (
            Firmware.objects
            .filter(
                models.Q(name__icontains=query) |
                models.Q(brand__name__icontains=query) |
                models.Q(description__icontains=query),
                is_active=True,
            )
            .select_related("brand")
            .distinct()[:50]
        )

    context = {"results": results, "query": query}

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/search_results.html", context)
    return render(request, "firmwares/search.html", context)
```

### PostgreSQL Full-Text Search
```python
from django.contrib.postgres.search import (
    SearchVector, SearchQuery, SearchRank, TrigramSimilarity,
)

def search_firmwares_fulltext(query: str) -> QuerySet[Firmware]:
    """Full-text search with ranking — PostgreSQL only."""
    if len(query) < 2:
        return Firmware.objects.none()

    search_vector = SearchVector("name", weight="A") + SearchVector("description", weight="B")
    search_query = SearchQuery(query)

    return (
        Firmware.objects
        .filter(is_active=True)
        .annotate(
            search=search_vector,
            rank=SearchRank(search_vector, search_query),
        )
        .filter(search=search_query)
        .order_by("-rank")
    )
```

### Trigram Similarity Search (Fuzzy)
```python
from django.contrib.postgres.search import TrigramSimilarity

def search_brands_fuzzy(query: str) -> QuerySet[Brand]:
    """Fuzzy search — finds 'Samsng' when searching 'Samsung'."""
    return (
        Brand.objects
        .annotate(similarity=TrigramSimilarity("name", query))
        .filter(similarity__gt=0.3)
        .order_by("-similarity")
    )
```

### Search Service Pattern
```python
# apps/firmwares/services.py
def search_firmwares(query: str, *, limit: int = 50) -> QuerySet[Firmware]:
    """Unified search with fallback: full-text → icontains."""
    query = query.strip()[:200]
    if len(query) < 2:
        return Firmware.objects.none()

    # Try full-text first
    results = search_firmwares_fulltext(query)
    if results.exists():
        return results[:limit]

    # Fallback to icontains
    return (
        Firmware.objects
        .filter(
            models.Q(name__icontains=query) | models.Q(brand__name__icontains=query),
            is_active=True,
        )
        .select_related("brand")[:limit]
    )
```

### HTMX Live Search Template
```html
<!-- Search input with debounce -->
<input type="search"
       name="q"
       placeholder="Search firmwares..."
       hx-get="{% url 'firmwares:search' %}"
       hx-trigger="input changed delay:300ms, search"
       hx-target="#search-results"
       hx-swap="innerHTML"
       hx-indicator="#search-spinner"
       value="{{ query }}" />

<div id="search-spinner" class="htmx-indicator">
    {% include "components/_loading.html" %}
</div>
<div id="search-results">
    {% include "firmwares/fragments/search_results.html" %}
</div>
```

### SearchVector Field (Precomputed)
```python
from django.contrib.postgres.search import SearchVectorField

class Firmware(TimestampedModel):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, default="")
    search_vector = SearchVectorField(null=True, blank=True)

    class Meta:
        indexes = [
            GinIndex(fields=["search_vector"], name="idx_fw_search"),
        ]

# Update vector on save (via signal or service):
from django.contrib.postgres.search import SearchVector

Firmware.objects.filter(pk=firmware.pk).update(
    search_vector=SearchVector("name", weight="A") + SearchVector("description", weight="B")
)
```

## Anti-Patterns
- Not limiting query length — user could send megabytes of search text
- Single-character searches — too expensive, enforce minimum 2 chars
- No `distinct()` on multi-field search — duplicate results
- Searching without `select_related` — N+1 on results display
- Not sanitizing search input — strip whitespace, enforce limits

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Full-Text Search](https://docs.djangoproject.com/en/5.2/ref/contrib/postgres/search/)
- [PostgreSQL Trigram Extension](https://www.postgresql.org/docs/17/pgtrgm.html)
