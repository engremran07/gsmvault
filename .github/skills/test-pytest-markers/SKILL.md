---
name: test-pytest-markers
description: "Custom markers: @pytest.mark.slow, @pytest.mark.integration. Use when: categorizing tests, selective test runs, CI pipeline stages."
---

# pytest Markers

## When to Use

- Categorizing tests by speed (slow, fast) or type (unit, integration, e2e)
- Skipping tests conditionally (missing service, wrong OS)
- Running subsets of tests in CI pipelines

## Rules

### Register Markers in pyproject.toml

```toml
[tool.pytest.ini_options]
addopts = "--strict-markers"
markers = [
    "slow: marks tests that take >2 seconds",
    "integration: requires external services (DB, Redis, API)",
    "e2e: end-to-end browser tests",
    "celery: requires Celery worker",
]
```

### Built-in Markers

```python
import pytest
import sys

@pytest.mark.skip(reason="Not implemented yet")
def test_future_feature():
    pass

@pytest.mark.skipif(sys.platform == "win32", reason="Unix-only test")
def test_unix_permissions():
    pass

@pytest.mark.xfail(reason="Known bug #123", strict=True)
def test_known_bug():
    pass

@pytest.mark.django_db
def test_model_creation():
    pass

@pytest.mark.django_db(transaction=True)
def test_concurrent_writes():
    pass
```

### Custom Markers

```python
@pytest.mark.slow
@pytest.mark.django_db
def test_full_firmware_pipeline():
    """Takes 5+ seconds — skip in quick CI runs."""
    pass

@pytest.mark.integration
def test_redis_cache():
    """Requires Redis running."""
    pass

@pytest.mark.celery
def test_async_processing():
    """Requires Celery worker."""
    pass
```

### Running with Markers

```powershell
# Only fast tests
& .\.venv\Scripts\python.exe -m pytest -m "not slow"
# Only integration
& .\.venv\Scripts\python.exe -m pytest -m integration
# Exclude e2e and slow
& .\.venv\Scripts\python.exe -m pytest -m "not (slow or e2e)"
# Only a specific combo
& .\.venv\Scripts\python.exe -m pytest -m "integration and not celery"
```

### Marker-based Fixture Activation

```python
@pytest.fixture(autouse=True)
def _setup_for_integration(request):
    if request.node.get_closest_marker("integration"):
        # Setup external service connections
        yield
        # Teardown
    else:
        yield
```

## Red Flags

- Missing `--strict-markers` — typos in marker names silently pass
- Not registering custom markers in pyproject.toml — warnings in output
- Using `@pytest.mark.skip` without reason — unclear why test is skipped
- Overusing `xfail` — masks real failures

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
