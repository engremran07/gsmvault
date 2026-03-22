from django.contrib import admin

from .models import EscrowHold, LedgerEntry, PayoutRequest, Transaction, Wallet


@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin[Wallet]):
    list_display = ["user", "balance", "locked_balance", "currency", "is_frozen"]
    list_filter = ["is_frozen", "currency"]
    search_fields = ["user__email"]


@admin.register(LedgerEntry)
class LedgerEntryAdmin(admin.ModelAdmin[LedgerEntry]):
    list_display = ["wallet", "entry_type", "amount", "balance_after", "created_at"]
    list_filter = ["entry_type"]
    readonly_fields = ["created_at", "balance_after"]


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin[Transaction]):
    list_display = ["pk", "tx_type", "amount", "status", "created_at"]
    list_filter = ["status", "tx_type"]
    readonly_fields = ["created_at"]


@admin.register(EscrowHold)
class EscrowHoldAdmin(admin.ModelAdmin[EscrowHold]):
    list_display = ["wallet", "amount", "reason", "status", "created_at"]
    list_filter = ["status"]


@admin.register(PayoutRequest)
class PayoutRequestAdmin(admin.ModelAdmin[PayoutRequest]):
    list_display = ["wallet", "amount", "method", "status", "created_at"]
    list_filter = ["status", "method"]
