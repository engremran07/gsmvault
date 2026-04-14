---
name: models-advanced
description: "Advanced model patterns: custom save(), clean(), constraints, db_table, Meta. Use when: overriding save/delete, adding database constraints, configuring Meta options."
---

# Advanced Model Patterns

## When to Use
- Overriding `save()` or `delete()` with custom logic
- Adding database-level constraints (`CheckConstraint`, `UniqueConstraint`)
- Setting `db_table` for dissolved app models
- Implementing `clean()` for cross-field validation

## Rules
- Always call `super().save(*args, **kwargs)` — never skip the parent call
- Business logic belongs in `services.py`, not `save()` — only use `save()` for data normalization
- Every model: `__str__`, `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`
- Use `constraints` in Meta, not deprecated `unique_together` for new code
- Dissolved app models MUST keep `db_table = "original_app_tablename"`

## Patterns

### Custom save() — Data Normalization Only
```python
from apps.core.models import TimestampedModel

class Firmware(TimestampedModel):
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, blank=True)
    version = models.CharField(max_length=50)

    def save(self, *args: Any, **kwargs: Any) -> None:
        if not self.slug:
            self.slug = slugify(self.name)
        self.version = self.version.strip().upper()
        super().save(*args, **kwargs)

    class Meta:
        db_table = "firmwares_firmware"
        verbose_name = "Firmware"
        verbose_name_plural = "Firmwares"
        ordering = ["-created_at"]
```

### Database Constraints
```python
from django.db.models import CheckConstraint, Q, UniqueConstraint

class DownloadToken(TimestampedModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="download_tokens")
    firmware = models.ForeignKey("firmwares.Firmware", on_delete=models.CASCADE, related_name="tokens")
    expires_at = models.DateTimeField()
    max_downloads = models.PositiveIntegerField(default=1)

    class Meta:
        db_table = "download_links_downloadtoken"
        constraints = [
            CheckConstraint(check=Q(max_downloads__gte=1), name="positive_max_downloads"),
            UniqueConstraint(fields=["user", "firmware"], condition=Q(status="active"), name="one_active_token_per_user_firmware"),
        ]
```

### clean() for Cross-Field Validation
```python
from django.core.exceptions import ValidationError

class Campaign(TimestampedModel):
    start_at = models.DateTimeField()
    end_at = models.DateTimeField()
    budget = models.DecimalField(max_digits=10, decimal_places=2)

    def clean(self) -> None:
        super().clean()
        if self.end_at and self.start_at and self.end_at <= self.start_at:
            raise ValidationError({"end_at": "End date must be after start date."})
        if self.budget is not None and self.budget < 0:
            raise ValidationError({"budget": "Budget cannot be negative."})
```

### Dissolved App db_table Preservation
```python
class CrawlerRule(TimestampedModel):
    """Migrated from dissolved apps.crawler_guard."""
    path_pattern = models.CharField(max_length=500)

    class Meta:
        db_table = "crawler_guard_crawlerrule"  # preserves existing data
        verbose_name = "Crawler Rule"
```

## Anti-Patterns
- Putting business logic in `save()` — move to `services.py`
- Forgetting `super().save()` — breaks Django internals
- Using `unique_together` for new models — use `UniqueConstraint` instead
- Changing `db_table` on dissolved-app models — breaks existing data

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Model Meta options](https://docs.djangoproject.com/en/5.2/ref/models/options/)
- [Django Constraints](https://docs.djangoproject.com/en/5.2/ref/models/constraints/)
