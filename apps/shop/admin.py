from django.contrib import admin

from .models import Order, OrderItem, Product, Subscription, SubscriptionPlan


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ["line_total"]


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = [
        "name",
        "price_monthly",
        "price_yearly",
        "max_downloads",
        "is_active",
    ]
    prepopulated_fields = {"slug": ["name"]}


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ["name", "product_type", "price", "is_active"]
    list_filter = ["product_type", "is_active"]
    prepopulated_fields = {"slug": ["name"]}


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ["user", "plan", "status", "started_at", "expires_at"]
    list_filter = ["status"]


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ["pk", "user", "status", "total", "created_at"]
    list_filter = ["status"]
    inlines = [OrderItemInline]
