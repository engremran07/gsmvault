"""apps.shop.services — Business logic for shop, packages, and quota enforcement."""

from __future__ import annotations

import logging
from datetime import timedelta
from decimal import Decimal
from typing import Any

from django.db.models import Count, Q, Sum
from django.utils import timezone

logger = logging.getLogger(__name__)


def get_shop_stats() -> dict[str, Any]:
    """Aggregate shop-wide KPIs for the admin dashboard."""
    from apps.shop.models import Order, PackageTier, Subscription, UserPackage

    now = timezone.now()
    thirty_days_ago = now - timedelta(days=30)

    active_subs = Subscription.objects.filter(status="active").count()
    total_orders = Order.objects.count()
    paid_orders = Order.objects.filter(status="paid")
    revenue_total = paid_orders.aggregate(t=Sum("total"))["t"] or Decimal("0")
    revenue_30d = paid_orders.filter(created_at__gte=thirty_days_ago).aggregate(
        t=Sum("total")
    )["t"] or Decimal("0")

    active_packages = UserPackage.objects.filter(status="active").count()
    trialing_packages = UserPackage.objects.filter(status="trialing").count()
    total_tiers = PackageTier.objects.filter(is_active=True).count()
    pending_orders = Order.objects.filter(status="pending").count()

    return {
        "active_subscriptions": active_subs,
        "total_orders": total_orders,
        "revenue_total": revenue_total,
        "revenue_30d": revenue_30d,
        "active_packages": active_packages,
        "trialing_packages": trialing_packages,
        "total_tiers": total_tiers,
        "pending_orders": pending_orders,
    }


def get_package_tier_list() -> list[Any]:
    """Return all package tiers with subscriber counts for admin view."""
    from apps.shop.models import PackageTier

    tiers = (
        PackageTier.objects.filter(is_active=True)
        .annotate(
            active_users=Count(
                "user_packages", filter=Q(user_packages__status="active")
            ),
            trialing_users=Count(
                "user_packages", filter=Q(user_packages__status="trialing")
            ),
        )
        .order_by("sort_order", "price_monthly")
    )
    return list(tiers)


def get_order_list(search: str = "", status_filter: str = "") -> Any:
    """Return filtered/searchable order queryset for admin."""
    from apps.shop.models import Order

    qs = Order.objects.select_related("user").order_by("-created_at")
    if status_filter:
        qs = qs.filter(status=status_filter)
    if search:
        qs = qs.filter(
            Q(user__email__icontains=search)
            | Q(user__username__icontains=search)
            | Q(external_order_id__icontains=search)
        )
    return qs


def get_subscription_list(search: str = "", status_filter: str = "") -> Any:
    """Return filtered subscription queryset for admin."""
    from apps.shop.models import Subscription

    qs = Subscription.objects.select_related("user", "plan").order_by("-started_at")
    if status_filter:
        qs = qs.filter(status=status_filter)
    if search:
        qs = qs.filter(
            Q(user__email__icontains=search) | Q(user__username__icontains=search)
        )
    return qs


def get_user_package_list(search: str = "", status_filter: str = "") -> Any:
    """Return filtered user-package queryset for admin."""
    from apps.shop.models import UserPackage

    qs = UserPackage.objects.select_related("user", "package").order_by("-started_at")
    if status_filter:
        qs = qs.filter(status=status_filter)
    if search:
        qs = qs.filter(
            Q(user__email__icontains=search) | Q(user__username__icontains=search)
        )
    return qs
