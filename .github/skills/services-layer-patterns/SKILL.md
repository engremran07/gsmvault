---
name: services-layer-patterns
description: "Service layer architecture: thin views, fat services, single responsibility. Use when: creating service functions, refactoring views, organizing business logic, structuring service modules."
---

# Service Layer Patterns

## When to Use
- Creating new business logic functions
- Refactoring fat views into services
- Organizing complex domains into service modules
- Deciding where logic belongs (view vs service vs model)

## Rules
- ALL business logic lives in `services.py` — views are thin orchestrators
- Views: parse request → call service → return response. Never ORM in views.
- Services MUST NOT import `HttpResponse`, `JsonResponse`, or `django.http` anything
- One `services.py` per app, or `services/` directory with `__init__.py` re-exports
- Service functions: full type hints on parameters AND return type
- Raise domain exceptions from services, never HTTP exceptions
- For `apps.seo`, `apps.distribution`, and `apps.ads`, ALWAYS enrich existing services/modules and existing model data flows; never introduce parallel "v2/new" service files

## Patterns

### Thin View, Fat Service
```python
# apps/firmwares/views.py — THIN
from django.http import HttpRequest, HttpResponse
from django.shortcuts import render, get_object_or_404
from . import services

def firmware_detail(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = services.get_firmware_detail(pk=pk, user=request.user)
    return render(request, "firmwares/detail.html", {"firmware": firmware})
```

```python
# apps/firmwares/services.py — FAT
import logging
from django.db.models import QuerySet
from .models import Firmware

logger = logging.getLogger(__name__)

class FirmwareNotFoundError(Exception):
    pass

def get_firmware_detail(*, pk: int, user: object) -> Firmware:
    """Retrieve firmware with access checks and related data."""
    try:
        firmware = (
            Firmware.objects
            .select_related("brand", "model", "variant")
            .prefetch_related("tags")
            .get(pk=pk, is_active=True)
        )
    except Firmware.DoesNotExist:
        raise FirmwareNotFoundError(f"Firmware {pk} not found")
    logger.info("Firmware %s accessed by user %s", pk, getattr(user, "pk", "anon"))
    return firmware
```

### Service with Multiple Operations
```python
# apps/wallet/services.py
from decimal import Decimal
from django.db import transaction
from .models import Wallet, Transaction

class InsufficientFundsError(Exception):
    pass

@transaction.atomic
def transfer_credits(
    *, from_user_id: int, to_user_id: int, amount: Decimal, reason: str
) -> Transaction:
    """Transfer credits between users with concurrency safety."""
    from_wallet = Wallet.objects.select_for_update().get(user_id=from_user_id)
    to_wallet = Wallet.objects.select_for_update().get(user_id=to_user_id)
    if from_wallet.balance < amount:
        raise InsufficientFundsError(f"Balance {from_wallet.balance} < {amount}")
    from_wallet.balance -= amount
    from_wallet.save(update_fields=["balance"])
    to_wallet.balance += amount
    to_wallet.save(update_fields=["balance"])
    return Transaction.objects.create(
        from_wallet=from_wallet, to_wallet=to_wallet,
        amount=amount, reason=reason,
    )
```

### Service Module Directory
```text
apps/firmwares/services/
    __init__.py         # Re-exports: from .firmware import *; from .download import *
    firmware.py         # CRUD operations
    download.py         # Download gating logic
    scraper.py          # OEM scraper orchestration
```

```python
# apps/firmwares/services/__init__.py
from .download import create_download_token, validate_download_token  # noqa: F401
from .firmware import get_firmware_detail, list_firmwares  # noqa: F401
```

## Anti-Patterns
- ORM queries inside views — move to services
- `HttpResponse` or `JsonResponse` imported in services — return domain objects
- Services calling services across app boundaries — use EventBus or signals
- `except Exception: pass` in services — always log and re-raise or handle
- Returning `True`/`False` for complex outcomes — raise typed exceptions
- Creating `*_v2.py`/`*_new.py` service modules to avoid refactoring existing services
- Creating duplicate service pathways that bypass existing models and persisted data

## Red Flags
- View function > 20 lines with ORM calls → extract to service
- `from django.http import` in a `services.py` → violation
- Service importing models from another app → boundary violation
- Feature request implemented via new parallel service file instead of extending existing module

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
