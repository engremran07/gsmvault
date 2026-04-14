---
paths: ["apps/*/models.py"]
---

# Django Model Rules

These rules are enforced on every `models.py` file in the `apps/` directory.

## Required on Every Model

Every model class MUST have:

1. **`__str__` method** — returns a human-readable string identifying the instance.
2. **`class Meta`** with ALL four of:
   - `verbose_name` (singular, lowercase, no leading uppercase)
   - `verbose_name_plural` (plural form)
   - `ordering` (list, at least one field, prefer `-created_at` or `-id`)
   - `db_table` (explicit table name, snake_case matching app+model convention)
3. **`related_name`** on EVERY `ForeignKey` and `ManyToManyField`.
   - Pattern: `"<appname>_<descriptive_name>"` or descriptive unique name.
   - Never use `related_name="+"` unless you explicitly do not need reverse access.

## Base Model Inheritance

- Use `TimestampedModel` (from `apps.core.models`) as the base for models needing `created_at`/`updated_at`.
- Use `SoftDeleteModel` for models that should be soft-deleteable.
- Use `AuditFieldsModel` for models that track `created_by`/`updated_by` user FKs.
- Import: `from apps.core.models import TimestampedModel, SoftDeleteModel, AuditFieldsModel`

## App Config

- Every app's `apps.py` must set `default_auto_field = "django.db.models.BigAutoField"`.

## Wallet / Financial Models

- ALWAYS use `select_for_update()` when reading a wallet or credit balance for update.
- Wrap wallet operations in `@transaction.atomic`.
- Never subtract from a balance without a lock: `Wallet.objects.select_for_update().get(user=user)`.

## Dissolved App Table Names

- Models absorbed from dissolved apps MUST keep `db_table = "original_app_tablename"` in Meta.
- Example: a model moved from `crawler_guard` app keeps `db_table = "crawler_guard_crawlerrule"`.
- NEVER change `db_table` on a model that already has data without a data migration.

## Cross-App FK References

- For FK to `User`, always use `settings.AUTH_USER_MODEL` (not a direct import):
  ```python
  from django.conf import settings
  user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="myapp_things")
  ```
- NEVER import another app's model inside `models.py` (except `apps.core`, `apps.site_settings`, and `settings.AUTH_USER_MODEL`).

## Pyright / Type Safety

- Django reverse FK managers are not resolved by Pyright → add `# type: ignore[attr-defined]` with a comment.
- `QuerySet.first()` returns `Model | None` — annotate helper parameters accordingly.
- Never bare `# type: ignore` — always specify: `# type: ignore[attr-defined]`.
