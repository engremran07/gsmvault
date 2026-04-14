---
name: models-abstract-bases
description: "Abstract base classes: TimestampedModel, SoftDeleteModel, AuditFieldsModel. Use when: creating new models, choosing base class, understanding the model hierarchy."
---

# Abstract Base Models

## When to Use
- Creating any new model in the project
- Choosing between `TimestampedModel`, `SoftDeleteModel`, `AuditFieldsModel`
- Understanding what fields are inherited from base classes

## Rules
- ALL models MUST inherit from `TimestampedModel` at minimum — never bare `models.Model`
- Import from `apps.core.models` (the re-export shim), NOT `apps.site_settings.models`
- `SoftDeleteModel` for content that users may want to restore
- `AuditFieldsModel` for admin-managed records needing `created_by` / `updated_by` tracking
- Never re-implement `created_at` / `updated_at` — they come from `TimestampedModel`

## Patterns

### TimestampedModel — Default Base
```python
from apps.core.models import TimestampedModel

class Brand(TimestampedModel):
    """Every model inherits created_at and updated_at automatically."""
    name = models.CharField(max_length=255, unique=True)
    slug = models.SlugField(max_length=255, unique=True)
    logo = models.ImageField(upload_to="brands/", blank=True)

    def __str__(self) -> str:
        return self.name

    class Meta:
        db_table = "firmwares_brand"
        verbose_name = "Brand"
        verbose_name_plural = "Brands"
        ordering = ["name"]
```

### SoftDeleteModel — Recoverable Deletion
```python
from apps.core.models import SoftDeleteModel

class ForumTopic(SoftDeleteModel):
    """Adds is_deleted, deleted_at fields. Use .objects for active, .all_objects for everything."""
    title = models.CharField(max_length=300)
    category = models.ForeignKey("ForumCategory", on_delete=models.CASCADE, related_name="forum_topics")

    def __str__(self) -> str:
        return self.title

    class Meta:
        db_table = "forum_forumtopic"
        ordering = ["-created_at"]
```

### AuditFieldsModel — Admin Tracking
```python
from apps.core.models import AuditFieldsModel

class BlogPost(AuditFieldsModel):
    """Adds created_by, updated_by FKs tracking who made changes."""
    title = models.CharField(max_length=300)
    content = models.TextField()
    status = models.CharField(max_length=20, choices=[("draft", "Draft"), ("published", "Published")])

    def __str__(self) -> str:
        return self.title

    class Meta:
        db_table = "blog_blogpost"
        ordering = ["-created_at"]
```

### Choosing the Right Base

| Base Class | Use For | Extra Fields |
|---|---|---|
| `TimestampedModel` | Default for all models | `created_at`, `updated_at` |
| `SoftDeleteModel` | User-generated content, forum posts | + `is_deleted`, `deleted_at` |
| `AuditFieldsModel` | Admin-managed records | + `created_by`, `updated_by` |

### Combining with Mixins
```python
from apps.core.models import TimestampedModel

class StatusMixin(models.Model):
    """Reusable mixin — NOT a standalone model."""
    is_active = models.BooleanField(default=True)
    status = models.CharField(max_length=20, default="draft")

    class Meta:
        abstract = True

class Product(StatusMixin, TimestampedModel):
    name = models.CharField(max_length=255)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        db_table = "shop_product"
```

## Anti-Patterns
- Inheriting from bare `models.Model` — always use `TimestampedModel`
- Importing base models from `apps.site_settings.models` directly — use `apps.core.models`
- Re-defining `created_at` / `updated_at` on a model — already inherited
- Making abstract base classes non-abstract (missing `abstract = True` in Meta)

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/core/models.py` — re-export shim
- `apps/site_settings/models.py` — actual base class definitions
