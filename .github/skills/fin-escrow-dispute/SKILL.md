---
name: fin-escrow-dispute
description: "Dispute resolution for escrow transactions. Use when: buyer or seller raises a dispute, admin mediation, split resolution outcomes."
---

# Escrow Dispute Resolution

## When to Use

- Buyer claims non-delivery or wrong item
- Seller claims buyer is abusing the system
- Admin mediates and decides outcome

## Rules

1. **Either party** can open a dispute while escrow is "held"
2. **Freeze escrow** — no release or refund while dispute is open
3. **Admin resolution** required — three outcomes: refund buyer, release to seller, or split
4. **Evidence collection** — both parties can submit messages/proof
5. **Atomic resolution** — escrow disposition in single transaction

## Pattern: Dispute Service

```python
from decimal import Decimal
from django.db import transaction
from apps.marketplace.models import EscrowHold, EscrowDispute

@transaction.atomic
def open_dispute(
    escrow_id: int,
    opened_by_id: int,
    reason: str,
) -> EscrowDispute:
    """Open a dispute on an active escrow."""
    hold = EscrowHold.objects.select_for_update().get(pk=escrow_id)
    if hold.status != "held":
        raise ValueError("Can only dispute active escrows")
    hold.status = "disputed"
    hold.save(update_fields=["status", "updated_at"])
    return EscrowDispute.objects.create(
        escrow=hold, opened_by_id=opened_by_id,
        reason=reason, status="open",
    )


@transaction.atomic
def resolve_dispute(
    dispute_id: int,
    admin_id: int,
    resolution: str,  # "refund_buyer", "release_seller", "split"
    buyer_share: Decimal = Decimal("0"),
    note: str = "",
) -> None:
    """Admin resolves a dispute."""
    dispute = EscrowDispute.objects.select_for_update().get(pk=dispute_id)
    hold = EscrowHold.objects.select_for_update().get(pk=dispute.escrow_id)

    if dispute.status != "open":
        raise ValueError("Dispute already resolved")

    if resolution == "refund_buyer":
        _refund_escrow_to_buyer(hold)
    elif resolution == "release_seller":
        from apps.wallet.models import Wallet
        release_escrow(hold.pk, released_by_id=admin_id)
    elif resolution == "split":
        _split_escrow(hold, buyer_share, admin_id)
    else:
        raise ValueError(f"Invalid resolution: {resolution}")

    dispute.status = "resolved"
    dispute.resolution = resolution
    dispute.resolved_by_id = admin_id
    dispute.resolution_note = note
    dispute.save(update_fields=["status", "resolution", "resolved_by_id",
                                 "resolution_note", "updated_at"])
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Auto-resolving disputes without admin | No human judgment | Require admin resolution |
| Allowing release while disputed | Undermines dispute process | Freeze on dispute |
| No evidence/message system | Can't make informed decision | Add dispute messages |

## Red Flags

- Disputes that can be bypassed by release/refund
- Missing `resolved_by` admin tracking
- No notification to both parties on resolution

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
