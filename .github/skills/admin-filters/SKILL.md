---
name: admin-filters
description: "Custom admin filters: SimpleListFilter, date range filters. Use when: adding sidebar filters to admin list views, creating custom filter logic, date-based filtering."
---

# Admin Filters

## When to Use
- Adding sidebar filters to admin change lists
- Creating custom filter logic beyond basic field lookups
- Filtering by date ranges, computed values, or cross-model relationships
- Building "has/does not have" binary filters

## Rules
- Use `list_filter` with field names for simple filters (BooleanField, FK, choices)
- Subclass `SimpleListFilter` for custom logic
- ALWAYS set `title` and `parameter_name` on custom filters
- Filter querysets must be efficient — add indexes for filtered fields
- NEVER do expensive computation in `lookups()` — cache if needed

## Patterns

### Built-in Field Filters
```python
@admin.register(Firmware)
class FirmwareAdmin(admin.ModelAdmin[Firmware]):
    list_filter = (
        "is_active",          # BooleanField — Yes/No toggle
        "firmware_type",      # CharField with choices
        "brand",              # FK — dropdown of all brands
        ("created_at", admin.DateFieldListFilter),  # Date hierarchy
    )
```

### Custom SimpleListFilter
```python
from django.contrib.admin import SimpleListFilter
from django.db.models import QuerySet


class HasDownloadsFilter(SimpleListFilter):
    title = "has downloads"
    parameter_name = "has_downloads"

    def lookups(self, request: HttpRequest, model_admin: admin.ModelAdmin) -> list[tuple[str, str]]:  # type: ignore[type-arg]
        return [
            ("yes", "Has downloads"),
            ("no", "No downloads"),
        ]

    def queryset(self, request: HttpRequest, queryset: QuerySet[Firmware]) -> QuerySet[Firmware]:
        if self.value() == "yes":
            return queryset.filter(download_count__gt=0)
        if self.value() == "no":
            return queryset.filter(download_count=0)
        return queryset


@admin.register(Firmware)
class FirmwareAdmin(admin.ModelAdmin[Firmware]):
    list_filter = ("is_active", HasDownloadsFilter)
```

### Date Range Filter
```python
from datetime import timedelta
from django.utils import timezone


class RecentlyCreatedFilter(SimpleListFilter):
    title = "created"
    parameter_name = "created_range"

    def lookups(self, request: HttpRequest, model_admin: admin.ModelAdmin) -> list[tuple[str, str]]:  # type: ignore[type-arg]
        return [
            ("today", "Today"),
            ("week", "Past 7 days"),
            ("month", "Past 30 days"),
            ("quarter", "Past 90 days"),
        ]

    def queryset(self, request: HttpRequest, queryset: QuerySet) -> QuerySet:  # type: ignore[type-arg]
        now = timezone.now()
        days_map = {"today": 1, "week": 7, "month": 30, "quarter": 90}
        days = days_map.get(self.value() or "")
        if days:
            return queryset.filter(created_at__gte=now - timedelta(days=days))
        return queryset
```

### Status Filter with Counts
```python
class IngestionStatusFilter(SimpleListFilter):
    title = "ingestion status"
    parameter_name = "ingestion_status"

    def lookups(self, request: HttpRequest, model_admin: admin.ModelAdmin) -> list[tuple[str, str]]:  # type: ignore[type-arg]
        return [
            ("pending", "Pending"),
            ("approved", "Approved"),
            ("rejected", "Rejected"),
            ("processing", "Processing"),
            ("done", "Done"),
            ("failed", "Failed"),
        ]

    def queryset(self, request: HttpRequest, queryset: QuerySet[IngestionJob]) -> QuerySet[IngestionJob]:
        if self.value():
            return queryset.filter(status=self.value())
        return queryset
```

### Related Model Filter
```python
class TrustLevelFilter(SimpleListFilter):
    title = "trust level"
    parameter_name = "trust_level"

    def lookups(self, request: HttpRequest, model_admin: admin.ModelAdmin) -> list[tuple[str, str]]:  # type: ignore[type-arg]
        return [
            ("high", "High Trust (90+)"),
            ("medium", "Medium Trust (50-89)"),
            ("low", "Low Trust (<50)"),
        ]

    def queryset(self, request: HttpRequest, queryset: QuerySet[Device]) -> QuerySet[Device]:
        match self.value():
            case "high":
                return queryset.filter(trust_score__score__gte=90)
            case "medium":
                return queryset.filter(trust_score__score__gte=50, trust_score__score__lt=90)
            case "low":
                return queryset.filter(trust_score__score__lt=50)
        return queryset
```

## Anti-Patterns
- NEVER do database queries in `lookups()` that aren't cached
- NEVER create filters for fields without database indexes
- NEVER use `filter()` without returning the queryset on unrecognized values

## Red Flags
- `queryset()` method that doesn't handle `self.value() is None` (return full queryset)
- Expensive joins in filter queryset without `select_related`
- Missing `return queryset` fallthrough for unknown filter values

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/admin.py` — existing filter implementations
