---
name: test-service-select-for-update
description: "select_for_update tests: concurrent access simulation. Use when: testing wallet transactions, credit operations, inventory decrements, race condition prevention."
---

# select_for_update Tests

## When to Use

- Testing wallet credit/debit with `select_for_update()`
- Verifying concurrent access doesn't cause data loss
- Testing inventory decrement under contention

## Rules

### Testing Basic select_for_update

```python
import pytest
from django.db import transaction

@pytest.mark.django_db(transaction=True)
def test_wallet_debit_uses_select_for_update():
    from tests.factories import WalletFactory
    from apps.wallet.services import debit_wallet
    wallet = WalletFactory(balance=100)
    debit_wallet(wallet.pk, amount=30)
    wallet.refresh_from_db()
    assert wallet.balance == 70
```

### Testing Insufficient Funds Rejection

```python
@pytest.mark.django_db(transaction=True)
def test_debit_insufficient_funds():
    from tests.factories import WalletFactory
    from apps.wallet.services import debit_wallet
    wallet = WalletFactory(balance=10)
    with pytest.raises(ValueError, match="[Ii]nsufficient"):
        debit_wallet(wallet.pk, amount=50)
    wallet.refresh_from_db()
    assert wallet.balance == 10  # Unchanged
```

### Simulating Concurrent Access

```python
import threading

@pytest.mark.django_db(transaction=True)
def test_concurrent_debits():
    """Two threads decrementing — total should be exact."""
    from tests.factories import WalletFactory
    from apps.wallet.services import debit_wallet
    wallet = WalletFactory(balance=100)
    errors = []

    def debit():
        try:
            debit_wallet(wallet.pk, amount=60)
        except Exception as e:
            errors.append(e)

    t1 = threading.Thread(target=debit)
    t2 = threading.Thread(target=debit)
    t1.start()
    t2.start()
    t1.join()
    t2.join()

    wallet.refresh_from_db()
    # One should succeed (100→40), one should fail (insufficient)
    assert len(errors) == 1
    assert wallet.balance == 40
```

### Testing Lock Ordering

```python
@pytest.mark.django_db(transaction=True)
def test_transfer_locks_both_wallets():
    """Transfer between wallets should lock both to prevent deadlock."""
    from tests.factories import WalletFactory
    from apps.wallet.services import transfer
    w1 = WalletFactory(balance=100)
    w2 = WalletFactory(balance=50)
    transfer(from_wallet=w1.pk, to_wallet=w2.pk, amount=30)
    w1.refresh_from_db()
    w2.refresh_from_db()
    assert w1.balance == 70
    assert w2.balance == 80
```

## Red Flags

- Missing `transaction=True` in `django_db` marker — kills real transaction behavior
- Not using `refresh_from_db()` after service call — stale object in memory
- Threading tests without proper DB connection handling — Django one-connection-per-thread
- Not testing the rejection case (insufficient funds)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
