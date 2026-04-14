---
name: models-meta-options
description: "Meta class options: ordering, verbose_name, unique_together, indexes, db_table. Use when: configuring model Meta, setting display names, default ordering, table names."
---

# Model Meta Options

## When to Use
- Configuring model display names for admin
- Setting default query ordering
- Defining database table names (especially for dissolved apps)
- Adding database indexes and constraints
- Setting permissions and abstract flags

## Rules
- Every model MUST have `class Meta` with: `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`
- `db_table` format: `"<app_label>_<modelname>"` (lowercase)
- Dissolved app models: `db_table = "original_app_tablename"` — preserves data
- Use `UniqueConstraint` and `Index` in `constraints`/`indexes` — NOT deprecated `unique_together`/`index_together`
- `ordering` affects ALL queries — use sparingly, prefer explicit `.order_by()` in views

## Patterns

### Complete Meta Configuration
```python
class Firmware(TimestampedModel):
    name = models.CharField(max_length=255)
    brand = models.ForeignKey("Brand", on_delete=models.CASCADE, related_name="firmwares_brand")
    version = models.CharField(max_length=50)
    is_active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return f"{self.brand} - {self.name} v{self.version}"

    class Meta:
        db_table = "firmwares_firmware"
        verbose_name = "Firmware"
        verbose_name_plural = "Firmwares"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["brand", "is_active"], name="idx_firmware_brand_active"),
            models.Index(fields=["-created_at"], name="idx_firmware_created"),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=["brand", "name", "version"],
                name="unique_firmware_brand_name_version",
            ),
        ]
```

### Dissolved App Table Preservation
```python
class CrawlerRule(TimestampedModel):
    """Migrated from dissolved apps.crawler_guard."""
    path_pattern = models.CharField(max_length=500)
    action = models.CharField(max_length=20)

    class Meta:
        db_table = "crawler_guard_crawlerrule"  # keeps existing table
        verbose_name = "Crawler Rule"
        verbose_name_plural = "Crawler Rules"
        ordering = ["path_pattern"]
```

### Abstract Model Meta
```python
class StatusMixin(models.Model):
    is_active = models.BooleanField(default=True)

    class Meta:
        abstract = True  # No table created — fields inherited by children
```

### Permissions
```python
class Firmware(TimestampedModel):
    class Meta:
        db_table = "firmwares_firmware"
        verbose_name = "Firmware"
        verbose_name_plural = "Firmwares"
        ordering = ["-created_at"]
        permissions = [
            ("can_approve_firmware", "Can approve firmware submissions"),
            ("can_export_firmware", "Can export firmware data"),
        ]
```

### Meta Options Reference

| Option | Purpose | Example |
|---|---|---|
| `db_table` | Table name | `"firmwares_firmware"` |
| `verbose_name` | Singular display | `"Firmware"` |
| `verbose_name_plural` | Plural display | `"Firmwares"` |
| `ordering` | Default ORDER BY | `["-created_at"]` |
| `indexes` | DB indexes | `[models.Index(...)]` |
| `constraints` | DB constraints | `[models.UniqueConstraint(...)]` |
| `abstract` | No table created | `True` |
| `proxy` | Same table, different behavior | `True` |
| `permissions` | Custom permissions | `[("can_X", "Can X")]` |
| `default_related_name` | FK reverse name | `"%(model_name)ss"` |
| `get_latest_by` | `.latest()` field | `"created_at"` |

## Anti-Patterns
- Missing `db_table` — Django auto-generates but explicit is better
- Missing `verbose_name` — admin shows ugly auto-generated names
- Using `unique_together` for new code — use `UniqueConstraint` instead
- Using `index_together` — deprecated, use `Index(fields=[...])` instead
- Setting heavy `ordering` on large tables — adds ORDER BY to every query
- Changing `db_table` on dissolved-app models — breaks existing data

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Model Meta](https://docs.djangoproject.com/en/5.2/ref/models/options/)
