---
name: test-model-validation
description: "Model validation tests: clean(), full_clean(), ValidationError. Use when: testing model-level validation rules, custom clean methods, field validators."
---

# Model Validation Tests

## When to Use

- Testing custom `clean()` method logic
- Verifying field validators reject bad data
- Ensuring `full_clean()` catches constraint violations
- Testing `ValidationError` messages

## Rules

### Testing clean() Method

```python
import pytest
from django.core.exceptions import ValidationError

@pytest.mark.django_db
def test_firmware_clean_rejects_negative_size():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory.build(file_size=-1)
    with pytest.raises(ValidationError) as exc_info:
        fw.full_clean()
    assert "file_size" in exc_info.value.message_dict

@pytest.mark.django_db
def test_firmware_clean_valid():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory.build(file_size=1024)
    fw.full_clean()  # Should not raise
```

### Testing Field Validators

```python
@pytest.mark.django_db
def test_email_validator():
    from tests.factories import UserFactory
    user = UserFactory.build(email="not-an-email")
    with pytest.raises(ValidationError) as exc_info:
        user.full_clean()
    assert "email" in exc_info.value.message_dict

@pytest.mark.django_db
def test_slug_validator():
    from tests.factories import PostFactory
    post = PostFactory.build(slug="INVALID SLUG!")
    with pytest.raises(ValidationError):
        post.full_clean()
```

### Testing Custom Validators

```python
@pytest.mark.django_db
def test_version_format_validator():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory.build(version="not.semver")
    with pytest.raises(ValidationError) as exc_info:
        fw.full_clean()
    errors = exc_info.value.message_dict
    assert "version" in errors

@pytest.mark.django_db
@pytest.mark.parametrize("version", ["1.0.0", "2.1.3", "10.20.30"])
def test_valid_versions(version):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory.build(version=version)
    fw.full_clean()  # Should not raise
```

### Testing Cross-Field Validation

```python
@pytest.mark.django_db
def test_date_range_validation():
    """end_date must be after start_date."""
    from tests.factories import CampaignFactory
    from datetime import date
    campaign = CampaignFactory.build(
        start_at=date(2025, 6, 1),
        end_at=date(2025, 5, 1),  # Before start
    )
    with pytest.raises(ValidationError) as exc_info:
        campaign.full_clean()
    assert "end_at" in str(exc_info.value)
```

## Red Flags

- Testing with `save()` instead of `full_clean()` — `save()` skips validation
- Not checking specific error fields in `message_dict` — weak assertions
- Missing test for valid data path — only testing rejections
- Using `assertRaises` without checking the error content

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
