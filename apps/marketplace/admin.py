from django.contrib import admin

from .models import Listing, SellerAnalyticsSnapshot, SellerProfile, SellerVerification


@admin.register(SellerProfile)
class SellerProfileAdmin(admin.ModelAdmin[SellerProfile]):
    list_display = [
        "user",
        "display_name",
        "verified",
        "rating",
        "total_sales",
        "is_active",
    ]
    list_filter = ["verified", "is_active"]


@admin.register(SellerVerification)
class SellerVerificationAdmin(admin.ModelAdmin[SellerVerification]):
    list_display = ["seller", "document_type", "status", "submitted_at"]
    list_filter = ["status", "document_type"]


@admin.register(Listing)
class ListingAdmin(admin.ModelAdmin[Listing]):
    list_display = [
        "title",
        "seller",
        "price",
        "is_active",
        "is_featured",
        "sale_count",
    ]
    list_filter = ["is_active", "is_featured"]
    search_fields = ["title", "seller__user__email"]


@admin.register(SellerAnalyticsSnapshot)
class SellerAnalyticsSnapshotAdmin(admin.ModelAdmin[SellerAnalyticsSnapshot]):
    list_display = ["seller", "period", "views", "sales", "revenue", "created_at"]
    list_filter = ["period"]
    search_fields = ["seller__display_name", "period"]
