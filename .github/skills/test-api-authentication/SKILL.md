---
name: test-api-authentication
description: "API auth tests: JWT, session, unauthorized access. Use when: testing DRF authentication, token validation, unauthorized/forbidden responses."
---

# API Authentication Tests

## When to Use

- Testing JWT token-based authentication
- Verifying 401 Unauthorized responses for unauthenticated requests
- Testing session authentication for browser-based API access
- Checking authentication header formats

## Rules

### Testing Unauthenticated Access

```python
import pytest
from rest_framework.test import APIClient

@pytest.fixture
def api_client():
    return APIClient()

@pytest.mark.django_db
def test_unauthenticated_gets_401(api_client):
    response = api_client.get("/api/v1/firmwares/")
    assert response.status_code in (401, 403)
```

### Testing with force_authenticate

```python
@pytest.mark.django_db
def test_authenticated_gets_200(api_client):
    from tests.factories import UserFactory
    user = UserFactory()
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/v1/firmwares/")
    assert response.status_code == 200
```

### Testing JWT Authentication

```python
@pytest.mark.django_db
def test_jwt_auth(api_client):
    from tests.factories import UserFactory
    user = UserFactory()
    user.set_password("testpass123")
    user.save()
    # Get token
    response = api_client.post("/api/v1/auth/token/", {
        "username": user.username, "password": "testpass123",
    })
    assert response.status_code == 200
    token = response.data["access"]
    # Use token
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    response = api_client.get("/api/v1/firmwares/")
    assert response.status_code == 200

@pytest.mark.django_db
def test_invalid_jwt_rejected(api_client):
    api_client.credentials(HTTP_AUTHORIZATION="Bearer invalid.token.here")
    response = api_client.get("/api/v1/firmwares/")
    assert response.status_code == 401
```

### Testing Staff-Only API Endpoints

```python
@pytest.mark.django_db
def test_non_staff_forbidden(api_client):
    from tests.factories import UserFactory
    user = UserFactory(is_staff=False)
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/v1/admin/users/")
    assert response.status_code == 403

@pytest.mark.django_db
def test_staff_allowed(api_client):
    from tests.factories import UserFactory
    user = UserFactory(is_staff=True)
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/v1/admin/users/")
    assert response.status_code == 200
```

### APIClient Fixture with Auth

```python
@pytest.fixture
def auth_api_client(db):
    from tests.factories import UserFactory
    client = APIClient()
    user = UserFactory()
    client.force_authenticate(user=user)
    client.user = user
    return client
```

## Red Flags

- Not testing unauthenticated access — every protected endpoint needs a 401 test
- Using `client` instead of `APIClient` for DRF views — wrong response format
- `force_authenticate` on all tests — also test real token flow at least once
- Missing expired token test for JWT auth

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
