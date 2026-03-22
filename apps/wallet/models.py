"""apps.wallet — User wallets, ledger, transactions, escrow, payouts."""

from __future__ import annotations

from django.conf import settings
from django.db import models


class Wallet(models.Model):
    """One wallet per user — holds balance across ledger entry types."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="wallet"
    )
    balance = models.DecimalField(max_digits=18, decimal_places=8, default=0)
    locked_balance = models.DecimalField(max_digits=18, decimal_places=8, default=0)
    currency = models.CharField(max_length=10, default="CREDIT")
    is_frozen = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Wallet"
        verbose_name_plural = "Wallets"

    def __str__(self) -> str:
        return f"Wallet({self.user}) {self.balance} {self.currency}"


class LedgerEntry(models.Model):
    """Immutable double-entry ledger line — never mutated after creation."""

    class EntryType(models.TextChoices):
        CREDIT = "credit", "Credit"
        DEBIT = "debit", "Debit"
        LOCK = "lock", "Lock"
        UNLOCK = "unlock", "Unlock"
        EXPIRE = "expire", "Expire"

    wallet = models.ForeignKey(
        Wallet, on_delete=models.CASCADE, related_name="ledger_entries"
    )
    entry_type = models.CharField(max_length=10, choices=EntryType.choices)
    amount = models.DecimalField(max_digits=18, decimal_places=8)
    description = models.CharField(max_length=255, blank=True, default="")
    reference = models.CharField(max_length=100, blank=True, default="", db_index=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    balance_after = models.DecimalField(max_digits=18, decimal_places=8)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "Ledger Entry"
        verbose_name_plural = "Ledger Entries"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.entry_type} {self.amount} @ {self.created_at}"


class Transaction(models.Model):
    """Peer-to-peer or system wallet transfer."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        COMPLETED = "completed", "Completed"
        FAILED = "failed", "Failed"
        REVERSED = "reversed", "Reversed"

    class TxType(models.TextChoices):
        TRANSFER = "transfer", "Transfer"
        REWARD = "reward", "Reward"
        PURCHASE = "purchase", "Purchase"
        REFUND = "refund", "Refund"
        PAYOUT = "payout", "Payout"

    from_wallet = models.ForeignKey(
        Wallet,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="sent_transactions",
    )
    to_wallet = models.ForeignKey(
        Wallet,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="received_transactions",
    )
    amount = models.DecimalField(max_digits=18, decimal_places=8)
    tx_type = models.CharField(max_length=12, choices=TxType.choices)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    reference = models.CharField(max_length=200, blank=True, default="", db_index=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Tx#{self.pk} {self.tx_type} {self.amount} [{self.status}]"


class EscrowHold(models.Model):
    """Temporary lock on funds (e.g., bounty reward)."""

    class Status(models.TextChoices):
        HOLDING = "holding", "Holding"
        RELEASED = "released", "Released"
        CANCELLED = "cancelled", "Cancelled"

    wallet = models.ForeignKey(
        Wallet, on_delete=models.CASCADE, related_name="escrow_holds"
    )
    amount = models.DecimalField(max_digits=18, decimal_places=8)
    reason = models.CharField(max_length=255)
    reference = models.CharField(max_length=200, blank=True, default="", db_index=True)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.HOLDING, db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    released_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Escrow Hold"
        verbose_name_plural = "Escrow Holds"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Escrow {self.amount} [{self.status}]"


class PayoutRequest(models.Model):
    """User withdrawal / payout request."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        PROCESSING = "processing", "Processing"
        PAID = "paid", "Paid"
        REJECTED = "rejected", "Rejected"

    wallet = models.ForeignKey(
        Wallet, on_delete=models.CASCADE, related_name="payout_requests"
    )
    amount = models.DecimalField(max_digits=18, decimal_places=8)
    method = models.CharField(
        max_length=20,
        choices=[("paypal", "PayPal"), ("crypto", "Crypto"), ("bank", "Bank Transfer")],
    )
    destination = models.CharField(max_length=255)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Payout Request"
        verbose_name_plural = "Payout Requests"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Payout {self.amount} via {self.method} [{self.status}]"
