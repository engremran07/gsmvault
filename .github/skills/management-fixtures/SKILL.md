---
name: management-fixtures
description: "Fixture management: dumpdata, loaddata, natural keys. Use when: exporting/importing test data, creating fixtures, seeding databases with JSON data."
---

# Fixture Management

## When to Use
- Creating reproducible test data as JSON fixtures
- Seeding a fresh database with initial data
- Exporting model data for backup or migration
- Sharing test datasets between developers

## Rules
- Fixtures live in `apps/<app>/fixtures/<name>.json`
- Use `natural_key()` for models with unique fields to avoid PK conflicts
- NEVER include user passwords in fixtures — use `set_password()` in seed commands
- Fixtures are for initial/reference data — NOT for large datasets
- Use `--indent 2` for readable JSON
- Prefer seed management commands over fixtures for complex data

## Patterns

### Dumping Data
```powershell
# Dump specific model
& .\.venv\Scripts\python.exe manage.py dumpdata firmwares.Brand --indent 2 --settings=app.settings_dev > apps/firmwares/fixtures/brands.json

# Dump app with natural keys
& .\.venv\Scripts\python.exe manage.py dumpdata forum.ForumCategory --natural-primary --natural-foreign --indent 2 --settings=app.settings_dev > apps/forum/fixtures/categories.json

# Dump multiple models
& .\.venv\Scripts\python.exe manage.py dumpdata firmwares.Brand firmwares.Model --indent 2 --settings=app.settings_dev > apps/firmwares/fixtures/catalog.json

# Exclude content types and permissions (avoid conflicts)
& .\.venv\Scripts\python.exe manage.py dumpdata --exclude contenttypes --exclude auth.permission --indent 2 --settings=app.settings_dev > fixtures/full_dump.json
```

### Loading Data
```powershell
# Load a single fixture
& .\.venv\Scripts\python.exe manage.py loaddata apps/firmwares/fixtures/brands.json --settings=app.settings_dev

# Load multiple fixtures (order matters for FK dependencies)
& .\.venv\Scripts\python.exe manage.py loaddata brands.json models.json firmwares.json --settings=app.settings_dev
```

### Fixture File Structure
```json
[
    {
        "model": "firmwares.brand",
        "pk": 1,
        "fields": {
            "name": "Samsung",
            "slug": "samsung",
            "is_active": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    },
    {
        "model": "firmwares.brand",
        "pk": 2,
        "fields": {
            "name": "Xiaomi",
            "slug": "xiaomi",
            "is_active": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    }
]
```

### Natural Keys (Avoid PK Conflicts)
```python
# apps/firmwares/models.py
class BrandManager(models.Manager["Brand"]):
    def get_by_natural_key(self, slug: str) -> "Brand":
        return self.get(slug=slug)


class Brand(TimestampedModel):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)

    objects = BrandManager()

    def natural_key(self) -> tuple[str]:
        return (self.slug,)

    class Meta:
        db_table = "firmwares_brand"
```

```json
[
    {
        "model": "firmwares.brand",
        "fields": {
            "name": "Samsung",
            "slug": "samsung",
            "is_active": true
        }
    }
]
```

### Fixture in Tests
```python
import pytest

@pytest.mark.django_db
class TestFirmwareViews:
    fixtures = ["brands.json", "models.json"]

    def test_brand_list(self, client):
        response = client.get("/firmwares/brands/")
        assert response.status_code == 200
```

## Anti-Patterns
- NEVER include plain-text passwords in fixtures
- NEVER fixture large datasets (1000+ records) — use seed commands
- NEVER include `contenttypes` or `auth.permission` in fixtures (PK conflicts)
- NEVER rely on auto-increment PKs in fixture references — use natural keys
- NEVER edit fixture files manually for production data changes

## Red Flags
- Fixture with hardcoded PKs that will conflict with existing data
- Missing `--natural-foreign` when dumping models with FK relationships
- Fixture file > 1MB — too large, use a seed command instead
- `auth.user` fixtures with `password` field in plain text

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/fixtures/` — existing fixture files
- `.claude/rules/fixtures-layer.md` — fixture rules
