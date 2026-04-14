---
name: test-view-function
description: "Function-based view tests: RequestFactory, assertContains, status codes. Use when: testing FBV responses, template rendering, context data, redirects."
---

# Function-Based View Tests

## When to Use

- Testing FBV response status codes
- Verifying template rendering and context
- Testing redirects after form submission
- Checking response content

## Rules

### Basic View Test with Client

```python
import pytest

@pytest.mark.django_db
def test_firmware_list_200(client):
    response = client.get("/firmwares/")
    assert response.status_code == 200

@pytest.mark.django_db
def test_firmware_list_template(client):
    response = client.get("/firmwares/")
    assert "firmwares/list.html" in [t.name for t in response.templates]
```

### Using RequestFactory for Unit Tests

```python
from django.test import RequestFactory

@pytest.mark.django_db
def test_firmware_detail_view():
    from apps.firmwares.views import firmware_detail
    from tests.factories import FirmwareFactory, UserFactory
    fw = FirmwareFactory()
    user = UserFactory()
    factory = RequestFactory()
    request = factory.get(f"/firmwares/{fw.pk}/")
    request.user = user
    response = firmware_detail(request, pk=fw.pk)
    assert response.status_code == 200
```

### Testing Context Data

```python
@pytest.mark.django_db
def test_firmware_list_context(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(3)
    response = client.get("/firmwares/")
    assert "firmwares" in response.context
    assert len(response.context["firmwares"]) == 3
```

### Testing Redirects

```python
@pytest.mark.django_db
def test_login_redirect(client):
    response = client.get("/admin/dashboard/")
    assert response.status_code == 302
    assert "/login/" in response.url
```

### Testing Response Content

```python
@pytest.mark.django_db
def test_firmware_name_in_response(client):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(version="3.2.1")
    response = client.get(f"/firmwares/{fw.pk}/")
    assert b"3.2.1" in response.content
```

### Testing with URL Reverse

```python
from django.urls import reverse

@pytest.mark.django_db
def test_firmware_list_by_name(client):
    url = reverse("firmwares:list")
    response = client.get(url)
    assert response.status_code == 200
```

## Red Flags

- Using `Client` when `RequestFactory` is sufficient — Client runs full middleware
- Not testing both GET and POST on form views
- Hardcoding URLs instead of `reverse()` — breaks on URL changes
- Missing authentication setup for protected views

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
