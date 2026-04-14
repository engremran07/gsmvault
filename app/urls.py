"""
Unified Core URL Configuration for the project.

Production-ready for:
  • Django 5.2+
  • Python 3.12+
  • django-allauth 0.65+

Features:
  - Async-safe lazy loader
  - Modular routing (users, notifications under users, consent, site_settings, core)
  - Static & media (dev only)
  - Health endpoint
  - Hardened admin identity (non-branded)
"""

from __future__ import annotations

import inspect
import logging
from collections.abc import Callable
from typing import Any

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import HttpResponse
from django.urls import include, path, re_path
from django.utils.module_loading import import_string
from django.views.generic import RedirectView

from apps.core import views as core_views
from apps.pages import views as pages_views

logger = logging.getLogger(__name__)


# =====================================================================
# Async-safe lazy view importer
# =====================================================================
def lazy_view(dotted_path: str) -> Callable[..., Any]:
    """
    Import view lazily at call time.
    Supports sync, async, and class-based views.
    """

    async def _wrapper(request, *args, **kwargs):
        view_obj = import_string(dotted_path)

        # Class-based view support
        if inspect.isclass(view_obj) and hasattr(view_obj, "as_view"):
            view_callable = view_obj.as_view()
        else:
            view_callable = view_obj

        result = view_callable(request, *args, **kwargs)

        # Async view support
        if inspect.isawaitable(result):
            return await result
        return result

    return _wrapper


# =====================================================================
# Admin Branding (non-branded; project rule)
# =====================================================================
admin.site.site_header = "Administration"
admin.site.site_title = "Admin Portal"
admin.site.index_title = "System Management Console"


