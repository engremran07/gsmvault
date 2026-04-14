---
paths: ["apps/*/services*.py", "apps/*/views.py", "apps/*/managers.py"]
---

# QuerySet Optimization

Rules for efficient database queries. PostgreSQL 17 is the database backend.

## Related Object Loading

- ALWAYS use `select_related()` when accessing FK fields in templates or serializers.
- ALWAYS use `prefetch_related()` for reverse FK, M2M, and `GenericRelation` access.
- If looping over a queryset and accessing `.related_field` → you need `select_related` or `prefetch_related`.
- Chain both when needed: `Model.objects.select_related("fk").prefetch_related("m2m")`.
- Use `Prefetch()` objects for filtered or annotated prefetches.

## Projection & Aggregation

- Use `only("field1", "field2")` for read-heavy code paths that don't need the full model.
- Use `defer("large_field")` to skip loading large text/binary columns.
- Use `values()` / `values_list()` for aggregation, export, or API responses not needing model instances.
- Use `values_list("field", flat=True)` for single-column lists.
- NEVER load full model instances just to extract one field.

## Existence & Counting

- Use `queryset.exists()` instead of `queryset.count() > 0` — stops at first match.
- Use `queryset.count()` instead of `len(queryset)` — uses SQL `COUNT(*)`, avoids loading objects.
- Use `Exists(subquery)` in annotations instead of Python-level filtering.
- Use `Subquery()` for correlated lookups instead of N+1 Python loops.

## Pagination & Limiting

- NEVER use `Model.objects.all()` unbounded in views — always paginate or slice.
- Use Django's `Paginator` or DRF pagination classes for list endpoints.
- Use cursor-based pagination for large, frequently-updated datasets.
- Use `[:limit]` slicing for "top N" queries — translates to SQL `LIMIT`.

## Bulk Operations

- Use `bulk_create()` for inserting multiple objects — one query instead of N.
- Use `bulk_update(objs, fields=["field1"])` for batch updates.
- Use `update()` on querysets for mass field changes without loading objects.
- Use `delete()` on querysets for mass deletion without loading objects.
- Set `batch_size` on `bulk_create()` for very large inserts (1000+ rows).

## Anti-Patterns to Avoid

- NEVER call `.save()` inside a loop when `bulk_update()` would work.
- NEVER use `get()` inside a loop — collect PKs first, then `filter(pk__in=pks)`.
- NEVER chain `.filter()` in Python when the ORM can express it in SQL.
- NEVER use `order_by("?")` on large tables — use `tablesample` or pre-randomized IDs instead.
- Watch for implicit queries in `__str__` methods that access related objects.
