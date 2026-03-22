"""Bounty DRF API URLs (mounted at /api/v1/bounty/)."""

from rest_framework.routers import DefaultRouter

from .api import BountyRequestViewSet, BountySubmissionViewSet, PeerReviewViewSet

app_name = "bounty_api"

router = DefaultRouter()
router.register("requests", BountyRequestViewSet, basename="requests")
router.register("submissions", BountySubmissionViewSet, basename="submissions")
router.register("reviews", PeerReviewViewSet, basename="reviews")

urlpatterns = router.urls
