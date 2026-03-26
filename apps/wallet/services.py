"""apps.wallet.services — Atomic wallet operations with double-entry ledger.

All public functions use ``select_for_update()`` inside
``transaction.atomic()`` to guarantee correctness under concurrency.
"""

from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING

from django.db import transaction
from django.utils import timezone

from .models import EscrowHold, LedgerEntry, Transaction, Wallet

if TYPE_CHECKING:
    from django.contrib.auth.models import AbstractBaseUser


class InsufficientFundsError(ValueError):
    """Raised when a debit/escrow exceeds the available wallet balance."""


# ---------------------------------------------------------------------------
# Wallet lifecycle
# ---------------------------------------------------------------------------


def get_or_create_wallet(user: AbstractBaseUser) -> Wallet:
    """Return the user's wallet, creating one if it doesn't exist."""
    wallet, _ = Wallet.objects.get_or_create(user=user)
    return wallet


# ---------------------------------------------------------------------------
# Ledger helpers (internal)
# ---------------------------------------------------------------------------


def _record_entry(
    wallet: Wallet,
    entry_type: str,
    amount: Decimal,
    description: str,
    reference: str,
) -> LedgerEntry:
    """Append an immutable ledger line — caller must already hold the row lock."""
    return LedgerEntry.objects.create(
        wallet=wallet,
        entry_type=entry_type,
        amount=amount,
        description=description,
        reference=reference,
        balance_after=wallet.balance,
    )


# ---------------------------------------------------------------------------
# Credit / Debit
# ---------------------------------------------------------------------------


def credit(
    wallet: Wallet,
    amount: Decimal,
    description: str = "",
    reference: str = "",
) -> LedgerEntry:
    """Add funds to *wallet*.  Returns the new :class:`LedgerEntry`."""
    if amount <= 0:
        raise ValueError("Credit amount must be positive.")
    with transaction.atomic():
        wallet = Wallet.objects.select_for_update().get(pk=wallet.pk)
        wallet.balance += amount
        wallet.save(update_fields=["balance", "updated_at"])
        return _record_entry(
            wallet, LedgerEntry.EntryType.CREDIT, amount, description, reference
        )


def debit(
    wallet: Wallet,
    amount: Decimal,
    description: str = "",
    reference: str = "",
) -> LedgerEntry:
    """Withdraw funds from *wallet*.

    Raises :class:`InsufficientFundsError` when the available balance
    (``balance - locked_balance``) is too low.
    """
    if amount <= 0:
        raise ValueError("Debit amount must be positive.")
    with transaction.atomic():
        wallet = Wallet.objects.select_for_update().get(pk=wallet.pk)
        available = wallet.balance - wallet.locked_balance
        if available < amount:
            raise InsufficientFundsError(
                f"Need {amount} but only {available} available "
                f"(balance={wallet.balance}, locked={wallet.locked_balance})."
            )
        wallet.balance -= amount
        wallet.save(update_fields=["balance", "updated_at"])
        return _record_entry(
            wallet, LedgerEntry.EntryType.DEBIT, amount, description, reference
        )


# ---------------------------------------------------------------------------
# Escrow (lock / release / cancel)
# ---------------------------------------------------------------------------


def lock_escrow(
    wallet: Wallet,
    amount: Decimal,
    reason: str = "",
    reference: str = "",
) -> EscrowHold:
    """Lock *amount* from *wallet* into a new :class:`EscrowHold`.

    The locked funds are moved from ``balance`` to ``locked_balance`` so they
    cannot be spent elsewhere.
    """
    if amount <= 0:
        raise ValueError("Escrow amount must be positive.")
    with transaction.atomic():
        wallet = Wallet.objects.select_for_update().get(pk=wallet.pk)
        available = wallet.balance - wallet.locked_balance
        if available < amount:
            raise InsufficientFundsError(
                f"Need {amount} to escrow but only {available} available."
            )
        wallet.locked_balance += amount
        wallet.save(update_fields=["locked_balance", "updated_at"])
        _record_entry(wallet, LedgerEntry.EntryType.LOCK, amount, reason, reference)
        return EscrowHold.objects.create(
            wallet=wallet,
            amount=amount,
            reason=reason,
            reference=reference,
            status=EscrowHold.Status.HOLDING,
        )


def release_escrow(
    escrow_hold: EscrowHold,
    to_wallet: Wallet,
) -> Transaction:
    """Release held funds to *to_wallet* and mark the escrow as released.

    Creates a completed :class:`Transaction` linking source → target.
    """
    with transaction.atomic():
        escrow_hold = EscrowHold.objects.select_for_update().get(pk=escrow_hold.pk)
        if escrow_hold.status != EscrowHold.Status.HOLDING:
            raise ValueError(
                f"Escrow {escrow_hold.pk} is {escrow_hold.status}, not HOLDING."
            )
        source = Wallet.objects.select_for_update().get(pk=escrow_hold.wallet_id)  # type: ignore[attr-defined]
        target = Wallet.objects.select_for_update().get(pk=to_wallet.pk)

        amount = escrow_hold.amount

        # Unlock from source
        source.locked_balance -= amount
        source.balance -= amount
        source.save(update_fields=["balance", "locked_balance", "updated_at"])
        _record_entry(
            source,
            LedgerEntry.EntryType.UNLOCK,
            amount,
            f"Escrow released → user {target.user_id}",  # type: ignore[attr-defined]
            escrow_hold.reference,
        )

        # Credit target
        target.balance += amount
        target.save(update_fields=["balance", "updated_at"])
        _record_entry(
            target,
            LedgerEntry.EntryType.CREDIT,
            amount,
            f"Escrow received from user {source.user_id}",  # type: ignore[attr-defined]
            escrow_hold.reference,
        )

        # Mark escrow released
        escrow_hold.status = EscrowHold.Status.RELEASED
        escrow_hold.released_at = timezone.now()
        escrow_hold.save(update_fields=["status", "released_at"])

        return Transaction.objects.create(
            from_wallet=source,
            to_wallet=target,
            amount=amount,
            tx_type=Transaction.TxType.TRANSFER,
            status=Transaction.Status.COMPLETED,
            reference=escrow_hold.reference,
            completed_at=timezone.now(),
        )


def cancel_escrow(escrow_hold: EscrowHold) -> None:
    """Cancel an escrow hold and return funds to the owner's available balance."""
    with transaction.atomic():
        escrow_hold = EscrowHold.objects.select_for_update().get(pk=escrow_hold.pk)
        if escrow_hold.status != EscrowHold.Status.HOLDING:
            raise ValueError(
                f"Escrow {escrow_hold.pk} is {escrow_hold.status}, not HOLDING."
            )
        wallet = Wallet.objects.select_for_update().get(pk=escrow_hold.wallet_id)  # type: ignore[attr-defined]

        wallet.locked_balance -= escrow_hold.amount
        wallet.save(update_fields=["locked_balance", "updated_at"])
        _record_entry(
            wallet,
            LedgerEntry.EntryType.UNLOCK,
            escrow_hold.amount,
            "Escrow cancelled — funds returned",
            escrow_hold.reference,
        )

        escrow_hold.status = EscrowHold.Status.CANCELLED
        escrow_hold.released_at = timezone.now()
        escrow_hold.save(update_fields=["status", "released_at"])
