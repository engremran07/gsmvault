---
name: fin-wallet-transfer
description: "Wallet-to-wallet transfers with atomic double-entry. Use when: P2P payments, marketplace seller payouts, bounty rewards between users."
---

# Wallet-to-Wallet Transfer

## When to Use

- User-to-user payments in marketplace
- Bounty payout from requester to submitter
- Any movement of credits between two wallets

## Rules

1. **Lock both wallets** in consistent order (by `id`) to prevent deadlocks
2. **Single** `@transaction.atomic` block for both debit and credit
3. **Double-entry**: debit amount == credit amount — system must balance
4. **Create two** transaction records linked by a shared reference
5. **Validate** sender has sufficient balance before transfer

## Pattern: Atomic Wallet Transfer

```python
from decimal import Decimal
from django.db import transaction
from apps.wallet.models import Wallet, Transaction
import uuid

@transaction.atomic
def transfer_credits(
    sender_id: int,
    recipient_id: int,
    amount: Decimal,
    reason: str,
) -> tuple[Transaction, Transaction]:
    """Transfer credits between wallets. Returns (debit_tx, credit_tx)."""
    if amount <= Decimal("0"):
        raise ValueError("Transfer amount must be positive")
    if sender_id == recipient_id:
        raise ValueError("Cannot transfer to self")

    # Lock in consistent order to prevent deadlocks
    ids = sorted([sender_id, recipient_id])
    wallets = {
        w.user_id: w
        for w in Wallet.objects.select_for_update().filter(user_id__in=ids)
    }
    sender_wallet = wallets[sender_id]
    recipient_wallet = wallets[recipient_id]

    if sender_wallet.balance < amount:
        raise ValueError("Insufficient balance")

    ref = str(uuid.uuid4())
    sender_wallet.balance -= amount
    sender_wallet.save(update_fields=["balance", "updated_at"])
    recipient_wallet.balance += amount
    recipient_wallet.save(update_fields=["balance", "updated_at"])

    debit_tx = Transaction.objects.create(
        wallet=sender_wallet, amount=-amount,
        transaction_type="transfer_out", reason=reason,
        reference=ref, balance_after=sender_wallet.balance,
    )
    credit_tx = Transaction.objects.create(
        wallet=recipient_wallet, amount=amount,
        transaction_type="transfer_in", reason=reason,
        reference=ref, balance_after=recipient_wallet.balance,
    )
    return debit_tx, credit_tx
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Locking wallets in arbitrary order | Deadlock when A→B and B→A happen concurrently | Sort by ID |
| Separate atomic blocks for debit/credit | Partial transfer if second block fails | Single block |
| No shared reference between transactions | Cannot correlate two sides of transfer | Use UUID ref |

## Red Flags

- Transfer without deadlock-safe lock ordering
- Debit and credit in separate transactions
- Self-transfer not blocked

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/wallet/` — Wallet, Transaction models
- `apps/marketplace/` — P2P trades triggering transfers
