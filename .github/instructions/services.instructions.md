---
applyTo: 'apps/*/services*.py'
---

# Service Layer Conventions

## Purpose

All business logic lives in `services.py` (or `services/` directory for large apps).
Views call services — never put logic in views. Service functions are the unit of testing.

```python
# services.py
from django.db import transaction

@transaction.atomic
def create_firmware(
    *, user: User, file: UploadedFile, brand: Brand, model: Model
) -> Firmware:
    """Create a new firmware entry with proper validation."""
    firmware = Firmware.objects.create(
        user=user, brand=brand, model=model, status="pending"
    )
    # Additional business logic...
    return firmware
```

## Transaction Safety

Use `@transaction.atomic` on any function that writes to multiple models:

```python
from django.db import transaction

@transaction.atomic
def approve_firmware(firmware: Firmware, *, approved_by: User) -> None:
    firmware.status = "approved"
    firmware.approved_by = approved_by
    firmware.save(update_fields=["status", "approved_by", "updated_at"])
    AuditLog.objects.create(action="approve", target=firmware, user=approved_by)
```

## Financial Operations

Always use `select_for_update()` on wallet/credit mutations:

```python
@transaction.atomic
def debit_wallet(user: User, amount: Decimal, reason: str) -> Transaction:
    wallet = Wallet.objects.select_for_update().get(user=user)
    if wallet.balance < amount:
        raise InsufficientFundsError(f"Balance {wallet.balance} < {amount}")
    wallet.balance -= amount
    wallet.save(update_fields=["balance", "updated_at"])
    return Transaction.objects.create(
        wallet=wallet, amount=-amount, reason=reason, balance_after=wallet.balance
    )
```

## App Boundary Rules — STRICT

Services MUST NOT import models from other apps (except `apps.core`, `apps.site_settings`, `AUTH_USER_MODEL`).

For cross-app communication:

```python
# CORRECT — use EventBus
from apps.core.events.bus import event_bus, EventTypes

def complete_download(session: DownloadSession) -> None:
    session.status = "completed"
    session.save()
    event_bus.emit(EventTypes.DOWNLOAD_COMPLETED, {"session_id": session.pk})

# WRONG — direct cross-app import
from apps.analytics.services import track_download  # FORBIDDEN in services
```

## Type Hints

Full type hints on all service functions — parameters and return types:

```python
def search_firmwares(
    *, query: str, brand_id: int | None = None, page: int = 1
) -> QuerySet[Firmware]:
    qs = Firmware.objects.filter(is_active=True)
    if query:
        qs = qs.filter(name__icontains=query)
    if brand_id:
        qs = qs.filter(brand_id=brand_id)
    return qs
```

## Input Sanitization

All user-supplied HTML content must be sanitized:

```python
from apps.core.sanitizers import sanitize_html_content

def update_profile_bio(user: User, bio: str) -> None:
    user.profile.bio = sanitize_html_content(bio)
    user.profile.save(update_fields=["bio", "updated_at"])
```

## QuerySet Optimization

Use `select_related()` for FK joins and `prefetch_related()` for M2M/reverse FK:

```python
def get_firmware_detail(pk: int) -> Firmware:
    return Firmware.objects.select_related(
        "brand", "model", "user"
    ).prefetch_related("tags").get(pk=pk)
```

## Error Handling

Raise meaningful exceptions — never swallow errors silently:

```python
class FirmwareNotFoundError(Exception):
    pass

class InsufficientFundsError(Exception):
    pass
```

## Naming Convention

Service functions use verb-noun naming:
- `create_firmware()`, `approve_firmware()`, `delete_firmware()`
- `search_topics()`, `create_reply()`, `toggle_like()`
- `debit_wallet()`, `credit_wallet()`, `transfer_funds()`
