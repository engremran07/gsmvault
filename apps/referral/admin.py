from django.contrib import admin

from .models import Commission, ReferralCode, ReferralTier


@admin.register(ReferralTier)
class ReferralTierAdmin(admin.ModelAdmin[ReferralTier]):
    list_display = ["name", "min_referrals", "commission_rate"]


@admin.register(ReferralCode)
class ReferralCodeAdmin(admin.ModelAdmin[ReferralCode]):
    list_display = ["code", "user", "clicks", "conversions", "is_active", "created_at"]
    list_filter = ["is_active"]
    search_fields = ["code", "user__email"]


@admin.register(Commission)
class CommissionAdmin(admin.ModelAdmin[Commission]):
    list_display = ["referral_code", "referred_user", "amount", "status", "created_at"]
    list_filter = ["status"]
