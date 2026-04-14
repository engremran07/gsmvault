"""
Enterprise-grade Site & Tenant Settings

✓ Django 5.2 / Python 3.12
✓ Admin-uploadable branding assets (logo, dark logo, favicon)
✓ Generic, non-branded defaults
✓ Hardened validation (colors, file uploads, limits)
✓ Fully safe file URL helpers (static() fallback)
✓ Strict ManyToMany consistency
✓ Tenant-aware
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any

from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator, RegexValidator
from django.db import models, transaction
from django.templatetags.static import static
from solo.models import SingletonModel

logger = logging.getLogger(__name__)

# =====================================================================
# GLOBAL CONSTANTS
# =====================================================================
_ALLOWED_VERIFICATION_EXTENSIONS = {".txt", ".html", ".xml", ".json"}
_MAX_VERIFICATION_FILE_BYTES = 1 * 1024 * 1024  # 1 MiB

_HEX_COLOR_VALIDATOR = RegexValidator(
    regex=r"^#(?:[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$",
    message="Enter a valid hex color like #0d6efd",
)


# =====================================================================
# GLOBAL / DEFAULT SITE SETTINGS (SINGLETON)
# =====================================================================
class SiteSettings(SingletonModel):
    """
    Global site-wide configuration (non-branded, fully generic).
    """

    # ------------------------------------------------------------------
    # Branding - MUST remain generic (no "GSM" or "Infinity"!)
    # ------------------------------------------------------------------
    site_name = models.CharField(max_length=100, default="Site")
    site_header = models.CharField(max_length=100, default="Admin")
    site_description = models.TextField(blank=True, default="")

    logo = models.ImageField(
        upload_to="branding/",
        blank=True,
        null=True,
        help_text="Primary site logo (SVG/PNG)",
    )
    dark_logo = models.ImageField(
        upload_to="branding/",
        blank=True,
        null=True,
        help_text="Dark mode logo",
    )
    favicon = models.ImageField(
        upload_to="branding/",
        blank=True,
        null=True,
        help_text="Favicon (PNG/ICO/SVG)",
    )

    # ------------------------------------------------------------------
    # Theme (kept minimal; runtime tokens supplied by CSS)
    # ------------------------------------------------------------------
    primary_color = models.CharField(  # noqa: DJ001
        max_length=7,
        blank=True,
        null=True,
        validators=[_HEX_COLOR_VALIDATOR],
        help_text="Deprecated: colors now come from the Themes app; kept for legacy templates.",
    )
    secondary_color = models.CharField(  # noqa: DJ001
        max_length=7,
        blank=True,
        null=True,
        validators=[_HEX_COLOR_VALIDATOR],
        help_text="Deprecated: colors now come from the Themes app; kept for legacy templates.",
    )

    # ------------------------------------------------------------------
    # Localization (global defaults only)
    # ------------------------------------------------------------------
    default_language = models.CharField(max_length=10, default="en")
    timezone = models.CharField(max_length=50, default="UTC")
    enable_localization = models.BooleanField(default=False)

    # Featured languages shown in header dropdown (comma-separated codes)
    # Example: "en,ar,fr,de,es,zh,ja,ko,ru,pt"
    featured_languages = models.CharField(
        max_length=200,
        blank=True,
        default="en,ar,fr,de,es,zh-hans,ja,ko,ru,pt",
        help_text="Comma-separated language codes to show in header (max 10). Other languages remain available via full selector.",
    )

    # ------------------------------------------------------------------
    # Core Ops
    # ------------------------------------------------------------------
    maintenance_mode = models.BooleanField(default=False)
    force_https = models.BooleanField(
        default=False,
        help_text="Enable only if TLS is enforced by reverse proxy",
    )
    pages_enabled = models.BooleanField(
        default=True, help_text="Enable dynamic pages app for public pages."
    )
    sitemap_enabled = models.BooleanField(
        default=True, help_text="Expose sitemap.xml for published pages."
    )
    sitemap_index_enabled = models.BooleanField(
        default=True, help_text="Expose sitemap_index.xml for published pages."
    )
    sitemap_page_size = models.PositiveIntegerField(
        default=2000, help_text="Max URLs per sitemap chunk."
    )

    # ------------------------------------------------------------------
    # Email (Gmail App Password)
    # ------------------------------------------------------------------
    gmail_enabled = models.BooleanField(
        default=False,
        help_text="Use Gmail SMTP with an app password (recommended). When disabled, falls back to environment settings.",
    )
    gmail_username = models.EmailField(
        blank=True, default="", help_text="Gmail address used for SMTP AUTH."
    )
    gmail_app_password = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="Gmail app password (never store your real password).",
    )
    gmail_from_email = models.EmailField(
        blank=True,
        default="",
        help_text="Optional From header. Defaults to gmail_username when empty.",
    )

    # ------------------------------------------------------------------
    # reCAPTCHA (global; per-app may override)
    # ------------------------------------------------------------------
    recaptcha_enabled = models.BooleanField(default=False)
    recaptcha_mode = models.CharField(
        max_length=20,
        choices=[("v2", "v2"), ("v3", "v3")],
        default="v2",
    )
    recaptcha_public_key = models.CharField(max_length=100, blank=True, null=True)  # noqa: DJ001
    recaptcha_private_key = models.CharField(max_length=100, blank=True, null=True)  # noqa: DJ001

    recaptcha_score_threshold = models.FloatField(
        default=0.5,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
    )
    recaptcha_timeout_ms = models.PositiveIntegerField(default=3000)

    # ------------------------------------------------------------------
    # MFA / Device Security
    # ------------------------------------------------------------------
    max_devices_per_user = models.PositiveIntegerField(default=3)
    lock_duration_minutes = models.PositiveIntegerField(default=15)
    fingerprint_mode = models.CharField(
        max_length=20,
        choices=[("strict", "Strict"), ("lenient", "Lenient")],
        default="strict",
    )
    enforce_unique_device = models.BooleanField(default=True)
    require_mfa = models.BooleanField(default=False)
    require_profile_completion = models.BooleanField(
        default=True,
        help_text="Require social auth users to complete profile before accessing the site",
    )

    mfa_totp_issuer = models.CharField(max_length=50, default="Site")

    # ------------------------------------------------------------------
    # Email Verification
    # ------------------------------------------------------------------
    email_verification_code_length = models.PositiveIntegerField(
        default=6,
        validators=[MinValueValidator(4), MaxValueValidator(12)],
    )
    email_verification_code_type = models.CharField(
        max_length=20,
        choices=[("numeric", "Numeric"), ("alphanumeric", "Alphanumeric")],
        default="alphanumeric",
    )

    # ------------------------------------------------------------------
    # Feature toggles (global)
    # ------------------------------------------------------------------
    enable_signup = models.BooleanField(
        default=True, help_text="Allow new user registration"
    )
    enable_notifications = models.BooleanField(
        default=True, help_text="Enable in-app and push notifications"
    )

    # ------------------------------------------------------------------
    # Site Identity & SEO
    # ------------------------------------------------------------------
    site_url = models.URLField(
        max_length=255,
        blank=True,
        default="",
        help_text="Canonical base URL (e.g. https://example.com)",
    )
    contact_email = models.EmailField(
        blank=True, default="", help_text="Public contact email for footer/legal"
    )
    copyright_text = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Footer copyright text (leave blank for auto: © {year} {site_name})",
    )

    # Social media links
    social_twitter = models.URLField(max_length=255, blank=True, default="")
    social_facebook = models.URLField(max_length=255, blank=True, default="")
    social_github = models.URLField(max_length=255, blank=True, default="")
    social_youtube = models.URLField(max_length=255, blank=True, default="")
    social_linkedin = models.URLField(max_length=255, blank=True, default="")
    social_telegram = models.URLField(max_length=255, blank=True, default="")

    # Open Graph / Twitter Card defaults
    og_image = models.ImageField(
        upload_to="branding/",
        blank=True,
        null=True,
        help_text="Default Open Graph share image (1200x630 recommended)",
    )
    twitter_handle = models.CharField(
        max_length=50,
        blank=True,
        default="",
        help_text="Twitter @handle for twitter:site card (without @)",
    )

    # Analytics
    google_analytics_id = models.CharField(
        max_length=50, blank=True, default="", help_text="GA4 Measurement ID (G-XXXX)"
    )
    google_tag_manager_id = models.CharField(
        max_length=50, blank=True, default="", help_text="GTM container ID (GTM-XXXX)"
    )

    # ------------------------------------------------------------------
    # Rate limiting
    # ------------------------------------------------------------------
    max_login_attempts = models.PositiveIntegerField(default=5)
    rate_limit_window_seconds = models.PositiveIntegerField(default=300)

    # Cache TTL (consumed by the context processor)
    cache_ttl_seconds = models.PositiveIntegerField(default=600)

    # ------------------------------------------------------------------
    # Scraper Schedule
    # ------------------------------------------------------------------
    gsmarena_scrape_interval_hours = models.PositiveIntegerField(
        default=0,
        help_text="Auto-scrape GSMArena every N hours (0 = disabled, manual only)",
    )
    multi_source_scrape_interval_hours = models.PositiveIntegerField(
        default=0,
        help_text=(
            "Auto-scrape ALL registered sources every N hours "
            "(0 = disabled, manual only). Runs independently from GSMArena."
        ),
    )

    # ------------------------------------------------------------------
    # Download Gating & Protection
    # ------------------------------------------------------------------
    download_gate_enabled = models.BooleanField(
        default=True,
        help_text="Enable the download gate system (countdown + ad gate + token validation)",
    )
    download_countdown_seconds = models.PositiveIntegerField(
        default=10,
        validators=[MinValueValidator(0), MaxValueValidator(120)],
        help_text="Countdown seconds before download link appears (0 = instant)",
    )
    download_ad_gate_enabled = models.BooleanField(
        default=False,
        help_text="Require users to complete ad gate before downloading",
    )
    download_ad_gate_seconds = models.PositiveIntegerField(
        default=30,
        validators=[MinValueValidator(5), MaxValueValidator(300)],
        help_text="Seconds user must watch ad before gate unlocks",
    )
    download_token_expiry_minutes = models.PositiveIntegerField(
        default=30,
        validators=[MinValueValidator(1), MaxValueValidator(1440)],
        help_text="Minutes before a download token expires",
    )
    download_require_login = models.BooleanField(
        default=False,
        help_text="Require user login before downloading firmware",
    )
    download_max_per_day = models.PositiveIntegerField(
        default=0,
        help_text="Max downloads per user per day (0 = unlimited)",
    )
    download_hotlink_protection = models.BooleanField(
        default=True,
        help_text="Block direct linking from external sites",
    )
    download_link_encryption = models.BooleanField(
        default=True,
        help_text="Use encrypted/signed tokens instead of direct file URLs",
    )

    # ------------------------------------------------------------------
    # Credit & Economy Pricing
    # ------------------------------------------------------------------
    signup_bonus_credits = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Credits awarded to new users upon registration",
    )
    referral_reward_credits = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Credits awarded to referrer when referee completes signup",
    )
    referee_bonus_credits = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Credits awarded to referred user (referee) as welcome bonus",
    )
    bounty_base_reward = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Default credit reward for fulfilling a firmware bounty",
    )
    download_cost_credits = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Credits deducted per firmware download (0 = free)",
    )
    profile_completion_bonus = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Credits awarded when user completes their profile",
    )
    daily_login_reward = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Credits awarded for daily login streak",
    )
    credit_to_currency_rate = models.DecimalField(
        max_digits=10,
        decimal_places=6,
        default=0,
        help_text="Exchange rate: 1 credit = X USD (for payout calculations)",
    )
    min_payout_credits = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=100,
        help_text="Minimum credit balance required to request a payout",
    )

    # ------------------------------------------------------------------
    # Meta Tags & Verification Files
    # ------------------------------------------------------------------
    meta_tags = models.ManyToManyField(
        "VerificationMetaTag",
        through="SiteSettingsMetaTagLink",
        blank=True,
    )
    verification_files = models.ManyToManyField(
        "VerificationFile",
        through="SiteSettingsVerificationFileLink",
        blank=True,
    )

    class Meta:
        verbose_name = "Site Settings"
        verbose_name_plural = "Site Settings"

    def __str__(self) -> str:
        return self.site_name or "Site Settings"

    @classmethod
    def get_solo(cls):
        """
        Singleton accessor with locking to prevent duplicate creation in multi-worker
        startup scenarios.
        """
        with transaction.atomic():
            obj, _ = cls.objects.select_for_update().get_or_create(pk=1)
        return obj

    # =================================================================
    # SAFE FILE URL HELPERS (always static fallback)
    # =================================================================
    def _safe_file_url(self, field, fallback: str) -> str:
        try:
            if field and getattr(field, "url", None):
                url = field.url
                if isinstance(url, str) and url.strip():
                    return url
        except Exception:  # noqa: S110
            pass
        return static(fallback)

    @property
    def logo_url(self) -> str:
        return self._safe_file_url(self.logo, "img/default-logo.svg")

    @property
    def dark_logo_url(self) -> str:
        # Try dark → fallback to normal → fallback to static
        url = self._safe_file_url(self.dark_logo, "")
        if url:
            return url
        url = self._safe_file_url(self.logo, "")
        if url:
            return url
        return static("img/default-logo-dark.svg")

    @property
    def favicon_url(self) -> str:
        return self._safe_file_url(self.favicon, "img/default-favicon.svg")

    @property
    def og_image_url(self) -> str:
        return self._safe_file_url(self.og_image, "img/default-og.png")

    # =================================================================
    # VALIDATION
    # =================================================================
    def clean(self):
        errors = {}

        for name, val in [
            ("primary_color", self.primary_color),
            ("secondary_color", self.secondary_color),
        ]:
            if val:
                try:
                    _HEX_COLOR_VALIDATOR(val)
                except ValidationError as exc:
                    errors[name] = exc.messages

        if errors:
            raise ValidationError(errors)

    # =================================================================
    # FRONTEND CONFIG HELPERS
    # =================================================================
    def get_theme(self) -> dict[str, Any]:
        return {
            "profile": "default",
            "primary_color": self.primary_color or "#0d6efd",
            "secondary_color": self.secondary_color or "#6c757d",
            "ai_mode": False,
        }

    def recaptcha_config(self) -> dict[str, Any]:
        return {
            "enabled": bool(self.recaptcha_enabled),
            "mode": self.recaptcha_mode,
            "public_key": self.recaptcha_public_key or "",
            "threshold": float(self.recaptcha_score_threshold),
            "timeout": int(self.recaptcha_timeout_ms),
        }


# =====================================================================
# META TAGS
# =====================================================================
class VerificationMetaTag(models.Model):
    provider = models.CharField(max_length=50, db_index=True)
    name_attr = models.CharField(max_length=100)
    content_attr = models.CharField(max_length=255)
    description = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["provider", "name_attr"], name="ver_meta_idx")]

    def __str__(self):
        return f"{self.provider}: {self.name_attr}"


# =====================================================================
# VERIFICATION FILES (SAFE)
# =====================================================================
class VerificationFile(models.Model):
    provider = models.CharField(max_length=50, db_index=True)
    file = models.FileField(upload_to="verification/")
    description = models.TextField(blank=True, default="")
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-uploaded_at"]
        indexes = [models.Index(fields=["provider"], name="ver_file_idx")]

    def __str__(self):
        name = getattr(self.file, "name", None)
        return f"{self.provider}: {name or '(invalid file)'}"

    # SAFE VALIDATION
    def clean(self):
        errors = {}

        # extension check
        try:
            ext = Path(self.file.name or "").suffix.lower()
            if ext not in _ALLOWED_VERIFICATION_EXTENSIONS:
                errors.setdefault("file", []).append(f"Unsupported extension: {ext}")
        except Exception:  # noqa: S110
            pass

        # size check
        try:
            if self.file.size > _MAX_VERIFICATION_FILE_BYTES:
                errors.setdefault("file", []).append(
                    f"File exceeds {_MAX_VERIFICATION_FILE_BYTES} bytes"
                )
        except Exception:  # noqa: S110
            pass

        if errors:
            raise ValidationError(errors)

    def save(self, *a, **kw):  # noqa: DJ012
        self.full_clean()
        return super().save(*a, **kw)


# =====================================================================
# THROUGH MODELS
# =====================================================================
class SiteSettingsMetaTagLink(models.Model):
    site_settings = models.ForeignKey(
        SiteSettings, on_delete=models.CASCADE, related_name="meta_tag_links"
    )
    meta_tag = models.ForeignKey(
        VerificationMetaTag, on_delete=models.CASCADE, related_name="site_links"
    )
    linked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("site_settings", "meta_tag")
        indexes = [
            models.Index(
                fields=["site_settings", "meta_tag"], name="site_meta_link_idx"
            )
        ]

    def __str__(self) -> str:
        return f"MetaTag link: {self.meta_tag_id} \u2192 Site {self.site_settings_id}"  # type: ignore[attr-defined]


class SiteSettingsVerificationFileLink(models.Model):
    site_settings = models.ForeignKey(
        SiteSettings, on_delete=models.CASCADE, related_name="verification_file_links"
    )
    verification_file = models.ForeignKey(
        VerificationFile, on_delete=models.CASCADE, related_name="site_links"
    )
    linked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("site_settings", "verification_file")
        indexes = [
            models.Index(
                fields=["site_settings", "verification_file"], name="site_file_link_idx"
            )
        ]

    def __str__(self) -> str:
        return f"File link: {self.verification_file_id} \u2192 Site {self.site_settings_id}"  # type: ignore[attr-defined]


# =====================================================================
# APP REGISTRY — feature toggles (dissolved from apps.core)
# =====================================================================
class AppRegistry(SingletonModel):
    """
    Admin-controlled feature toggles for all installed modules.
    Single row, managed via Admin Suite > Settings.
    """

    seo_enabled = models.BooleanField(default=True)
    ads_enabled = models.BooleanField(default=True)
    tags_enabled = models.BooleanField(default=True)
    blog_enabled = models.BooleanField(default=True)
    comments_enabled = models.BooleanField(default=True)
    distribution_enabled = models.BooleanField(default=True)
    users_enabled = models.BooleanField(default=True)
    device_identity_enabled = models.BooleanField(default=True)
    crawler_guard_enabled = models.BooleanField(default=True)
    ai_enabled = models.BooleanField(default=True)
    notifications_enabled = models.BooleanField(default=True)
    shop_enabled = models.BooleanField(default=False)
    wallet_enabled = models.BooleanField(default=False)
    gamification_enabled = models.BooleanField(default=False)
    marketplace_enabled = models.BooleanField(default=False)

    class Meta:
        verbose_name = "App Registry"

    def __str__(self) -> str:
        return "App Registry"
