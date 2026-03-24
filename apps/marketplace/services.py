"""apps.marketplace.services — Business logic for marketplace admin."""

from __future__ import annotations

import logging
from datetime import timedelta
from decimal import Decimal
from typing import Any

from django.db.models import Q, Sum
from django.utils import timezone

logger = logging.getLogger(__name__)


def get_marketplace_stats() -> dict[str, Any]:
    """Aggregate marketplace KPIs for the admin dashboard."""
    from apps.marketplace.models import Listing, SellerProfile, SellerVerification

    now = timezone.now()
    thirty_days_ago = now - timedelta(days=30)

    total_sellers = SellerProfile.objects.filter(is_active=True).count()
    verified_sellers = SellerProfile.objects.filter(
        is_active=True, verified=True
    ).count()
    pending_verifications = SellerVerification.objects.filter(status="pending").count()

    total_listings = Listing.objects.filter(is_active=True).count()
    featured_listings = Listing.objects.filter(is_active=True, is_featured=True).count()
    total_sales = SellerProfile.objects.aggregate(t=Sum("total_sales"))["t"] or 0
    total_revenue = (
        Listing.objects.filter(is_active=True).aggregate(t=Sum("sale_count"))["t"] or 0
    )

    new_listings_30d = Listing.objects.filter(created_at__gte=thirty_days_ago).count()

    return {
        "total_sellers": total_sellers,
        "verified_sellers": verified_sellers,
        "pending_verifications": pending_verifications,
        "total_listings": total_listings,
        "featured_listings": featured_listings,
        "total_sales": total_sales,
        "total_revenue": Decimal(str(total_revenue)),
        "new_listings_30d": new_listings_30d,
    }


def get_seller_list(search: str = "", verified_filter: str = "") -> Any:
    """Return filtered seller queryset for admin."""
    from apps.marketplace.models import SellerProfile

    qs = SellerProfile.objects.select_related("user").order_by("-total_sales")
    if verified_filter == "verified":
        qs = qs.filter(verified=True)
    elif verified_filter == "unverified":
        qs = qs.filter(verified=False)
    if search:
        qs = qs.filter(
            Q(user__email__icontains=search)
            | Q(user__username__icontains=search)
            | Q(display_name__icontains=search)
        )
    return qs


def get_listing_list(search: str = "", status_filter: str = "") -> Any:
    """Return filtered listing queryset for admin."""
    from apps.marketplace.models import Listing

    qs = Listing.objects.select_related("seller", "seller__user").order_by(
        "-created_at"
    )
    if status_filter == "active":
        qs = qs.filter(is_active=True)
    elif status_filter == "inactive":
        qs = qs.filter(is_active=False)
    elif status_filter == "featured":
        qs = qs.filter(is_featured=True)
    if search:
        qs = qs.filter(
            Q(title__icontains=search) | Q(seller__display_name__icontains=search)
        )
    return qs


def get_verification_list(status_filter: str = "") -> Any:
    """Return filtered verification requests for admin."""
    from apps.marketplace.models import SellerVerification

    qs = SellerVerification.objects.select_related(
        "seller", "seller__user", "reviewer"
    ).order_by("-submitted_at")
    if status_filter:
        qs = qs.filter(status=status_filter)
    return qs
