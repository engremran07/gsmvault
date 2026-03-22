from django.urls import path
from rest_framework.routers import DefaultRouter

from .api import CommissionViewSet, ReferralCodeViewSet, ReferralTierViewSet
from .views import validate_code_api

app_name = "referral"

router = DefaultRouter()
router.register("tiers", ReferralTierViewSet, basename="tiers")
router.register("codes", ReferralCodeViewSet, basename="codes")
router.register("commissions", CommissionViewSet, basename="commissions")

urlpatterns = [
    path("validate/", validate_code_api, name="validate_code"),
    *router.urls,
]
