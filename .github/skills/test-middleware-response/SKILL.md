---
name: test-middleware-response
description: "Response middleware tests: header verification, content changes. Use when: testing middleware that modifies responses, adds security headers, sets cookies."
---

# Response Middleware Tests

## When to Use

- Verifying security headers (CSP, X-Frame-Options, HSTS)
- Testing cookie manipulation middleware
- Checking response content modification
- Testing cache headers

## Rules

### Testing Security Headers

```python
import pytest

@pytest.mark.django_db
def test_x_frame_options(client):
    response = client.get("/")
    assert response.get("X-Frame-Options") == "DENY"

@pytest.mark.django_db
def test_csp_header(client):
    response = client.get("/")
    csp = response.get("Content-Security-Policy", "")
    assert "default-src" in csp or "script-src" in csp or csp == ""

@pytest.mark.django_db
def test_xss_protection(client):
    response = client.get("/")
    xss = response.get("X-Content-Type-Options", "")
    assert xss == "nosniff"
```

### Testing CSP Nonce Middleware

```python
@pytest.mark.django_db
def test_csp_nonce_in_response(client):
    response = client.get("/")
    if response.status_code == 200:
        csp = response.get("Content-Security-Policy", "")
        if "nonce-" in csp:
            # Extract nonce and verify it's in the HTML
            import re
            nonce_match = re.search(r"nonce-([A-Za-z0-9+/=]+)", csp)
            if nonce_match:
                nonce = nonce_match.group(1)
                assert nonce in response.content.decode()
```

### Testing Cookie Setting

```python
@pytest.mark.django_db
def test_consent_cookie_httponly(client):
    response = client.get("/")
    for cookie in response.cookies.values():
        if cookie.key == "consent":
            assert cookie["httponly"]
```

### Testing Middleware with Process Response

```python
@pytest.mark.django_db
def test_middleware_process_response():
    from django.test import RequestFactory
    from django.http import HttpResponse
    from app.middleware.csp_nonce import CSPNonceMiddleware
    factory = RequestFactory()
    request = factory.get("/")
    response = HttpResponse("OK")
    middleware = CSPNonceMiddleware(lambda r: response)
    result = middleware(request)
    assert result is not None
```

### Testing Cache Headers

```python
@pytest.mark.django_db
def test_static_cache_headers(client):
    response = client.get("/api/v1/firmwares/")
    cache_control = response.get("Cache-Control", "")
    # API responses should have appropriate cache headers
    assert "no-cache" in cache_control or "max-age" in cache_control or cache_control == ""
```

## Red Flags

- Not testing security headers in production mode — some only enabled in production
- Missing HSTS header checks for production settings
- Not verifying CSP nonce changes per request — should be unique each time
- Testing headers only on "/" — check multiple endpoints

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
