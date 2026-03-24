"""apps.shop — Products, subscription plans, packages, orders."""

from __future__ import annotations

from django.conf import settings
from django.db import models


class ProductType(models.TextChoices):
    FIRMWARE = "firmware", "Firmware"
    SUBSCRIPTION = "subscription", "Subscription"
    TOKEN_PACK = "token_pack", "Token Pack"
    SERVICE = "service", "Service"
    PACKAGE = "package", "Package"


class BillingCycle(models.TextChoices):
    MONTHLY = "monthly", "Monthly"
    QUARTERLY = "quarterly", "Quarterly"
    YEARLY = "yearly", "Yearly"
    LIFETIME = "lifetime", "Lifetime"


class SubscriptionPlan(models.Model):
    """Recurring subscription tier."""

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    price_monthly = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    price_yearly = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    max_downloads = models.IntegerField(default=-1, help_text="-1 = unlimited")
    features = models.JSONField(default=dict, blank=True)
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Subscription Plan"
        verbose_name_plural = "Subscription Plans"
        ordering = ["sort_order"]

    def __str__(self) -> str:
        return self.name


# =============================================================================
# PACKAGE TIER SYSTEM
# =============================================================================


class PackageTier(models.Model):
    """Configurable download package with quotas, limits, and features.

    Each tier defines download/bandwidth/speed limits and feature flags
    that are enforced at download time. Fully admin-configurable.
    """

    class TierLevel(models.TextChoices):
        FREE = "free", "Free"
        BASIC = "basic", "Basic"
        PRO = "pro", "Pro"
        PREMIUM = "premium", "Premium"
        ENTERPRISE = "enterprise", "Enterprise"

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    tier_level = models.CharField(
        max_length=12, choices=TierLevel.choices, default=TierLevel.FREE, db_index=True
    )
    description = models.TextField(blank=True, default="")
    badge_color = models.CharField(
        max_length=20,
        default="blue",
        help_text="Tailwind color for badge (blue, emerald, purple, amber, red)",
    )
    badge_icon = models.CharField(
        max_length=50,
        default="package",
        help_text="Lucide icon name for tier badge",
    )

    # --- Pricing ---
    price_monthly = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    price_quarterly = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    price_yearly = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    price_lifetime = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    credit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Price in platform credits (0 = not purchasable with credits)",
    )
    trial_days = models.PositiveSmallIntegerField(
        default=0, help_text="Trial period in days (0 = no trial)"
    )

    # --- Download Quotas ---
    daily_download_limit = models.IntegerField(
        default=5, help_text="Max downloads per 24h (-1 = unlimited)"
    )
    monthly_download_limit = models.IntegerField(
        default=50, help_text="Max downloads per month (-1 = unlimited)"
    )
    max_file_size_mb = models.IntegerField(
        default=500, help_text="Max single file size in MB (-1 = unlimited)"
    )

    # --- Bandwidth Quotas ---
    daily_bandwidth_mb = models.IntegerField(
        default=2048, help_text="Max bandwidth per 24h in MB (-1 = unlimited)"
    )
    monthly_bandwidth_mb = models.IntegerField(
        default=20480, help_text="Max bandwidth per month in MB (-1 = unlimited)"
    )

    # --- Speed & Concurrency ---
    max_download_speed_kbps = models.IntegerField(
        default=0, help_text="Speed cap in KB/s (0 = no limit)"
    )
    max_concurrent_downloads = models.PositiveSmallIntegerField(
        default=1, help_text="Max simultaneous downloads"
    )

    # --- Feature Flags ---
    ad_free = models.BooleanField(
        default=False, help_text="Skip ad gates before download"
    )
    priority_queue = models.BooleanField(
        default=False, help_text="Priority download queue (server-side)"
    )
    resume_support = models.BooleanField(
        default=True, help_text="Allow download resume after interruption"
    )
    api_access = models.BooleanField(
        default=False, help_text="Allow firmware downloads via API"
    )
    early_access = models.BooleanField(
        default=False, help_text="Access to new firmware before public release"
    )
    direct_links = models.BooleanField(
        default=False, help_text="Generate direct download links (no redirect)"
    )

    # --- Firmware Type Access ---
    access_official = models.BooleanField(default=True, help_text="Official firmware")
    access_engineering = models.BooleanField(
        default=False, help_text="Engineering/test firmware"
    )
    access_readback = models.BooleanField(
        default=False, help_text="Readback / dump firmware"
    )
    access_modified = models.BooleanField(
        default=False, help_text="Modified / custom ROM"
    )

    # --- Cooldowns ---
    cooldown_seconds = models.PositiveIntegerField(
        default=60,
        help_text="Wait time between downloads in seconds (0 = no cooldown)",
    )

    # --- Admin Config ---
    is_active = models.BooleanField(default=True, db_index=True)
    is_default = models.BooleanField(
        default=False,
        help_text="Assign to new users automatically (only one should be default)",
    )
    is_featured = models.BooleanField(
        default=False, help_text="Highlight on pricing page"
    )
    sort_order = models.PositiveSmallIntegerField(default=0)
    extra_features = models.JSONField(
        default=dict,
        blank=True,
        help_text="Additional feature flags as key-value pairs",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Package Tier"
        verbose_name_plural = "Package Tiers"
        ordering = ["sort_order", "price_monthly"]
        db_table = "shop_packagetier"

    def __str__(self) -> str:
        return f"{self.name} ({self.get_tier_level_display()})"  # type: ignore[attr-defined]

    @property
    def is_unlimited_downloads(self) -> bool:
        return self.daily_download_limit == -1 and self.monthly_download_limit == -1

    @property
    def is_unlimited_bandwidth(self) -> bool:
        return self.daily_bandwidth_mb == -1 and self.monthly_bandwidth_mb == -1


class UserPackage(models.Model):
    """User's active package subscription — links a user to a PackageTier."""

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        TRIALING = "trialing", "Trialing"
        EXPIRED = "expired", "Expired"
        CANCELLED = "cancelled", "Cancelled"
        SUSPENDED = "suspended", "Suspended"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="user_packages",
    )
    package = models.ForeignKey(
        PackageTier,
        on_delete=models.PROTECT,
        related_name="user_packages",
    )
    billing_cycle = models.CharField(
        max_length=12, choices=BillingCycle.choices, default=BillingCycle.MONTHLY
    )
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.ACTIVE, db_index=True
    )

    # --- Usage Tracking ---
    downloads_today = models.PositiveIntegerField(default=0)
    downloads_this_month = models.PositiveIntegerField(default=0)
    bandwidth_today_mb = models.PositiveIntegerField(default=0)
    bandwidth_this_month_mb = models.PositiveIntegerField(default=0)
    last_download_at = models.DateTimeField(null=True, blank=True)
    usage_reset_date = models.DateField(
        null=True, blank=True, help_text="Next monthly usage counter reset"
    )

    # --- Lifecycle ---
    started_at = models.DateTimeField(auto_now_add=True)
    trial_ends_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True, db_index=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    external_id = models.CharField(
        max_length=200, blank=True, default="", help_text="Payment gateway ref"
    )

    class Meta:
        verbose_name = "User Package"
        verbose_name_plural = "User Packages"
        ordering = ["-started_at"]
        db_table = "shop_userpackage"
        indexes = [
            models.Index(fields=["user", "status"], name="userpkg_user_status_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.user} → {self.package} [{self.status}]"


class PackageQuotaOverride(models.Model):
    """Per-user override for specific quota fields (admin-granted exceptions)."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="package_quota_overrides",
    )
    daily_download_limit = models.IntegerField(
        null=True, blank=True, help_text="Override daily limit (null = use tier)"
    )
    monthly_download_limit = models.IntegerField(
        null=True, blank=True, help_text="Override monthly limit (null = use tier)"
    )
    daily_bandwidth_mb = models.IntegerField(
        null=True, blank=True, help_text="Override daily bandwidth (null = use tier)"
    )
    monthly_bandwidth_mb = models.IntegerField(
        null=True, blank=True, help_text="Override monthly bandwidth (null = use tier)"
    )
    max_download_speed_kbps = models.IntegerField(
        null=True, blank=True, help_text="Override speed cap (null = use tier)"
    )
    max_concurrent_downloads = models.PositiveSmallIntegerField(
        null=True, blank=True, help_text="Override concurrency (null = use tier)"
    )
    reason = models.CharField(max_length=255, blank=True, default="")
    granted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="granted_quota_overrides",
    )
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Package Quota Override"
        verbose_name_plural = "Package Quota Overrides"
        ordering = ["-created_at"]
        db_table = "shop_packagequotaoverride"

    def __str__(self) -> str:
        return f"Override for {self.user} (by {self.granted_by})"


class Product(models.Model):
    """Purchasable item in the shop."""

    name = models.CharField(max_length=200)
    slug = models.SlugField(max_length=200, unique=True)
    product_type = models.CharField(max_length=15, choices=ProductType.choices)
    description = models.TextField(blank=True, default="")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    firmware = models.ForeignKey(
        "firmwares.OfficialFirmware",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="shop_products",
    )
    subscription_plan = models.ForeignKey(
        SubscriptionPlan,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="products",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Product"
        verbose_name_plural = "Products"
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.name} (${self.price})"


class Subscription(models.Model):
    """User's active subscription to a plan."""

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        CANCELLED = "cancelled", "Cancelled"
        EXPIRED = "expired", "Expired"
        PAST_DUE = "past_due", "Past Due"
        TRIALING = "trialing", "Trialing"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="subscriptions"
    )
    plan = models.ForeignKey(
        SubscriptionPlan, on_delete=models.PROTECT, related_name="subscriptions"
    )
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.ACTIVE, db_index=True
    )
    started_at = models.DateTimeField(auto_now_add=True)
    trial_ends_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True, db_index=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    external_subscription_id = models.CharField(max_length=200, blank=True, default="")

    class Meta:
        verbose_name = "Subscription"
        verbose_name_plural = "Subscriptions"
        ordering = ["-started_at"]
        indexes = [
            models.Index(fields=["user", "status"], name="sub_user_status_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.user} → {self.plan} [{self.status}]"


class Order(models.Model):
    """Purchase order header."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        PAID = "paid", "Paid"
        REFUNDED = "refunded", "Refunded"
        CANCELLED = "cancelled", "Cancelled"
        FAILED = "failed", "Failed"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="orders"
    )
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    total = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="USD")
    payment_gateway = models.CharField(max_length=50, blank=True, default="")
    external_order_id = models.CharField(max_length=200, blank=True, default="")
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Order"
        verbose_name_plural = "Orders"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Order #{self.pk} [{self.status}] ${self.total}"


class OrderItem(models.Model):
    """Line item within an order."""

    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey(
        Product, on_delete=models.PROTECT, related_name="order_items"
    )
    quantity = models.PositiveSmallIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        verbose_name = "Order Item"
        verbose_name_plural = "Order Items"

    def __str__(self) -> str:
        return f"{self.quantity}× {self.product} in Order #{self.order_id}"  # type: ignore[attr-defined]
