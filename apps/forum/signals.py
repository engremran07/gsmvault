"""Forum signals — hooks into EventBus for gamification & notifications."""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def _on_topic_created(data: dict[str, object]) -> None:
    """Award XP for creating a topic."""
    try:
        from apps.core.events.bus import event_bus

        event_bus.publish(
            "gamification.award_xp",
            {
                "user_id": data.get("user_id"),
                "amount": 10,
                "reason": "Created a forum topic",
                "source_type": "forum_topic",
                "source_id": data.get("topic_id"),
            },
        )
    except Exception:
        logger.debug("Gamification event failed for topic_created")


def _on_reply_created(data: dict[str, object]) -> None:
    """Award XP for replying and notify topic subscribers."""
    try:
        from apps.core.events.bus import event_bus

        event_bus.publish(
            "gamification.award_xp",
            {
                "user_id": data.get("user_id"),
                "amount": 5,
                "reason": "Replied in forum topic",
                "source_type": "forum_reply",
                "source_id": data.get("reply_id"),
            },
        )
    except Exception:
        logger.debug("Gamification event failed for reply_created")


def _on_like_received(data: dict[str, object]) -> None:
    """Award XP to the reply author when their reply is liked."""
    author_id = data.get("author_id")
    if not author_id:
        return
    try:
        from apps.core.events.bus import event_bus

        event_bus.publish(
            "gamification.award_xp",
            {
                "user_id": author_id,
                "amount": 2,
                "reason": "Forum reply liked",
                "source_type": "forum_like",
                "source_id": data.get("reply_id"),
            },
        )
    except Exception:
        logger.debug("Gamification event failed for like_received")


def _on_mention(data: dict[str, object]) -> None:
    """Notify the mentioned user."""
    logger.debug("Forum mention event: %s", data)


def register_event_handlers() -> None:
    """Register forum event handlers with the EventBus."""
    try:
        from apps.core.events.bus import event_bus

        event_bus.subscribe("forum.topic_created")(_on_topic_created)
        event_bus.subscribe("forum.reply_created")(_on_reply_created)
        event_bus.subscribe("forum.like_received")(_on_like_received)
        event_bus.subscribe("forum.mention")(_on_mention)
    except Exception:
        logger.debug("Failed to register forum event handlers")


# Auto-register on import
register_event_handlers()
