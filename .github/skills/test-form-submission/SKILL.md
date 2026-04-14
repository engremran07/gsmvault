---
name: test-form-submission
description: "Form submission tests: POST data, redirect, object creation. Use when: testing form views end-to-end, POST handling, success redirects, database state after submit."
---

# Form Submission Tests

## When to Use

- Testing form POST → object creation → redirect flow
- Verifying database state after form submission
- Testing form re-render with errors on invalid POST
- Testing CSRF protection on form submissions

## Rules

### Basic POST Test

```python
import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_form_post_creates_object(staff_client):
    from apps.firmwares.models import Firmware
    url = reverse("firmwares:create")
    data = {"version": "1.0.0", "build_number": "100"}
    response = staff_client.post(url, data=data)
    assert response.status_code == 302  # Redirect on success
    assert Firmware.objects.filter(version="1.0.0").exists()

@pytest.mark.django_db
def test_form_post_redirects(staff_client):
    url = reverse("firmwares:create")
    data = {"version": "1.0.0", "build_number": "100"}
    response = staff_client.post(url, data=data, follow=True)
    assert response.status_code == 200
    assert b"1.0.0" in response.content
```

### Testing Invalid POST Re-renders Form

```python
@pytest.mark.django_db
def test_invalid_post_renders_form(staff_client):
    url = reverse("firmwares:create")
    response = staff_client.post(url, data={})
    assert response.status_code == 200  # Re-renders, not redirect
    assert "form" in response.context
    assert response.context["form"].errors
```

### Testing Update Form

```python
@pytest.mark.django_db
def test_update_post(staff_client):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(version="1.0.0")
    url = reverse("firmwares:update", kwargs={"pk": fw.pk})
    response = staff_client.post(url, data={"version": "2.0.0"})
    assert response.status_code == 302
    fw.refresh_from_db()
    assert fw.version == "2.0.0"
```

### Testing Delete Confirmation

```python
@pytest.mark.django_db
def test_delete_post(staff_client):
    from tests.factories import FirmwareFactory
    from apps.firmwares.models import Firmware
    fw = FirmwareFactory()
    pk = fw.pk
    url = reverse("firmwares:delete", kwargs={"pk": pk})
    response = staff_client.post(url)
    assert response.status_code == 302
    assert not Firmware.objects.filter(pk=pk).exists()
```

### Testing File Upload Form

```python
from django.core.files.uploadedfile import SimpleUploadedFile

@pytest.mark.django_db
def test_file_upload(staff_client):
    url = reverse("firmwares:upload")
    file = SimpleUploadedFile("firmware.bin", b"\x00" * 1024, content_type="application/octet-stream")
    response = staff_client.post(url, {"file": file, "version": "1.0.0"})
    assert response.status_code == 302
```

## Red Flags

- Not using `follow=True` when testing redirect destination content
- Missing `refresh_from_db()` after update — stale object in memory
- Not testing invalid POST (empty data) — missing error-path coverage
- Forgetting `content_type` on `SimpleUploadedFile` — may bypass validation

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
