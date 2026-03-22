from rest_framework.routers import DefaultRouter

from .api import APIEndpointViewSet, APIKeyViewSet

app_name = "api"

router = DefaultRouter()
router.register("keys", APIKeyViewSet, basename="keys")
router.register("endpoints", APIEndpointViewSet, basename="endpoints")

urlpatterns = router.urls
