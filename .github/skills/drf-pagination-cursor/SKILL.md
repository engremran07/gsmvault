---
name: drf-pagination-cursor
description: "Cursor-based pagination for infinite scroll and large datasets. Use when: paginating large querysets, implementing infinite scroll APIs, avoiding offset-based performance issues."
---

# DRF Cursor-Based Pagination

## When to Use
- Paginating datasets with 10k+ records
- Infinite scroll / load-more UI pattern
- Avoiding offset pagination performance degradation on large tables
- Default pagination strategy for this platform

## Rules
- Cursor pagination is the platform default — configured in `REST_FRAMEWORK` settings
- Requires a stable, unique ordering field (usually `-created_at` or `-pk`)
- Returns `next`/`previous` cursor links — no page numbers
- Cannot jump to arbitrary pages (trade-off for O(1) performance)
- Use `ordering` attribute on the pagination class or ViewSet

## Patterns

### Global Configuration (Already Set)
```python
# app/settings.py
REST_FRAMEWORK = {
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.CursorPagination",
    "PAGE_SIZE": 20,
}
```

### Custom Cursor Paginator
```python
from rest_framework.pagination import CursorPagination

class TimelinePagination(CursorPagination):
    page_size = 20
    ordering = "-created_at"
    cursor_query_param = "cursor"
    page_size_query_param = "page_size"
    max_page_size = 100
```

### ViewSet with Custom Pagination
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    serializer_class = FirmwareSerializer
    pagination_class = TimelinePagination
```

### Response Format
```json
{
    "next": "http://api.example.com/firmwares/?cursor=cD0yMDIz...",
    "previous": null,
    "results": [
        {"id": 1, "name": "ROM_V1.2.3", "created_at": "2025-01-15T10:00:00Z"}
    ]
}
```

### Multiple Orderings per ViewSet
```python
class RecentPagination(CursorPagination):
    page_size = 10
    ordering = "-created_at"

class PopularPagination(CursorPagination):
    page_size = 10
    ordering = "-download_count"

class FirmwareViewSet(viewsets.ModelViewSet):
    def get_pagination_class(self):
        sort = self.request.query_params.get("sort", "recent")
        if sort == "popular":
            return PopularPagination
        return RecentPagination

    @property
    def pagination_class(self):
        return self.get_pagination_class()
```

### Disabling Pagination on Specific ViewSets
```python
class BrandViewSet(viewsets.ReadOnlyModelViewSet):
    """Small dataset — no pagination needed."""
    queryset = Brand.objects.filter(is_active=True)
    serializer_class = BrandSerializer
    pagination_class = None  # Override global default
```

### Client-Side Infinite Scroll (HTMX)
```html
<div id="firmware-list" hx-get="/api/v1/firmwares/" hx-trigger="revealed"
     hx-swap="afterend" hx-vals='{"cursor": "{{ next_cursor }}"}'>
</div>
```

## Anti-Patterns
- Using `LimitOffsetPagination` on large tables → `OFFSET 100000` is O(n)
- Ordering by non-indexed field → slow cursor queries
- Ordering by non-unique field without tiebreaker → duplicate/missing results
- Expecting page numbers with cursor pagination → use keyset if needed

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-pagination-keyset` — alternative keyset approach
- Skill: `views-pagination` — template-level pagination
