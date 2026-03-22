from rest_framework import permissions, serializers, viewsets
from rest_framework.filters import OrderingFilter, SearchFilter

from .models import (
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


class NotificationTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationTemplate
        fields = ["id", "name", "slug", "channel", "is_active"]
        read_only_fields = ["id"]


class NotificationQueueSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationQueue
        fields = ["id", "recipient", "channel", "status", "priority", "created_at"]
        read_only_fields = ["id", "created_at"]


class NotificationDeliverySerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationDelivery
        fields = [
            "id",
            "queue_item",
            "attempt_number",
            "delivered_at",
            "is_read",
            "read_at",
        ]
        read_only_fields = ["id", "delivered_at"]


class NotificationTemplateViewSet(viewsets.ModelViewSet):
    queryset = NotificationTemplate.objects.all()
    serializer_class = NotificationTemplateSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [SearchFilter]
    search_fields = ["name", "slug"]


class NotificationQueueViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = NotificationQueue.objects.all()
    serializer_class = NotificationQueueSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [OrderingFilter]


# ---------------------------------------------------------------------------
# Email system (merged from apps.email_system)
# ---------------------------------------------------------------------------


class EmailTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailTemplate
        fields = ["id", "name", "slug", "subject", "is_active"]


class EmailQueueSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailQueue
        fields = ["id", "to_email", "subject", "status", "created_at"]
        read_only_fields = fields


class EmailBounceSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailBounce
        fields = ["id", "email", "bounce_type", "occurred_at"]
        read_only_fields = fields


class EmailLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailLog
        fields = ["id", "to_email", "subject", "status", "sent_at"]
        read_only_fields = fields


class EmailTemplateViewSet(viewsets.ModelViewSet):
    queryset = EmailTemplate.objects.all()
    serializer_class = EmailTemplateSerializer
    permission_classes = [permissions.IsAdminUser]


class EmailQueueViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EmailQueue.objects.all()
    serializer_class = EmailQueueSerializer
    permission_classes = [permissions.IsAdminUser]


# ---------------------------------------------------------------------------
# Webhooks (merged from apps.webhooks)
# ---------------------------------------------------------------------------


class WebhookEndpointSerializer(serializers.ModelSerializer):
    class Meta:
        model = WebhookEndpoint
        fields = ["id", "url", "events", "is_active", "created_at"]
        read_only_fields = ["id", "created_at"]


class WebhookDeliverySerializer(serializers.ModelSerializer):
    class Meta:
        model = WebhookDelivery
        fields = [
            "id",
            "endpoint",
            "event_type",
            "status",
            "attempts",
            "created_at",
        ]
        read_only_fields = fields


class WebhookEndpointViewSet(viewsets.ModelViewSet):
    serializer_class = WebhookEndpointSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return WebhookEndpoint.objects.all()
        return WebhookEndpoint.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class WebhookDeliveryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = WebhookDeliverySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return WebhookDelivery.objects.all()
        return WebhookDelivery.objects.filter(endpoint__user=self.request.user)
