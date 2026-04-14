---
name: test-api-filtering
description: "Filter tests: query params, search, ordering. Use when: testing django-filter integration, SearchFilter, OrderingFilter on DRF endpoints."
---

# API Filtering Tests

## When to Use

- Testing query parameter filtering on list endpoints
- Verifying search functionality
- Testing ordering/sort parameters
- Testing filter combinations

## Rules

### Testing Query Param Filters

```python
import pytest

@pytest.mark.django_db
def test_filter_by_status(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory(status="active")
    FirmwareFactory(status="draft")
    response = auth_api.get("/api/v1/firmwares/", {"status": "active"})
    assert response.status_code == 200
    assert all(r["status"] == "active" for r in response.data["results"])

@pytest.mark.django_db
def test_filter_by_brand(auth_api):
    from tests.factories import FirmwareFactory, BrandFactory
    brand = BrandFactory(name="Samsung")
    FirmwareFactory(model__brand=brand)
    FirmwareFactory()  # Different brand
    response = auth_api.get("/api/v1/firmwares/", {"brand": brand.pk})
    assert len(response.data["results"]) == 1
```

### Testing Search

```python
@pytest.mark.django_db
def test_search_by_name(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="Galaxy-S24-Update")
    FirmwareFactory(version="Pixel-9-Patch")
    response = auth_api.get("/api/v1/firmwares/", {"search": "Galaxy"})
    assert len(response.data["results"]) == 1
    assert "Galaxy" in response.data["results"][0]["version"]

@pytest.mark.django_db
def test_search_no_results(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="TestFirmware")
    response = auth_api.get("/api/v1/firmwares/", {"search": "nonexistent"})
    assert len(response.data["results"]) == 0
```

### Testing Ordering

```python
@pytest.mark.django_db
def test_ordering_ascending(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="b-version")
    FirmwareFactory(version="a-version")
    response = auth_api.get("/api/v1/firmwares/", {"ordering": "version"})
    versions = [r["version"] for r in response.data["results"]]
    assert versions == sorted(versions)

@pytest.mark.django_db
def test_ordering_descending(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="a-version")
    FirmwareFactory(version="b-version")
    response = auth_api.get("/api/v1/firmwares/", {"ordering": "-version"})
    versions = [r["version"] for r in response.data["results"]]
    assert versions == sorted(versions, reverse=True)
```

### Testing Filter Combinations

```python
@pytest.mark.django_db
def test_combined_filters(auth_api):
    from tests.factories import FirmwareFactory
    FirmwareFactory(status="active", version="Samsung-v1")
    FirmwareFactory(status="draft", version="Samsung-v2")
    FirmwareFactory(status="active", version="Pixel-v1")
    response = auth_api.get("/api/v1/firmwares/", {
        "status": "active",
        "search": "Samsung",
    })
    assert len(response.data["results"]) == 1
```

## Red Flags

- Not testing empty filter results — should return empty list, not error
- Missing test for invalid filter values — should return 200 with no results or 400
- Not testing ordering with `ordering` param — just relying on default
- Testing filters only with one record — use multiple to verify filtering works

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
