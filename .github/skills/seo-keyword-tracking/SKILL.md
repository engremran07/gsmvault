---
name: seo-keyword-tracking
description: "Keyword position tracking and reporting. Use when: tracking keyword rankings, storing SERP positions, building keyword dashboards, monitoring SEO progress."
---

# Keyword Position Tracking

## When to Use

- Tracking keyword rankings over time
- Storing SERP position snapshots
- Building keyword performance dashboards in admin
- Monitoring SEO campaign progress

## Rules

### Keyword Tracking Models

```python
# apps/seo/models.py
class TrackedKeyword(TimestampedModel):
    keyword = models.CharField(max_length=300)
    target_url = models.CharField(max_length=500)
    search_engine = models.CharField(
        max_length=20, default="google",
        choices=[("google", "Google"), ("bing", "Bing"), ("yandex", "Yandex")],
    )
    is_active = models.BooleanField(default=True)
    priority = models.PositiveSmallIntegerField(default=5)  # 1=highest

    class Meta:
        db_table = "seo_trackedkeyword"
        unique_together = ["keyword", "target_url", "search_engine"]
        ordering = ["priority", "keyword"]
        verbose_name = "Tracked Keyword"
        verbose_name_plural = "Tracked Keywords"

    def __str__(self) -> str:
        return f"{self.keyword} → {self.target_url}"


class KeywordPosition(TimestampedModel):
    keyword = models.ForeignKey(
        TrackedKeyword, on_delete=models.CASCADE,
        related_name="positions",
    )
    position = models.PositiveSmallIntegerField()  # 1-100
    checked_at = models.DateTimeField()
    previous_position = models.PositiveSmallIntegerField(null=True, blank=True)

    class Meta:
        db_table = "seo_keywordposition"
        ordering = ["-checked_at"]
        verbose_name = "Keyword Position"
        verbose_name_plural = "Keyword Positions"
        indexes = [
            models.Index(fields=["keyword", "-checked_at"]),
        ]

    def __str__(self) -> str:
        return f"{self.keyword.keyword}: #{self.position}"

    @property
    def change(self) -> int | None:
        if self.previous_position is None:
            return None
        return self.previous_position - self.position  # positive = improved
```

### Position Check Service

```python
# apps/seo/services.py
def record_keyword_position(
    keyword_id: int,
    position: int,
    checked_at: datetime | None = None,
) -> None:
    """Record a new position snapshot for a tracked keyword."""
    from apps.seo.models import TrackedKeyword, KeywordPosition
    from django.utils import timezone

    keyword = TrackedKeyword.objects.get(pk=keyword_id)
    last = keyword.positions.first()  # type: ignore[attr-defined]
    KeywordPosition.objects.create(
        keyword=keyword,
        position=position,
        checked_at=checked_at or timezone.now(),
        previous_position=last.position if last else None,
    )
```

### Dashboard Aggregation

| Metric | Query |
|--------|-------|
| Average position | `positions.aggregate(Avg("position"))` |
| Position trend (7d) | Last 7 snapshots ordered by `checked_at` |
| Top movers (improved) | Filter `change > 0`, order by `change DESC` |
| Top losers (dropped) | Filter `change < 0`, order by `change ASC` |

## Anti-Patterns

- Querying SERP APIs without rate limiting — get blocked fast
- Storing raw SERP HTML — wastes storage, only store position integer
- No deduplication of daily checks — one check per keyword per day max

## Red Flags

- Missing index on `(keyword, -checked_at)` — slow trend queries
- No `previous_position` tracking — can't calculate movement
- Position checks in sync views — must be Celery tasks
- `TrackedKeyword` without `is_active` flag — no way to pause tracking

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
