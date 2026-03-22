"""apps.referral.services — Referral business logic."""

from __future__ import annotations

import hashlib
import logging
from decimal import Decimal
from typing import TYPE_CHECKING

from django.db import transaction

if TYPE_CHECKING:
    from django.http import HttpRequest

    from apps.users.models import CustomUser

from .models import Commission, ReferralClick, ReferralCode

logger = logging.getLogger(__name__)


def get_or_create_referral_code(user: CustomUser) -> ReferralCode:
    """Return the user's active referral code, creating one if needed."""
    code = ReferralCode.objects.filter(user=user, is_active=True).first()
    if code:
        return code
    return ReferralCode.objects.create(user=user)


def validate_referral_code(code_str: str) -> ReferralCode | None:
    """Validate and return a ReferralCode if it exists and is active."""
    if not code_str or not code_str.strip():
        return None
    return (
        ReferralCode.objects.select_related("user")
        .filter(code=code_str.strip(), is_active=True)
        .first()
    )


def _hash_value(value: str) -> str:
    """Create a SHA-256 hash for anonymized storage."""
    return hashlib.sha256(value.encode()).hexdigest()


def record_referral_click(
    referral_code: ReferralCode, request: HttpRequest
) -> ReferralClick:
    """Record an anonymized click event on a referral link."""
    ip = _get_ip(request)
    ua = request.META.get("HTTP_USER_AGENT", "")

    click = ReferralClick.objects.create(
        code=referral_code,
        ip_hash=_hash_value(ip) if ip else "",
        user_agent_hash=_hash_value(ua) if ua else "",
    )
    ReferralCode.objects.filter(pk=referral_code.pk).update(
        clicks=referral_code.clicks + 1
    )
    return click


@transaction.atomic
def process_referral_signup(
    referred_user: CustomUser, referral_code_str: str
) -> Commission | None:
    """
    Process a referral conversion when a new user signs up with a code.
    Awards credits via SiteSettings configuration.
    Returns the Commission or None if invalid.
    """
    ref_code = validate_referral_code(referral_code_str)
    if not ref_code:
        logger.info("Invalid referral code on signup: %s", referral_code_str)
        return None

    # Prevent self-referral
    if ref_code.user.pk == referred_user.pk:
        logger.warning(
            "Self-referral attempt by user %s with code %s",
            referred_user.pk,
            referral_code_str,
        )
        return None

    # Prevent duplicate conversions for same user
    if Commission.objects.filter(
        referral_code=ref_code, referred_user=referred_user
    ).exists():
        logger.info(
            "Duplicate referral conversion attempt: user=%s code=%s",
            referred_user.pk,
            referral_code_str,
        )
        return None

    # Get reward amounts from site settings
    referral_reward, referee_bonus = _get_referral_rewards()

    # Create commission for referrer
    commission = Commission.objects.create(
        referral_code=ref_code,
        referred_user=referred_user,
        amount=referral_reward,
        tx_type="signup_bonus",
        status=Commission.Status.PENDING,
    )

    # Update conversion stats
    ReferralCode.objects.filter(pk=ref_code.pk).update(
        conversions=ref_code.conversions + 1
    )

    # Mark matching click as converted (most recent unmatched click)
    ReferralClick.objects.filter(
        code=ref_code,
        converted=False,
    ).order_by("-created_at").update(
        converted=True,
        converted_user=referred_user,
    )

    logger.info(
        "Referral conversion: user=%s referred by code=%s (owner=%s) | "
        "referrer_reward=%s referee_bonus=%s",
        referred_user.pk,
        ref_code.code,
        ref_code.user.pk,
        referral_reward,
        referee_bonus,
    )

    return commission


def _get_referral_rewards() -> tuple[Decimal, Decimal]:
    """Get referral reward amounts from SiteSettings."""
    try:
        from apps.site_settings.models import SiteSettings

        ss = SiteSettings.objects.first()
        if ss:
            return (
                getattr(ss, "referral_reward_credits", Decimal("0")),
                getattr(ss, "referee_bonus_credits", Decimal("0")),
            )
    except Exception:
        logger.debug("Could not load SiteSettings for referral rewards", exc_info=True)
    return Decimal("0"), Decimal("0")


def _get_ip(request: HttpRequest) -> str:
    """Extract client IP from request."""
    xff = request.META.get("HTTP_X_FORWARDED_FOR", "")
    if xff:
        return xff.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "")
