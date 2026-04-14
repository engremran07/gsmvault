---
name: drf-filtering-search
description: "SearchFilter, custom search backends, multi-field search. Use when: adding text search to API list endpoints, implementing search across multiple model fields."
---

# DRF SearchFilter Patterns

## When to Use
- Adding `?search=keyword` text search to list endpoints
- Searching across multiple model fields (name, description, tags)
- Combining search with other filters and ordering

## Rules
- `SearchFilter` searches using `icontains` by default
- Prefix search fields with `^` (startswith), `=` (exact), `@` (full-text), `$` (regex)
- For PostgreSQL full-text search, use `SearchVector`/`SearchRank` instead
- Always combine with `DjangoFilterBackend` and `OrderingFilter`

## Patterns

### Basic SearchFilter
```python
from rest_framework import viewsets, filters

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    serializer_class = FirmwareSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name", "version", "description", "brand__name"]
    # Usage: GET /api/v1/firmwares/?search=samsung
```

### Search Field Prefixes
```python
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = [
        "=username",       # exact match
        "^email",          # starts with
        "first_name",      # icontains (default)
        "last_name",       # icontains (default)
    ]
```

### Combined Filter Backends
```python
from django_filters.rest_framework import DjangoFilterBackend

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer
    filter_backends = [
        DjangoFilterBackend,     # ?brand=samsung&status=active
        filters.SearchFilter,    # ?search=keyword
        filters.OrderingFilter,  # ?ordering=-created_at
    ]
    filterset_fields = ["brand", "status"]
    search_fields = ["name", "version", "description"]
    ordering_fields = ["created_at", "name", "file_size"]
    ordering = ["-created_at"]
```

### PostgreSQL Full-Text Search Backend
```python
from rest_framework.filters import SearchFilter
from django.contrib.postgres.search import SearchVector, SearchRank, SearchQuery

class FullTextSearchFilter(SearchFilter):
    """PostgreSQL full-text search instead of icontains."""

    def filter_queryset(self, request, queryset, view):
        search_term = request.query_params.get(self.search_param, "")
        if not search_term:
            return queryset

        search_query = SearchQuery(search_term, config="english")
        search_vector = SearchVector("name", weight="A") + SearchVector(
            "description", weight="B"
        )
        return (
            queryset.annotate(
                search=search_vector,
                rank=SearchRank(search_vector, search_query),
            )
            .filter(search=search_query)
            .order_by("-rank")
        )
```

### Custom Search with Relevance
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    filter_backends = [FullTextSearchFilter, filters.OrderingFilter]
    search_fields = ["name", "description"]  # Still needed for schema docs
```

### Search Across Related Models
```python
class TopicViewSet(viewsets.ModelViewSet):
    queryset = ForumTopic.objects.select_related("author", "category").all()
    serializer_class = TopicSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = [
        "title",
        "body",
        "author__username",
        "category__name",
        "tags__name",  # M2M traversal
    ]
```

## Anti-Patterns
- Using `icontains` on millions of rows without DB index → slow queries
- `search_fields = ["__all__"]` → not supported, will error
- SearchFilter on non-text fields → unexpected results
- Missing `distinct()` when searching M2M fields → duplicate results

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-filtering-django-filter` — structured filtering
- Skill: `drf-filtering-ordering` — ordering patterns
- Skill: `services-search-fulltext` — PostgreSQL full-text search
