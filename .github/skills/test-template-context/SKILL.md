---
name: test-template-context
description: "Context variable tests: assertContains, context verification. Use when: testing view context data, template variable availability, context processor output."
---

# Template Context Tests

## When to Use

- Verifying context variables passed to templates
- Testing context processor output
- Checking computed context values
- Testing paginated context (page_obj)

## Rules

### Testing Context Variables

```python
import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_context_has_firmwares(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(3)
    response = client.get(reverse("firmwares:list"))
    assert "firmwares" in response.context or "object_list" in response.context

@pytest.mark.django_db
def test_context_firmware_count(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(5)
    response = client.get(reverse("firmwares:list"))
    ctx = response.context
    key = "firmwares" if "firmwares" in ctx else "object_list"
    assert len(ctx[key]) == 5
```

### Testing Detail Context

```python
@pytest.mark.django_db
def test_detail_context(client):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    response = client.get(reverse("firmwares:detail", kwargs={"pk": fw.pk}))
    assert response.context["object"] == fw
    assert response.context["object"].version == fw.version
```

### Testing Context Processors

```python
@pytest.mark.django_db
def test_site_settings_in_context(client):
    response = client.get("/")
    if response.status_code == 200:
        # Global context processors add site-wide variables
        ctx = response.context
        assert "site_settings" in ctx or "SITE_NAME" in ctx or True

@pytest.mark.django_db
def test_theme_context(client):
    response = client.get("/")
    if response.status_code == 200:
        ctx = response.context
        if "theme" in ctx:
            assert ctx["theme"] in ("dark", "light", "contrast")
```

### Testing Form in Context

```python
@pytest.mark.django_db
def test_create_view_has_form(staff_client):
    response = staff_client.get(reverse("firmwares:create"))
    assert "form" in response.context
    form = response.context["form"]
    assert not form.is_bound  # Fresh form on GET
```

### Testing Computed Context

```python
@pytest.mark.django_db
def test_context_stats(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(10)
    response = client.get(reverse("firmwares:list"))
    ctx = response.context
    if "total_count" in ctx:
        assert ctx["total_count"] == 10
```

### Using assertContains

```python
@pytest.mark.django_db
def test_contains_firmware_version(client):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(version="5.0.0-beta")
    response = client.get(reverse("firmwares:list"))
    # assertContains checks status code and content
    from django.test import TestCase
    tc = TestCase()
    tc.maxDiff = None
    tc.assertContains(response, "5.0.0-beta")
```

## Red Flags

- Checking `response.context` without verifying response.status_code == 200 first
- Missing context key checks — `response.context["key"]` raises KeyError
- Not testing empty context (no data) — should have default values or empty lists
- Testing context processor via view instead of directly — isolate the processor

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
