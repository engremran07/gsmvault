---
applyTo: 'apps/*/tests*.py, tests/**'
---

# Testing Instructions

## Framework & Tools

- **pytest** as the test runner (not Django's `manage.py test`)
- **factory_boy** for test data creation — never create models manually in tests
- **pytest-django** for Django integration (`@pytest.mark.django_db`)
- **DRF `APIClient`** for API endpoint tests
- Configuration in `pyproject.toml` and root `conftest.py`

## Running Tests

```powershell
# All tests
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing

# Single app
& .\.venv\Scripts\python.exe -m pytest apps/firmwares/tests/

# Single test file
& .\.venv\Scripts\python.exe -m pytest apps/firmwares/tests/test_services.py

# Single test function
& .\.venv\Scripts\python.exe -m pytest apps/firmwares/tests/test_services.py::test_create_download_token

# With verbose output
& .\.venv\Scripts\python.exe -m pytest -v --tb=short
```

## Coverage Targets

| Layer | Target |
|---|---|
| Service functions | 80%+ |
| Views | 60%+ |
| Models (clean/save) | 70%+ |
| API endpoints | 70%+ |
| Template tags/filters | 80%+ |
| Management commands | 60%+ |

## Test File Organization

```
apps/<app_name>/
  tests/
    __init__.py
    conftest.py          # App-level fixtures and factories
    test_models.py       # Model validation, constraints, __str__
    test_services.py     # Service layer business logic
    test_views.py        # View responses, templates, redirects
    test_api.py          # DRF endpoint tests
    test_tasks.py        # Celery task tests
```

Or for smaller apps, a single `tests.py` file is acceptable.

## Factory Pattern

```python
import factory
from apps.users.models import User
from apps.firmwares.models import Brand, FirmwareFile


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f"user_{n}")
    email = factory.LazyAttribute(lambda obj: f"{obj.username}@example.com")
    is_active = True


class BrandFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Brand

    name = factory.Sequence(lambda n: f"Brand {n}")
    slug = factory.LazyAttribute(lambda obj: obj.name.lower().replace(" ", "-"))


class FirmwareFileFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = FirmwareFile

    brand = factory.SubFactory(BrandFactory)
    file_type = "official"
```

Place factories in `conftest.py` or a dedicated `factories.py` within the test directory.

## Database Access

Always mark tests that need the database:

```python
import pytest

@pytest.mark.django_db
def test_create_user():
    user = UserFactory()
    assert user.pk is not None

@pytest.mark.django_db(transaction=True)
def test_concurrent_wallet_debit():
    # Tests requiring transaction control
    pass
```

## Service Layer Testing — Primary Focus

Test service functions directly — they contain the business logic:

```python
@pytest.mark.django_db
def test_create_download_token_sets_expiry():
    user = UserFactory()
    firmware = FirmwareFileFactory()
    token = create_download_token(user=user, firmware=firmware)
    assert token.status == "active"
    assert token.expires_at is not None

@pytest.mark.django_db
def test_create_download_token_respects_quota():
    user = UserFactory()
    # Exhaust quota
    for _ in range(user.quota_tier.daily_limit):
        create_download_token(user=user, firmware=FirmwareFileFactory())
    with pytest.raises(QuotaExceededError):
        create_download_token(user=user, firmware=FirmwareFileFactory())
```

## API Endpoint Testing

```python
from rest_framework.test import APIClient
import pytest

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def authenticated_client(api_client):
    user = UserFactory()
    api_client.force_authenticate(user=user)
    return api_client, user

@pytest.mark.django_db
def test_firmware_list_returns_200(authenticated_client):
    client, user = authenticated_client
    response = client.get("/api/v1/firmwares/")
    assert response.status_code == 200

@pytest.mark.django_db
def test_firmware_list_unauthenticated_returns_401(api_client):
    response = api_client.get("/api/v1/firmwares/")
    assert response.status_code == 401
```

## Query Performance Testing

Use `assertNumQueries` or `django_assert_num_queries` to prevent N+1 regressions:

```python
@pytest.mark.django_db
def test_firmware_list_query_count(django_assert_num_queries, authenticated_client):
    client, _ = authenticated_client
    FirmwareFileFactory.create_batch(10)
    with django_assert_num_queries(3):  # auth + count + list
        client.get("/api/v1/firmwares/")
```

## View Testing

Test views for correct template, status code, and context — NOT internal logic:

```python
from django.test import Client

@pytest.mark.django_db
def test_firmware_detail_uses_correct_template(client):
    fw = FirmwareFileFactory()
    response = client.get(f"/firmwares/{fw.pk}/")
    assert response.status_code == 200
    assert "firmwares/detail.html" in [t.name for t in response.templates]

@pytest.mark.django_db
def test_admin_view_requires_staff(client):
    response = client.get("/admin-panel/firmwares/")
    assert response.status_code == 302  # Redirect to login
```

## HTMX View Testing

```python
@pytest.mark.django_db
def test_htmx_request_returns_fragment(client):
    response = client.get("/firmwares/search/", HTTP_HX_REQUEST="true")
    assert response.status_code == 200
    # Fragment should NOT extend base template
    assert "<!DOCTYPE" not in response.content.decode()
```

## Fixtures in conftest.py

Shared fixtures go in the appropriate `conftest.py`:

```python
# Root conftest.py — available to ALL tests
@pytest.fixture
def admin_user():
    return UserFactory(is_staff=True, is_superuser=True)

# apps/firmwares/tests/conftest.py — available to firmware tests
@pytest.fixture
def sample_firmware():
    return FirmwareFileFactory(file_type="official")
```

## What NOT to Test

- Django internals (ORM, middleware, template engine)
- Third-party library functionality
- Private methods (test via public API)
- Exact HTML output (test for key elements, not markup structure)
