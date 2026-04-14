---
name: test-view-pagination
description: "Pagination tests: page_obj, page count, boundary conditions. Use when: testing paginated list views, page navigation, empty pages, out-of-range pages."
---

# Pagination Tests

## When to Use

- Testing paginated list views return correct page sizes
- Verifying page navigation (next/previous)
- Testing boundary conditions (empty, last page, out-of-range)

## Rules

### Basic Pagination Test

```python
import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_pagination_default_page(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(25)  # More than one page
    response = client.get(reverse("firmwares:list"))
    assert response.status_code == 200
    page_obj = response.context["page_obj"]
    assert page_obj.number == 1
    assert len(page_obj.object_list) <= 20  # Default page size
```

### Testing Page Navigation

```python
@pytest.mark.django_db
def test_second_page(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(25)
    response = client.get(reverse("firmwares:list"), {"page": 2})
    page_obj = response.context["page_obj"]
    assert page_obj.number == 2
    assert page_obj.has_previous()
```

### Boundary Conditions

```python
@pytest.mark.django_db
def test_empty_list(client):
    response = client.get(reverse("firmwares:list"))
    assert response.status_code == 200
    page_obj = response.context["page_obj"]
    assert len(page_obj.object_list) == 0

@pytest.mark.django_db
def test_last_page(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(25)
    response = client.get(reverse("firmwares:list"), {"page": 2})
    page_obj = response.context["page_obj"]
    assert not page_obj.has_next()

@pytest.mark.django_db
def test_out_of_range_page(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(5)
    response = client.get(reverse("firmwares:list"), {"page": 999})
    assert response.status_code == 404  # Or last page, depending on view

@pytest.mark.django_db
def test_invalid_page_param(client):
    response = client.get(reverse("firmwares:list"), {"page": "abc"})
    assert response.status_code in (200, 404)  # Depends on error handling
```

### Testing Page Size

```python
@pytest.mark.django_db
def test_exact_page_size(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(20)  # Exactly one page
    response = client.get(reverse("firmwares:list"))
    page_obj = response.context["page_obj"]
    assert len(page_obj.object_list) == 20
    assert not page_obj.has_next()
    assert page_obj.paginator.num_pages == 1
```

## Red Flags

- Not testing empty state — pagination with 0 items should still work
- Missing out-of-range test — `page=999` should return 404 or last page
- Not testing `has_next()`/`has_previous()` — template navigation depends on these
- Testing pagination in isolation without the view — misses integration issues

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
