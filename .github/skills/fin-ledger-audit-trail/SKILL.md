---
name: fin-ledger-audit-trail
description: "Transaction audit trail with immutable records. Use when: logging financial operations, compliance tracking, admin adjustments, forensic analysis."
---

# Transaction Audit Trail

## When to Use

- Every financial operation must create an audit record
- Admin manual adjustments need full traceability
- Investigating disputed transactions
- Regulatory compliance requirements

## Rules

1. **Immutable** — never `update()` or `delete()` transaction records
2. **Every field change** logged: amount, type, user, timestamp, IP, reason
3. **Admin adjustments** record `adjusted_by` (the admin user)
4. **Reversal pattern** — create inverse entry, never modify original
5. **Idempotency key** — prevent duplicate processing of the same event

## Pattern: Immutable Transaction Log

```python
from decimal import Decimal
from django.db import models
from apps.core.models import TimestampedModel

class TransactionLog(TimestampedModel):
    """Immutable financial audit record."""
    wallet = models.ForeignKey("wallet.Wallet", on_delete=models.PROTECT,
                               related_name="transaction_logs")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    balance_after = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_type = models.CharField(max_length=30)
    reason = models.CharField(max_length=255)
    reference = models.CharField(max_length=64, db_index=True)
    idempotency_key = models.CharField(max_length=64, unique=True, null=True)
    ip_address = models.GenericIPAddressField(null=True)
    performed_by = models.ForeignKey(
        "users.User", null=True, on_delete=models.SET_NULL,
        related_name="performed_transactions",
    )

    class Meta:
        ordering = ["-created_at"]
        db_table = "wallet_transactionlog"

    def save(self, *args, **kwargs):
        if self.pk:
            raise ValueError("Transaction logs are immutable")
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        raise ValueError("Transaction logs cannot be deleted")
```

## Pattern: Reversal (Not Deletion)

```python
@transaction.atomic
def reverse_transaction(original_tx_id: int, reason: str, admin_user) -> TransactionLog:
    original = TransactionLog.objects.get(pk=original_tx_id)
    wallet = Wallet.objects.select_for_update().get(pk=original.wallet_id)
    wallet.balance -= original.amount  # Undo the effect
    wallet.save(update_fields=["balance", "updated_at"])
    return TransactionLog.objects.create(
        wallet=wallet, amount=-original.amount,
        balance_after=wallet.balance, transaction_type="reversal",
        reason=f"Reversal of #{original_tx_id}: {reason}",
        reference=original.reference, performed_by=admin_user,
    )
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| `TransactionLog.objects.filter(...).update(amount=...)` | Destroys audit trail | Create reversal entry |
| `TransactionLog.objects.filter(...).delete()` | Destroys financial records | Never delete |
| Missing `performed_by` on admin adjustments | No accountability | Always track admin |

## Red Flags

- Any `.update()` or `.delete()` on financial log models
- Missing IP address or user tracking on transactions
- No idempotency key on payment-related entries

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
