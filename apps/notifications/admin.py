from django.contrib import admin

from .models import NotificationDelivery, NotificationQueue, NotificationTemplate


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin[NotificationTemplate]):
    list_display = ["name", "slug", "channel", "is_active", "updated_at"]
    list_filter = ["channel", "is_active"]
    search_fields = ["name", "slug"]
    prepopulated_fields = {"slug": ["name"]}


@admin.register(NotificationQueue)
class NotificationQueueAdmin(admin.ModelAdmin[NotificationQueue]):
    list_display = ["recipient", "channel", "status", "priority", "created_at"]
    list_filter = ["status", "channel"]
    search_fields = ["recipient__email"]
    readonly_fields = ["created_at"]


@admin.register(NotificationDelivery)
class NotificationDeliveryAdmin(admin.ModelAdmin[NotificationDelivery]):
    list_display = ["queue_item", "attempt_number", "delivered_at", "is_read"]
    list_filter = ["is_read"]
    readonly_fields = ["created_at"]
