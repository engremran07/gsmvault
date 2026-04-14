---
name: test-concurrent-access
description: "Concurrent access tests: threading, race conditions. Use when: testing concurrent writes, shared resource access, multi-user scenarios."
---

# Concurrent Access Tests

## When to Use

- Testing multiple users accessing the same resource simultaneously
- Verifying concurrent write safety on shared data
- Testing download token concurrent usage
- Checking inventory/credit deduction under load

## Rules

### Testing Concurrent Writes

```python
import pytest
from concurrent.futures import ThreadPoolExecutor, as_completed
from django.db import connection

@pytest.mark.django_db(transaction=True)
def test_concurrent_credit_deduction():
    from tests.factories import UserFactory
    from apps.wallet.models import Wallet
    user = UserFactory()
    wallet = Wallet.objects.create(user=user, balance=100)

    def deduct_credits(amount):
        from django.db import connections
        connections.close_all()
        from apps.wallet.models import Wallet as W
        from django.db import transaction
        with transaction.atomic():
            w = W.objects.select_for_update().get(pk=wallet.pk)
            if w.balance >= amount:
                w.balance -= amount
                w.save()
                return True
            return False

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = [executor.submit(deduct_credits, 30) for _ in range(5)]
        results = [f.result() for f in as_completed(futures)]

    wallet.refresh_from_db()
    successful = sum(1 for r in results if r)
    assert wallet.balance == 100 - (successful * 30)
    assert wallet.balance >= 0  # Never goes negative
```

### Testing Concurrent Token Usage

```python
@pytest.mark.django_db(transaction=True)
def test_download_token_single_use():
    from tests.factories import DownloadTokenFactory
    token = DownloadTokenFactory(status="active")

    def use_token():
        from django.db import connections
        connections.close_all()
        from apps.firmwares.models import DownloadToken
        from django.db import transaction
        with transaction.atomic():
            t = DownloadToken.objects.select_for_update().get(pk=token.pk)
            if t.status == "active":
                t.status = "used"
                t.save()
                return True
            return False

    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(use_token) for _ in range(3)]
        results = [f.result() for f in as_completed(futures)]

    assert sum(1 for r in results if r) == 1  # Only one succeeds
```

### Testing Database Connection Safety

```python
@pytest.mark.django_db(transaction=True)
def test_separate_connections():
    """Each thread must use its own database connection."""
    import threading
    results = []

    def query():
        from django.db import connections
        connections.close_all()
        from apps.firmwares.models import Firmware
        count = Firmware.objects.count()
        results.append(count)

    threads = [threading.Thread(target=query) for _ in range(3)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    assert len(results) == 3
```

## Red Flags

- Not calling `connections.close_all()` in threads — causes DatabaseError
- Missing `transaction=True` in `@pytest.mark.django_db` — needed for real transactions
- Testing concurrency with `CELERY_TASK_ALWAYS_EAGER` — doesn't test real parallelism
- Not using `select_for_update()` on contested resources — race condition guaranteed

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
