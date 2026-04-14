---
name: test-api-viewset
description: "ViewSet tests: CRUD operations, custom actions, filters. Use when: testing DRF ModelViewSet endpoints, list/create/retrieve/update/destroy, @action methods."
---

# API ViewSet Tests

## When to Use

- Testing full CRUD cycle on a ModelViewSet
- Testing custom `@action` endpoints
- Verifying queryset filtering and permissions

## Rules

### Testing CRUD Lifecycle

```python
import pytest
from rest_framework.test import APIClient

@pytest.fixture
def auth_api(db):
    from tests.factories import UserFactory
    client = APIClient()
    user = UserFactory(is_staff=True)
    client.force_authenticate(user=user)
    return client

@pytest.mark.django_db
def test_list(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(3)
    response = auth_api.get("/api/v1/firmwares/")
    assert response.status_code == 200
    assert len(response.data["results"]) == 3

@pytest.mark.django_db
def test_create(auth_api):
    data = {"version": "1.0.0", "build_number": "100"}
    response = auth_api.post("/api/v1/firmwares/", data=data)
    assert response.status_code == 201
    assert response.data["version"] == "1.0.0"

@pytest.mark.django_db
def test_retrieve(auth_api):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    response = auth_api.get(f"/api/v1/firmwares/{fw.pk}/")
    assert response.status_code == 200
    assert response.data["id"] == fw.pk

@pytest.mark.django_db
def test_update(auth_api):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    response = auth_api.patch(f"/api/v1/firmwares/{fw.pk}/", {"version": "2.0.0"})
    assert response.status_code == 200
    assert response.data["version"] == "2.0.0"

@pytest.mark.django_db
def test_destroy(auth_api):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    response = auth_api.delete(f"/api/v1/firmwares/{fw.pk}/")
    assert response.status_code == 204
```

### Testing Custom Actions

```python
@pytest.mark.django_db
def test_custom_action_approve(auth_api):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(status="pending")
    response = auth_api.post(f"/api/v1/firmwares/{fw.pk}/approve/")
    assert response.status_code == 200
    fw.refresh_from_db()
    assert fw.status == "approved"
```

### Testing 404 on Missing Object

```python
@pytest.mark.django_db
def test_retrieve_404(auth_api):
    response = auth_api.get("/api/v1/firmwares/99999/")
    assert response.status_code == 404
```

### Testing Method Not Allowed

```python
@pytest.mark.django_db
def test_method_not_allowed(auth_api):
    response = auth_api.put("/api/v1/firmwares/")  # PUT on list endpoint
    assert response.status_code == 405
```

## Red Flags

- Testing ViewSet without authentication — gets false 200s or missed 401s
- Not testing both list and detail endpoints — different permission paths
- Missing 404 test for retrieve/update/destroy
- Not using `format="json"` for POST with nested data

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
