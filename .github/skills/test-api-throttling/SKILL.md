---
name: test-api-throttling
description: "Throttle tests: rate limit exhaustion, retry-after headers. Use when: testing DRF throttle classes, rate limit responses, cooldown behavior."
---

# API Throttle Tests

## When to Use

- Testing DRF throttle rate limits are enforced
- Verifying `Retry-After` header in 429 responses
- Testing different throttle rates per user tier
- Checking throttle scope configuration

## Rules

### Basic Throttle Test

```python
import pytest
from rest_framework.test import APIClient
from unittest.mock import patch

@pytest.mark.django_db
def test_throttle_kicks_in(api_client):
    from tests.factories import UserFactory
    user = UserFactory()
    api_client.force_authenticate(user=user)
    # Override throttle rate to very low for testing
    with patch.dict("rest_framework.throttling.SimpleRateThrottle.THROTTLE_RATES", {"user": "2/min"}):
        for _ in range(2):
            response = api_client.get("/api/v1/firmwares/")
            assert response.status_code == 200
        # Third request should be throttled
        response = api_client.get("/api/v1/firmwares/")
        assert response.status_code == 429
```

### Testing Retry-After Header

```python
@pytest.mark.django_db
def test_retry_after_header(api_client):
    from tests.factories import UserFactory
    user = UserFactory()
    api_client.force_authenticate(user=user)
    with patch.dict("rest_framework.throttling.SimpleRateThrottle.THROTTLE_RATES", {"user": "1/min"}):
        api_client.get("/api/v1/firmwares/")
        response = api_client.get("/api/v1/firmwares/")
        assert response.status_code == 429
        assert "Retry-After" in response or response.has_header("Retry-After")
```

### Testing Anonymous vs Authenticated Rates

```python
@pytest.mark.django_db
def test_anon_throttle_lower():
    """Anonymous users should have stricter rate limits."""
    anon_client = APIClient()
    with patch.dict("rest_framework.throttling.SimpleRateThrottle.THROTTLE_RATES", {"anon": "1/min"}):
        anon_client.get("/api/v1/firmwares/")
        response = anon_client.get("/api/v1/firmwares/")
        assert response.status_code == 429
```

### Override Throttle in Tests

```python
from rest_framework.test import APIClient

@pytest.fixture
def unthrottled_api_client():
    """Client with throttling disabled for non-throttle tests."""
    client = APIClient()
    client.handler._force_token = True
    return client

# Or use override_settings:
from django.test import override_settings

@override_settings(REST_FRAMEWORK={"DEFAULT_THROTTLE_CLASSES": []})
@pytest.mark.django_db
def test_without_throttle(api_client):
    from tests.factories import UserFactory
    api_client.force_authenticate(UserFactory())
    for _ in range(100):
        response = api_client.get("/api/v1/firmwares/")
        assert response.status_code == 200
```

## Red Flags

- Not resetting throttle cache between tests — use `cache.clear()` fixture
- Testing throttle with production rates — too many requests, slow tests
- Missing `Retry-After` header validation — clients need it for backoff
- Not testing both anonymous and authenticated throttle tiers

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
