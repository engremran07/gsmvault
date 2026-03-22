from rest_framework.routers import DefaultRouter

from .api import (
    OrderViewSet,
    ProductViewSet,
    SubscriptionPlanViewSet,
    SubscriptionViewSet,
)

app_name = "shop"

router = DefaultRouter()
router.register("plans", SubscriptionPlanViewSet, basename="plans")
router.register("products", ProductViewSet, basename="products")
router.register("subscriptions", SubscriptionViewSet, basename="subscriptions")
router.register("orders", OrderViewSet, basename="orders")

urlpatterns = router.urls
