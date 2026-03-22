---
name: testing
description: "Testing patterns with pytest, factory_boy, DRF API tests. Use when: writing unit tests, integration tests, API tests, model tests, view tests, template tests."
---

# Testing Skill

## Pytest Configuration

Root `conftest.py` at `d:\GSMFWs\conftest.py` configures Django settings:

```python
import pytest

# pytest.ini or pyproject.toml sets:
# [tool.pytest.ini_options]
# DJANGO_SETTINGS_MODULE = "app.settings_dev"
# python_files = ["tests.py", "test_*.py"]
# python_classes = ["Test*"]
# python_functions = ["test_*"]
```

All tests that touch the database must be decorated:

```python
@pytest.mark.django_db
def test_my_model():
    ...
```

Or use the class decorator for all methods:

```python
@pytest.mark.django_db
class TestMyModel:
    def test_create(self):
        ...
    def test_str(self):
        ...
```

Run tests:

```powershell
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing
& .\.venv\Scripts\python.exe -m pytest apps/firmwares/tests.py -v
& .\.venv\Scripts\python.exe -m pytest -k "test_firmware_download"
```

---

## Factory Pattern

Use `factory_boy` to create test fixtures. Each app has factories in its test file or a dedicated `tests/factories.py`.

```python
import factory
from apps.users.models import User
from apps.firmwares.models import Firmware
from apps.devices.models import Device

class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f"user_{n}")
    email = factory.LazyAttribute(lambda o: f"{o.username}@example.com")
    is_active = True

class DeviceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Device

    brand = factory.Faker("company")
    model = factory.Faker("word")
    is_active = True

class FirmwareFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Firmware

    device = factory.SubFactory(DeviceFactory)
    version = factory.Sequence(lambda n: f"1.0.{n}")
    is_active = True
```

Usage in tests:

```python
@pytest.mark.django_db
def test_firmware_str():
    fw = FirmwareFactory(version="2.0.1")
    assert "2.0.1" in str(fw)

@pytest.mark.django_db
def test_batch_create():
    firmwares = FirmwareFactory.create_batch(5)
    assert len(firmwares) == 5
```

---

## API Test Pattern

Use DRF's `APIClient` for API endpoint tests:

```python
import pytest
from rest_framework.test import APIClient
from rest_framework import status

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def authenticated_client(api_client):
    user = UserFactory()
    api_client.force_authenticate(user=user)
    return api_client, user

@pytest.mark.django_db
class TestFirmwareAPI:
    def test_list_firmwares(self, authenticated_client):
        client, user = authenticated_client
        FirmwareFactory.create_batch(3)
        response = client.get("/api/v1/firmwares/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 3

    def test_list_requires_auth(self, api_client):
        response = api_client.get("/api/v1/firmwares/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_create_firmware(self, authenticated_client):
        client, user = authenticated_client
        device = DeviceFactory()
        data = {"device": device.pk, "version": "1.0.0"}
        response = client.post("/api/v1/firmwares/", data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["version"] == "1.0.0"

    def test_filter_by_device(self, authenticated_client):
        client, user = authenticated_client
        device = DeviceFactory()
        FirmwareFactory.create_batch(2, device=device)
        FirmwareFactory()  # different device
        response = client.get(f"/api/v1/firmwares/?device={device.pk}")
        assert len(response.data["results"]) == 2
```

---

## Model Tests

Verify model behavior — `__str__`, `Meta.ordering`, `related_name`, field defaults:

```python
@pytest.mark.django_db
class TestDeviceModel:
    def test_str(self):
        device = DeviceFactory(brand="Samsung", model="Galaxy S24")
        assert str(device) == "Samsung Galaxy S24"  # or whatever __str__ returns

    def test_ordering(self):
        DeviceFactory(brand="Xiaomi")
        DeviceFactory(brand="Apple")
        devices = list(Device.objects.values_list("brand", flat=True))
        assert devices == sorted(devices)  # verify Meta.ordering

    def test_related_name(self):
        device = DeviceFactory()
        FirmwareFactory(device=device)
        # Verify related_name works
        assert device.firmwares_device.count() == 1  # or whatever the related_name is

    def test_field_defaults(self):
        device = DeviceFactory()
        assert device.is_active is True  # verify default value

    def test_unique_constraint(self):
        DeviceFactory(brand="Samsung", model="A55")
        with pytest.raises(Exception):  # IntegrityError
            DeviceFactory(brand="Samsung", model="A55")
```

---

## View Tests

Test both full page and HTMX fragment responses:

```python
import pytest
from django.test import Client, RequestFactory

@pytest.fixture
def client():
    return Client()

@pytest.mark.django_db
class TestFirmwareListView:
    def test_full_page(self, client):
        """Full page load returns complete HTML with base template."""
        response = client.get("/firmwares/")
        assert response.status_code == 200
        assert "base/_base.html" in [t.name for t in response.templates]

    def test_htmx_fragment(self, client):
        """HTMX request returns only the fragment, not the full page."""
        response = client.get(
            "/firmwares/",
            HTTP_HX_REQUEST="true",
        )
        assert response.status_code == 200
        # Fragment template should be used, not full page
        template_names = [t.name for t in response.templates]
        assert "firmwares/fragments/list.html" in template_names
        assert "base/_base.html" not in template_names

    def test_context_data(self, client):
        """View passes expected context variables."""
        FirmwareFactory.create_batch(3)
        response = client.get("/firmwares/")
        assert "firmwares" in response.context
        assert len(response.context["firmwares"]) == 3
```

Using `RequestFactory` for isolated view unit tests:

```python
from django.test import RequestFactory

@pytest.mark.django_db
def test_view_with_request_factory():
    factory = RequestFactory()
    request = factory.get("/firmwares/")
    request.user = UserFactory()
    response = firmware_list(request)
    assert response.status_code == 200
```

---

## Template Tests

Verify template rendering, inheritance, and content:

```python
@pytest.mark.django_db
class TestTemplateRendering:
    def test_template_used(self, client):
        response = client.get("/firmwares/")
        assert response.status_code == 200
        # assertTemplateUsed checks template inheritance chain
        self.assertTemplateUsed(response, "firmwares/list.html")
        self.assertTemplateUsed(response, "layouts/default.html")
        self.assertTemplateUsed(response, "base/_base.html")

    def test_contains_expected_content(self, client):
        fw = FirmwareFactory(version="3.0.0")
        response = client.get("/firmwares/")
        assert b"3.0.0" in response.content

    def test_does_not_contain(self, client):
        response = client.get("/firmwares/")
        assert b"secret_admin_data" not in response.content

    def test_context_processor(self, client):
        """Verify context processors inject expected variables."""
        response = client.get("/firmwares/")
        assert "site_settings" in response.context
```

Using pytest-django's `assertTemplateUsed`:

```python
@pytest.mark.django_db
def test_template_chain(client):
    response = client.get("/firmwares/")
    # Check the full template inheritance chain
    templates = [t.name for t in response.templates]
    assert "firmwares/list.html" in templates
    assert "layouts/default.html" in templates
```
