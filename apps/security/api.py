from rest_framework import permissions, serializers, viewsets

from .models import BlockedIP, RateLimitRule, SecurityEvent


class SecurityEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = SecurityEvent
        fields = ["id", "event_type", "severity", "ip", "path", "created_at"]
        read_only_fields = fields


class BlockedIPSerializer(serializers.ModelSerializer):
    class Meta:
        model = BlockedIP
        fields = ["id", "ip", "reason", "blocked_until", "is_active", "created_at"]
        read_only_fields = ["created_at"]


class RateLimitRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = RateLimitRule
        fields = [
            "id",
            "path_pattern",
            "limit",
            "window_seconds",
            "action",
            "is_active",
        ]


class SecurityEventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = SecurityEvent.objects.all()
    serializer_class = SecurityEventSerializer
    permission_classes = [permissions.IsAdminUser]


class BlockedIPViewSet(viewsets.ModelViewSet):
    queryset = BlockedIP.objects.filter(is_active=True)
    serializer_class = BlockedIPSerializer
    permission_classes = [permissions.IsAdminUser]


# ---------------------------------------------------------------------------
# Service helpers — imported from within the project (replaces security_events
# and security_suite api modules which are dissolved)
# ---------------------------------------------------------------------------

import logging  # noqa: E402
from typing import Any  # noqa: E402

from django.db import DatabaseError  # noqa: E402

from .models import SecurityConfig  # noqa: E402 (already imported above via models)

_log = logging.getLogger(__name__)


def emit_security_event(
    event_type: str,
    user=None,
    device=None,
    ip: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> None:
    """Best-effort security event recorder. Safe to call even before migrations."""
    try:
        extra: dict[str, Any] = metadata or {}
        if device is not None:
            extra = {**extra, "device_id": getattr(device, "pk", None)}
        SecurityEvent.objects.create(
            event_type=event_type,
            user=user if getattr(user, "is_authenticated", False) else None,
            ip=ip,
            metadata=extra,
        )
        if (
            user
            and getattr(user, "is_authenticated", False)
            and event_type in {"login_fail", "password_reset", "mfa_fail"}
        ):
            try:
                from apps.users.services.notifications import (
                    send_notification,  # type: ignore[import-untyped]
                )

                _titles = {
                    "login_fail": "Failed login attempt",
                    "password_reset": "Password reset",
                    "mfa_fail": "MFA failure detected",
                }
                _msgs = {
                    "login_fail": f"A failed login was detected from {ip or 'unknown IP'}.",
                    "password_reset": "Your password was recently reset.",
                    "mfa_fail": "A failed MFA attempt was recorded on your account.",
                }
                send_notification(
                    recipient=user,
                    title=_titles.get(event_type, "Security Alert"),
                    message=_msgs.get(event_type, "A security event occurred."),
                    level="warning",
                    channel="web",
                    action_type="security",
                    icon="shield",
                )
            except Exception:  # noqa: S110 - notification failure is non-critical
                pass
    except Exception as exc:
        _log.debug("emit_security_event skipped: %s", exc)


def get_device_quota_policy() -> dict[str, Any]:
    """Return device quota enforcement policy from SecurityConfig."""
    try:
        cfg = SecurityConfig.get_solo()
    except DatabaseError:
        return {"enforcement_enabled": False}
    except Exception as exc:
        _log.debug("SecurityConfig unavailable: %s", exc)
        return {"enforcement_enabled": False}
    if not cfg.device_quota_enforcement_enabled:
        return {"enforcement_enabled": False}
    window_map = {"3m": 90, "6m": 180, "12m": 365}
    return {
        "enforcement_enabled": True,
        "default_window": cfg.default_device_window,
        "default_limit": int(cfg.default_device_limit or 5),
        "window_days": window_map.get(cfg.default_device_window, 365),
    }


def security_settings_snapshot() -> dict[str, Any]:
    """Return a snapshot of active security settings from SecurityConfig."""
    try:
        cfg = SecurityConfig.get_solo()
        return {
            "crawler_guard_enabled": getattr(cfg, "crawler_guard_enabled", True),
            "crawler_default_action": getattr(cfg, "crawler_default_action", "log"),
            "login_risk_policy": getattr(cfg, "login_risk_policy", "log"),
            "device_quota_enforcement_enabled": bool(
                getattr(cfg, "device_quota_enforcement_enabled", False)
            ),
        }
    except Exception:
        return {}


def active_crawler_rules():
    """Return active crawler rules (merged from apps.crawler_guard)."""
    from .models import CrawlerRule

    return CrawlerRule.objects.filter(is_enabled=True)


def log_crawler_event(**kwargs) -> "Any | None":
    """Create a CrawlerEvent record (merged from apps.crawler_guard)."""
    try:
        from .models import CrawlerEvent

        return CrawlerEvent.objects.create(**kwargs)
    except Exception:
        return None
