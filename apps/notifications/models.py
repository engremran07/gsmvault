"""
apps.notifications — Template-driven notification delivery system.
Note: Notification, NotificationPreferences, PushSubscription live in apps.users.
This app adds: templates, queue, and delivery tracking.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models


class NotificationChannel(models.TextChoices):
    EMAIL = "email", "Email"
    PUSH = "push", "Push"
    IN_APP = "in_app", "In-App"
    SMS = "sms", "SMS"
    WEBHOOK = "webhook", "Webhook"


class NotificationTemplate(models.Model):
    """Reusable notification templates rendered per channel."""

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, db_index=True)
    channel = models.CharField(max_length=10, choices=NotificationChannel.choices)
    subject_template = models.CharField(max_length=255, blank=True, default="")
    body_template = models.TextField()
    variables = models.JSONField(
        default=list,
        blank=True,
        help_text="List of variable names expected in context",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Notification Template"
        verbose_name_plural = "Notification Templates"
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.name} [{self.channel}]"


class NotificationQueue(models.Model):
    """Pending notification deliveries — consumed by Celery workers."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        PROCESSING = "processing", "Processing"
        SENT = "sent", "Sent"
        FAILED = "failed", "Failed"
        CANCELLED = "cancelled", "Cancelled"

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_queue",
    )
    template = models.ForeignKey(
        NotificationTemplate,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="queued",
    )
    channel = models.CharField(max_length=10, choices=NotificationChannel.choices)
    context = models.JSONField(default=dict, blank=True)
    # Rendered at send time
    subject = models.CharField(max_length=255, blank=True, default="")
    body = models.TextField(blank=True, default="")
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    priority = models.SmallIntegerField(default=5, help_text="Lower = higher priority")
    scheduled_at = models.DateTimeField(null=True, blank=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    process_after = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Notification Queue Item"
        verbose_name_plural = "Notification Queue"
        ordering = ["priority", "created_at"]
        indexes = [
            models.Index(
                fields=["status", "priority", "created_at"], name="nq_status_prio_idx"
            ),
        ]

    def __str__(self) -> str:
        return f"{self.channel} → {self.recipient} [{self.status}]"


class NotificationDelivery(models.Model):
    """Final delivery record with attempt tracking."""

    queue_item = models.ForeignKey(
        NotificationQueue,
        on_delete=models.CASCADE,
        related_name="deliveries",
    )
    attempt_number = models.PositiveSmallIntegerField(default=1)
    delivered_at = models.DateTimeField(null=True, blank=True, db_index=True)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    error = models.TextField(blank=True, default="")
    external_id = models.CharField(max_length=200, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Notification Delivery"
        verbose_name_plural = "Notification Deliveries"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Delivery#{self.pk} attempt {self.attempt_number}"


# =============================================================================
# Email System — merged from apps.email_system
# =============================================================================


class EmailTemplate(models.Model):
    """HTML + text email templates rendered at send time."""

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, db_index=True)
    subject = models.CharField(max_length=255)
    body_html = models.TextField()
    body_text = models.TextField(blank=True, default="")
    variables = models.JSONField(
        default=list,
        blank=True,
        help_text="List of variable names expected in context",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "email_system_emailtemplate"
        verbose_name = "Email Template"
        verbose_name_plural = "Email Templates"
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class EmailQueue(models.Model):
    """Outbound email queue — consumed by Celery send workers."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        PROCESSING = "processing", "Processing"
        SENT = "sent", "Sent"
        FAILED = "failed", "Failed"
        CANCELLED = "cancelled", "Cancelled"

    template = models.ForeignKey(
        EmailTemplate,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="queued_emails",
    )
    to_email = models.EmailField(db_index=True)
    from_email = models.EmailField(blank=True, default="")
    subject = models.CharField(max_length=255)
    body_html = models.TextField(blank=True, default="")
    context = models.JSONField(default=dict, blank=True)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    retry_count = models.SmallIntegerField(default=0)
    scheduled_at = models.DateTimeField(null=True, blank=True, db_index=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    error = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "email_system_emailqueue"
        verbose_name = "Email Queue Item"
        verbose_name_plural = "Email Queue"
        ordering = ["created_at"]
        indexes = [
            models.Index(fields=["status", "scheduled_at"], name="eq_status_sched_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.to_email} — {self.subject} [{self.status}]"


class EmailBounce(models.Model):
    """Bounce / complaint event recorded from the email provider."""

    class BounceType(models.TextChoices):
        HARD = "hard", "Hard Bounce"
        SOFT = "soft", "Soft Bounce"
        COMPLAINT = "complaint", "Spam Complaint"

    email = models.EmailField(db_index=True)
    bounce_type = models.CharField(max_length=12, choices=BounceType.choices)
    message = models.TextField(blank=True, default="")
    provider_data = models.JSONField(default=dict, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = "email_system_emailbounce"
        verbose_name = "Email Bounce"
        verbose_name_plural = "Email Bounces"
        ordering = ["-timestamp"]

    def __str__(self) -> str:
        return f"{self.bounce_type} — {self.email}"


class EmailLog(models.Model):
    """Immutable send log — one row per email successfully dispatched."""

    to_email = models.EmailField(db_index=True)
    subject = models.CharField(max_length=255)
    template = models.ForeignKey(
        EmailTemplate,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="send_logs",
    )
    status = models.CharField(max_length=12)
    sent_at = models.DateTimeField(auto_now_add=True, db_index=True)
    message_id = models.CharField(max_length=200, blank=True, default="")
    provider = models.CharField(max_length=50, blank=True, default="")

    class Meta:
        db_table = "email_system_emaillog"
        verbose_name = "Email Log"
        verbose_name_plural = "Email Logs"
        ordering = ["-sent_at"]

    def __str__(self) -> str:
        return f"{self.to_email} — {self.subject}"


# =============================================================================
# Webhooks — merged from apps.webhooks
# =============================================================================


class WebhookEndpoint(models.Model):
    """User-registered HTTPS endpoint for event delivery."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="webhook_endpoints",
    )
    url = models.URLField(max_length=500)
    events = models.JSONField(default=list, help_text="List of event type strings")
    secret_hash = models.CharField(
        max_length=128, help_text="HMAC secret — stored hashed"
    )
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "webhooks_webhookendpoint"
        verbose_name = "Webhook Endpoint"
        verbose_name_plural = "Webhook Endpoints"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.user} → {self.url}"


