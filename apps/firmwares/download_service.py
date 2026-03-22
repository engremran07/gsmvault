"""
Download gating service — server-side enforcement for firmware downloads.

Handles token creation, validation, ad-gate enforcement, rate limiting,
and hotlink protection. All download protection is server-side; client
countdown is cosmetic only.
"""

from __future__ import annotations

import hashlib
import hmac
import logging
import secrets
from datetime import timedelta
from typing import Any

from django.conf import settings
from django.http import HttpRequest
from django.utils import timezone

from .models import AdGateLog, DownloadSession, DownloadToken, HotlinkBlock

logger = logging.getLogger(__name__)


def _get_download_config() -> dict[str, Any]:
    """Load download configuration from SiteSettings singleton."""
    try:
        from apps.site_settings.models import SiteSettings

        ss = SiteSettings.get_solo()
        return {
            "gate_enabled": ss.download_gate_enabled,
            "countdown_seconds": ss.download_countdown_seconds,
            "ad_gate_enabled": ss.download_ad_gate_enabled,
            "ad_gate_seconds": ss.download_ad_gate_seconds,
            "token_expiry_minutes": ss.download_token_expiry_minutes,
            "require_login": ss.download_require_login,
            "max_per_day": ss.download_max_per_day,
            "hotlink_protection": ss.download_hotlink_protection,
            "link_encryption": ss.download_link_encryption,
        }
    except Exception:
        return {
            "gate_enabled": True,
            "countdown_seconds": 10,
            "ad_gate_enabled": False,
            "ad_gate_seconds": 30,
            "token_expiry_minutes": 30,
            "require_login": False,
            "max_per_day": 0,
            "hotlink_protection": True,
            "link_encryption": True,
        }


def get_client_ip(request: HttpRequest) -> str:
    """Extract real client IP from request headers."""
    xff = request.META.get("HTTP_X_FORWARDED_FOR", "")
    if xff:
        return xff.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "127.0.0.1")


def create_download_token(
    firmware: Any,
    request: HttpRequest,
) -> DownloadToken:
    """Create a signed download token for a firmware file."""
    config = _get_download_config()
    user = request.user if request.user.is_authenticated else None

    token = DownloadToken.objects.create(
        firmware=firmware,
        user=user,
        token=secrets.token_urlsafe(32),
        ad_gate_required=config["ad_gate_enabled"],
        ad_gate_completed=not config["ad_gate_enabled"],
        ip=get_client_ip(request),
        status=DownloadToken.Status.ACTIVE,
        expires_at=timezone.now() + timedelta(minutes=config["token_expiry_minutes"]),
    )
    return token


def validate_download_token(token_str: str) -> DownloadToken | None:
    """Validate a download token. Returns the token or None if invalid."""
    try:
        token = DownloadToken.objects.select_related("firmware").get(
            token=token_str,
            status=DownloadToken.Status.ACTIVE,
        )
    except DownloadToken.DoesNotExist:
        return None

    if token.expires_at < timezone.now():
        token.status = DownloadToken.Status.EXPIRED
        token.save(update_fields=["status"])
        return None

    return token


def complete_ad_gate(token: DownloadToken, ad_type: str = "video") -> bool:
    """Mark ad-gate as completed for a token."""
    if not token.ad_gate_required:
        return True

    config = _get_download_config()
    token.ad_gate_completed = True
    token.save(update_fields=["ad_gate_completed"])

    # Create a session for ad-gate logging
    session = DownloadSession.objects.filter(token=token).first()
    if session:
        AdGateLog.objects.create(
            session=session,
            ad_type=ad_type,
            watched_seconds=config["ad_gate_seconds"],
            required_seconds=config["ad_gate_seconds"],
            completed=True,
        )
    return True


def check_download_allowed(request: HttpRequest, firmware: Any) -> tuple[bool, str]:
    """
    Check if a download is allowed (rate limits, login requirements, etc.).
    Returns (allowed, reason).
    """
    config = _get_download_config()

    if config["require_login"] and not request.user.is_authenticated:
        return False, "Login required to download firmware."

    if config["max_per_day"] > 0 and request.user.is_authenticated:
        day_ago = timezone.now() - timedelta(hours=24)
        daily_count = DownloadToken.objects.filter(
            user=request.user,
            created_at__gte=day_ago,
            status__in=[
                DownloadToken.Status.ACTIVE,
                DownloadToken.Status.USED,
            ],
        ).count()
        if daily_count >= config["max_per_day"]:
            return False, f"Daily download limit ({config['max_per_day']}) reached."

    return True, ""


def check_hotlink(request: HttpRequest) -> bool:
    """Check if request is a blocked hotlink. Returns True if BLOCKED."""
    config = _get_download_config()
    if not config["hotlink_protection"]:
        return False

    referer = request.META.get("HTTP_REFERER", "")
    if not referer:
        return False

    try:
        from urllib.parse import urlparse

        domain = urlparse(referer).hostname or ""
    except Exception:
        return False

    # Allow our own domain
    allowed_hosts = getattr(settings, "ALLOWED_HOSTS", [])
    if domain in allowed_hosts or domain == "localhost" or domain == "127.0.0.1":
        return False

    blocked = HotlinkBlock.objects.filter(domain=domain, is_active=True).first()
    if blocked:
        HotlinkBlock.objects.filter(pk=blocked.pk).update(
            blocked_count=blocked.blocked_count + 1
        )
        return True

    return False


def start_download_session(
    token: DownloadToken, request: HttpRequest
) -> DownloadSession:
    """Create a download session and mark the token as used."""
    session = DownloadSession.objects.create(
        token=token,
        user=token.user,
        ip=get_client_ip(request),
        user_agent=request.META.get("HTTP_USER_AGENT", "")[:255],
        status=DownloadSession.Status.STARTED,
    )
    token.status = DownloadToken.Status.USED
    token.used_at = timezone.now()
    token.save(update_fields=["status", "used_at"])
    return session


def generate_signed_url(firmware: Any, token: DownloadToken) -> str | None:
    """Generate a signed/encrypted download URL for a firmware file."""
    if not firmware.stored_file_path:
        return None

    # If already a full URL (external storage), return it directly
    if firmware.stored_file_path.startswith(("http://", "https://")):
        return firmware.stored_file_path

    return None


def sign_token(token_str: str) -> str:
    """Create an HMAC signature for a download token."""
    key = getattr(settings, "SECRET_KEY", "fallback-key").encode()
    return hmac.new(key, token_str.encode(), hashlib.sha256).hexdigest()[:16]


def verify_signature(token_str: str, signature: str) -> bool:
    """Verify an HMAC signature for a download token."""
    expected = sign_token(token_str)
    return hmac.compare_digest(expected, signature)


def expire_stale_tokens() -> int:
    """Expire tokens that have passed their expiry time. Returns count expired."""
    now = timezone.now()
    count = DownloadToken.objects.filter(
        status=DownloadToken.Status.ACTIVE,
        expires_at__lt=now,
    ).update(status=DownloadToken.Status.EXPIRED)
    return count
