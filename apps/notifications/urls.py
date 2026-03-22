from rest_framework.routers import DefaultRouter

from .api import (
    EmailQueueViewSet,
    EmailTemplateViewSet,
    NotificationQueueViewSet,
    NotificationTemplateViewSet,
    WebhookDeliveryViewSet,
    WebhookEndpointViewSet,
)

app_name = "notifications"

router = DefaultRouter()
router.register("templates", NotificationTemplateViewSet, basename="templates")
router.register("queue", NotificationQueueViewSet, basename="queue")
router.register("email-templates", EmailTemplateViewSet, basename="email-templates")
router.register("email-queue", EmailQueueViewSet, basename="email-queue")
router.register("webhooks", WebhookEndpointViewSet, basename="webhooks")
router.register(
    "webhook-deliveries", WebhookDeliveryViewSet, basename="webhook-deliveries"
)

urlpatterns = router.urls
