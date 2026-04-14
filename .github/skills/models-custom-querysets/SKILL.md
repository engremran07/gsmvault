---
name: models-custom-querysets
description: "QuerySet chaining, as_manager(), annotate/aggregate patterns. Use when: building chainable query methods, complex aggregations, annotation pipelines."
---

# Custom QuerySets

## When to Use
- Building chainable `.active().recent().by_brand()` query pipelines
- Using `as_manager()` to combine QuerySet methods with Manager
- Complex annotations (`annotate`, `aggregate`, `Subquery`, `F`, `Q`)
- Reusing query logic across views and services

## Rules
- Prefer `QuerySet.as_manager()` over separate Manager + QuerySet when both are needed
- Type the QuerySet: `class MyQuerySet(models.QuerySet["MyModel"]):`
- Chainable methods return `Self` (from `typing`) or the QuerySet type
- Keep annotation logic in QuerySet class, not scattered in views
- Use `F()` expressions for database-level field references — never Python-side

## Patterns

### Custom QuerySet with as_manager()
```python
# apps/blog/managers.py
from __future__ import annotations
from typing import Self
from django.db import models
from django.utils import timezone

class PostQuerySet(models.QuerySet["Post"]):
    def published(self) -> Self:
        return self.filter(status="published", published_at__lte=timezone.now())

    def drafts(self) -> Self:
        return self.filter(status="draft")

    def by_author(self, user_id: int) -> Self:
        return self.filter(author_id=user_id)

    def with_comment_count(self) -> Self:
        return self.annotate(comment_count=models.Count("comments"))

    def popular(self, min_views: int = 100) -> Self:
        return self.filter(view_count__gte=min_views)

# In models.py:
class Post(TimestampedModel):
    objects = PostQuerySet.as_manager()
```

### Chaining in Views/Services
```python
# apps/blog/services.py
def get_trending_posts(days: int = 7) -> QuerySet[Post]:
    return (
        Post.objects
        .published()
        .with_comment_count()
        .filter(created_at__gte=timezone.now() - timedelta(days=days))
        .order_by("-comment_count", "-view_count")[:10]
    )
```

### Annotation Patterns
```python
from django.db.models import Count, Avg, Sum, F, Q, Value
from django.db.models.functions import Coalesce

class FirmwareQuerySet(models.QuerySet["Firmware"]):
    def with_download_stats(self) -> Self:
        return self.annotate(
            total_downloads=Coalesce(Count("download_sessions"), Value(0)),
            avg_file_size=Avg("file_size"),
        )

    def with_rating(self) -> Self:
        return self.annotate(
            avg_rating=Coalesce(Avg("ratings__score"), Value(0.0)),
            rating_count=Count("ratings"),
        )
```

### Subquery and OuterRef
```python
from django.db.models import Subquery, OuterRef

class DeviceQuerySet(models.QuerySet["Device"]):
    def with_latest_event(self) -> Self:
        from .models import DeviceEvent
        latest = (
            DeviceEvent.objects
            .filter(device=OuterRef("pk"))
            .order_by("-created_at")
            .values("event_type")[:1]
        )
        return self.annotate(latest_event=Subquery(latest))
```

### Aggregate in Services
```python
from django.db.models import Sum, Count

def get_download_summary(brand_id: int) -> dict[str, Any]:
    return Firmware.objects.filter(brand_id=brand_id).aggregate(
        total_files=Count("id"),
        total_size=Sum("file_size"),
        total_downloads=Sum("download_count"),
    )
```

## Anti-Patterns
- Filtering in Python instead of the database — always push filters to QuerySet
- Calling `.all()` before chaining — unnecessary, QuerySets are lazy
- N+1 queries from missing `select_related` / `prefetch_related` — add to QuerySet
- Using `len(qs)` instead of `qs.count()` — fetches all rows unnecessarily
- Evaluating QuerySets multiple times — assign to variable and reuse

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django QuerySet API](https://docs.djangoproject.com/en/5.2/ref/models/querysets/)
- [Django Aggregation](https://docs.djangoproject.com/en/5.2/topics/db/aggregation/)
