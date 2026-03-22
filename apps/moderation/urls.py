from rest_framework.routers import DefaultRouter

from .api import AppealViewSet, ModerationItemViewSet, ModerationRuleViewSet

app_name = "moderation"

router = DefaultRouter()
router.register("rules", ModerationRuleViewSet, basename="rules")
router.register("items", ModerationItemViewSet, basename="items")
router.register("appeals", AppealViewSet, basename="appeals")

urlpatterns = router.urls
