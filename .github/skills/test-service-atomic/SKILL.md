---
name: test-service-atomic
description: "Service transaction tests: atomic blocks, rollback on error. Use when: testing @transaction.atomic, verifying rollback on exceptions, multi-model operations."
---

# Service Transaction Tests

## When to Use

- Testing service functions wrapped in `@transaction.atomic`
- Verifying full rollback when any step fails
- Testing multi-model operations are all-or-nothing

## Rules

### Testing Successful Transaction

```python
import pytest
from django.db import transaction

@pytest.mark.django_db
def test_service_creates_multiple_models():
    from apps.firmwares.services import create_firmware_with_metadata
    result = create_firmware_with_metadata(
        version="1.0.0", brand_name="Samsung", model_name="Galaxy S24",
    )
    assert result.pk is not None
    assert result.model.brand.name == "Samsung"
```

### Testing Rollback on Error

```python
@pytest.mark.django_db
def test_rollback_on_failure():
    from apps.firmwares.models import Firmware
    from apps.firmwares.services import create_firmware_with_metadata
    initial_count = Firmware.objects.count()
    with pytest.raises(Exception):
        create_firmware_with_metadata(
            version="1.0.0", brand_name="Samsung",
            model_name=None,  # Causes error
        )
    assert Firmware.objects.count() == initial_count  # Rolled back
```

### Testing Nested Transactions

```python
@pytest.mark.django_db(transaction=True)
def test_savepoint_rollback():
    from apps.wallet.models import Wallet
    from tests.factories import WalletFactory
    wallet = WalletFactory(balance=100)
    try:
        with transaction.atomic():
            wallet.balance -= 50
            wallet.save()
            # Inner operation fails
            with transaction.atomic():
                wallet.balance -= 200  # Would go negative
                wallet.save()
                raise ValueError("Insufficient funds")
    except ValueError:
        pass
    wallet.refresh_from_db()
    # Depends on where the error was caught
    assert wallet.balance >= 0
```

### Testing Service Atomicity Pattern

```python
@pytest.mark.django_db
def test_partial_failure_rolls_back_everything():
    """If step 3 of 5 fails, steps 1-2 should also be rolled back."""
    from apps.shop.models import Order, OrderItem
    from apps.shop.services import create_order
    from tests.factories import ProductFactory
    product = ProductFactory(stock=0)  # No stock — will fail
    initial_orders = Order.objects.count()
    initial_items = OrderItem.objects.count()
    with pytest.raises(Exception):
        create_order(
            items=[{"product_id": product.pk, "quantity": 1}],
        )
    assert Order.objects.count() == initial_orders
    assert OrderItem.objects.count() == initial_items
```

## Red Flags

- Missing `transaction=True` in `@pytest.mark.django_db` for transaction tests
- Not checking DB state AFTER exception — just catching the exception
- Testing atomicity without verifying rollback count
- Using `TestCase` (which wraps in transaction) for transaction tests — use `TransactionTestCase`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
