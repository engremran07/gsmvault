from django.contrib import admin

from .models import (
    Order,
    OrderItem,
    PackageQuotaOverride,
    PackageTier,
    Product,
    Subscription,
    SubscriptionPlan,
    UserPackage,
)


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ["line_total"]


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin[SubscriptionPlan]):
    list_display = [
        "name",
        "price_monthly",
        "price_yearly",
        "max_downloads",
        "is_active",
    ]
    prepopulated_fields = {"slug": ["name"]}


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin[Product]):
    list_display = ["name", "product_type", "price", "is_active"]
    list_filter = ["product_type", "is_active"]
    prepopulated_fields = {"slug": ["name"]}


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin[Subscription]):
    list_display = ["user", "plan", "status", "started_at", "expires_at"]
    list_filter = ["status"]


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin[Order]):
    list_display = ["pk", "user", "status", "total", "created_at"]
    list_filter = ["status"]
    inlines = [OrderItemInline]


@admin.register(PackageTier)
class PackageTierAdmin(admin.ModelAdmin[PackageTier]):
    list_display = [
        "name",
        "tier_level",
        "price_monthly",
        "daily_download_limit",
        "is_active",
        "is_default",
        "sort_order",
    ]
    list_filter = ["tier_level", "is_active", "is_default"]
    search_fields = ["name", "slug"]
    prepopulated_fields = {"slug": ["name"]}
    list_editable = ["sort_order", "is_active"]


@admin.register(UserPackage)
class UserPackageAdmin(admin.ModelAdmin[UserPackage]):
    list_display = [
        "user",
        "package",
        "status",
        "billing_cycle",
        "downloads_today",
        "started_at",
        "expires_at",
    ]
    list_filter = ["status", "billing_cycle"]
    search_fields = ["user__email", "user__username"]
    readonly_fields = ["started_at"]


@admin.register(PackageQuotaOverride)
class PackageQuotaOverrideAdmin(admin.ModelAdmin[PackageQuotaOverride]):
    list_display = ["user", "reason", "granted_by", "expires_at", "created_at"]
    list_filter = ["expires_at"]
    search_fields = ["user__email", "reason"]
    readonly_fields = ["created_at"]
