---
name: test-pytest-config
description: "pytest configuration: conftest.py, pyproject.toml, markers, plugins. Use when: setting up test infrastructure, configuring pytest, adding markers, organizing conftest files."
---

# pytest Configuration

## When to Use

- Setting up pytest for a new app or the project root
- Configuring `pyproject.toml` `[tool.pytest.ini_options]`
- Adding shared fixtures in `conftest.py`
- Registering custom markers

## Rules

### pyproject.toml Configuration

```toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "app.settings_dev"
python_files = ["tests.py", "test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "--strict-markers --tb=short -q"
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks integration tests requiring external services",
]
filterwarnings = [
    "ignore::DeprecationWarning:factory.*",
]
```

### conftest.py Hierarchy

```text
conftest.py                    # Root: Django settings, shared fixtures
apps/firmwares/tests/
    conftest.py                # App-level: app-specific factories, fixtures
    test_models.py
    test_views.py
```

### Root conftest.py Pattern

```python
import pytest
from django.test import RequestFactory

@pytest.fixture
def request_factory():
    return RequestFactory()

@pytest.fixture
def staff_user(db):
    from apps.users.models import User
    return User.objects.create_user(
        username="staff", email="staff@test.com",
        password="testpass123", is_staff=True,
    )
```

### Run Commands

```powershell
# All tests with coverage
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing
# Single app
& .\.venv\Scripts\python.exe -m pytest apps/firmwares/tests/ -v
# By keyword
& .\.venv\Scripts\python.exe -m pytest -k "test_download"
# Exclude slow
& .\.venv\Scripts\python.exe -m pytest -m "not slow"
```

## Red Flags

- Missing `DJANGO_SETTINGS_MODULE` in pyproject.toml — tests use wrong settings
- Fixtures that create data without `db` or `django_db` marker — `DatabaseError`
- conftest.py importing from app models at module level — import loops
- Not using `--strict-markers` — typos in marker names silently pass

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
