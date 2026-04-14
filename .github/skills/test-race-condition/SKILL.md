---
name: test-race-condition
description: "Race condition detection: select_for_update, atomic blocks. Use when: testing financial operations, counter increments, status transitions under concurrency."
---

# Race Condition Tests

## When to Use

- Verifying `select_for_update()` prevents lost updates
- Testing counter/balance operations under concurrency
- Detecting TOCTOU (time-of-check-to-time-of-use) bugs
- Testing status transition conflicts

## Rules

### Testing Counter Increment Race

```python
import pytest
from concurrent.futures import ThreadPoolExecutor, as_completed

@pytest.mark.django_db(transaction=True)
def test_download_counter_race():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory(download_count=0)

    def increment():
        from django.db import connections, transaction
        connections.close_all()
        from apps.firmwares.models import Firmware
        with transaction.atomic():
            obj = Firmware.objects.select_for_update().get(pk=fw.pk)
            obj.download_count += 1
            obj.save()

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(increment) for _ in range(10)]
        for f in as_completed(futures):
            f.result()

    fw.refresh_from_db()
    assert fw.download_count == 10  # All 10 counted
```

### Testing F() Expression vs Select-for-Update

```python
@pytest.mark.django_db(transaction=True)
def test_f_expression_atomic():
    """F() expressions avoid race conditions for simple increments."""
    from tests.factories import FirmwareFactory
    from django.db.models import F
    fw = FirmwareFactory(download_count=0)

    def increment_f():
        from django.db import connections
        connections.close_all()
        from apps.firmwares.models import Firmware
        Firmware.objects.filter(pk=fw.pk).update(
            download_count=F("download_count") + 1
        )

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(increment_f) for _ in range(10)]
        for f in as_completed(futures):
            f.result()

    fw.refresh_from_db()
    assert fw.download_count == 10
```

### Testing Status Transition Conflict

```python
@pytest.mark.django_db(transaction=True)
def test_status_transition_conflict():
    from tests.factories import DownloadTokenFactory
    token = DownloadTokenFactory(status="active")

    def transition_to_used():
        from django.db import connections, transaction
        connections.close_all()
        from apps.firmwares.models import DownloadToken
        with transaction.atomic():
            t = DownloadToken.objects.select_for_update().get(pk=token.pk)
            if t.status == "active":
                t.status = "used"
                t.save()
                return "used"
            return "already_used"

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = [executor.submit(transition_to_used) for _ in range(5)]
        results = [f.result() for f in as_completed(futures)]

    assert results.count("used") == 1
    assert results.count("already_used") == 4
```

## Red Flags

- Using `obj.field += 1; obj.save()` without `select_for_update()` — classic race condition
- Missing `transaction.atomic()` around select_for_update — lock not held
- Not testing with enough threads — race conditions may not manifest with 2 threads
- Using `@pytest.mark.django_db` without `transaction=True` — tests run in transaction wrapper

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