class WebhookDelivery(models.Model):
    """Delivery task for a single event to a single endpoint."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        DELIVERED = "delivered", "Delivered"
        FAILED = "failed", "Failed"
        RETRYING = "retrying", "Retrying"

    endpoint = models.ForeignKey(
        WebhookEndpoint, on_delete=models.CASCADE, related_name="deliveries"
    )
    event_type = models.CharField(max_length=100, db_index=True)
    payload = models.JSONField(default=dict)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    attempts = models.SmallIntegerField(default=0)
    next_retry_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "webhooks_webhookdelivery"
        verbose_name = "Webhook Delivery"
        verbose_name_plural = "Webhook Deliveries"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.event_type} → {self.endpoint} [{self.status}]"


class DeliveryAttempt(models.Model):
    """Individual HTTP attempt log for a webhook delivery."""

    delivery = models.ForeignKey(
        WebhookDelivery, on_delete=models.CASCADE, related_name="delivery_attempts"
    )
    attempt_number = models.SmallIntegerField()
    response_code = models.SmallIntegerField(null=True, blank=True)
    response_body = models.TextField(blank=True, default="")
    error = models.TextField(blank=True, default="")
    latency_ms = models.PositiveIntegerField(default=0)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "webhooks_deliveryattempt"
        verbose_name = "Delivery Attempt"
        verbose_name_plural = "Delivery Attempts"
        ordering = ["timestamp"]

    def __str__(self) -> str:
        return f"Attempt #{self.attempt_number} → {self.response_code}"
