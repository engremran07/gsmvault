---
name: drf-testing-api
description: "API test patterns: APIClient, force_authenticate, status code assertions. Use when: writing tests for DRF endpoints, testing auth, permissions, serializers, viewsets."
---

# DRF API Testing

## When to Use
- Writing tests for API endpoints (ViewSets, APIViews)
- Testing authentication and permission checks
- Validating serializer behavior
- Integration testing of full request/response cycle

## Rules
- Use `APIClient` not Django's `TestClient` for DRF endpoints
- Use `force_authenticate()` to test as specific users without real login
- Always assert status codes AND response body structure
- Use `pytest` + `pytest-django` (platform standard)
- Test files: `apps/<app>/tests.py` or `tests/test_<app>_api.py`

## Patterns

### Basic GET Test
```python
import pytest
from rest_framework import status
from rest_framework.test import APIClient
from apps.firmwares.models import Firmware

@pytest.mark.django_db
class TestFirmwareAPI:
    def setup_method(self):
        self.client = APIClient()

    def test_list_firmwares_unauthenticated(self):
        response = self.client.get("/api/v1/firmwares/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_firmwares_authenticated(self, user):
        self.client.force_authenticate(user=user)
        response = self.client.get("/api/v1/firmwares/")
        assert response.status_code == status.HTTP_200_OK
        assert "results" in response.data
```

### Factory Fixtures (conftest.py)
```python
# conftest.py or apps/<app>/conftest.py
import pytest
from django.contrib.auth import get_user_model

User = get_user_model()

@pytest.fixture
def user(db):
    return User.objects.create_user(
        email="test@example.com", username="testuser", password="testpass123"
    )

@pytest.fixture
def staff_user(db):
    return User.objects.create_user(
        email="staff@example.com", username="staffuser",
        password="testpass123", is_staff=True,
    )

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def auth_client(user):
    client = APIClient()
    client.force_authenticate(user=user)
    return client
```

### POST / Create Test
```python
@pytest.mark.django_db
def test_create_firmware(auth_client, brand):
    data = {
        "name": "Test ROM",
        "version": "1.0.0",
        "brand": brand.pk,
    }
    response = auth_client.post("/api/v1/firmwares/", data, format="json")
    assert response.status_code == status.HTTP_201_CREATED
    assert response.data["name"] == "Test ROM"
    assert Firmware.objects.filter(name="Test ROM").exists()
```

### Permission Tests
```python
@pytest.mark.django_db
class TestPermissions:
    def test_non_staff_cannot_delete(self, auth_client, firmware):
        response = auth_client.delete(f"/api/v1/firmwares/{firmware.pk}/")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_staff_can_delete(self, staff_user, firmware):
        client = APIClient()
        client.force_authenticate(user=staff_user)
        response = client.delete(f"/api/v1/firmwares/{firmware.pk}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT

    def test_owner_can_update(self, user, firmware):
        firmware.uploaded_by = user
        firmware.save()
        client = APIClient()
        client.force_authenticate(user=user)
        response = client.patch(
            f"/api/v1/firmwares/{firmware.pk}/",
            {"name": "Updated"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
```

### Validation Error Test
```python
@pytest.mark.django_db
def test_invalid_version_format(auth_client, brand):
    data = {"name": "Test", "version": "bad", "brand": brand.pk}
    response = auth_client.post("/api/v1/firmwares/", data, format="json")
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert response.data["code"] == "VALIDATION_ERROR"
```

### Pagination Test
```python
@pytest.mark.django_db
def test_pagination(auth_client, firmware_factory):
    firmware_factory.create_batch(25)
    response = auth_client.get("/api/v1/firmwares/")
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data["results"]) == 20  # PAGE_SIZE default
    assert response.data["next"] is not None
```

### Serializer Unit Test
```python
@pytest.mark.django_db
def test_firmware_serializer(firmware):
    from apps.firmwares.api import FirmwareSerializer
    serializer = FirmwareSerializer(firmware)
    assert "id" in serializer.data
    assert "name" in serializer.data
    assert "password" not in serializer.data  # write_only excluded
```

## Anti-Patterns
- Using Django `Client` instead of DRF `APIClient` → missing content negotiation
- Testing only happy paths → always test 4xx and 5xx scenarios
- Hardcoding URLs instead of `reverse()` → breaks on URL changes
- Not testing permission boundaries → security gaps

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `testing` — general pytest patterns
- Skill: `drf-error-handling` — error response format to assert against
