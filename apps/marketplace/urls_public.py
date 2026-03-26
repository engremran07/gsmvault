"""Marketplace public page URLs (mounted at /marketplace/)."""

from django.urls import path

from . import views

app_name = "marketplace_public"

urlpatterns = [
    path("", views.listing_browse, name="listing_browse"),
    path("listing/<int:pk>/", views.listing_detail, name="listing_detail"),
    path("seller/<int:pk>/", views.seller_profile, name="seller_profile"),
    path("my-listings/", views.my_listings, name="my_listings"),
    path("become-seller/", views.become_seller, name="become_seller"),
]
