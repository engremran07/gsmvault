from rest_framework import permissions, serializers, viewsets

from .models import Commission, ReferralCode, ReferralTier


class ReferralTierSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReferralTier
        fields = ["id", "name", "min_referrals", "commission_rate", "perks"]


class ReferralCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReferralCode
        fields = [
            "id",
            "code",
            "tier",
            "clicks",
            "conversions",
            "is_active",
            "created_at",
        ]
        read_only_fields = ["id", "code", "clicks", "conversions", "created_at"]


class CommissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Commission
        fields = ["id", "referral_code", "amount", "status", "created_at"]
        read_only_fields = ["id", "created_at"]


class ReferralTierViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ReferralTier.objects.all()
    serializer_class = ReferralTierSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]


class ReferralCodeViewSet(viewsets.ModelViewSet):
    serializer_class = ReferralCodeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return ReferralCode.objects.all()
        return ReferralCode.objects.filter(user=self.request.user)


class CommissionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CommissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return Commission.objects.all()
        return Commission.objects.filter(referral_code__user=self.request.user)
