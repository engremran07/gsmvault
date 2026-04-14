---
name: test-coverage-mutation
description: "Mutation testing concepts: mutmut, quality over quantity. Use when: validating test quality, finding tests that pass regardless, detecting weak assertions."
---

# Mutation Testing

## When to Use

- Validating that tests actually detect bugs (not just achieve coverage)
- Finding tests with weak assertions
- Proving critical business logic is thoroughly tested
- Evaluating test suite quality beyond line coverage

## Rules

### Running Mutation Tests

```powershell
# Install mutmut
& .\.venv\Scripts\pip.exe install mutmut

# Run against specific module
& .\.venv\Scripts\python.exe -m mutmut run --paths-to-mutate=apps/firmwares/services.py

# View results
& .\.venv\Scripts\python.exe -m mutmut results

# View specific surviving mutant
& .\.venv\Scripts\python.exe -m mutmut show 42
```

### Configuration

```toml
# pyproject.toml or setup.cfg
[tool.mutmut]
paths_to_mutate = "apps/firmwares/services.py"
tests_dir = "tests/"
runner = "python -m pytest -x --tb=short"
dict_synonyms = "Struct,NamedStruct"
```

### Understanding Mutation Types

```python
# mutmut changes your code and checks if tests catch it:

# Original:
def check_quota(user, tier):
    if tier.daily_limit > 0:
        return user.downloads_today < tier.daily_limit
    return True

# Mutation 1 — change operator:
#   if tier.daily_limit >= 0:   (> to >=)
#   Test should FAIL — detects boundary change

# Mutation 2 — change comparison:
#   return user.downloads_today <= tier.daily_limit  (< to <=)
#   Test should FAIL — off-by-one caught

# Mutation 3 — change return:
#   return False  (True to False)
#   Test should FAIL — logic inversion caught
```

### Writing Mutation-Resistant Tests

```python
import pytest

# WEAK — survives mutations:
@pytest.mark.django_db
def test_quota_check_weak():
    result = check_quota(user, tier)
    assert result is not None  # Too vague

# STRONG — kills mutations:
@pytest.mark.django_db
def test_quota_under_limit():
    from tests.factories import UserFactory
    user = UserFactory(downloads_today=5)
    tier = type("Tier", (), {"daily_limit": 10})()
    assert check_quota(user, tier) is True

@pytest.mark.django_db
def test_quota_at_limit():
    user = type("U", (), {"downloads_today": 10})()
    tier = type("Tier", (), {"daily_limit": 10})()
    assert check_quota(user, tier) is False  # Exact boundary

@pytest.mark.django_db
def test_quota_over_limit():
    user = type("U", (), {"downloads_today": 15})()
    tier = type("Tier", (), {"daily_limit": 10})()
    assert check_quota(user, tier) is False

@pytest.mark.django_db
def test_quota_unlimited():
    user = type("U", (), {"downloads_today": 999})()
    tier = type("Tier", (), {"daily_limit": 0})()
    assert check_quota(user, tier) is True  # Unlimited tier
```

### Focus Mutation Testing on Critical Code

```python
# Run mutation tests on financial/security code ONLY:
# - apps/wallet/services.py
# - apps/firmwares/download_service.py
# - apps/security/middleware.py
# These modules have the highest impact if bugs slip through.
```

## Red Flags

- 100% line coverage but surviving mutants — tests don't assert behavior
- Using `assert True` or `assert result` — too weak to catch mutations
- Not testing boundary values — off-by-one mutants survive
- Running mutation tests on entire codebase — too slow, focus on critical modules

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
