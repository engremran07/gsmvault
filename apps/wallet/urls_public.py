"""Wallet public page URLs (mounted at /wallet/)."""

from django.urls import path

from . import views

app_name = "wallet_public"

urlpatterns = [
    path("", views.wallet_dashboard, name="dashboard"),
    path("transactions/", views.wallet_transactions, name="transactions"),
    path("payouts/", views.wallet_payouts, name="payouts"),
]
