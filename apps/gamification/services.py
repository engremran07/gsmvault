"""Gamification service layer — XP awards, badge evaluation, streak tracking."""

from __future__ import annotations

import logging
from datetime import timedelta
from typing import TYPE_CHECKING

from django.db import transaction
from django.db.models import Sum
from django.utils import timezone

from .models import (
    Badge,
    Leaderboard,
    LeaderboardEntry,
    Level,
    Streak,
    UserBadge,
    XPTransaction,
)

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# XP
# ---------------------------------------------------------------------------


@transaction.atomic
def award_xp(
    *,
    user_id: int,
    amount: int,
    reason: str,
    source_type: str = "",
    source_id: int | None = None,
) -> XPTransaction | None:
    """Credit (or debit) XP and evaluate badges + level afterwards."""
    if not amount:
        return None

    # Avoid duplicate awards for the same source
    if source_type and source_id:
        exists = XPTransaction.objects.filter(
            user_id=user_id, source_type=source_type, source_id=source_id
        ).exists()
        if exists:
            logger.debug("Duplicate XP award skipped: %s/%s", source_type, source_id)
            return None

    txn = XPTransaction.objects.create(
        user_id=user_id,
        amount=amount,
        reason=reason,
        source_type=source_type,
        source_id=source_id,
    )

    # Evaluate badges and level after XP change
    evaluate_badges(user_id)
    update_streak(user_id)

    return txn


def get_total_xp(user_id: int) -> int:
    """Return total XP for a user."""
    result = XPTransaction.objects.filter(user_id=user_id).aggregate(
        total=Sum("amount")
    )
    return result["total"] or 0


def get_current_level(user_id: int) -> Level | None:
    """Return the highest Level the user qualifies for based on XP."""
    total = get_total_xp(user_id)
    return Level.objects.filter(min_xp__lte=total).order_by("-min_xp").first()


# ---------------------------------------------------------------------------
# Badge evaluation engine
# ---------------------------------------------------------------------------

# Supported criteria keys in Badge.criteria JSON:
#   "min_xp": 500            — user must have >= 500 total XP
#   "min_topics": 5          — user must have >= 5 forum topics
#   "min_replies": 20        — user must have >= 20 forum replies
#   "min_likes_given": 10    — user must have given >= 10 forum likes
#   "min_likes_received": 10 — user must have received >= 10 forum likes
#   "min_downloads": 5       — user must have >= 5 firmware downloads
#   "min_streak": 7          — user must have >= 7 day streak
#   "min_referrals": 3       — user must have >= 3 referrals
#   "min_bounties": 1        — user must have >= 1 completed bounty


def evaluate_badges(user_id: int) -> list[Badge]:
    """Evaluate all active badges and award any the user qualifies for.

    Returns list of newly awarded badges.
    """
    already_earned = set(
        UserBadge.objects.filter(user_id=user_id).values_list("badge_id", flat=True)
    )
    candidates = Badge.objects.filter(is_active=True).exclude(pk__in=already_earned)

    if not candidates.exists():
        return []

    # Gather user stats once
    stats = _gather_user_stats(user_id)
    awarded: list[Badge] = []

    for badge in candidates:
        criteria = badge.criteria or {}
        if not criteria:
            continue
        if _meets_criteria(stats, criteria):
            UserBadge.objects.create(user_id=user_id, badge=badge)
            # Award bonus XP for badge (without re-evaluating to avoid recursion)
            if badge.xp_value:
                XPTransaction.objects.create(
                    user_id=user_id,
                    amount=badge.xp_value,
                    reason=f"Badge earned: {badge.name}",
                    source_type="badge",
                    source_id=badge.pk,
                )
            awarded.append(badge)
            logger.info("User %s earned badge: %s", user_id, badge.name)

    return awarded


