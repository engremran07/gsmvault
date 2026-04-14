---
name: test-api-serializer
description: "Serializer tests: to_representation, to_internal_value, validation. Use when: testing DRF serializer output, input validation, custom field logic."
---

# API Serializer Tests

## When to Use

- Testing serializer output matches expected JSON structure
- Verifying serializer validation rejects bad input
- Testing custom `to_representation` / `to_internal_value`
- Checking nested serializer behavior

## Rules

### Testing Serialization Output

```python
import pytest

@pytest.mark.django_db
def test_serializer_output():
    from tests.factories import FirmwareFactory
    from apps.firmwares.serializers import FirmwareSerializer
    fw = FirmwareFactory(version="1.0.0")
    serializer = FirmwareSerializer(fw)
    data = serializer.data
    assert data["version"] == "1.0.0"
    assert "id" in data
    assert "created_at" in data

@pytest.mark.django_db
def test_serializer_excludes_sensitive():
    from tests.factories import UserFactory
    from apps.users.serializers import UserSerializer
    user = UserFactory()
    data = UserSerializer(user).data
    assert "password" not in data
    assert "email" in data
```

### Testing Deserialization (Input Validation)

```python
@pytest.mark.django_db
def test_serializer_valid_input():
    from apps.firmwares.serializers import FirmwareSerializer
    data = {"version": "1.0.0", "build_number": "100"}
    serializer = FirmwareSerializer(data=data)
    assert serializer.is_valid(), serializer.errors

@pytest.mark.django_db
def test_serializer_invalid_input():
    from apps.firmwares.serializers import FirmwareSerializer
    serializer = FirmwareSerializer(data={})
    assert not serializer.is_valid()
    assert "version" in serializer.errors

@pytest.mark.django_db
@pytest.mark.parametrize("field,value", [
    ("version", ""),
    ("version", None),
    ("file_size", -1),
])
def test_serializer_field_validation(field, value):
    from apps.firmwares.serializers import FirmwareSerializer
    serializer = FirmwareSerializer(data={field: value})
    assert not serializer.is_valid()
    assert field in serializer.errors
```

### Testing Custom Validation

```python
@pytest.mark.django_db
def test_serializer_validate_method():
    from apps.firmwares.serializers import FirmwareSerializer
    data = {"version": "1.0.0", "min_android": "15", "max_android": "10"}
    serializer = FirmwareSerializer(data=data)
    assert not serializer.is_valid()
    assert "non_field_errors" in serializer.errors
```

### Testing Read-Only Fields

```python
@pytest.mark.django_db
def test_read_only_field_ignored():
    from apps.firmwares.serializers import FirmwareSerializer
    data = {"version": "1.0.0", "download_count": 999}
    serializer = FirmwareSerializer(data=data)
    if serializer.is_valid():
        obj = serializer.save()
        assert obj.download_count != 999  # Read-only, should be default
```

### Testing Nested Serializers

```python
@pytest.mark.django_db
def test_nested_serializer():
    from tests.factories import FirmwareFactory
    from apps.firmwares.serializers import FirmwareDetailSerializer
    fw = FirmwareFactory()
    data = FirmwareDetailSerializer(fw).data
    assert "model" in data
    assert "brand" in data["model"]
```

## Red Flags

- Not testing both serialization and deserialization directions
- Missing validation tests for required fields
- Testing serializer through views instead of directly — harder to debug
- Not checking `serializer.errors` content — just checking `is_valid()` is weak

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
