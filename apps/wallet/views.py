"""apps.wallet.views — Public wallet pages (balance, transactions, payout)."""

from __future__ import annotations

import logging

from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.shortcuts import render

from .models import LedgerEntry, PayoutRequest, Transaction, Wallet

logger = logging.getLogger(__name__)


@login_required
def wallet_dashboard(request: HttpRequest) -> HttpResponse:
    """Wallet overview — balance + recent transactions."""
    wallet = Wallet.objects.filter(user=request.user).first()

    recent_ledger: list[LedgerEntry] = []
    recent_transactions: list[Transaction] = []
    pending_payouts: list[PayoutRequest] = []

    if wallet:
        recent_ledger = list(
            LedgerEntry.objects.filter(wallet=wallet).order_by("-created_at")[:10]
        )
        recent_transactions = list(
            Transaction.objects.filter(from_wallet=wallet).order_by("-created_at")[:10]
            | Transaction.objects.filter(to_wallet=wallet).order_by("-created_at")[:10]
        )
        pending_payouts = list(
            PayoutRequest.objects.filter(wallet=wallet, status="pending")
        )

    context = {
        "wallet": wallet,
        "recent_ledger": recent_ledger,
        "recent_transactions": recent_transactions,
        "pending_payouts": pending_payouts,
    }
    return render(request, "wallet/dashboard.html", context)


@login_required
def wallet_transactions(request: HttpRequest) -> HttpResponse:
    """Full transaction and ledger history."""
    wallet = Wallet.objects.filter(user=request.user).first()

    ledger_entries: list[LedgerEntry] = []
    if wallet:
        ledger_entries = list(
            LedgerEntry.objects.filter(wallet=wallet).order_by("-created_at")[:100]
        )

    template = "wallet/transactions.html"
    if request.headers.get("HX-Request"):
        template = "wallet/fragments/transaction_list.html"

    context = {
        "wallet": wallet,
        "ledger_entries": ledger_entries,
    }
    return render(request, template, context)


@login_required
def wallet_payouts(request: HttpRequest) -> HttpResponse:
    """Payout requests — history and new request."""
    wallet = Wallet.objects.filter(user=request.user).first()

    payouts: list[PayoutRequest] = []
    if wallet:
        payouts = list(
            PayoutRequest.objects.filter(wallet=wallet).order_by("-created_at")[:50]
        )

    context = {
        "wallet": wallet,
        "payouts": payouts,
    }
    return render(request, "wallet/payouts.html", context)
