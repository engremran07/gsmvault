---
name: fin-bounty-workflow
description: "Bounty lifecycle: create→claim→submit→review→payout. Use when: managing firmware bounty programs, processing bounty claims, handling bounty payouts."
---

# Bounty Workflow

## When to Use

- User creates a bounty for a specific firmware
- Contributors claim and submit bounty work
- Admin/requester reviews submissions and triggers payout

## Rules

1. **State machine**: open → claimed → submitted → reviewing → approved/rejected → paid
2. **Escrow on creation** — bounty amount held from requester wallet
3. **One active claim** per bounty at a time (or configurable)
4. **Review by requester or admin** — not auto-approved
5. **Payout from escrow** on approval — refund on rejection/expiry

## Pattern: Bounty State Machine

```python
BOUNTY_TRANSITIONS = {
    "open": ["claimed", "cancelled"],
    "claimed": ["submitted", "open"],          # Can unclaim → reopen
    "submitted": ["reviewing"],
    "reviewing": ["approved", "rejected"],
    "approved": ["paid"],
    "rejected": ["open"],                      # Reopen for new claims
    "cancelled": [],
    "paid": [],
}

@transaction.atomic
def transition_bounty(
    bounty_id: int,
    new_status: str,
    actor_id: int,
) -> None:
    from apps.bounty.models import Bounty, BountyStatusLog
    bounty = Bounty.objects.select_for_update().get(pk=bounty_id)
    allowed = BOUNTY_TRANSITIONS.get(bounty.status, [])
    if new_status not in allowed:
        raise ValueError(
            f"Cannot transition from '{bounty.status}' to '{new_status}'"
        )
    old = bounty.status
    bounty.status = new_status
    bounty.save(update_fields=["status", "updated_at"])
    BountyStatusLog.objects.create(
        bounty=bounty, from_status=old, to_status=new_status,
        changed_by_id=actor_id,
    )
```

## Pattern: Bounty Creation with Escrow

```python
@transaction.atomic
def create_bounty(
    requester_id: int,
    amount: Decimal,
    title: str,
    description: str,
    firmware_model_id: int | None = None,
) -> "Bounty":
    from apps.bounty.models import Bounty
    from apps.wallet.models import Wallet

    wallet = Wallet.objects.select_for_update().get(user_id=requester_id)
    if wallet.balance < amount:
        raise ValueError("Insufficient balance for bounty")

    wallet.balance -= amount
    wallet.save(update_fields=["balance", "updated_at"])

    return Bounty.objects.create(
        requester_id=requester_id, amount=amount,
        title=title, description=description,
        firmware_model_id=firmware_model_id,
        status="open", escrowed=True,
    )
```

## Pattern: Bounty Payout

```python
@transaction.atomic
def payout_bounty(bounty_id: int, admin_id: int) -> None:
    from apps.bounty.models import Bounty
    bounty = Bounty.objects.select_for_update().get(pk=bounty_id)
    if bounty.status != "approved":
        raise ValueError("Only approved bounties can be paid")

    # Credit claimant wallet from escrow
    credit_wallet(bounty.claimant_id, bounty.amount,
                  reason=f"Bounty payout: {bounty.title}")

    bounty.status = "paid"
    bounty.save(update_fields=["status", "updated_at"])
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| No escrow on creation | Requester can drain wallet after posting | Escrow immediately |
| Auto-approval without review | Quality issues | Require review step |
| Multiple concurrent claims | Wasted work | One claim at a time |

## Red Flags

- Bounty creation without wallet debit
- Payout without approval
- Missing state transition validation

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
