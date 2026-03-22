from rest_framework.routers import DefaultRouter

from .api import ListingViewSet, SellerProfileViewSet

app_name = "marketplace"

router = DefaultRouter()
router.register("sellers", SellerProfileViewSet, basename="sellers")
router.register("listings", ListingViewSet, basename="listings")

urlpatterns = router.urls
