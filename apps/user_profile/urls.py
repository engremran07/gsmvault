from rest_framework.routers import DefaultRouter

from .api import ActivityFeedViewSet, FollowingViewSet, ProfileViewSet

app_name = "user_profile"

router = DefaultRouter()
router.register("profiles", ProfileViewSet, basename="profiles")
router.register("following", FollowingViewSet, basename="following")
router.register("activity", ActivityFeedViewSet, basename="activity")

urlpatterns = router.urls
