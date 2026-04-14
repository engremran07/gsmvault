---
name: test-template-rendering
description: "Template rendering tests: assertTemplateUsed, context data. Use when: verifying correct template is rendered, template inheritance works, includes resolve."
---

# Template Rendering Tests

## When to Use

- Verifying the correct template is rendered for a view
- Testing template inheritance chain
- Checking `{% include %}` components render
- Testing template context variables

## Rules

### Testing Template Used

```python
import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_correct_template(client):
    response = client.get(reverse("firmwares:list"))
    assert response.status_code == 200
    templates = [t.name for t in response.templates]
    assert "firmwares/list.html" in templates

@pytest.mark.django_db
def test_base_template_chain(client):
    response = client.get(reverse("firmwares:list"))
    templates = [t.name for t in response.templates]
    assert "base/base.html" in templates  # Inherits from base
```

### Testing Template Output

```python
@pytest.mark.django_db
def test_template_renders_data(client):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(version="3.2.1")
    response = client.get(reverse("firmwares:detail", kwargs={"pk": fw.pk}))
    assert b"3.2.1" in response.content

@pytest.mark.django_db
def test_template_renders_empty_state(client):
    response = client.get(reverse("firmwares:list"))
    assert response.status_code == 200
    # Should show empty state component
    content = response.content.decode()
    assert "No firmware" in content or "empty" in content.lower()
```

### Testing Template with render_to_string

```python
from django.template.loader import render_to_string

def test_component_renders():
    html = render_to_string("components/_badge.html", {"text": "Active", "variant": "success"})
    assert "Active" in html
    assert "badge" in html.lower() or "bg-" in html

def test_admin_kpi_card():
    html = render_to_string("components/_admin_kpi_card.html", {
        "title": "Downloads",
        "value": "1,234",
        "icon": "download",
    })
    assert "Downloads" in html
    assert "1,234" in html
```

### Testing Template Tags

```python
@pytest.mark.django_db
def test_csrf_token_in_form(client):
    from tests.factories import UserFactory
    client.force_login(UserFactory(is_staff=True))
    response = client.get(reverse("firmwares:create"))
    assert b"csrfmiddlewaretoken" in response.content

@pytest.mark.django_db
def test_static_tag_renders(client):
    response = client.get(reverse("firmwares:list"))
    content = response.content.decode()
    assert "/static/" in content or "cdn" in content.lower()
```

### Testing Error Templates

```python
@pytest.mark.django_db
def test_404_template(client):
    response = client.get("/nonexistent-12345/")
    assert response.status_code == 404
```

## Red Flags

- Not testing template inheritance — broken base template breaks everything
- Only testing HTTP status, not template content — misses rendering errors
- Testing templates without data — should test with realistic fixtures
- Missing empty state tests — lists with no data should render cleanly

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
