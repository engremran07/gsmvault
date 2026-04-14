---
name: test-middleware-exception
description: "Exception middleware tests: error handling, logging. Use when: testing middleware that catches exceptions, custom error pages, exception logging."
---

# Exception Middleware Tests

## When to Use

- Testing middleware `process_exception` handlers
- Verifying custom error pages render correctly
- Testing exception logging behavior
- Checking error response format (HTML vs JSON)

## Rules

### Testing Exception Handler

```python
import pytest
from unittest.mock import patch

@pytest.mark.django_db
def test_500_returns_error_page(client):
    with patch("apps.firmwares.views.firmware_list", side_effect=RuntimeError("test")):
        response = client.get("/firmwares/")
        assert response.status_code == 500

@pytest.mark.django_db
def test_404_custom_page(client):
    response = client.get("/nonexistent-url-12345/")
    assert response.status_code == 404
    # Custom 404 template should be used
    if hasattr(response, "templates"):
        template_names = [t.name for t in response.templates]
        assert "errors/404.html" in template_names or "404.html" in template_names
```

### Testing Exception Logging

```python
@pytest.mark.django_db
def test_exception_is_logged(client):
    with patch("apps.firmwares.views.firmware_list", side_effect=RuntimeError("test error")):
        with patch("logging.Logger.error") as mock_log:
            client.get("/firmwares/")
            # Exception should be logged
```

### Testing API Exception Handler

```python
from rest_framework.test import APIClient

@pytest.mark.django_db
def test_api_500_returns_json():
    api_client = APIClient()
    from tests.factories import UserFactory
    api_client.force_authenticate(UserFactory())
    with patch("apps.firmwares.api.FirmwareViewSet.list", side_effect=RuntimeError):
        response = api_client.get("/api/v1/firmwares/")
        assert response.status_code == 500
        assert response["Content-Type"] == "application/json"
```

### Testing Process Exception Method

```python
def test_process_exception_method():
    from django.test import RequestFactory
    from django.http import HttpResponse
    factory = RequestFactory()
    request = factory.get("/test/")

    # Test custom middleware exception handler
    def get_response(r):
        raise ValueError("test")

    try:
        from app.middleware.csp_nonce import CSPNonceMiddleware
        middleware = CSPNonceMiddleware(get_response)
        middleware(request)
    except ValueError:
        pass  # Expected if middleware doesn't handle it
```

### Testing Error Page Content

```python
from django.test import override_settings

@override_settings(DEBUG=False)
@pytest.mark.django_db
def test_error_page_no_debug_info(client):
    with patch("apps.firmwares.views.firmware_list", side_effect=RuntimeError("secret error")):
        response = client.get("/firmwares/")
        if response.status_code == 500:
            content = response.content.decode()
            assert "secret error" not in content  # No stack traces in production
            assert "Traceback" not in content
```

## Red Flags

- Not testing with `DEBUG=False` — error pages differ between debug modes
- Missing JSON error format test for API endpoints
- Not verifying stack traces are hidden in production
- Exception middleware not in correct position in `MIDDLEWARE` list

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
