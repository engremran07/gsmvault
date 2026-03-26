"""apps.marketplace.views — Public marketplace pages."""

from __future__ import annotations

import logging

from django.contrib.auth.decorators import login_required
from django.db.models import Q, QuerySet
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, redirect, render

from .models import Listing, SellerProfile

logger = logging.getLogger(__name__)


def listing_browse(request: HttpRequest) -> HttpResponse:
    """Browse all active marketplace listings with search and filters."""
    q = request.GET.get("q", "").strip()
    sort = request.GET.get("sort", "-created_at")
    featured_only = request.GET.get("featured") == "1"

    qs: QuerySet[Listing] = Listing.objects.filter(is_active=True).select_related(
        "seller__user", "firmware"
    )

    if featured_only:
        qs = qs.filter(is_featured=True)

    if q:
        qs = qs.filter(Q(title__icontains=q) | Q(description__icontains=q))

    allowed_sorts = {
        "-created_at": "-created_at",
        "price": "price",
        "-price": "-price",
        "popular": "-sale_count",
    }
    qs = qs.order_by(allowed_sorts.get(sort, "-created_at"))

    template = "marketplace/listing_browse.html"
    if request.headers.get("HX-Request"):
        template = "marketplace/fragments/listing_grid.html"

    context = {
        "listings": qs[:60],
        "search_query": q,
        "current_sort": sort,
        "featured_only": featured_only,
    }
    return render(request, template, context)


def listing_detail(request: HttpRequest, pk: int) -> HttpResponse:
    """Single listing detail page."""
    listing = get_object_or_404(
        Listing.objects.select_related("seller__user", "firmware"),
        pk=pk,
        is_active=True,
    )

    # Increment view count
    Listing.objects.filter(pk=pk).update(view_count=listing.view_count + 1)

    # Other listings by same seller
    related = (
        Listing.objects.filter(seller=listing.seller, is_active=True)
        .exclude(pk=pk)
        .select_related("seller__user")[:4]
    )

    context = {
        "listing": listing,
        "seller": listing.seller,
        "related_listings": related,
    }
    return render(request, "marketplace/listing_detail.html", context)


def seller_profile(request: HttpRequest, pk: int) -> HttpResponse:
    """Public seller profile page with their listings."""
    seller = get_object_or_404(
        SellerProfile.objects.select_related("user"),
        pk=pk,
        is_active=True,
    )

    listings = (
        Listing.objects.filter(seller=seller, is_active=True)
        .select_related("firmware")
        .order_by("-is_featured", "-created_at")[:30]
    )

    context = {
        "seller": seller,
        "listings": listings,
    }
    return render(request, "marketplace/seller_profile.html", context)


@login_required
def my_listings(request: HttpRequest) -> HttpResponse:
    """Seller dashboard — manage own listings."""
    seller = SellerProfile.objects.filter(user=request.user).first()

    if not seller:
        # Prompt to become a seller
        return render(request, "marketplace/become_seller.html")

    listings = (
        Listing.objects.filter(seller=seller)
        .select_related("firmware")
        .order_by("-created_at")
    )

    context = {
        "seller": seller,
        "listings": listings,
        "active_count": listings.filter(is_active=True).count(),
        "total_sales": seller.total_sales,
    }
    return render(request, "marketplace/my_listings.html", context)


@login_required
def become_seller(request: HttpRequest) -> HttpResponse:
    """Register as a seller on the marketplace."""
    if SellerProfile.objects.filter(user=request.user).exists():
        return redirect("marketplace_public:my_listings")

    if request.method == "POST":
        display_name = request.POST.get("display_name", "").strip()
        bio = request.POST.get("bio", "").strip()

        if not display_name:
            return render(
                request,
                "marketplace/become_seller.html",
                {"error": "Display name is required."},
            )

        SellerProfile.objects.create(
            user=request.user,
            display_name=display_name,
            bio=bio,
        )
        return redirect("marketplace_public:my_listings")

    return render(request, "marketplace/become_seller.html")
