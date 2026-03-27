"""Gamification event handlers — subscribe to EventBus for XP and badge awards."""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def _on_award_xp(data: dict[str, object]) -> None:
    """Handle gamification.award_xp event from any app."""
    user_id = data.get("user_id")
    amount = data.get("amount", 0)
    reason = data.get("reason", "")
    source_type = data.get("source_type", "")
    source_id = data.get("source_id")

    if not user_id or not amount:
        return

    try:
        from . import services

        services.award_xp(
            user_id=int(str(user_id)),
            amount=int(str(amount)),
            reason=str(reason),
            source_type=str(source_type),
            source_id=int(str(source_id)) if source_id else None,
        )
    except Exception:
        logger.exception("Failed to award XP for user %s", user_id)


def _on_refresh_leaderboard(data: dict[str, object]) -> None:
    """Handle gamification.refresh_leaderboard event."""
    try:
        from . import services

        period = str(data.get("period_type", "all_time"))
        scope = str(data.get("scope", "global"))
        services.refresh_leaderboard(period_type=period, scope=scope)
    except Exception:
        logger.exception("Failed to refresh leaderboard")


def register_event_handlers() -> None:
    """Subscribe gamification handlers to the EventBus."""
    try:
        from apps.core.events.bus import event_bus

        event_bus.subscribe("gamification.award_xp")(_on_award_xp)
        event_bus.subscribe("gamification.refresh_leaderboard")(_on_refresh_leaderboard)
        logger.debug("Gamification event handlers registered")
    except Exception:
        logger.debug("Failed to register gamification event handlers")
