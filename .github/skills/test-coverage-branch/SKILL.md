---
name: test-coverage-branch
description: "Branch coverage: testing all conditional paths. Use when: ensuring both if/else branches are tested, switch cases covered, guard clauses exercised."
---

# Branch Coverage Tests

## When to Use

- Ensuring both `if` and `else` paths are tested
- Covering `try`/`except` branches
- Testing guard clause early returns
- Covering ternary expressions

## Rules

### Testing Both Branches

```python
import pytest

@pytest.mark.django_db
def test_active_firmware_path():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(is_active=True)
    from apps.firmwares.services import get_firmware_display
    result = get_firmware_display(fw.pk)
    assert result is not None

@pytest.mark.django_db
def test_inactive_firmware_path():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(is_active=False)
    from apps.firmwares.services import get_firmware_display
    result = get_firmware_display(fw.pk)
    # Should return None or raise — depending on implementation
```

### Testing Guard Clauses

```python
@pytest.mark.django_db
def test_nonexistent_firmware_guard():
    from apps.firmwares.services import get_firmware_display
    result = get_firmware_display(99999)
    assert result is None  # Guard clause returns early

@pytest.mark.django_db
def test_valid_firmware_guard():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    from apps.firmwares.services import get_firmware_display
    result = get_firmware_display(fw.pk)
    assert result is not None  # Passes guard clause
```

### Testing Exception Branches

```python
@pytest.mark.django_db
def test_service_success_path():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    from apps.firmwares.services import process_firmware
    result = process_firmware(fw.pk)
    assert result["status"] == "success"

@pytest.mark.django_db
def test_service_exception_path():
    from apps.firmwares.services import process_firmware
    result = process_firmware(None)
    assert result is None or result.get("status") == "error"
```

### Parametrized Branch Coverage

```python
@pytest.mark.django_db
@pytest.mark.parametrize("user_tier,expected_gated", [
    ("free", True),
    ("registered", True),
    ("subscriber", False),
    ("premium", False),
])
def test_ad_gate_branches(user_tier, expected_gated):
    """Cover all tier branches in ad-gate logic."""
    from apps.firmwares.download_service import requires_ad_gate
    result = requires_ad_gate(user_tier)
    assert result == expected_gated
```

### Covering Ternary Expressions

```python
@pytest.mark.parametrize("value,expected", [
    ("", "Unknown"),
    ("Samsung", "Samsung"),
    (None, "Unknown"),
])
def test_brand_display(value, expected):
    display = value if value else "Unknown"
    assert display == expected
```

### Testing with/without Optional Parameters

```python
@pytest.mark.django_db
def test_with_search_query(client):
    response = client.get("/firmwares/?q=samsung")
    assert response.status_code == 200

@pytest.mark.django_db
def test_without_search_query(client):
    response = client.get("/firmwares/")
    assert response.status_code == 200
```

## Red Flags

- Only testing the happy path — else/except branches have zero coverage
- Using mock to skip branches instead of testing them
- Not testing `None`/empty string input — common branch trigger
- Missing parametrize for enum/choice fields — each choice is a branch

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
