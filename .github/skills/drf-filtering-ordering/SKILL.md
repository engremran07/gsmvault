---
name: drf-filtering-ordering
description: "OrderingFilter: sortable fields, default ordering. Use when: adding sort-by query parameter to API list endpoints, configuring default sort order."
---

# DRF OrderingFilter Patterns

## When to Use
- Adding `?ordering=name` or `?ordering=-created_at` to list endpoints
- Configuring which fields clients can sort by
- Setting default sort order for API responses

## Rules
- Always whitelist sortable fields via `ordering_fields` — never allow arbitrary sorting
- Set `ordering` for default sort when no `?ordering` param is provided
- Prefix with `-` for descending (`?ordering=-created_at`)
- Combine with `SearchFilter` and `DjangoFilterBackend`

## Patterns

### Basic OrderingFilter
```python
from rest_framework import viewsets, filters

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ["created_at", "name", "file_size", "download_count"]
    ordering = ["-created_at"]  # Default sort
    # Usage: GET /api/v1/firmwares/?ordering=name
    # Usage: GET /api/v1/firmwares/?ordering=-file_size
```

### Multiple Sort Fields
```python
# Client can sort by multiple fields:
# GET /api/v1/firmwares/?ordering=-download_count,name

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ["created_at", "name", "file_size", "download_count"]
    ordering = ["-download_count", "name"]  # Default: popular first, then alpha
```

### Ordering on Related Fields
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    serializer_class = FirmwareSerializer
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ["created_at", "name", "brand__name"]
    ordering = ["-created_at"]
    # Usage: GET /api/v1/firmwares/?ordering=brand__name
```

### Combined with All Filters
```python
from django_filters.rest_framework import DjangoFilterBackend

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    serializer_class = FirmwareSerializer
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    filterset_fields = ["brand", "status"]
    search_fields = ["name", "version"]
    ordering_fields = ["created_at", "name", "file_size"]
    ordering = ["-created_at"]
    # GET /api/v1/firmwares/?brand=samsung&search=rom&ordering=-file_size
```

### Custom Ordering with Annotations
```python
from django.db.models import Count

class BrandViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = BrandSerializer
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ["name", "firmware_count"]
    ordering = ["-firmware_count"]

    def get_queryset(self):
        return Brand.objects.annotate(
            firmware_count=Count("firmwares")
        )
```

### Rename Ordering Param
```python
from rest_framework.filters import OrderingFilter

class CustomOrderingFilter(OrderingFilter):
    ordering_param = "sort_by"  # ?sort_by=-name instead of ?ordering=-name
```

### Restricting Sort Directions
```python
from rest_framework.filters import OrderingFilter

class AscendingOnlyFilter(OrderingFilter):
    """Only allow ascending sort on specific fields."""

    def remove_invalid_fields(self, queryset, fields, view, request):
        valid = super().remove_invalid_fields(queryset, fields, view, request)
        asc_only = getattr(view, "ascending_only_fields", [])
        return [
            f for f in valid
            if not (f.startswith("-") and f.lstrip("-") in asc_only)
        ]
```

## Anti-Patterns
- `ordering_fields = "__all__"` — allows sorting on any field including internal ones
- Missing `ordering_fields` whitelist → DRF allows all serializer fields
- Sorting on non-indexed columns in large tables → slow
- No default `ordering` → inconsistent result order across requests

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-filtering-search` — SearchFilter patterns
- Skill: `drf-filtering-django-filter` — structured filtering
