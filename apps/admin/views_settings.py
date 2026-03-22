from __future__ import annotations

from datetime import timedelta

from .views_shared import *  # noqa: F403
from .views_shared import _ADMIN_DISABLED, _make_breadcrumb, _render_admin


# Extracted views_settings views from legacy views.py
@staff_member_required  # noqa: F405
def admin_suite_settings(request: HttpRequest) -> HttpResponse:  # noqa: F405
    """Settings and security flags overview."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):  # noqa: F405
        raise _ADMIN_DISABLED  # noqa: F405

    site_snapshot: dict[str, Any] = {}  # noqa: F405
    message = ""
    _ALLOWED_TOGGLES = {
        "seo_enabled",
        "ads_enabled",
        "tags_enabled",
        "blog_enabled",
        "comments_enabled",
        "distribution_enabled",
        "users_enabled",
        "device_identity_enabled",
        "crawler_guard_enabled",
        "ai_enabled",
        "notifications_enabled",
        "shop_enabled",
        "wallet_enabled",
        "gamification_enabled",
        "marketplace_enabled",
    }
    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.site_settings.models import AppRegistry

            reg = AppRegistry.get_solo()
            if action and action in _ALLOWED_TOGGLES and hasattr(reg, action):
                current = bool(getattr(reg, action))
                setattr(reg, action, not current)
                reg.save(update_fields=[action])
                message = f"{action} set to {not current}"
            elif action and action not in _ALLOWED_TOGGLES:
                message = f"Toggle '{action}' is not allowed."
        except Exception as exc:
            logger.warning("Admin suite registry toggle failed: %s", exc)  # noqa: F405
            message = "Toggle failed."
    try:
        from apps.site_settings.models import SiteSettings

        ss = SiteSettings.get_solo()
        site_snapshot = {
            "site_name": getattr(ss, "site_name", "Site"),
            "site_header": getattr(ss, "site_header", ""),
            "site_description": getattr(ss, "site_description", ""),
            "primary_color": getattr(ss, "primary_color", "#0d6efd") or "#0d6efd",
            "secondary_color": getattr(ss, "secondary_color", "#6c757d") or "#6c757d",
            "enable_signup": bool(getattr(ss, "enable_signup", True)),
            "maintenance_mode": bool(getattr(ss, "maintenance_mode", False)),
            "force_https": bool(getattr(ss, "force_https", False)),
            "cache_ttl_seconds": getattr(ss, "cache_ttl_seconds", 600),
        }
    except Exception as exc:
        logger.warning("Admin suite site settings snapshot failed: %s", exc)  # noqa: F405

    security_status = {
        "devices_enabled": False,
        "bots_enabled": False,
        "risk_enabled": False,
        "login_policy": "mfa_if_high",
        "ads_enabled": True,
        "seo_enabled": True,
        "comments_enabled": True,
        "distribution_enabled": True,
        "device_identity_enabled": True,
        "crawler_guard_enabled": True,
        "ai_enabled": True,
    }
    try:
        from apps.security.models import SecurityConfig
        from apps.site_settings.models import AppRegistry

        reg = AppRegistry.get_solo()
        try:
            sec = SecurityConfig.get_solo()
            security_status["devices_enabled"] = bool(
                getattr(sec, "device_guard_enabled", False)
            )
            security_status["bots_enabled"] = bool(
                getattr(sec, "crawler_guard_enabled", False)
            )
            security_status["risk_enabled"] = bool(
                getattr(sec, "risk_scoring_enabled", False)
            )
            security_status["login_policy"] = getattr(
                sec, "login_risk_policy", "mfa_if_high"
            )
        except Exception:  # noqa: S110
            pass
        security_status.update(
            {
                "ads_enabled": bool(getattr(reg, "ads_enabled", True)),
                "seo_enabled": bool(getattr(reg, "seo_enabled", True)),
                "comments_enabled": bool(getattr(reg, "comments_enabled", True)),
                "distribution_enabled": bool(
                    getattr(reg, "distribution_enabled", True)
                ),
                "device_identity_enabled": bool(
                    getattr(reg, "device_identity_enabled", True)
                ),
                "crawler_guard_enabled": bool(
                    getattr(reg, "crawler_guard_enabled", True)
                ),
                "ai_enabled": bool(getattr(reg, "ai_enabled", True)),
            }
        )
    except Exception as exc:
        logger.debug("Admin suite security snapshot failed: %s", exc)  # noqa: F405

    # Build structured module list for the template grid
    _MODULE_LABELS = {
        "ads_enabled": "Ads",
        "seo_enabled": "SEO",
        "comments_enabled": "Comments",
        "distribution_enabled": "Distribution",
        "device_identity_enabled": "Device Identity",
        "crawler_guard_enabled": "Crawler Guard",
        "ai_enabled": "AI Behavior",
    }
    security_modules = [
        {"label": label, "enabled": bool(security_status.get(key, False))}
        for key, label in _MODULE_LABELS.items()
    ]

    return _render_admin(
        request,
        "admin_suite/settings.html",
        {
            "site_snapshot": site_snapshot,
            "security_status": security_status,
            "security_modules": security_modules,
            "message": message,
        },
        nav_active="settings",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"), ("Settings", None)
        ),
    )


@staff_member_required  # noqa: F405
def admin_suite_settings_edit(request: HttpRequest) -> HttpResponse:  # noqa: F405
    """Edit SiteSettings with a constrained form and cache invalidation."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):  # noqa: F405
        raise _ADMIN_DISABLED  # noqa: F405

    class SettingsForm(forms.Form):  # noqa: F405
        site_name = forms.CharField(max_length=100, required=True)  # noqa: F405
        site_header = forms.CharField(max_length=100, required=False)  # noqa: F405
        site_description = forms.CharField(max_length=500, required=False)  # noqa: F405
        primary_color = forms.CharField(max_length=7, required=False)  # noqa: F405
        secondary_color = forms.CharField(max_length=7, required=False)  # noqa: F405
        enable_signup = forms.BooleanField(required=False)  # noqa: F405
        maintenance_mode = forms.BooleanField(required=False)  # noqa: F405
        force_https = forms.BooleanField(required=False)  # noqa: F405
        cache_ttl_seconds = forms.IntegerField(  # noqa: F405
            required=False, min_value=60, max_value=86400
        )

    instance = None
    initial = {}
    try:
        from apps.site_settings.models import SiteSettings

        instance = SiteSettings.get_solo()
        initial = {
            "site_name": getattr(instance, "site_name", ""),
            "site_header": getattr(instance, "site_header", ""),
            "site_description": getattr(instance, "site_description", ""),
            "primary_color": getattr(instance, "primary_color", ""),
            "secondary_color": getattr(instance, "secondary_color", ""),
            "enable_signup": bool(getattr(instance, "enable_signup", True)),
            "maintenance_mode": bool(getattr(instance, "maintenance_mode", False)),
            "force_https": bool(getattr(instance, "force_https", False)),
            "cache_ttl_seconds": getattr(instance, "cache_ttl_seconds", 600),
        }
    except Exception as exc:
        logger.warning("Admin suite settings load failed: %s", exc)  # noqa: F405

    if request.method == "POST":
        form = SettingsForm(request.POST)
        if form.is_valid() and instance:
            cleaned = form.cleaned_data
            for field, value in cleaned.items():
                setattr(instance, field, value)
            try:
                instance.save()
                try:
                    from apps.core.cache import DistributedCacheManager

                    DistributedCacheManager.invalidate_site_settings()
                except Exception:  # noqa: S110
                    pass
                return redirect("admin_suite:settings")  # noqa: F405
            except Exception as exc:
                form.add_error(None, f"Save failed: {exc}")
    else:
        form = SettingsForm(initial=initial)

    return _render_admin(
        request,
        "admin_suite/settings_edit.html",
        {
            "form": form,
        },
        nav_active="settings",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Settings", "admin_suite:admin_suite_settings"),
            ("Edit", None),
        ),
    )


