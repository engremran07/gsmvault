---
name: test-view-htmx
description: "HTMX view tests: HX-Request header, fragment response verification. Use when: testing HTMX partial responses, fragment templates, HX-Trigger headers."
---

# HTMX View Tests

## When to Use

- Testing views that return different responses for HTMX vs full-page requests
- Verifying fragment templates are used (not full base template)
- Testing HX-Trigger, HX-Redirect response headers
- Testing HTMX swap behavior

## Rules

### Testing HTMX Detection

```python
import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_htmx_returns_fragment(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(3)
    url = reverse("firmwares:list")
    response = client.get(url, HTTP_HX_REQUEST="true")
    assert response.status_code == 200
    templates = [t.name for t in response.templates]
    assert "firmwares/fragments/list.html" in templates
    assert "base/base.html" not in templates  # Fragment, not full page

@pytest.mark.django_db
def test_non_htmx_returns_full_page(client):
    url = reverse("firmwares:list")
    response = client.get(url)
    templates = [t.name for t in response.templates]
    assert "firmwares/list.html" in templates
```

### Testing HX-Trigger Header

```python
@pytest.mark.django_db
def test_htmx_delete_triggers_refresh(staff_client):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    url = reverse("firmwares:delete", kwargs={"pk": fw.pk})
    response = staff_client.delete(url, HTTP_HX_REQUEST="true")
    assert response.status_code == 200
    assert "firmwareListChanged" in response.get("HX-Trigger", "")
```

### Testing HTMX Search

```python
@pytest.mark.django_db
def test_htmx_search(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="1.0.0")
    FirmwareFactory(version="2.0.0")
    url = reverse("firmwares:search")
    response = client.get(url, {"q": "1.0"}, HTTP_HX_REQUEST="true")
    assert response.status_code == 200
    assert b"1.0.0" in response.content
    assert b"2.0.0" not in response.content
```

### Testing HTMX Form Submission

```python
@pytest.mark.django_db
def test_htmx_form_submit(staff_client):
    url = reverse("firmwares:create")
    data = {"version": "1.0.0", "build_number": "100"}
    response = staff_client.post(
        url, data=data, HTTP_HX_REQUEST="true",
    )
    # HTMX form may return fragment or HX-Redirect
    assert response.status_code in (200, 204)

@pytest.mark.django_db
def test_htmx_form_validation_error(staff_client):
    url = reverse("firmwares:create")
    response = staff_client.post(
        url, data={}, HTTP_HX_REQUEST="true",
    )
    assert response.status_code == 200  # Re-render form with errors
    assert b"error" in response.content.lower() or b"required" in response.content.lower()
```

### HTMX Request Helper Fixture

```python
@pytest.fixture
def htmx_client(client):
    """Client that always sends HX-Request header."""
    original_get = client.get
    original_post = client.post
    def htmx_get(url, *args, **kwargs):
        kwargs.setdefault("HTTP_HX_REQUEST", "true")
        return original_get(url, *args, **kwargs)
    def htmx_post(url, *args, **kwargs):
        kwargs.setdefault("HTTP_HX_REQUEST", "true")
        return original_post(url, *args, **kwargs)
    client.get = htmx_get
    client.post = htmx_post
    return client
```

## Red Flags

- Not testing both HTMX and non-HTMX paths — dual behavior must have dual tests
- Fragment templates using `{% extends %}` — HTMX fragments must be standalone
- Missing HX-Request header in test — gets full page instead of fragment
- Not checking HX-Trigger headers on mutation responses

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
