---
paths: ["apps/*/models.py"]
---

# Database Indexes

Rules for index management on PostgreSQL 17. Proper indexing prevents slow queries at scale.

## When to Index

- Add `db_index=True` on fields frequently used in `filter()`, `exclude()`, and `order_by()`.
- Add `db_index=True` on fields used in `get()` lookups outside of PKs and unique fields.
- Foreign keys are indexed automatically by Django — NEVER add redundant `db_index=True` on FK fields.
- Boolean fields used in filters with highly skewed distribution (e.g., `is_active`) benefit from partial indexes.
- NEVER add indexes on small tables (< 1000 rows expected) — the overhead exceeds the benefit.

## Composite Indexes

- Use `class Meta: indexes = [models.Index(fields=["field1", "field2"])]` for multi-column lookups.
- Column order matters: put the most selective (highest cardinality) column first.
- A composite index on `(A, B)` serves queries on `A` alone but NOT on `B` alone.
- Name indexes explicitly: `models.Index(fields=[...], name="idx_<app>_<model>_<fields>")`.

## Unique Constraints

- Use `UniqueConstraint` (preferred) over `unique_together` (legacy).
- Conditional uniqueness: `UniqueConstraint(fields=[...], condition=Q(is_active=True), name="...")`.
- Unique constraints automatically create indexes — no need to add `db_index=True` separately.

## PostgreSQL-Specific Indexes

- Use `GinIndex` for `SearchVectorField` or `JSONField` lookups.
- Use `BTreeIndex` (default) for range queries and ordering.
- Use `HashIndex` only for exact-match lookups on large text fields.
- Use partial indexes (`condition=Q(...)`) to index only relevant rows.
- Use `opclasses=["varchar_pattern_ops"]` for `LIKE 'prefix%'` queries.

## Monitoring & Maintenance

- Monitor slow query logs for queries scanning full tables — candidate for new indexes.
- Use `EXPLAIN ANALYZE` on complex queries to verify index usage.
- Unused indexes waste write performance and storage — audit periodically with `pg_stat_user_indexes`.
- After bulk data changes, ensure `ANALYZE` runs to update statistics (Django runs this in migrations).
