---
name: drf-filtering-django-filter
description: "django-filter integration: FilterSet, field lookups. Use when: adding querystring-based filtering to DRF list endpoints, creating FilterSet classes."
---

# DRF django-filter Integration

## When to Use
- Adding `?status=active&brand=samsung` style filtering to list endpoints
- Complex field lookups (range, contains, exact, in)
- Reusable filter logic across ViewSets

## Rules
- Use `django_filters.FilterSet` for reusable filter definitions
- Add `DjangoFilterBackend` to `filter_backends` on ViewSet
- Define explicit filter fields — never use `fields = "__all__"`
- Combine with `SearchFilter` and `OrderingFilter` as needed

## Patterns

### Basic FilterSet
```python
import django_filters
from .models import Firmware

class FirmwareFilter(django_filters.FilterSet):
    brand = django_filters.CharFilter(field_name="brand__slug", lookup_expr="exact")
    status = django_filters.ChoiceFilter(choices=Firmware.STATUS_CHOICES)
    min_size = django_filters.NumberFilter(field_name="file_size", lookup_expr="gte")
    max_size = django_filters.NumberFilter(field_name="file_size", lookup_expr="lte")
    created_after = django_filters.DateTimeFilter(
        field_name="created_at", lookup_expr="gte"
    )

    class Meta:
        model = Firmware
        fields = ["brand", "status", "min_size", "max_size", "created_after"]
```

### ViewSet Integration
```python
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets, filters

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    serializer_class = FirmwareSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = FirmwareFilter
    search_fields = ["name", "version"]
    ordering_fields = ["created_at", "file_size"]
```

### Shorthand (Without FilterSet Class)
```python
class BrandViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Brand.objects.all()
    serializer_class = BrandSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = {
        "name": ["exact", "icontains"],
        "country": ["exact"],
        "is_active": ["exact"],
    }
```

### Boolean Filter
```python
class DeviceFilter(django_filters.FilterSet):
    is_trusted = django_filters.BooleanFilter(field_name="trust_score", method="filter_trusted")

    class Meta:
        model = Device
        fields = ["is_trusted"]

    def filter_trusted(self, queryset, name, value):
        if value:
            return queryset.filter(trust_score__gte=80)
        return queryset.filter(trust_score__lt=80)
```

### Multiple Value Filter (IN Lookup)
```python
class FirmwareFilter(django_filters.FilterSet):
    brand_id = django_filters.BaseInFilter(
        field_name="brand_id", lookup_expr="in"
    )
    # Usage: ?brand_id=1,2,3

    class Meta:
        model = Firmware
        fields = ["brand_id"]
```

### Date Range Filter
```python
class AuditLogFilter(django_filters.FilterSet):
    date_from = django_filters.DateFilter(field_name="created_at", lookup_expr="gte")
    date_to = django_filters.DateFilter(field_name="created_at", lookup_expr="lte")

    class Meta:
        model = AuditLog
        fields = ["date_from", "date_to", "action"]
```

### Request URL Examples
```
GET /api/v1/firmwares/?brand=samsung&status=active
GET /api/v1/firmwares/?min_size=1000000&created_after=2025-01-01
GET /api/v1/firmwares/?brand_id=1,2,3
GET /api/v1/audit/?date_from=2025-06-01&date_to=2025-06-30&action=login
```

## Anti-Patterns
- `filterset_fields = "__all__"` — exposes internal fields to filtering
- Missing `DjangoFilterBackend` in `filter_backends` → filters silently ignored
- Filtering on non-indexed columns for large tables → slow queries
- Complex filter logic in ViewSet instead of FilterSet → scattered code

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-filtering-search` — SearchFilter patterns
- Skill: `drf-filtering-ordering` — OrderingFilter patterns
