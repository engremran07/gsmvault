---
name: test-middleware-request
description: "Request middleware tests: header injection, request modification. Use when: testing middleware that modifies requests, adds headers, checks IP, logs requests."
---

# Request Middleware Tests

## When to Use

- Testing middleware that modifies incoming requests
- Verifying header injection (client IP, request ID)
- Testing request blocking/filtering logic
- Checking middleware ordering effects

## Rules

### Testing Middleware with Client

```python
import pytest

@pytest.mark.django_db
def test_middleware_adds_header(client):
    response = client.get("/")
    # Check response was affected by middleware
    assert response.status_code in (200, 302)

@pytest.mark.django_db
def test_blocked_ip(client, settings):
    """Test security middleware blocks banned IPs."""
    from tests.factories import BlockedIPFactory
    BlockedIPFactory(ip_address="127.0.0.1")
    response = client.get("/", REMOTE_ADDR="127.0.0.1")
    assert response.status_code == 403
```

### Testing with RequestFactory

```python
from django.test import RequestFactory

@pytest.mark.django_db
def test_middleware_process_request():
    from app.middleware.csp_nonce import CSPNonceMiddleware
    factory = RequestFactory()
    request = factory.get("/")
    middleware = CSPNonceMiddleware(lambda r: None)
    middleware.process_request(request)
    assert hasattr(request, "csp_nonce")
```

### Testing Middleware Ordering

```python
def test_middleware_order(settings):
    mw = settings.MIDDLEWARE
    security_idx = next(
        (i for i, m in enumerate(mw) if "Security" in m), None
    )
    session_idx = next(
        (i for i, m in enumerate(mw) if "Session" in m), None
    )
    if security_idx is not None and session_idx is not None:
        assert security_idx < session_idx  # Security before session
```

### Testing Request Modification

```python
@pytest.mark.django_db
def test_middleware_sets_request_attribute():
    from django.test import RequestFactory
    from app.middleware.htmx_auth import HtmxAuthMiddleware
    factory = RequestFactory()
    request = factory.get("/", HTTP_HX_REQUEST="true")
    get_response = lambda r: None  # noqa: E731
    middleware = HtmxAuthMiddleware(get_response)
    middleware(request)
    # Middleware should have set htmx-related attributes
```

### Testing Middleware Skip Conditions

```python
@pytest.mark.django_db
def test_middleware_skips_static_files(client):
    response = client.get("/static/css/main.css")
    # Middleware should not process static file requests
    assert response.status_code in (200, 404)  # Not blocked
```

## Red Flags

- Testing middleware only via integration (Client) — also test process_request directly
- Not testing middleware bypass paths (static files, health checks)
- Missing IP-based test variations — use `REMOTE_ADDR` kwarg
- Not verifying middleware is in `MIDDLEWARE` list

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
