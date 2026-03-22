from django.urls import path
from rest_framework.routers import DefaultRouter

from . import views
from .api import BlockedIPViewSet, SecurityEventViewSet

app_name = "security"

router = DefaultRouter()
router.register("events", SecurityEventViewSet, basename="security-events")
router.register("blocked-ips", BlockedIPViewSet, basename="blocked-ips")

urlpatterns = [
    path("status/", views.security_status, name="security_status"),
    *router.urls,
]
