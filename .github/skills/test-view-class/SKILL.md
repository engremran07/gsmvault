---
name: test-view-class
description: "Class-based view tests: setup, assertions, template verification. Use when: testing CBVs (ListView, DetailView, CreateView), testing get/post methods."
---

# Class-Based View Tests

## When to Use

- Testing ListView, DetailView, CreateView, UpdateView, DeleteView
- Verifying CBV method overrides (get_queryset, get_context_data)
- Testing form handling in CBVs

## Rules

### Testing ListView

```python
import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_firmware_list_view(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(5)
    url = reverse("firmwares:list")
    response = client.get(url)
    assert response.status_code == 200
    assert len(response.context["object_list"]) == 5

@pytest.mark.django_db
def test_firmware_list_only_active(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory(is_active=True)
    FirmwareFactory(is_active=False)
    response = client.get(reverse("firmwares:list"))
    assert len(response.context["object_list"]) == 1
```

### Testing DetailView

```python
@pytest.mark.django_db
def test_firmware_detail_view(client):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    response = client.get(reverse("firmwares:detail", kwargs={"pk": fw.pk}))
    assert response.status_code == 200
    assert response.context["object"] == fw

@pytest.mark.django_db
def test_firmware_detail_404(client):
    response = client.get(reverse("firmwares:detail", kwargs={"pk": 99999}))
    assert response.status_code == 404
```

### Testing CreateView

```python
@pytest.mark.django_db
def test_create_view_get(staff_client):
    response = staff_client.get(reverse("firmwares:create"))
    assert response.status_code == 200
    assert "form" in response.context

@pytest.mark.django_db
def test_create_view_post(staff_client):
    from apps.firmwares.models import Firmware
    data = {"version": "1.0.0", "build_number": "100"}
    response = staff_client.post(reverse("firmwares:create"), data=data)
    assert response.status_code == 302  # Redirect on success
    assert Firmware.objects.filter(version="1.0.0").exists()
```

### Testing with setup_method Pattern

```python
@pytest.mark.django_db
class TestFirmwareUpdateView:
    @pytest.fixture(autouse=True)
    def setup(self, client, db):
        from tests.factories import FirmwareFactory, UserFactory
        self.user = UserFactory(is_staff=True)
        self.firmware = FirmwareFactory()
        client.force_login(self.user)
        self.client = client

    def test_get_form(self):
        url = reverse("firmwares:update", kwargs={"pk": self.firmware.pk})
        response = self.client.get(url)
        assert response.status_code == 200

    def test_post_update(self):
        url = reverse("firmwares:update", kwargs={"pk": self.firmware.pk})
        response = self.client.post(url, {"version": "2.0.0"})
        assert response.status_code == 302
```

## Red Flags

- Testing CBV by instantiating the class directly — use Client or RequestFactory
- Not testing both GET and POST for form views
- Missing 404 test for detail views
- Not testing `get_queryset` filtering via response assertions

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
