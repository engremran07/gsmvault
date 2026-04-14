---
name: test-performance-response
description: "Response time tests: timing assertions, slow test detection. Use when: benchmarking view response times, detecting slow queries, marking slow tests."
---

# Response Time Tests

## When to Use

- Benchmarking view response times
- Detecting performance regressions
- Marking slow tests for separate CI runs
- Setting response time SLAs

## Rules

### Testing Response Time

```python
import pytest
import time

@pytest.mark.django_db
def test_list_view_response_time(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(50)
    start = time.perf_counter()
    response = client.get("/firmwares/")
    elapsed = time.perf_counter() - start
    assert response.status_code == 200
    assert elapsed < 1.0  # Must respond within 1 second

@pytest.mark.django_db
def test_api_response_time(client):
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(100)
    start = time.perf_counter()
    response = client.get("/api/v1/firmwares/")
    elapsed = time.perf_counter() - start
    assert response.status_code == 200
    assert elapsed < 0.5  # API should be faster
```

### Marking Slow Tests

```python
@pytest.mark.slow
@pytest.mark.django_db
def test_bulk_import_performance():
    """Takes >5s — skip in fast CI, run in nightly."""
    from tests.factories import FirmwareFactory
    start = time.perf_counter()
    FirmwareFactory.create_batch(1000)
    elapsed = time.perf_counter() - start
    assert elapsed < 30  # 1000 records under 30s
```

```toml
# pyproject.toml
[tool.pytest.ini_options]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
]
```

```powershell
# Run fast tests only
& .\.venv\Scripts\python.exe -m pytest -m "not slow"
# Run slow tests only (nightly CI)
& .\.venv\Scripts\python.exe -m pytest -m slow
```

### Testing Database Query Performance

```python
@pytest.mark.django_db
def test_search_performance():
    from tests.factories import FirmwareFactory
    FirmwareFactory.create_batch(200)
    start = time.perf_counter()
    from apps.firmwares.models import Firmware
    results = list(Firmware.objects.filter(version__icontains="1.0"))
    elapsed = time.perf_counter() - start
    assert elapsed < 0.5  # Search should be fast with index
```

### Setting Response Time SLAs

```python
RESPONSE_TIME_SLAS = {
    "/": 0.5,
    "/firmwares/": 1.0,
    "/api/v1/firmwares/": 0.5,
    "/blog/": 1.0,
}

@pytest.mark.django_db
@pytest.mark.parametrize("url,max_seconds", list(RESPONSE_TIME_SLAS.items()))
def test_response_time_sla(client, url, max_seconds):
    start = time.perf_counter()
    response = client.get(url)
    elapsed = time.perf_counter() - start
    assert response.status_code in (200, 302)
    assert elapsed < max_seconds, f"{url} took {elapsed:.2f}s (SLA: {max_seconds}s)"
```

### Detecting Slow Test Timeout

```toml
# pyproject.toml
[tool.pytest.ini_options]
timeout = 30  # Kill tests that run longer than 30 seconds
timeout_method = "signal"
```

## Red Flags

- No performance tests — regressions only discovered in production
- Absolute timing thresholds too tight — CI environments are slower than local
- Not using `time.perf_counter()` — `time.time()` has lower resolution
- Missing `@pytest.mark.slow` on heavy tests — slows down fast feedback loop

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
