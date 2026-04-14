---
applyTo: 'apps/*/models.py'
---

# Django Model Conventions

## Base Classes

All models must inherit from `TimestampedModel` (provides `created_at`, `updated_at`):

```python
from apps.core.models import TimestampedModel

class MyModel(TimestampedModel):
    ...
```

For soft-deletable models, use `SoftDeleteModel`. For audit tracking, use `AuditFieldsModel`.
All three are re-exported from `apps.core.models` (originally defined in `apps.site_settings`).

## Required Meta Class

Every model MUST have a complete `class Meta`:

```python
class Meta:
    verbose_name = "Firmware File"
    verbose_name_plural = "Firmware Files"
    ordering = ["-created_at"]
    db_table = "firmwares_firmwarefile"
    default_auto_field = "django.db.models.BigAutoField"
```

## Required `__str__`

Every model MUST define `__str__`:

```python
def __str__(self) -> str:
    return self.name
```

## Foreign Keys and M2M

Every FK and M2M field MUST have a `related_name`:

```python
user = models.ForeignKey(
    settings.AUTH_USER_MODEL,
    on_delete=models.CASCADE,
    related_name="firmwares_uploads",
)
tags = models.ManyToManyField("tags.Tag", related_name="firmwares_tagged", blank=True)
```

Pattern: `"<appname>_<descriptive_name>"` or a unique descriptive name.

## Dissolved App Models

Models migrated from dissolved apps MUST keep their original table name:

```python
class Meta:
    db_table = "crawler_guard_crawlerrule"  # Preserves existing data
```

Never reference dissolved app names in imports — import from the target app only.

## App Boundary Rules — STRICT

Models MUST NOT import from other apps except:
- `apps.core.*` — infrastructure layer (always allowed)
- `apps.site_settings.*` — global config (always allowed)
- `settings.AUTH_USER_MODEL` — user FK reference (always allowed)

For cross-app references, use `settings.AUTH_USER_MODEL` string reference or abstract bases.
For cross-app communication, use `apps.core.events.EventBus` or Django signals.

## No Raw SQL

Django ORM exclusively. Never use `connection.cursor()`, `raw()`, or `extra()`.
Parameterized queries are enforced by the ORM — never format user data into query strings.

## Type Hints

Full type hints on all public methods:

```python
def get_download_url(self) -> str:
    return reverse("firmwares:download", kwargs={"pk": self.pk})

@classmethod
def get_active(cls) -> QuerySet["MyModel"]:
    return cls.objects.filter(is_active=True)
```

## Field Conventions

- Use `BigAutoField` for primary keys (set via `default_auto_field`)
- Use `TextField` for unbounded text, `CharField(max_length=N)` for bounded
- Use `DecimalField` for monetary values, never `FloatField`
- Use `JSONField` for structured data (PostgreSQL native)
- Always set `help_text` on non-obvious fields
- Always set `blank=True` and/or `null=True` explicitly when needed

## Database Indexes

Add indexes for frequently queried fields:

```python
class Meta:
    indexes = [
        models.Index(fields=["status", "created_at"]),
        models.Index(fields=["user", "is_active"]),
    ]
```

## Financial Records

Always use `select_for_update()` on wallet/credit mutations — enforced in service layer.
