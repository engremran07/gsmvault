"""Shop public page URLs (mounted at /shop/)."""

from django.urls import path

from . import views

app_name = "shop_public"

urlpatterns = [
    path("pricing/", views.pricing, name="pricing"),
    path("products/", views.product_list, name="product_list"),
    path("products/<slug:slug>/", views.product_detail, name="product_detail"),
    path("my-subscriptions/", views.my_subscriptions, name="my_subscriptions"),
    path("orders/", views.order_history, name="order_history"),
]
