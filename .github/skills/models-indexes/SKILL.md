---
name: models-indexes
description: "Database index strategies: db_index, Index, unique_together, GIN/GiST. Use when: optimizing query performance, adding composite indexes, full-text search indexes."
---

# Database Index Strategies

## When to Use
- Queries are slow on large tables (check `EXPLAIN ANALYZE`)
- Adding composite indexes for multi-column filters
- Full-text search with PostgreSQL GIN indexes
- Unique constraints with conditions (partial unique indexes)
- JSON field lookups on PostgreSQL

## Rules
- Single-column: `db_index=True` on the field definition
- Composite: `models.Index(fields=[...])` in `Meta.indexes`
- Unique: `models.UniqueConstraint(fields=[...])` in `Meta.constraints`
- GIN/GiST: use `opclasses` parameter on `models.Index`
- Index names MUST be unique across the entire database — use descriptive prefixes
- Don't over-index — each index slows down writes

## Patterns

### Single-Column Index
```python
class Firmware(TimestampedModel):
    name = models.CharField(max_length=255, db_index=True)
    slug = models.SlugField(max_length=255, unique=True)  # unique implies index
    brand = models.ForeignKey("Brand", on_delete=models.CASCADE, related_name="firmwares_brand")
    # FK fields are auto-indexed by Django
```

### Composite Index
```python
class Firmware(TimestampedModel):
    class Meta:
        indexes = [
            # Most selective column first
            models.Index(fields=["brand", "firmware_type", "is_active"], name="idx_fw_brand_type_active"),
            models.Index(fields=["-created_at", "is_active"], name="idx_fw_recent_active"),
            models.Index(fields=["brand", "-download_count"], name="idx_fw_brand_popular"),
        ]
```

### Partial Index (Conditional)
```python
class DownloadToken(TimestampedModel):
    class Meta:
        indexes = [
            # Only index active tokens — skip expired/used ones
            models.Index(
                fields=["user", "firmware"],
                condition=models.Q(status="active"),
                name="idx_active_tokens_user_fw",
            ),
        ]
```

### GIN Index for Full-Text Search
```python
from django.contrib.postgres.indexes import GinIndex
from django.contrib.postgres.search import SearchVectorField

class Firmware(TimestampedModel):
    search_vector = SearchVectorField(null=True)

    class Meta:
        indexes = [
            GinIndex(fields=["search_vector"], name="idx_fw_search_gin"),
        ]
```

### GIN Index for JSONField
```python
from django.contrib.postgres.indexes import GinIndex

class DeviceConfig(TimestampedModel):
    settings_data = models.JSONField(default=dict)

    class Meta:
        indexes = [
            GinIndex(fields=["settings_data"], name="idx_device_config_json_gin"),
        ]
```

### Unique Constraint with Condition
```python
class DownloadToken(TimestampedModel):
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "firmware"],
                condition=models.Q(status="active"),
                name="one_active_token_per_user_firmware",
            ),
        ]
```

### Index Strategy Decision Table

| Query Pattern | Index Type | Example |
|---|---|---|
| `WHERE field = X` | Single `db_index=True` | `status = "active"` |
| `WHERE a = X AND b = Y` | Composite `Index(fields=[a, b])` | Brand + type filter |
| `ORDER BY -created_at` | Descending `Index(fields=["-created_at"])` | Recent items list |
| `WHERE status = "active"` only | Partial index with `condition=` | Active tokens only |
| Full-text search | `GinIndex` on `SearchVectorField` | Search firmware names |
| JSON key lookups | `GinIndex` on `JSONField` | JSON config queries |
| `UNIQUE(a, b)` | `UniqueConstraint` | One active token per user |

### Checking Index Usage
```sql
-- Run in Django shell or psql:
EXPLAIN ANALYZE SELECT * FROM firmwares_firmware WHERE brand_id = 1 AND is_active = true;
-- Look for "Index Scan" or "Bitmap Index Scan" — NOT "Seq Scan"
```

## Anti-Patterns
- Indexing every column — too many indexes slow writes
- Composite index in wrong order — put most selective column first
- Missing index on FK fields — Django adds these, but verify
- Using `unique_together` — use `UniqueConstraint` instead
- Index names that collide across apps — prefix with app/model name
- Not checking `EXPLAIN ANALYZE` — index may not be used

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Index Reference](https://docs.djangoproject.com/en/5.2/ref/models/indexes/)
- [PostgreSQL Index Types](https://www.postgresql.org/docs/17/indexes-types.html)
