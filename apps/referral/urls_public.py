"""apps.referral.urls_public — Public referral pages."""

from django.urls import path

from .views import referral_dashboard

app_name = "referral_public"

urlpatterns = [
    path("", referral_dashboard, name="dashboard"),
]