@staff_member_required  # noqa: F405
def admin_suite_consent(request: HttpRequest) -> HttpResponse:  # noqa: F405
    """Consent overview: policies and recent decisions/events (read-only)."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):  # noqa: F405
        raise _ADMIN_DISABLED  # noqa: F405

    stats = {
        "policies_total": 0,
        "policies_active": 0,
        "decisions_24h": 0,
    }
    policies: list[dict[str, Any]] = []  # noqa: F405
    decisions: list[dict[str, Any]] = []  # noqa: F405
    events: list[dict[str, Any]] = []  # noqa: F405

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from django.utils import timezone

            from apps.consent.models import ConsentPolicy

            if action == "create_policy":
                ConsentPolicy.objects.create(
                    version=(request.POST.get("version") or "")[:50],
                    site_domain=(request.POST.get("site_domain") or "")[:255],
                    is_active=bool(request.POST.get("is_active")),
                    banner_text=(request.POST.get("banner_text") or "")[:255],
                    manage_text=(request.POST.get("manage_text") or "")[:255],
                    cache_ttl_seconds=int(request.POST.get("cache_ttl_seconds") or 600),
                    text=request.POST.get("text") or "",
                    effective_from=request.POST.get("effective_from") or timezone.now(),
                )
            elif action == "update_policy":
                pid = request.POST.get("policy_id")
                ConsentPolicy.objects.filter(pk=pid).update(
                    site_domain=(request.POST.get("site_domain") or "")[:255],
                    is_active=bool(request.POST.get("is_active")),
                    banner_text=(request.POST.get("banner_text") or "")[:255],
                    manage_text=(request.POST.get("manage_text") or "")[:255],
                    cache_ttl_seconds=int(request.POST.get("cache_ttl_seconds") or 600),
                    text=request.POST.get("text") or "",
                )
        except Exception as exc:
            logger.warning("Admin suite consent action failed: %s", exc)  # noqa: F405

    try:
        from django.utils import timezone

        from apps.consent.models import ConsentDecision, ConsentEvent, ConsentPolicy

        stats["policies_total"] = ConsentPolicy.objects.count()
        stats["policies_active"] = ConsentPolicy.objects.filter(is_active=True).count()

        policies = list(
            ConsentPolicy.objects.order_by("-effective_from")[:10].values(
                "id", "version", "site_domain", "is_active", "effective_from"
            )
        )

        since = timezone.now() - timedelta(hours=24)
        stats["decisions_24h"] = ConsentDecision.objects.filter(
            created_at__gte=since
        ).count()
        decisions = list(
            ConsentDecision.objects.select_related("user", "policy")
            .order_by("-created_at")[:10]
            .values(
                "created_at",
                "user__email",
                "session_id",
                "policy__version",
            )
        )

        events = list(
            ConsentEvent.objects.select_related("policy")
            .order_by("-created_at")[:10]
            .values("event_type", "created_at", "policy__version")
        )
    except Exception as exc:
        logger.debug("Admin suite consent snapshot failed: %s", exc)  # noqa: F405

    return _render_admin(
        request,
        "admin_suite/consent.html",
        {
            "stats": stats,
            "policies": policies,
            "decisions": decisions,
            "events": events,
        },
        nav_active="consent",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"), ("Consent", None)
        ),
        subtitle="Policies, decisions, and banner health",
    )


@staff_member_required  # noqa: F405
def admin_suite_email_settings(request: HttpRequest) -> HttpResponse:  # noqa: F405
    """Manage Gmail SMTP settings from SiteSettings."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):  # noqa: F405
        raise _ADMIN_DISABLED  # noqa: F405

    class EmailForm(forms.Form):  # noqa: F405
        gmail_enabled = forms.BooleanField(required=False)  # noqa: F405
        gmail_username = forms.EmailField(required=False)  # noqa: F405
        gmail_app_password = forms.CharField(  # noqa: F405
            widget=forms.PasswordInput(render_value=False),  # noqa: F405
            required=False,  # noqa: F405
        )
        gmail_from_email = forms.EmailField(required=False)  # noqa: F405

    instance = None
    initial: dict[str, Any] = {}  # noqa: F405
    try:
        from apps.site_settings.models import SiteSettings

        instance = SiteSettings.get_solo()
        initial = {
            "gmail_enabled": bool(getattr(instance, "gmail_enabled", False)),
            "gmail_username": getattr(instance, "gmail_username", "") or "",
            "gmail_app_password": getattr(instance, "gmail_app_password", "") or "",
            "gmail_from_email": getattr(instance, "gmail_from_email", "") or "",
        }
    except Exception as exc:
        logger.warning("Admin suite email settings load failed: %s", exc)  # noqa: F405

    if request.method == "POST":
        form = EmailForm(request.POST)
        if form.is_valid() and instance:
            data = form.cleaned_data
            try:
                instance.gmail_enabled = bool(data.get("gmail_enabled"))
                instance.gmail_username = data.get("gmail_username", "") or ""
                instance.gmail_app_password = data.get("gmail_app_password", "") or ""
                instance.gmail_from_email = data.get("gmail_from_email", "") or ""
                instance.save(
                    update_fields=[
                        "gmail_enabled",
                        "gmail_username",
                        "gmail_app_password",
                        "gmail_from_email",
                    ]
                )
                try:
                    from apps.core.cache import DistributedCacheManager

                    DistributedCacheManager.invalidate_site_settings()
                except Exception:  # noqa: S110
                    pass
                messages.success(request, "Email settings updated.")  # noqa: F405
                return redirect("admin_suite:email_settings")  # noqa: F405
            except Exception as exc:
                form.add_error(None, f"Save failed: {exc}")
    else:
        form = EmailForm(initial=initial)

    return _render_admin(
        request,
        "admin_suite/email_settings.html",
        {"form": form},
        nav_active="settings_email",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Settings", "admin_suite:admin_suite_settings"),
            ("Email & Delivery", None),
        ),
        subtitle="Configure Gmail SMTP (app password)",
    )


__all__ = [
    "admin_suite_consent",
    "admin_suite_email_settings",
    "admin_suite_settings",
    "admin_suite_settings_edit",
]
