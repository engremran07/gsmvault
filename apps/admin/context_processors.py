"""Admin suite context processor — sidebar badge counts (cached 5 min)."""

from __future__ import annotations

import logging
from typing import Any

from django.core.cache import cache
from django.http import HttpRequest

logger = logging.getLogger(__name__)

_CACHE_KEY = "admin_sidebar_badges"
_CACHE_TTL = 300  # 5 minutes


def admin_sidebar_badges(request: HttpRequest) -> dict[str, Any]:
    """Inject sidebar badge counts only for staff on admin pages."""
    if not getattr(request, "resolver_match", None):
        return {}
    namespace = getattr(request.resolver_match, "namespace", "")
    if namespace != "admin_suite" or not getattr(request.user, "is_staff", False):
        return {}

    badges = cache.get(_CACHE_KEY)
    if badges is not None:
        return badges

    badges = _compute_badges()
    cache.set(_CACHE_KEY, badges, _CACHE_TTL)
    return badges


def _compute_badges() -> dict[str, Any]:
    """Compute badge counts with safe imports (apps may not be ready)."""
    from datetime import timedelta

    from django.utils import timezone

    counts: dict[str, Any] = {}

    # Pending comments
    try:
        from apps.comments.models import Comment

        counts["sidebar_pending_comments"] = Comment.objects.filter(
            status=Comment.Status.PENDING
        ).count()
    except Exception:
        counts["sidebar_pending_comments"] = 0

    # Critical security events (last 24h)
    try:
        from apps.security.models import SecurityEvent

        cutoff = timezone.now() - timedelta(hours=24)
        counts["sidebar_critical_events"] = SecurityEvent.objects.filter(
            severity=SecurityEvent.Severity.CRITICAL,
            created_at__gte=cutoff,
        ).count()
    except Exception:
        counts["sidebar_critical_events"] = 0

    # Blog posts pending review
    try:
        from apps.blog.models import Post, PostStatus

        counts["sidebar_review_posts"] = Post.objects.filter(
            status__in=[PostStatus.DRAFT, PostStatus.IN_REVIEW]
        ).count()
    except Exception:
        counts["sidebar_review_posts"] = 0

    return counts