# =====================================================================
# URL Patterns
# =====================================================================
urlpatterns = [
    # Admin Suite (custom) at /admin/; Django admin under alternate path.
    path(
        "admin/", include(("apps.admin.urls", "admin_suite"), namespace="admin_suite")
    ),
    path("admin-suite/", RedirectView.as_view(url="/admin/", permanent=True)),
    # Keep Django admin available under a non-default path for reverse('admin:*') compatibility
    path("django-admin/", admin.site.urls),
    # Legacy Django-admin blog paths redirect to Admin Suite blog manager
    path("admin/blog/", RedirectView.as_view(url="/admin/blog/", permanent=False)),
    path(
        "admin/blog/post/<int:pk>/change/",
        RedirectView.as_view(url="/admin/blog/?post_id=%(pk)s", permanent=False),
    ),
    # Authentication (allauth)
    path("accounts/", include("allauth.urls")),
    # Users module
    path("users/", include(("apps.users.urls", "users"), namespace="users")),
    # Notifications (implemented inside users app)
    # NOTE: module apps.users.notifications_urls defines app_name="users_notifications",
    # so we include it with the same internal app_name and namespace to avoid conflicts.
    path(
        "notifications/",
        include(
            ("apps.users.notifications_urls", "users_notifications"),
            namespace="users_notifications",
        ),
    ),
    # Consent subsystem
    path("consent/", include(("apps.consent.urls", "consent"), namespace="consent")),
    # Site settings
    path(
        "site_settings/",
        include(
            ("apps.site_settings.urls", "site_settings"), namespace="site_settings"
        ),
    ),
    # Ads subsystem
    path("ads/", include(("apps.ads.urls", "ads"), namespace="ads")),
    # Analytics & metrics
    path(
        "analytics/",
        include(("apps.analytics.urls", "analytics"), namespace="analytics"),
    ),
    # Distribution / syndication
    path(
        "distribution/",
        include(("apps.distribution.urls", "distribution"), namespace="distribution"),
    ),
    path("devices/", include(("apps.devices.urls", "devices"), namespace="devices")),
    # Tags
    path("tags/", include(("apps.tags.urls", "tags"), namespace="tags")),
    # Blog (public)
    path("blog/", include(("apps.blog.urls", "blog"), namespace="blog")),
    # Comments API
    path(
        "comments/", include(("apps.comments.urls", "comments"), namespace="comments")
    ),
    # Core API endpoints
    path(
        "api/comments/",
        include(("apps.comments.urls_api", "comments_api"), namespace="comments_api"),
    ),
    path(
        "api/tags/", include(("apps.tags.urls_api", "tags_api"), namespace="tags_api")
    ),
    path(
        "api/storage/", include(("apps.storage.urls", "storage"), namespace="storage")
    ),
    path(
        "firmwares/",
        include(("apps.firmwares.urls", "firmwares"), namespace="firmwares"),
    ),
    # Legacy redirect: /api/firmwares/* → /firmwares/*
    path(
        "api/firmwares/",
        RedirectView.as_view(url="/firmwares/", permanent=True),
    ),
    # Security (merged security_suite + security_events)
    path(
        "api/v1/security/",
        include(("apps.security.urls", "security"), namespace="security"),
    ),
    # AI micro-app
    path("ai/", include(("apps.ai.urls", "ai"), namespace="ai")),
    # New platform apps — all under /api/v1/
    path(
        "api/v1/notifications/",
        include(
            ("apps.notifications.urls", "notifications"), namespace="notifications"
        ),
    ),
    path(
        "api/v1/moderation/",
        include(("apps.moderation.urls", "moderation"), namespace="moderation"),
    ),
    path("api/v1/shop/", include(("apps.shop.urls", "shop"), namespace="shop")),
    path("api/v1/seo/", include(("apps.seo.urls", "seo"), namespace="seo")),
    path("api/v1/wallet/", include(("apps.wallet.urls", "wallet"), namespace="wallet")),
    path(
        "api/v1/bounty/",
        include(("apps.bounty.urls_api", "bounty_api"), namespace="bounty_api"),
    ),
    # Bounty public pages
    path("bounty/", include(("apps.bounty.urls", "bounty"), namespace="bounty")),
    # ── Public pages for commerce/community apps ──
    path(
        "marketplace/",
        include(
            ("apps.marketplace.urls_public", "marketplace_public"),
            namespace="marketplace_public",
        ),
    ),
    path(
        "shop/",
        include(
            ("apps.shop.urls_public", "shop_public"),
            namespace="shop_public",
        ),
    ),
    path(
        "wallet/",
        include(
            ("apps.wallet.urls_public", "wallet_public"),
            namespace="wallet_public",
        ),
    ),
    path(
        "rewards/",
        include(
            ("apps.gamification.urls_public", "gamification_public"),
            namespace="gamification_public",
        ),
    ),
    path(
        "referrals/",
        include(
            ("apps.referral.urls_public", "referral_public"),
            namespace="referral_public",
        ),
    ),
    path(
        "api/v1/referral/",
        include(("apps.referral.urls", "referral"), namespace="referral"),
    ),
    # Referral landing — short URL for sharing
    path(
        "ref/<str:code>/",
        lazy_view("apps.referral.views.referral_landing"),
        name="referral_landing",
    ),
    path(
        "api/v1/gamification/",
        include(("apps.gamification.urls", "gamification"), namespace="gamification"),
    ),
    path(
        "api/v1/profile/",
        include(("apps.user_profile.urls", "user_profile"), namespace="user_profile"),
    ),
    path("api/v1/api-keys/", include(("apps.api.urls", "api"), namespace="api")),
    path("api/v1/backup/", include(("apps.backup.urls", "backup"), namespace="backup")),
    path(
        "api/v1/marketplace/",
        include(("apps.marketplace.urls", "marketplace"), namespace="marketplace"),
    ),
    # Forum
    path("forum/", include(("apps.forum.urls", "forum"), namespace="forum")),
    path(
        "api/v1/forum/",
        include(("apps.forum.urls_api", "forum_api"), namespace="forum_api"),
    ),
    # changelog dissolved into apps.firmwares — models/viewsets now in apps.firmwares
    # Viewsets available at: api/firmwares/changelog-entries/ and firmware-diffs/
    # Legacy core namespace (site_map redirects, etc.)
    path("core/", include(("apps.core.urls", "core"), namespace="core")),
    # Legacy /pages/* routes redirect to new root-based pages
    path("pages/", RedirectView.as_view(url="/", permanent=True)),
    path("pages/<slug:slug>/", RedirectView.as_view(url="/%(slug)s/", permanent=True)),
    # Homepage with stats, search, firmwares, and blogs
    path("", pages_views.home_landing, name="home"),
    # Public pages (slug-based CMS pages)
    path("", include(("apps.pages.urls", "pages"), namespace="pages")),
    # Redirect /home/ to root homepage
    path("home/", RedirectView.as_view(pattern_name="home", permanent=True)),
    # Health check (well-known)
    path(
        ".well-known/health",
        lazy_view("apps.core.views.health_check"),
        name="health_check",
    ),
    # AI assistant endpoint (frontend widget)
    path("api/ai/ask", core_views.ai_assistant_view, name="api_ai_ask"),
    # Legacy redirect
    path("index/", RedirectView.as_view(pattern_name="home", permanent=True)),
    # Legacy dashboard redirect removed (user dashboard lives under /users/dashboard/)
    # Favicon
    re_path(
        r"^favicon\.ico$",
        RedirectView.as_view(url="/static/favicon.ico", permanent=True),
    ),
    # Silence Chrome DevTools .well-known noise (Chrome 133+)
    re_path(
        r"^\.well-known/appspecific/",
        lambda request: HttpResponse(status=204),
    ),
]


# =====================================================================
# Static & Media (DEV only)
# =====================================================================
if settings.DEBUG:
    # media files
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

    try:
        from django.contrib.staticfiles.urls import staticfiles_urlpatterns

        urlpatterns += staticfiles_urlpatterns()
    except Exception as exc:
        logger.warning("staticfiles_urlpatterns() unavailable: %s", exc)
        urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)


# =====================================================================
# Error handlers
# =====================================================================
handler400 = "apps.core.views.error_400_view"
handler403 = "apps.core.views.error_403_view"
handler404 = "apps.core.views.error_404_view"
handler500 = "apps.core.views.error_500_view"
