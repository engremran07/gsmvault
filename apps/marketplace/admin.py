from django.contrib import admin

from .models import Listing, SellerProfile, SellerVerification


@admin.register(SellerProfile)
class SellerProfileAdmin(admin.ModelAdmin):
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
class SellerVerificationAdmin(admin.ModelAdmin):
    list_display = ["seller", "document_type", "status", "submitted_at"]
    list_filter = ["status", "document_type"]


@admin.register(Listing)
class ListingAdmin(admin.ModelAdmin):
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
