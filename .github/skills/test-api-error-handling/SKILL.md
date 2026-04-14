---
name: test-api-error-handling
description: "Error response tests: 400, 404, 500, error format verification. Use when: testing API error responses, error JSON structure, validation errors, exception handling."
---

# API Error Handling Tests

## When to Use

- Verifying error responses have consistent JSON structure
- Testing 400 Bad Request for validation failures
- Testing 404 Not Found for missing resources
- Testing custom exception handler output

## Rules

### Testing 400 Validation Error Format

```python
import pytest

@pytest.mark.django_db
def test_400_validation_error(auth_api):
    response = auth_api.post("/api/v1/firmwares/", data={})
    assert response.status_code == 400
    assert isinstance(response.data, dict)
    # Should have field-level errors
    assert any(key in response.data for key in ("version", "non_field_errors"))
```

### Testing 404 Not Found

```python
@pytest.mark.django_db
def test_404_response(auth_api):
    response = auth_api.get("/api/v1/firmwares/99999/")
    assert response.status_code == 404
    assert "detail" in response.data or "error" in response.data

@pytest.mark.django_db
def test_404_on_invalid_url(auth_api):
    response = auth_api.get("/api/v1/nonexistent/")
    assert response.status_code == 404
```

### Testing 403 Forbidden

```python
@pytest.mark.django_db
def test_403_non_owner(auth_api):
    from tests.factories import FirmwareFactory, UserFactory
    other_user = UserFactory()
    fw = FirmwareFactory(uploaded_by=other_user)
    response = auth_api.delete(f"/api/v1/firmwares/{fw.pk}/")
    assert response.status_code in (403, 404)  # 404 if queryset filtered
```

### Testing 405 Method Not Allowed

```python
@pytest.mark.django_db
def test_405_wrong_method(auth_api):
    response = auth_api.put("/api/v1/firmwares/")
    assert response.status_code == 405
    assert "detail" in response.data
```

### Testing Error Response Consistency

```python
@pytest.mark.django_db
@pytest.mark.parametrize("url,method,expected", [
    ("/api/v1/firmwares/99999/", "get", 404),
    ("/api/v1/firmwares/", "put", 405),
])
def test_error_format_consistency(auth_api, url, method, expected):
    response = getattr(auth_api, method)(url)
    assert response.status_code == expected
    # All errors should return JSON
    assert response["Content-Type"] == "application/json"
```

### Testing Custom Error Codes

```python
@pytest.mark.django_db
def test_custom_error_code(auth_api):
    """Platform convention: {"error": "message", "code": "ERROR_CODE"}."""
    response = auth_api.post("/api/v1/firmwares/", data={})
    assert response.status_code == 400
    # Check platform error format if custom exception handler is used
    if "code" in response.data:
        assert isinstance(response.data["code"], str)
```

### Testing Throttle Error (429)

```python
@pytest.mark.django_db
def test_429_error_format(auth_api):
    from unittest.mock import patch
    with patch.dict("rest_framework.throttling.SimpleRateThrottle.THROTTLE_RATES", {"user": "0/min"}):
        response = auth_api.get("/api/v1/firmwares/")
        assert response.status_code == 429
        assert "detail" in response.data
```

## Red Flags

- Not checking `Content-Type` on error responses — should be JSON
- Missing error format tests — inconsistent errors confuse API consumers
- Only testing success paths — error paths need coverage too
- Not verifying error detail messages — empty errors are unhelpful

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
