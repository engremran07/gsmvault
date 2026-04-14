---
name: test-api-pagination
description: "API pagination tests: cursor, next/previous, count. Use when: testing DRF pagination responses, page size, cursor-based navigation, link headers."
---

# API Pagination Tests

## When to Use

- Testing paginated API list responses
- Verifying `next`/`previous` links in response
- Testing page size limits
- Cursor-based pagination validation

## Rules

### Testing Default Pagination

```python
import pytest
from rest_framework.test import APIClient

@pytest.mark.django_db
def test_api_pagination_response(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(25)
    response = auth_api.get("/api/v1/firmwares/")
    assert response.status_code == 200
    assert "results" in response.data
    assert "count" in response.data or "next" in response.data
    assert len(response.data["results"]) <= 20

@pytest.mark.django_db
def test_api_pagination_has_next(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(25)
    response = auth_api.get("/api/v1/firmwares/")
    assert response.data["next"] is not None

@pytest.mark.django_db
def test_api_last_page_no_next(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(5)
    response = auth_api.get("/api/v1/firmwares/")
    assert response.data["next"] is None
```

### Testing Page Size Parameter

```python
@pytest.mark.django_db
def test_custom_page_size(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(10)
    response = auth_api.get("/api/v1/firmwares/", {"page_size": 5})
    assert len(response.data["results"]) == 5
```

### Testing Cursor Pagination

```python
@pytest.mark.django_db
def test_cursor_pagination(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(25)
    response = auth_api.get("/api/v1/firmwares/")
    assert response.status_code == 200
    next_url = response.data.get("next")
    if next_url:
        response2 = auth_api.get(next_url)
        assert response2.status_code == 200
        # Results should be different
        ids1 = {r["id"] for r in response.data["results"]}
        ids2 = {r["id"] for r in response2.data["results"]}
        assert ids1.isdisjoint(ids2)
```

### Testing Total Count

```python
@pytest.mark.django_db
def test_pagination_count(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(15)
    response = auth_api.get("/api/v1/firmwares/")
    if "count" in response.data:
        assert response.data["count"] == 15
```

### Testing Empty Results

```python
@pytest.mark.django_db
def test_empty_pagination(auth_api):
    response = auth_api.get("/api/v1/firmwares/")
    assert response.status_code == 200
    assert response.data["results"] == []
```

## Red Flags

- Not testing empty results — pagination should handle zero items
- Assuming `count` exists — cursor pagination doesn't include it
- Not following `next` link to verify it works — broken pagination links
- Hardcoding page sizes in assertions — check against settings

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
