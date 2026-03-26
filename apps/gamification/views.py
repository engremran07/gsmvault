"""apps.gamification.views — Public gamification pages (progress, badges, leaderboard)."""

from __future__ import annotations

import logging

from django.contrib.auth.decorators import login_required
from django.db.models import Sum
from django.http import HttpRequest, HttpResponse
from django.shortcuts import render

from .models import (
    Badge,
    Leaderboard,
    LeaderboardEntry,
    Level,
    Streak,
    UserBadge,
    XPTransaction,
)

logger = logging.getLogger(__name__)


@login_required
def my_progress(request: HttpRequest) -> HttpResponse:
    """User's gamification progress — level, XP, badges, streak."""
    total_xp = (
        XPTransaction.objects.filter(user=request.user).aggregate(total=Sum("amount"))[
            "total"
        ]
        or 0
    )

    # Current level
    current_level = (
        Level.objects.filter(min_xp__lte=total_xp).order_by("-min_xp").first()
    )
    next_level = None
    if current_level:
        next_level = (
            Level.objects.filter(min_xp__gt=total_xp).order_by("min_xp").first()
        )

    # User badges
    user_badges = (
        UserBadge.objects.filter(user=request.user)
        .select_related("badge")
        .order_by("-earned_at")
    )

    # Streak
    streak = Streak.objects.filter(user=request.user).first()

    # Recent XP
    recent_xp = XPTransaction.objects.filter(user=request.user).order_by("-created_at")[
        :15
    ]

    context = {
        "total_xp": total_xp,
        "current_level": current_level,
        "next_level": next_level,
        "user_badges": user_badges,
        "streak": streak,
        "recent_xp": recent_xp,
    }
    return render(request, "gamification/my_progress.html", context)


def badge_showcase(request: HttpRequest) -> HttpResponse:
    """Browse all available badges."""
    badges = Badge.objects.filter(is_active=True).order_by("name")

    # If authenticated, mark which ones the user has
    earned_ids: set[int] = set()
    if request.user.is_authenticated:
        earned_ids = set(
            UserBadge.objects.filter(user=request.user).values_list(
                "badge_id", flat=True
            )
        )

    context = {
        "badges": badges,
        "earned_ids": earned_ids,
    }
    return render(request, "gamification/badge_showcase.html", context)


def global_leaderboard(request: HttpRequest) -> HttpResponse:
    """Global leaderboard page."""
    period = request.GET.get("period", "all_time")

    leaderboard = Leaderboard.objects.filter(period_type=period, scope="global").first()

    entries: list[LeaderboardEntry] = []
    if leaderboard:
        entries = list(
            LeaderboardEntry.objects.filter(leaderboard=leaderboard)
            .select_related("user")
            .order_by("rank")[:50]
        )

    context = {
        "entries": entries,
        "current_period": period,
        "period_choices": Leaderboard.PeriodType.choices,
    }
    return render(request, "gamification/leaderboard.html", context)
