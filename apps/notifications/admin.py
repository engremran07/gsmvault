from django.contrib import admin

from .models import (
    DeliveryAttempt,
    EmailBounce,
    EmailLog,
    EmailQueue,
    EmailTemplate,
    NotificationDelivery,
    NotificationQueue,
    NotificationTemplate,
    WebhookDelivery,
    WebhookEndpoint,
)


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


# =============================================================================
# Email System (merged from apps.email_system)
# =============================================================================


@admin.register(EmailTemplate)
class EmailTemplateAdmin(admin.ModelAdmin[EmailTemplate]):
    list_display = ["name", "slug", "is_active", "created_at", "updated_at"]
    list_filter = ["is_active"]
    search_fields = ["name", "slug", "subject"]
    prepopulated_fields = {"slug": ["name"]}
    readonly_fields = ["created_at", "updated_at"]


@admin.register(EmailQueue)
class EmailQueueAdmin(admin.ModelAdmin[EmailQueue]):
    list_display = [
        "to_email",
        "subject",
        "status",
        "retry_count",
        "scheduled_at",
        "created_at",
    ]
    list_filter = ["status"]
    search_fields = ["to_email", "subject"]
    readonly_fields = ["created_at", "sent_at"]


@admin.register(EmailBounce)
class EmailBounceAdmin(admin.ModelAdmin[EmailBounce]):
    list_display = ["email", "bounce_type", "timestamp"]
    list_filter = ["bounce_type"]
    search_fields = ["email"]
    readonly_fields = ["timestamp"]


@admin.register(EmailLog)
class EmailLogAdmin(admin.ModelAdmin[EmailLog]):
    list_display = ["to_email", "subject", "status", "provider", "sent_at"]
    list_filter = ["status", "provider"]
    search_fields = ["to_email", "subject", "message_id"]
    readonly_fields = ["sent_at"]


# =============================================================================
# Webhooks (merged from apps.webhooks)
# =============================================================================


@admin.register(WebhookEndpoint)
class WebhookEndpointAdmin(admin.ModelAdmin[WebhookEndpoint]):
    list_display = ["user", "url", "is_active", "created_at"]
    list_filter = ["is_active"]
    search_fields = ["user__email", "url"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(WebhookDelivery)
class WebhookDeliveryAdmin(admin.ModelAdmin[WebhookDelivery]):
    list_display = ["endpoint", "event_type", "status", "attempts", "created_at"]
    list_filter = ["status", "event_type"]
    search_fields = ["event_type"]
    readonly_fields = ["created_at", "delivered_at"]


@admin.register(DeliveryAttempt)
class DeliveryAttemptAdmin(admin.ModelAdmin[DeliveryAttempt]):
    list_display = [
        "delivery",
        "attempt_number",
        "response_code",
        "latency_ms",
        "timestamp",
    ]
    list_filter = ["response_code"]
    readonly_fields = ["timestamp"]
