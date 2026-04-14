---
applyTo: 'apps/wallet/**, apps/shop/**, apps/marketplace/**, apps/bounty/**'
---

# Wallet & Financial Operations Instructions

## Core Principle: Atomic Financial Safety

Every financial operation MUST be wrapped in `@transaction.atomic` with `select_for_update()` on balance fields. Race conditions on money are critical bugs.

## Wallet Balance Mutations

```python
from django.db import transaction

@transaction.atomic
def debit_wallet(user, amount, transaction_type, description=""):
    wallet = Wallet.objects.select_for_update().get(user=user)
    if wallet.balance < amount:
        raise InsufficientFundsError(f"Balance {wallet.balance} < {amount}")
    wallet.balance -= amount
    wallet.save(update_fields=["balance"])
    Transaction.objects.create(
        wallet=wallet,
        amount=-amount,
        transaction_type=transaction_type,
        description=description,
        balance_after=wallet.balance,
    )
    return wallet

@transaction.atomic
def credit_wallet(user, amount, transaction_type, description=""):
    wallet = Wallet.objects.select_for_update().get(user=user)
    wallet.balance += amount
    wallet.save(update_fields=["balance"])
    Transaction.objects.create(
        wallet=wallet,
        amount=amount,
        transaction_type=transaction_type,
        description=description,
        balance_after=wallet.balance,
    )
    return wallet
```

**MANDATORY**: Always `select_for_update()` before reading balance. Always `save(update_fields=["balance"])` after modification.

## Double-Entry Pattern

Every debit has a corresponding credit. The system balance must always be zero:

```python
@transaction.atomic
def transfer(sender, receiver, amount, description=""):
    debit_wallet(sender, amount, TransactionType.TRANSFER_OUT, description)
    credit_wallet(receiver, amount, TransactionType.TRANSFER_IN, description)
```

For platform fees:

```python
@transaction.atomic
def marketplace_sale(seller, buyer, amount, fee_rate=0.10):
    fee = amount * fee_rate
    net = amount - fee
    debit_wallet(buyer, amount, TransactionType.PURCHASE)
    credit_wallet(seller, net, TransactionType.SALE)
    credit_wallet(platform_account, fee, TransactionType.PLATFORM_FEE)
```

## Negative Balance Prevention

Never allow negative balances unless an explicit business rule permits it:

```python
# ALWAYS check before debit
if wallet.balance < amount:
    raise InsufficientFundsError(...)

# Database-level safety net
class Wallet(models.Model):
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    class Meta:
        constraints = [
            models.CheckConstraint(
                check=models.Q(balance__gte=0),
                name="wallet_non_negative_balance",
            ),
        ]
```

## Transaction Types

Use an enum or constant class for transaction types — never bare strings:

```python
class TransactionType(models.TextChoices):
    DEPOSIT = "deposit", "Deposit"
    WITHDRAWAL = "withdrawal", "Withdrawal"
    PURCHASE = "purchase", "Purchase"
    SALE = "sale", "Sale"
    REFUND = "refund", "Refund"
    REWARD = "reward", "Reward"
    AD_CREDIT = "ad_credit", "Ad Credit"
    BOUNTY_PAYOUT = "bounty_payout", "Bounty Payout"
    REFERRAL_BONUS = "referral_bonus", "Referral Bonus"
    PLATFORM_FEE = "platform_fee", "Platform Fee"
    TRANSFER_IN = "transfer_in", "Transfer In"
    TRANSFER_OUT = "transfer_out", "Transfer Out"
    ESCROW_HOLD = "escrow_hold", "Escrow Hold"
    ESCROW_RELEASE = "escrow_release", "Escrow Release"
```

## Audit Trail — MANDATORY

Every transaction MUST be logged with:
- `wallet` (FK)
- `amount` (positive for credit, negative for debit)
- `transaction_type` (from enum)
- `balance_after` (snapshot of balance post-operation)
- `description` (human-readable)
- `created_at` (auto-timestamp)
- `reference_id` (optional: link to order, bounty, etc.)

Transactions are **append-only** — never update or delete transaction records.

## Escrow for Marketplace

P2P trades use escrow hold/release:

```python
@transaction.atomic
def escrow_hold(buyer, amount, order):
    debit_wallet(buyer, amount, TransactionType.ESCROW_HOLD, f"Escrow for order {order.pk}")
    order.escrow_amount = amount
    order.status = "escrow_held"
    order.save(update_fields=["escrow_amount", "status"])

@transaction.atomic
def escrow_release(seller, order):
    fee = order.escrow_amount * order.fee_rate
    net = order.escrow_amount - fee
    credit_wallet(seller, net, TransactionType.ESCROW_RELEASE, f"Payment for order {order.pk}")
    credit_wallet(platform_account, fee, TransactionType.PLATFORM_FEE)
    order.status = "completed"
    order.save(update_fields=["status"])
```

## Bounty Payouts

```python
@transaction.atomic
def payout_bounty(bounty, claimant):
    credit_wallet(claimant, bounty.reward_amount, TransactionType.BOUNTY_PAYOUT,
                  f"Bounty #{bounty.pk}: {bounty.title}")
    bounty.status = "paid"
    bounty.paid_to = claimant
    bounty.save(update_fields=["status", "paid_to"])
```

## Forbidden Practices

- Never modify `balance` without `select_for_update()` — causes race conditions
- Never do financial operations outside `@transaction.atomic`
- Never delete transaction records — they are the audit trail
- Never hardcode amounts — always compute from business rules
- Never allow unauthenticated users to trigger financial operations
- Never use floating-point math for money — use `Decimal` exclusively
