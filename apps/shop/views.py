"""apps.shop.views — Public shop pages (pricing, products)."""

from __future__ import annotations

import logging

from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, render

from .models import Order, PackageTier, Product, Subscription, UserPackage

logger = logging.getLogger(__name__)


def pricing(request: HttpRequest) -> HttpResponse:
    """Pricing page — subscription tier comparison."""
    tiers = PackageTier.objects.filter(is_active=True).order_by(
        "sort_order", "tier_level"
    )

    # Current user's package
    current_package = None
    if request.user.is_authenticated:
        current_package = (
            UserPackage.objects.filter(user=request.user, status="active")
            .select_related("package")
            .first()
        )

    context = {
        "tiers": tiers,
        "current_package": current_package,
    }
    return render(request, "shop/pricing.html", context)


def product_list(request: HttpRequest) -> HttpResponse:
    """Browse purchasable products."""
    products = Product.objects.filter(is_active=True).order_by("-created_at")

    context = {
        "products": products,
    }
    return render(request, "shop/product_list.html", context)


def product_detail(request: HttpRequest, slug: str) -> HttpResponse:
    """Single product detail page."""
    product = get_object_or_404(Product, slug=slug, is_active=True)

    context = {
        "product": product,
    }
    return render(request, "shop/product_detail.html", context)


@login_required
def my_subscriptions(request: HttpRequest) -> HttpResponse:
    """User's active subscriptions and package info."""
    user_package = (
        UserPackage.objects.filter(user=request.user)
        .select_related("package")
        .order_by("-started_at")
        .first()
    )

    legacy_subs = (
        Subscription.objects.filter(user=request.user)
        .select_related("plan")
        .order_by("-started_at")
    )

    context = {
        "user_package": user_package,
        "legacy_subs": legacy_subs,
    }
    return render(request, "shop/my_subscriptions.html", context)


@login_required
def order_history(request: HttpRequest) -> HttpResponse:
    """User's order history."""
    orders = (
        Order.objects.filter(user=request.user)
        .prefetch_related("items__product")  # type: ignore[attr-defined]
        .order_by("-created_at")
    )

    context = {
        "orders": orders,
    }
    return render(request, "shop/order_history.html", context)
