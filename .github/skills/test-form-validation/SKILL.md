---
name: test-form-validation
description: "Form validation tests: valid data, invalid data, error messages. Use when: testing Django form validation, clean methods, field validators, error display."
---

# Form Validation Tests

## When to Use

- Testing form `is_valid()` with various inputs
- Verifying custom `clean_*()` methods
- Checking error messages for specific fields
- Testing cross-field validation in `clean()`

## Rules

### Testing Valid Data

```python
import pytest

@pytest.mark.django_db
def test_form_valid_data():
    from apps.firmwares.forms import FirmwareForm
    data = {"version": "1.0.0", "build_number": "100", "file_size": 1024}
    form = FirmwareForm(data=data)
    assert form.is_valid(), form.errors

@pytest.mark.django_db
def test_form_creates_object():
    from apps.firmwares.forms import FirmwareForm
    data = {"version": "1.0.0", "build_number": "100"}
    form = FirmwareForm(data=data)
    assert form.is_valid()
    obj = form.save()
    assert obj.pk is not None
```

### Testing Invalid Data

```python
@pytest.mark.django_db
def test_form_missing_required():
    from apps.firmwares.forms import FirmwareForm
    form = FirmwareForm(data={})
    assert not form.is_valid()
    assert "version" in form.errors

@pytest.mark.django_db
def test_form_invalid_email():
    from apps.users.forms import RegistrationForm
    form = RegistrationForm(data={"email": "not-valid"})
    assert not form.is_valid()
    assert "email" in form.errors

@pytest.mark.django_db
@pytest.mark.parametrize("field,value,error_key", [
    ("version", "", "version"),
    ("version", "x" * 256, "version"),
    ("file_size", -1, "file_size"),
])
def test_field_validation(field, value, error_key):
    from apps.firmwares.forms import FirmwareForm
    form = FirmwareForm(data={field: value})
    assert not form.is_valid()
    assert error_key in form.errors
```

### Testing Custom clean Methods

```python
@pytest.mark.django_db
def test_clean_method_cross_field():
    from apps.ads.forms import CampaignForm
    data = {
        "start_at": "2025-06-01",
        "end_at": "2025-05-01",  # Before start
    }
    form = CampaignForm(data=data)
    assert not form.is_valid()
    assert "__all__" in form.errors or "end_at" in form.errors
```

### Testing Error Messages

```python
@pytest.mark.django_db
def test_error_message_content():
    from apps.users.forms import RegistrationForm
    form = RegistrationForm(data={"password": "123"})
    assert not form.is_valid()
    error_text = str(form.errors["password"])
    assert "too short" in error_text.lower() or "minimum" in error_text.lower()
```

## Red Flags

- Only testing valid data — always test rejection cases
- Not checking which field has the error — `assert not form.is_valid()` is too weak
- Missing parametrize for multiple invalid inputs — use data-driven tests
- Testing form validation through views instead of directly — slower, harder to debug

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
