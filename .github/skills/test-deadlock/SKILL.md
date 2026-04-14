---
name: test-deadlock
description: "Deadlock prevention tests: lock ordering, timeout handling. Use when: testing multi-table locking, nested transactions, preventing deadlocks."
---

# Deadlock Prevention Tests

## When to Use

- Testing operations that lock multiple tables
- Verifying consistent lock ordering across services
- Testing timeout behavior on locked resources
- Ensuring deadlock recovery in service functions

## Rules

### Testing Lock Ordering

```python
import pytest
from concurrent.futures import ThreadPoolExecutor
from django.db import connections, transaction

@pytest.mark.django_db(transaction=True)
def test_consistent_lock_ordering():
    """Both operations lock wallet THEN firmware — same order prevents deadlock."""
    from tests.factories import UserFactory, FirmwareFactory
    from apps.wallet.models import Wallet
    user = UserFactory()
    wallet = Wallet.objects.create(user=user, balance=100)
    fw = FirmwareFactory()

    def purchase():
        connections.close_all()
        from apps.wallet.models import Wallet as W
        from apps.firmwares.models import Firmware
        with transaction.atomic():
            w = W.objects.select_for_update().get(pk=wallet.pk)
            f = Firmware.objects.select_for_update().get(pk=fw.pk)
            w.balance -= 10
            w.save()
            f.download_count += 1
            f.save()
            return True

    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(purchase) for _ in range(3)]
        results = [f.result() for f in futures]
    assert all(results)
```

### Testing Nowait Lock

```python
@pytest.mark.django_db(transaction=True)
def test_nowait_raises_on_locked_row():
    from tests.factories import UserFactory
    from apps.wallet.models import Wallet
    import threading
    user = UserFactory()
    wallet = Wallet.objects.create(user=user, balance=100)
    lock_acquired = threading.Event()
    error_raised = threading.Event()

    def hold_lock():
        connections.close_all()
        from apps.wallet.models import Wallet as W
        with transaction.atomic():
            W.objects.select_for_update().get(pk=wallet.pk)
            lock_acquired.set()
            import time
            time.sleep(2)  # Hold lock

    def try_nowait():
        lock_acquired.wait(timeout=5)
        connections.close_all()
        from apps.wallet.models import Wallet as W
        try:
            with transaction.atomic():
                W.objects.select_for_update(nowait=True).get(pk=wallet.pk)
        except Exception:
            error_raised.set()

    t1 = threading.Thread(target=hold_lock)
    t2 = threading.Thread(target=try_nowait)
    t1.start()
    t2.start()
    t1.join(timeout=5)
    t2.join(timeout=5)
    assert error_raised.is_set()  # nowait should raise
```

### Testing Transaction Timeout

```python
@pytest.mark.django_db(transaction=True)
def test_long_transaction_completes():
    """Verify no idle-in-transaction timeout for normal operations."""
    from tests.factories import UserFactory
    from apps.wallet.models import Wallet
    user = UserFactory()
    wallet = Wallet.objects.create(user=user, balance=100)
    with transaction.atomic():
        w = Wallet.objects.select_for_update().get(pk=wallet.pk)
        w.balance -= 10
        w.save()
    wallet.refresh_from_db()
    assert wallet.balance == 90
```

## Red Flags

- Locking tables in different order in different functions — deadlock guaranteed
- Using `select_for_update()` without `transaction.atomic()` — lock not held
- Holding locks while calling external APIs — blocks DB connections
- Not using `nowait=True` or `skip_locked=True` for non-critical operations

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
