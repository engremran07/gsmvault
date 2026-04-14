---
name: services-select-for-update
description: "select_for_update() for concurrent access on financial records. Use when: wallet transactions, credit operations, inventory decrements, any read-modify-write on shared counters."
---

# Select For Update Patterns

## When to Use
- Wallet balance modifications (MANDATORY — zero exceptions)
- Inventory/stock decrements
- Download quota counter updates
- Any read-modify-write cycle on shared numeric fields
- Concurrent token generation or reservation

## Rules
- `select_for_update()` MUST be inside `@transaction.atomic` — it has no effect otherwise
- Always lock BEFORE reading the value you will modify
- Lock the narrowest set of rows possible — avoid locking entire tables
- Use `select_for_update(nowait=True)` to fail fast instead of waiting on deadlocks
- Wallet operations: `select_for_update()` is MANDATORY per project rules

## Patterns

### Wallet Credit/Debit
```python
from decimal import Decimal
from django.db import transaction
from .models import Wallet

class InsufficientFundsError(Exception):
    pass

@transaction.atomic
def debit_wallet(*, user_id: int, amount: Decimal, reason: str) -> Wallet:
    """Debit user wallet with row-level locking."""
    wallet = Wallet.objects.select_for_update().get(user_id=user_id)
    if wallet.balance < amount:
        raise InsufficientFundsError(
            f"User {user_id} balance {wallet.balance} < {amount}"
        )
    wallet.balance -= amount
    wallet.save(update_fields=["balance"])
    wallet.transactions.create(amount=-amount, reason=reason)  # type: ignore[attr-defined]
    return wallet

@transaction.atomic
def credit_wallet(*, user_id: int, amount: Decimal, reason: str) -> Wallet:
    """Credit user wallet with row-level locking."""
    wallet = Wallet.objects.select_for_update().get(user_id=user_id)
    wallet.balance += amount
    wallet.save(update_fields=["balance"])
    wallet.transactions.create(amount=amount, reason=reason)  # type: ignore[attr-defined]
    return wallet
```

### Inventory Decrement
```python
@transaction.atomic
def reserve_stock(*, product_id: int, quantity: int) -> None:
    product = Product.objects.select_for_update().get(pk=product_id)
    if product.stock < quantity:
        raise ValueError(f"Insufficient stock: {product.stock} < {quantity}")
    product.stock -= quantity
    product.save(update_fields=["stock"])
```

### Nowait for Fast-Fail
```python
from django.db import OperationalError

@transaction.atomic
def try_claim_bounty(*, bounty_id: int, user_id: int) -> bool:
    """Try to claim a bounty — fail immediately if locked."""
    try:
        bounty = Bounty.objects.select_for_update(nowait=True).get(
            pk=bounty_id, status="open"
        )
    except OperationalError:
        raise ConcurrencyError("Bounty is being claimed by another user")
    bounty.status = "claimed"
    bounty.claimed_by_id = user_id
    bounty.save(update_fields=["status", "claimed_by_id"])
    return True
```

### Skip Locked for Queue Processing
```python
@transaction.atomic
def process_next_job() -> IngestionJob | None:
    """Pick next pending job, skip already-locked rows."""
    job = (
        IngestionJob.objects
        .select_for_update(skip_locked=True)
        .filter(status="pending")
        .order_by("created_at")
        .first()
    )
    if job is None:
        return None
    job.status = "processing"
    job.save(update_fields=["status"])
    return job
```

## Anti-Patterns
- `select_for_update()` without `@transaction.atomic` — lock is ignored
- Locking rows you don't intend to modify — unnecessary contention
- Holding locks while calling external APIs — long lock duration = deadlock risk
- Using `select_for_update()` on read-only operations — wasteful

## Red Flags
- Wallet `.save()` without `select_for_update()` → race condition
- `balance += amount` without a lock → lost updates under concurrency
- Long operations between `select_for_update()` and `.save()` → lock contention

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
