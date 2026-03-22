"""apps.referral — Referral codes, clicks, conversions, commissions."""

from __future__ import annotations

import secrets

from django.conf import settings
from django.db import models


def _gen_code() -> str:
    return secrets.token_urlsafe(8).upper()[:10]


class ReferralTier(models.Model):
    """Commission tier — assigned based on number of successful referrals."""

    name = models.CharField(max_length=60, unique=True)
    min_referrals = models.PositiveIntegerField(default=0)
    commission_rate = models.DecimalField(max_digits=5, decimal_places=4)
    perks = models.JSONField(default=dict, blank=True)

    class Meta:
        verbose_name = "Referral Tier"
        verbose_name_plural = "Referral Tiers"
        ordering = ["min_referrals"]

    def __str__(self) -> str:
        return f"{self.name} ({self.commission_rate * 100:.1f}%)"


class ReferralCode(models.Model):
    """Unique referral code per user."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="referral_codes",
    )
    code = models.CharField(
        max_length=20, unique=True, default=_gen_code, db_index=True
    )
    tier = models.ForeignKey(
        ReferralTier,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="codes",
    )
    clicks = models.PositiveIntegerField(default=0)
    conversions = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Referral Code"
        verbose_name_plural = "Referral Codes"

    def __str__(self) -> str:
        return f"{self.code} ({self.user})"


class ReferralClick(models.Model):
    """Anonymised click event on a referral link."""

    code = models.ForeignKey(
        ReferralCode, on_delete=models.CASCADE, related_name="click_events"
    )
    ip_hash = models.CharField(max_length=64, blank=True, default="")
    user_agent_hash = models.CharField(max_length=64, blank=True, default="")
    converted = models.BooleanField(default=False)
    converted_user = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "Referral Click"
        verbose_name_plural = "Referral Clicks"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Click on {self.code.code} [{'converted' if self.converted else 'pending'}]"


class Commission(models.Model):
    """Earnings record for a referral conversion."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        PAID = "paid", "Paid"
        REVERSED = "reversed", "Reversed"

    referral_code = models.ForeignKey(
        ReferralCode, on_delete=models.CASCADE, related_name="commissions"
    )
    referred_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="generated_commissions",
    )
    amount = models.DecimalField(max_digits=14, decimal_places=4)
    tx_type = models.CharField(max_length=30, blank=True, default="signup_bonus")
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    paid_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Commission"
        verbose_name_plural = "Commissions"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Commission {self.amount} for {self.referral_code.code} [{self.status}]"
