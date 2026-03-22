from rest_framework.routers import DefaultRouter

from .api import (
    BadgeViewSet,
    LeaderboardViewSet,
    LevelViewSet,
    UserBadgeViewSet,
    XPTransactionViewSet,
)

app_name = "gamification"

router = DefaultRouter()
router.register("levels", LevelViewSet, basename="levels")
router.register("badges", BadgeViewSet, basename="badges")
router.register("my-badges", UserBadgeViewSet, basename="my-badges")
router.register("xp", XPTransactionViewSet, basename="xp")
router.register("leaderboards", LeaderboardViewSet, basename="leaderboards")

urlpatterns = router.urls
