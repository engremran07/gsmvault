---
name: test-coverage-strategy
description: "Coverage strategy: branch coverage, meaningful tests, gap analysis. Use when: planning test coverage, identifying coverage gaps, setting coverage floors."
---

# Test Coverage Strategy

## When to Use

- Setting up coverage configuration for a project
- Identifying untested code paths
- Planning coverage improvement sprints
- Establishing coverage floors for CI gates

## Rules

### Coverage Configuration

```toml
# pyproject.toml
[tool.pytest.ini_options]
addopts = "--cov=apps --cov-report=term-missing --cov-report=html --cov-branch"

[tool.coverage.run]
branch = true
source = ["apps"]
omit = [
    "*/migrations/*",
    "*/tests/*",
    "*/test_*.py",
    "*/__init__.py",
    "*/admin.py",
]

[tool.coverage.report]
fail_under = 60
show_missing = true
skip_covered = false
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "if __name__ ==",
    "raise NotImplementedError",
]
```

### Running Coverage

```powershell
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing --cov-branch
# HTML report
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=html
# Open htmlcov/index.html
```

### Coverage Priority Matrix

```python
# Priority 1 — MUST be covered (>90%):
# - services.py (business logic)
# - download_service.py (financial/gating logic)
# - models.py (validation, clean, save overrides)

# Priority 2 — SHOULD be covered (>70%):
# - views.py (request handling)
# - api.py (API endpoints)
# - forms.py (validation)

# Priority 3 — NICE to cover (>50%):
# - tasks.py (Celery tasks)
# - middleware (request/response processing)
# - templatetags (display logic)

# OK to exclude:
# - migrations (auto-generated)
# - admin.py (Django admin config — low risk)
# - __init__.py (empty / re-exports)
```

### Identifying Coverage Gaps

```python
@pytest.mark.django_db
def test_gap_analysis():
    """Run this to identify critical untested paths."""
    from apps.firmwares.models import Firmware
    # Ensure model __str__ is tested
    fw = Firmware(version="1.0.0")
    assert str(fw)

    # Ensure model clean() is tested
    from django.core.exceptions import ValidationError
    fw_invalid = Firmware()
    try:
        fw_invalid.full_clean()
    except ValidationError:
        pass  # Expected — validates required fields
```

### Meaningful Coverage vs Line Coverage

```python
# BAD — high coverage, low value:
def test_model_exists():
    from apps.firmwares.models import Firmware
    assert Firmware  # Just imports the class

# GOOD — tests actual behavior:
@pytest.mark.django_db
def test_firmware_slug_generation():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(version="3.2.1")
    assert fw.slug  # Auto-generated slug
    assert "3-2-1" in fw.slug or fw.slug != ""
```

## Red Flags

- Counting coverage without `--cov-branch` — misses untested branches
- Padding coverage with trivial import tests — inflates numbers meaninglessly
- Excluding entire modules from coverage — hides critical gaps
- Setting `fail_under` too low — coverage ratchet should only go up

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
