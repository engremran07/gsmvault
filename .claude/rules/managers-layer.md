---
paths: ["apps/*/managers.py"]
---

# Managers Layer Rules

Custom managers encapsulate common query patterns and provide a clean queryset API. Business logic belongs in services, not managers.

## Manager Definition

- Custom managers MUST inherit from `models.Manager` or extend a custom base manager.
- ALWAYS annotate return types on manager methods:
  ```python
  def active(self) -> QuerySet["MyModel"]:
      return self.get_queryset().filter(is_active=True)
  ```
- Use `TYPE_CHECKING` imports for model type annotations to avoid circular imports.
- Set `objects = MyManager()` on the model explicitly when using a custom manager.

## QuerySet Methods

- Encapsulate frequently used filters into named manager methods: `active()`, `published()`, `visible_to(user)`, `recent()`.
- Use `select_related()` and `prefetch_related()` in manager methods that are known to need related data:
  ```python
  def with_brand(self) -> QuerySet["Firmware"]:
      return self.get_queryset().select_related("brand", "model")
  ```
- Chain QuerySet methods — return `QuerySet` so callers can further filter.
- NEVER return lists or individual objects from manager methods — return QuerySets for composability.

## SoftDelete Pattern

- `SoftDeleteModel` uses a custom manager that filters out `is_deleted=True` records by default.
- The default manager (`objects`) MUST exclude soft-deleted records.
- Provide `all_with_deleted` or `include_deleted()` for admin views that need deleted records.
- NEVER override the default manager to include deleted records — add a separate manager instead.

## Boundaries

- Managers MUST NOT contain business logic — that belongs in `services.py`.
- Managers MUST NOT call external APIs, send emails, or dispatch tasks.
- Managers MUST NOT import from other apps (except `apps.core` base classes).
- Managers CAN use database annotations, aggregations, and window functions.
- Complex multi-step operations that combine queries with logic belong in services, not managers.

## Performance

- ALWAYS use `.only()` or `.defer()` in manager methods that serve list pages with many rows.
- Use `.values()` or `.values_list()` for aggregation queries that don't need full model instances.
- Avoid `.count()` after `.all()` — use the manager's queryset directly.
- Add database indexes for fields commonly used in manager filter methods.
