---
name: drf-pagination-keyset
description: "Keyset pagination as alternative to offset for ordered results. Use when: need stable page-based navigation with deterministic ordering, alternative to cursor when page numbers are needed."
---

# DRF Keyset Pagination

## When to Use
- Need page-number-like navigation but efficient on large datasets
- Results must be deterministically ordered (no shifting pages)
- Alternative to cursor when clients need `?after=<id>` style

## Rules
- Keyset pagination uses a filter (`WHERE id > last_seen_id`) instead of `OFFSET`
- Requires a unique, indexed ordering column (usually `pk` or `created_at` + `pk`)
- O(1) performance regardless of page depth
- Custom implementation — DRF doesn't include keyset natively

## Patterns

### Custom Keyset Paginator
```python
from rest_framework.pagination import BasePagination
from rest_framework.response import Response
from rest_framework.request import Request
from django.db.models import QuerySet
from collections import OrderedDict

class KeysetPagination(BasePagination):
    page_size = 20
    cursor_field = "id"
    max_page_size = 100

    def paginate_queryset(
        self, queryset: QuerySet, request: Request, view=None
    ) -> list:
        self.request = request
        page_size = min(
            int(request.query_params.get("page_size", self.page_size)),
            self.max_page_size,
        )
        after = request.query_params.get("after")

        if after is not None:
            queryset = queryset.filter(**{f"{self.cursor_field}__gt": after})

        results = list(queryset.order_by(self.cursor_field)[:page_size + 1])
        self.has_next = len(results) > page_size
        results = results[:page_size]
        self.last_id = getattr(results[-1], self.cursor_field) if results else None
        return results

    def get_paginated_response(self, data: list) -> Response:
        return Response(OrderedDict([
            ("next_after", self.last_id if self.has_next else None),
            ("has_next", self.has_next),
            ("results", data),
        ]))
```

### ViewSet Usage
```python
class FirmwareViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    serializer_class = FirmwareSerializer
    pagination_class = KeysetPagination
```

### Response Format
```json
{
    "next_after": 145,
    "has_next": true,
    "results": [
        {"id": 126, "name": "ROM_V1"},
        {"id": 145, "name": "ROM_V2"}
    ]
}
```

### Client Request Pattern
```
GET /api/v1/firmwares/                    # First page
GET /api/v1/firmwares/?after=145          # Next page
GET /api/v1/firmwares/?after=145&page_size=50  # Custom size
```

### Composite Keyset (Timestamp + ID)
```python
class TimestampKeysetPagination(BasePagination):
    """For ordered-by-time results with stable pagination."""
    page_size = 20

    def paginate_queryset(self, queryset, request, view=None):
        self.request = request
        after_ts = request.query_params.get("after_ts")
        after_id = request.query_params.get("after_id")

        if after_ts and after_id:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(created_at__lt=after_ts)
                | Q(created_at=after_ts, id__lt=int(after_id))
            )

        results = list(
            queryset.order_by("-created_at", "-id")[: self.page_size + 1]
        )
        self.has_next = len(results) > self.page_size
        results = results[: self.page_size]
        if results:
            last = results[-1]
            self.last_ts = last.created_at.isoformat()
            self.last_id = last.id
        else:
            self.last_ts = self.last_id = None
        return results

    def get_paginated_response(self, data):
        return Response(OrderedDict([
            ("next_after_ts", self.last_ts if self.has_next else None),
            ("next_after_id", self.last_id if self.has_next else None),
            ("has_next", self.has_next),
            ("results", data),
        ]))
```

## Anti-Patterns
- Using offset pagination (`OFFSET 50000`) on large tables → O(n) query
- Keyset on non-indexed column → defeats the purpose
- Non-unique keyset field without tiebreaker → missing/duplicate rows
- Allowing negative or zero `page_size` → add `min(max(size, 1), max_page_size)`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-pagination-cursor` — DRF built-in cursor pagination
