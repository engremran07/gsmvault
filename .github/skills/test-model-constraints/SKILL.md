---
name: test-model-constraints
description: "Model constraint tests: unique_together, CheckConstraint, UniqueConstraint. Use when: verifying database-level constraints, unique combinations, check constraints."
---

# Model Constraint Tests

## When to Use

- Verifying `unique_together` / `UniqueConstraint` enforcement
- Testing `CheckConstraint` at the database level
- Ensuring duplicate detection works

## Rules

### Testing UniqueConstraint

```python
import pytest
from django.db import IntegrityError

@pytest.mark.django_db
def test_unique_firmware_version_per_model():
    from tests.factories import FirmwareFactory, ModelFactory
    model = ModelFactory()
    FirmwareFactory(model=model, version="1.0.0")
    with pytest.raises(IntegrityError):
        FirmwareFactory(model=model, version="1.0.0")

@pytest.mark.django_db
def test_different_models_same_version_ok():
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="1.0.0")  # Different model (SubFactory)
    FirmwareFactory(version="1.0.0")  # OK — different model
```

### Testing unique_together

```python
@pytest.mark.django_db
def test_duplicate_tag_on_same_object():
    from tests.factories import TagFactory
    tag1 = TagFactory(content_type_id=1, object_id=1, name="test")
    with pytest.raises(IntegrityError):
        TagFactory(content_type_id=1, object_id=1, name="test")
```

### Testing CheckConstraint

```python
@pytest.mark.django_db(transaction=True)
def test_negative_price_rejected():
    """CheckConstraint: price >= 0."""
    from tests.factories import ProductFactory
    with pytest.raises(IntegrityError):
        ProductFactory(price=-10)

@pytest.mark.django_db
def test_zero_price_allowed():
    from tests.factories import ProductFactory
    product = ProductFactory(price=0)
    assert product.price == 0
```

### Testing with transaction=True

```python
@pytest.mark.django_db(transaction=True)
def test_constraint_violation_in_transaction():
    """Use transaction=True for IntegrityError tests."""
    from tests.factories import FirmwareFactory, ModelFactory
    model = ModelFactory()
    FirmwareFactory(model=model, version="1.0.0")
    with pytest.raises(IntegrityError):
        FirmwareFactory(model=model, version="1.0.0")
```

### Testing Soft-Delete Unique Constraints

```python
@pytest.mark.django_db
def test_soft_deleted_unique_allows_reuse():
    """Deleted records don't block unique constraint for active records."""
    from tests.factories import FirmwareFactory
    fw1 = FirmwareFactory(slug="test-fw")
    fw1.is_deleted = True
    fw1.save()
    fw2 = FirmwareFactory(slug="test-fw")  # Should work if constraint excludes deleted
    assert fw2.slug == "test-fw"
```

## Red Flags

- Testing constraints without `transaction=True` — `IntegrityError` may break test DB
- Not testing both violation and valid cases
- Testing at Python level when constraint is DB-only — use `full_clean()` for validators
- Missing the distinction between model validation and DB constraints

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
