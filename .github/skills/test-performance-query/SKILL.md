---
name: test-performance-query
description: "Query performance tests: assertNumQueries, query count limits. Use when: detecting N+1 queries, verifying select_related/prefetch_related, query budget enforcement."
---

# Query Performance Tests

## When to Use

- Detecting N+1 query problems
- Verifying `select_related`/`prefetch_related` usage
- Setting query count budgets for views
- Testing QuerySet optimization

## Rules

### Using assertNumQueries

```python
import pytest
from django.test.utils import override_settings

@pytest.mark.django_db
def test_list_view_query_count(client, django_assert_num_queries):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(10)
    with django_assert_num_queries(3):  # 1 count + 1 list + 1 related
        response = client.get("/firmwares/")
        assert response.status_code == 200
```

### Detecting N+1 Queries

```python
@pytest.mark.django_db
def test_no_n_plus_one(client, django_assert_num_queries):
    from tests.factories import FirmwareFactory
    # Create 50 firmwares with related brands
    FirmwareFactory.create_batch(50)
    with django_assert_num_queries(lambda n: n < 10):
        response = client.get("/firmwares/")
        assert response.status_code == 200
    # Without select_related, this would be 50+ queries

@pytest.mark.django_db
def test_detail_view_constant_queries(client, django_assert_num_queries):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    with django_assert_num_queries(lambda n: n <= 5):
        response = client.get(f"/firmwares/{fw.pk}/")
        assert response.status_code in (200, 302)
```

### Testing QuerySet Optimization

```python
@pytest.mark.django_db
def test_select_related_used():
    from apps.firmwares.models import Firmware
    from django.test.utils import CaptureQueriesContext
    from django.db import connection
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(5)

    with CaptureQueriesContext(connection) as ctx:
        list(Firmware.objects.select_related("brand", "model").all())

    # Should be 1 query with JOINs, not 1 + N
    assert len(ctx.captured_queries) == 1

@pytest.mark.django_db
def test_prefetch_related_used():
    from apps.firmwares.models import Firmware
    from django.test.utils import CaptureQueriesContext
    from django.db import connection
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(5)

    with CaptureQueriesContext(connection) as ctx:
        list(Firmware.objects.prefetch_related("tags").all())

    assert len(ctx.captured_queries) <= 2  # 1 main + 1 prefetch
```

### Testing API Query Count

```python
from rest_framework.test import APIClient

@pytest.mark.django_db
def test_api_list_queries(django_assert_num_queries):
    from tests.factories import UserFactory, FirmwareFactory
    api_client = APIClient()
    api_client.force_authenticate(UserFactory())
    FirmwareFactory.create_batch(20)

    with django_assert_num_queries(lambda n: n < 8):
        response = api_client.get("/api/v1/firmwares/")
        assert response.status_code == 200
```

### Setting Query Budgets

```python
QUERY_BUDGETS = {
    "/firmwares/": 5,
    "/api/v1/firmwares/": 8,
    "/blog/": 6,
}

@pytest.mark.django_db
@pytest.mark.parametrize("url,max_queries", list(QUERY_BUDGETS.items()))
def test_query_budget(client, url, max_queries, django_assert_num_queries):
    with django_assert_num_queries(lambda n: n <= max_queries):
        client.get(url)
```

## Red Flags

- No query count assertions — N+1 bugs silently hit production
- Hard-coding exact query count — breaks on schema changes, use `<=` threshold
- Not testing with realistic data volume — N+1 only visible with many records
- Missing `select_related`/`prefetch_related` — every FK access is a query

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
