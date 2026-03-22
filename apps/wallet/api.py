from rest_framework import permissions, serializers, viewsets

from .models import LedgerEntry, PayoutRequest, Transaction, Wallet


class WalletSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wallet
        fields = ["id", "balance", "locked_balance", "currency", "is_frozen"]
        read_only_fields = fields


class LedgerEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = LedgerEntry
        fields = [
            "id",
            "entry_type",
            "amount",
            "description",
            "balance_after",
            "created_at",
        ]
        read_only_fields = fields


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ["id", "tx_type", "amount", "status", "reference", "created_at"]
        read_only_fields = ["id", "created_at"]


class PayoutRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = PayoutRequest
        fields = ["id", "amount", "method", "destination", "status", "created_at"]
        read_only_fields = ["id", "status", "created_at"]


class WalletViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = WalletSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return Wallet.objects.all()
        return Wallet.objects.filter(user=self.request.user)


class LedgerEntryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = LedgerEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = LedgerEntry.objects.all()
        if not getattr(self.request.user, "is_staff", False):
            qs = qs.filter(wallet__user=self.request.user)
        return qs


class PayoutRequestViewSet(viewsets.ModelViewSet):
    serializer_class = PayoutRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ["get", "post", "head", "options"]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return PayoutRequest.objects.all()
        return PayoutRequest.objects.filter(wallet__user=self.request.user)
