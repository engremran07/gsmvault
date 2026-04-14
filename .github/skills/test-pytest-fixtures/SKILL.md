---
name: test-pytest-fixtures
description: "Fixture patterns: scope, autouse, parameterized, shared conftest. Use when: creating reusable test data, shared setup, fixture composition."
---

# pytest Fixtures

## When to Use

- Creating reusable test data across multiple tests
- Sharing setup/teardown logic between test modules
- Composing fixtures from other fixtures

## Rules

### Fixture Scopes

```python
import pytest

@pytest.fixture(scope="function")  # Default — fresh per test
def user(db):
    from apps.users.models import User
    return User.objects.create_user(username="testuser", password="pass123")

@pytest.fixture(scope="session")  # Once per test session — no DB access
def api_url():
    return "/api/v1/firmwares/"

@pytest.fixture(scope="class")  # Shared across class methods
def firmware_data():
    return {"version": "1.0.0", "build_number": "100"}
```

### Autouse Fixtures

```python
@pytest.fixture(autouse=True)
def clear_cache():
    """Clear cache before every test automatically."""
    from django.core.cache import cache
    cache.clear()
    yield
    cache.clear()
```

### Fixture Composition

```python
@pytest.fixture
def authenticated_client(db, client):
    from apps.users.models import User
    user = User.objects.create_user(username="auth", password="pass123")
    client.login(username="auth", password="pass123")
    return client

@pytest.fixture
def staff_client(db, client):
    from apps.users.models import User
    user = User.objects.create_user(
        username="staff", password="pass123", is_staff=True,
    )
    client.login(username="staff", password="pass123")
    return client
```

### Yield Fixtures for Teardown

```python
@pytest.fixture
def temp_file(tmp_path):
    f = tmp_path / "test.bin"
    f.write_bytes(b"\x00" * 1024)
    yield f
    # Cleanup runs after test
    if f.exists():
        f.unlink()
```

### Parameterized Fixtures

```python
@pytest.fixture(params=["free", "registered", "premium"])
def user_tier(request, db):
    from tests.factories import UserFactory
    return UserFactory(tier=request.param)
```

## Red Flags

- `scope="session"` fixtures accessing the database — DB is reset between tests
- Fixtures doing too much — keep them focused, compose from smaller fixtures
- Not using `yield` for cleanup — resources leak between tests
- Fixtures in test files instead of conftest.py — not reusable

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
