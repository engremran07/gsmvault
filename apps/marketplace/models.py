"""apps.marketplace — Seller profiles, listings, verification."""

from __future__ import annotations

from django.conf import settings
from django.db import models


class SellerProfile(models.Model):
    """Extended seller profile attached to a user."""

    class PayoutMethod(models.TextChoices):
        PAYPAL = "paypal", "PayPal"
        CRYPTO = "crypto", "Crypto"
        BANK = "bank", "Bank Transfer"
        WALLET = "wallet", "Platform Wallet"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="seller_profile",
    )
    bio = models.TextField(max_length=2000, blank=True, default="")
    display_name = models.CharField(max_length=100, blank=True, default="")
    verified = models.BooleanField(default=False, db_index=True)
    rating = models.FloatField(default=0.0)
    total_sales = models.PositiveIntegerField(default=0)
    payout_method = models.CharField(
        max_length=10, choices=PayoutMethod.choices, default=PayoutMethod.WALLET
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Seller Profile"
        verbose_name_plural = "Seller Profiles"

    def __str__(self) -> str:
        return f"Seller({self.user}) verified={self.verified}"


class SellerVerification(models.Model):
    """KYC/identity verification request for a seller."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending Review"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        EXPIRED = "expired", "Expired"

    seller = models.ForeignKey(
        SellerProfile, on_delete=models.CASCADE, related_name="verifications"
    )
    document_type = models.CharField(
        max_length=20,
        choices=[
            ("id_card", "ID Card"),
            ("passport", "Passport"),
            ("driver_license", "Driver License"),
        ],
    )
    document_url = models.CharField(max_length=500, blank=True, default="")
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL
    )
    notes = models.TextField(blank=True, default="")
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Seller Verification"
        verbose_name_plural = "Seller Verifications"
        ordering = ["-submitted_at"]

    def __str__(self) -> str:
        return f"Verification for {self.seller} [{self.status}]"


class Listing(models.Model):
    """Marketplace listing for a firmware product."""

    seller = models.ForeignKey(
        SellerProfile, on_delete=models.CASCADE, related_name="listings"
    )
    firmware = models.ForeignKey(
        "firmwares.OfficialFirmware",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="marketplace_listings",
    )
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, default="")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    discount_price = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    is_featured = models.BooleanField(default=False, db_index=True)
    is_active = models.BooleanField(default=True, db_index=True)
    view_count = models.PositiveIntegerField(default=0)
    sale_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Listing"
        verbose_name_plural = "Listings"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["is_active", "is_featured"], name="listing_active_feat_idx"
            ),
        ]

    def __str__(self) -> str:
        return f"{self.title} by {self.seller}"


class SellerAnalyticsSnapshot(models.Model):
    """Periodic analytics snapshot per seller."""

    seller = models.ForeignKey(
        SellerProfile, on_delete=models.CASCADE, related_name="analytics_snapshots"
    )
    period = models.CharField(max_length=20, help_text="e.g. 2024-01 or 2024-W03")
    views = models.PositiveIntegerField(default=0)
    sales = models.PositiveIntegerField(default=0)
    revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Seller Analytics Snapshot"
        verbose_name_plural = "Seller Analytics Snapshots"
        unique_together = [("seller", "period")]
        ordering = ["-period"]

    def __str__(self) -> str:
        return f"{self.seller} {self.period}: {self.sales} sales"
