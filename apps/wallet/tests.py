from __future__ import annotations

from decimal import Decimal
from typing import cast

from django.contrib.auth import get_user_model
from django.test import TestCase

from apps.users.models import CustomUserManager
from apps.wallet.models import EscrowHold, LedgerEntry
from apps.wallet.services import (
    InsufficientFundsError,
    cancel_escrow,
    credit,
    debit,
    get_or_create_wallet,
    lock_escrow,
)


class WalletServiceTests(TestCase):
    def setUp(self) -> None:
        user_model = get_user_model()
        user_manager = cast(CustomUserManager, user_model.objects)
        self.user = user_manager.create_user(
            username="wallet_user",
            email="wallet@example.com",
            password="test-pass-123",
        )
        self.wallet = get_or_create_wallet(self.user)

    def test_credit_and_debit_update_balance_and_ledger(self) -> None:
        credit_entry = credit(self.wallet, Decimal("100.00"), "fund", "ref-credit")
        debit_entry = debit(self.wallet, Decimal("40.00"), "spend", "ref-debit")

        self.wallet.refresh_from_db()

        self.assertEqual(self.wallet.balance, Decimal("60.00"))
        self.assertEqual(credit_entry.entry_type, LedgerEntry.EntryType.CREDIT)
        self.assertEqual(debit_entry.entry_type, LedgerEntry.EntryType.DEBIT)

    def test_debit_raises_on_insufficient_funds(self) -> None:
        credit(self.wallet, Decimal("10.00"), "fund", "ref-credit")

        with self.assertRaises(InsufficientFundsError):
            debit(self.wallet, Decimal("25.00"), "spend", "ref-debit")

    def test_lock_and_cancel_escrow_restores_available_balance(self) -> None:
        credit(self.wallet, Decimal("50.00"), "fund", "ref-credit")

        hold = lock_escrow(self.wallet, Decimal("20.00"), "escrow", "ref-escrow")
        self.wallet.refresh_from_db()
        self.assertEqual(hold.status, EscrowHold.Status.HOLDING)
        self.assertEqual(self.wallet.balance, Decimal("50.00"))
        self.assertEqual(self.wallet.locked_balance, Decimal("20.00"))

        cancel_escrow(hold)
        self.wallet.refresh_from_db()
        hold.refresh_from_db()

        self.assertEqual(hold.status, EscrowHold.Status.CANCELLED)
        self.assertEqual(self.wallet.locked_balance, Decimal("0"))