def _gather_user_stats(user_id: int) -> dict[str, int]:
    """Collect all stats needed for badge criteria evaluation."""
    stats: dict[str, int] = {
        "total_xp": get_total_xp(user_id),
        "topics": 0,
        "replies": 0,
        "likes_given": 0,
        "likes_received": 0,
        "downloads": 0,
        "streak": 0,
        "referrals": 0,
        "bounties": 0,
    }

    # Forum stats (graceful — forum may not be installed)
    try:
        from apps.forum.models import ForumLike, ForumReply, ForumTopic

        stats["topics"] = ForumTopic.objects.filter(user_id=user_id).count()
        stats["replies"] = ForumReply.objects.filter(user_id=user_id).count()
        stats["likes_given"] = ForumLike.objects.filter(user_id=user_id).count()
        stats["likes_received"] = (
            ForumReply.objects.filter(user_id=user_id).aggregate(
                total=Sum("likes_count")
            )["total"]
            or 0
        )
    except Exception:
        logger.debug("Forum stats unavailable for user %s", user_id)

    # Download stats
    try:
        from apps.firmwares.models import DownloadSession

        stats["downloads"] = DownloadSession.objects.filter(user_id=user_id).count()
    except Exception:
        logger.debug("Download stats unavailable for user %s", user_id)

    # Streak
    try:
        streak_obj = Streak.objects.filter(user_id=user_id).first()
        if streak_obj:
            stats["streak"] = streak_obj.count
    except Exception:
        logger.debug("Streak stats unavailable for user %s", user_id)

    # Referrals
    try:
        from apps.referral.models import ReferralClick, ReferralCode

        codes = ReferralCode.objects.filter(user_id=user_id).values_list(
            "pk", flat=True
        )
        stats["referrals"] = ReferralClick.objects.filter(
            code_id__in=codes, converted=True
        ).count()
    except Exception:
        logger.debug("Referral stats unavailable for user %s", user_id)

    # Bounties completed
    try:
        from apps.bounty.models import BountySubmission

        stats["bounties"] = BountySubmission.objects.filter(
            user_id=user_id, status="approved"
        ).count()
    except Exception:
        logger.debug("Bounty stats unavailable for user %s", user_id)

    return stats


_CRITERIA_MAP: dict[str, str] = {
    "min_xp": "total_xp",
    "min_topics": "topics",
    "min_replies": "replies",
    "min_likes_given": "likes_given",
    "min_likes_received": "likes_received",
    "min_downloads": "downloads",
    "min_streak": "streak",
    "min_referrals": "referrals",
    "min_bounties": "bounties",
}


def _meets_criteria(stats: dict[str, int], criteria: dict[str, object]) -> bool:
    """Return True if all criteria keys are met."""
    for key, threshold in criteria.items():
        stat_key = _CRITERIA_MAP.get(key)
        if stat_key is None:
            continue  # Unknown criterion — skip
        try:
            if stats.get(stat_key, 0) < int(threshold):  # type: ignore[arg-type]
                return False
        except (TypeError, ValueError):
            return False
    return True


# ---------------------------------------------------------------------------
# Streaks
# ---------------------------------------------------------------------------


def update_streak(user_id: int) -> Streak:
    """Bump daily streak if user hasn't logged activity today."""
    today = timezone.now().date()
    streak, _ = Streak.objects.get_or_create(user_id=user_id)

    if streak.last_activity_date == today:
        return streak  # Already counted today

    yesterday = today - timedelta(days=1)
    if streak.last_activity_date == yesterday:
        streak.count += 1
    else:
        streak.count = 1  # Streak broken — restart

    streak.last_activity_date = today
    if streak.count > streak.longest_streak:
        streak.longest_streak = streak.count
    streak.save(
        update_fields=["count", "last_activity_date", "longest_streak", "updated_at"]
    )

    return streak


# ---------------------------------------------------------------------------
# Leaderboard refresh
# ---------------------------------------------------------------------------


def refresh_leaderboard(period_type: str = "all_time", scope: str = "global") -> None:
    """Rebuild a leaderboard from XP transaction aggregates."""
    leaderboard, _ = Leaderboard.objects.get_or_create(
        period_type=period_type, scope=scope
    )

    # Determine time window
    since = None
    now = timezone.now()
    if period_type == "daily":
        since = now - timedelta(days=1)
    elif period_type == "weekly":
        since = now - timedelta(weeks=1)
    elif period_type == "monthly":
        since = now - timedelta(days=30)

    qs = XPTransaction.objects.all()
    if since:
        qs = qs.filter(created_at__gte=since)

    rankings = (
        qs.values("user_id")
        .annotate(score=Sum("amount"))
        .filter(score__gt=0)
        .order_by("-score")[:100]
    )

    # Atomic swap
    with transaction.atomic():
        LeaderboardEntry.objects.filter(leaderboard=leaderboard).delete()
        entries = [
            LeaderboardEntry(
                leaderboard=leaderboard,
                user_id=row["user_id"],
                rank=idx + 1,
                score=row["score"],
            )
            for idx, row in enumerate(rankings)
        ]
        LeaderboardEntry.objects.bulk_create(entries)
    leaderboard.save(update_fields=["updated_at"])
