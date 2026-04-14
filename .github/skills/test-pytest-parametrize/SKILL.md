---
name: test-pytest-parametrize
description: "@pytest.mark.parametrize for data-driven tests. Use when: testing multiple inputs, boundary values, equivalence classes, reducing test duplication."
---

# pytest Parametrize

## When to Use

- Testing a function/view with multiple input combinations
- Boundary value analysis (edge cases)
- Reducing boilerplate from repetitive test cases

## Rules

### Basic Parametrize

```python
import pytest

@pytest.mark.parametrize("version,expected", [
    ("1.0.0", True),
    ("", False),
    (None, False),
    ("v2.3.1-beta", True),
])
def test_firmware_version_valid(version, expected):
    from apps.firmwares.services import is_valid_version
    assert is_valid_version(version) == expected
```

### Multiple Parameters

```python
@pytest.mark.parametrize("status_code,template", [
    (200, "firmwares/list.html"),
    (404, "errors/404.html"),
])
@pytest.mark.django_db
def test_view_templates(client, status_code, template):
    # Test template selection based on conditions
    pass
```

### Stacked Parametrize (Cartesian Product)

```python
@pytest.mark.parametrize("method", ["GET", "POST", "PUT", "DELETE"])
@pytest.mark.parametrize("auth", [True, False])
@pytest.mark.django_db
def test_endpoint_auth_matrix(method, auth, client, staff_user):
    """Tests all method × auth combinations = 8 test cases."""
    if auth:
        client.force_login(staff_user)
    response = getattr(client, method.lower())("/api/v1/firmwares/")
    if not auth:
        assert response.status_code in (401, 403)
```

### IDs for Readability

```python
@pytest.mark.parametrize("input_data,error_field", [
    pytest.param({"email": ""}, "email", id="empty-email"),
    pytest.param({"email": "bad"}, "email", id="invalid-email"),
    pytest.param({"email": "a@b.com"}, None, id="valid-email"),
])
@pytest.mark.django_db
def test_registration_validation(input_data, error_field):
    from apps.users.forms import RegistrationForm
    form = RegistrationForm(data=input_data)
    if error_field:
        assert not form.is_valid()
        assert error_field in form.errors
    else:
        assert form.is_valid()
```

### Indirect Parametrize with Fixtures

```python
@pytest.fixture
def user_with_tier(request, db):
    from tests.factories import UserFactory
    return UserFactory(tier=request.param)

@pytest.mark.parametrize("user_with_tier", ["free", "premium"], indirect=True)
def test_download_limit(user_with_tier):
    assert user_with_tier.tier in ("free", "premium")
```

## Red Flags

- Parametrize with too many combinations — use targeted boundary values instead
- Missing `id` on complex params — test output becomes unreadable
- Parametrizing DB-dependent tests without `@pytest.mark.django_db`
- Using parametrize when fixtures would be cleaner

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
