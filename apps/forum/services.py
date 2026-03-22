from __future__ import annotations

import logging
import re
from typing import TYPE_CHECKING

from django.db import models, transaction
from django.db.models import F
from django.utils import timezone

from apps.core.sanitizers import sanitize_html_content

from .models import (
    ForumAttachment,
    ForumBookmark,
    ForumCategory,
    ForumFlag,
    ForumLike,
    ForumMention,
    ForumPoll,
    ForumPollChoice,
    ForumPollVote,
    ForumPrivateTopic,
    ForumPrivateTopicUser,
    ForumReply,
    ForumReplyHistory,
    ForumTopic,
    ForumTopicFavorite,
    ForumTopicSubscription,
    NotifyFrequency,
    PollMode,
    TopicAction,
)

if TYPE_CHECKING:
    from django.contrib.auth.base_user import AbstractBaseUser
    from django.db.models import QuerySet

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Markdown rendering
# ---------------------------------------------------------------------------

_MENTION_RE = re.compile(r"@([\w.-]+)")


def render_markdown(raw: str) -> str:
    """Convert Markdown to sanitized HTML.

    Uses nh3-based sanitizer from apps.core. Markdown→HTML conversion is
    intentionally lightweight: we wrap paragraphs and handle basic syntax
    server-side. A richer editor can be added later without model changes.
    """
    import markdown

    html = markdown.markdown(
        raw,
        extensions=["extra", "codehilite", "nl2br", "sane_lists"],
    )
    return sanitize_html_content(html)


def extract_mentions(content: str) -> list[str]:
    """Extract unique @username mentions from markdown content."""
    return list(dict.fromkeys(_MENTION_RE.findall(content)))


# ---------------------------------------------------------------------------
# Category helpers
# ---------------------------------------------------------------------------


def get_visible_categories(
    user: AbstractBaseUser | None = None,
) -> QuerySet[ForumCategory]:
    qs = ForumCategory.objects.visible()  # type: ignore[attr-defined]
    if not user or not user.is_authenticated:
        return qs.filter(is_private=False)
    return qs


def recount_category(category: ForumCategory) -> None:
    """Recalculate denormalized counts on a category."""
    topic_count = ForumTopic.objects.filter(category=category, is_removed=False).count()
    reply_count = ForumReply.objects.filter(
        topic__category=category, is_removed=False
    ).count()
    last_topic = (
        ForumTopic.objects.filter(category=category, is_removed=False)
        .order_by("-last_active")
        .values_list("last_active", flat=True)
        .first()
    )
    ForumCategory.objects.filter(pk=category.pk).update(
        topic_count=topic_count,
        reply_count=reply_count,
        last_active=last_topic,
    )


# ---------------------------------------------------------------------------
# Topic CRUD
# ---------------------------------------------------------------------------


@transaction.atomic
def create_topic(
    *,
    user: AbstractBaseUser,
    category: ForumCategory,
    title: str,
    content: str,
    ip_address: str | None = None,
) -> ForumTopic:
    content_html = render_markdown(content)
    topic = ForumTopic.objects.create(
        category=category,
        user=user,
        title=title,
        content=content,
        content_html=content_html,
    )
    # Auto-subscribe author
    ForumTopicSubscription.objects.create(
        topic=topic, user=user, frequency=NotifyFrequency.IMMEDIATELY
    )
    # First "reply" is the topic body itself — create as reply #0 for consistency
    ForumReply.objects.create(
        topic=topic,
        user=user,
        content=content,
        content_html=content_html,
        action=TopicAction.COMMENT,
        ip_address=ip_address,
    )
    # Update category stats
    ForumCategory.objects.filter(pk=category.pk).update(
        topic_count=F("topic_count") + 1,
        last_active=timezone.now(),
    )
    # Publish event
    _publish_event("forum.topic_created", {"topic_id": topic.pk, "user_id": user.pk})

    return topic


def close_topic(topic: ForumTopic, *, user: AbstractBaseUser) -> ForumReply:
    topic.is_closed = True
    topic.save(update_fields=["is_closed", "updated_at"])
    reply = ForumReply.objects.create(
        topic=topic,
        user=user,
        content="",
        content_html="",
        action=TopicAction.CLOSED,
    )
    return reply


def reopen_topic(topic: ForumTopic, *, user: AbstractBaseUser) -> ForumReply:
    topic.is_closed = False
    topic.save(update_fields=["is_closed", "updated_at"])
    reply = ForumReply.objects.create(
        topic=topic,
        user=user,
        content="",
        content_html="",
        action=TopicAction.UNCLOSED,
    )
    return reply


def pin_topic(
    topic: ForumTopic, *, user: AbstractBaseUser, globally: bool = False
) -> ForumReply:
    if globally:
        topic.is_globally_pinned = True
    else:
        topic.is_pinned = True
    topic.save(update_fields=["is_pinned", "is_globally_pinned", "updated_at"])
    reply = ForumReply.objects.create(
        topic=topic,
        user=user,
        content="",
        content_html="",
        action=TopicAction.PINNED,
    )
    return reply


def unpin_topic(topic: ForumTopic, *, user: AbstractBaseUser) -> ForumReply:
    topic.is_pinned = False
    topic.is_globally_pinned = False
    topic.save(update_fields=["is_pinned", "is_globally_pinned", "updated_at"])
    reply = ForumReply.objects.create(
        topic=topic,
        user=user,
        content="",
        content_html="",
        action=TopicAction.UNPINNED,
    )
    return reply


# ---------------------------------------------------------------------------
# Reply CRUD
# ---------------------------------------------------------------------------


@transaction.atomic
def create_reply(
    *,
    topic: ForumTopic,
    user: AbstractBaseUser,
    content: str,
    ip_address: str | None = None,
) -> ForumReply:
    content_html = render_markdown(content)
    reply = ForumReply.objects.create(
        topic=topic,
        user=user,
        content=content,
        content_html=content_html,
        action=TopicAction.COMMENT,
        ip_address=ip_address,
    )
    # Update topic stats
    ForumTopic.objects.filter(pk=topic.pk).update(
        reply_count=F("reply_count") + 1,
        last_active=timezone.now(),
        last_reply_user=user,
    )
    # Update category last_active
    ForumCategory.objects.filter(pk=topic.category_id).update(  # type: ignore[attr-defined]
        reply_count=F("reply_count") + 1,
        last_active=timezone.now(),
    )
    # Process mentions
    mentioned_usernames = extract_mentions(content)
    if mentioned_usernames:
        _create_mentions(reply, mentioned_usernames)

    # Auto-subscribe replier if not already subscribed
    ForumTopicSubscription.objects.get_or_create(
        topic=topic, user=user, defaults={"frequency": NotifyFrequency.IMMEDIATELY}
    )

    # Publish event
    _publish_event(
        "forum.reply_created",
        {"reply_id": reply.pk, "topic_id": topic.pk, "user_id": user.pk},
    )

    return reply


@transaction.atomic
def edit_reply(
    reply: ForumReply,
    *,
    user: AbstractBaseUser,
    new_content: str,
) -> ForumReply:
    # Save history
    ForumReplyHistory.objects.create(
        reply=reply,
        content=reply.content,
        content_html=reply.content_html,
        edited_by=user,
    )
    # Update content
    reply.content = new_content
    reply.content_html = render_markdown(new_content)
    reply.is_modified = True
    reply.modified_count = F("modified_count") + 1
    reply.save(
        update_fields=[
            "content",
            "content_html",
            "is_modified",
            "modified_count",
            "updated_at",
        ]
    )
    reply.refresh_from_db(fields=["modified_count"])

    # Re-process mentions
    ForumMention.objects.filter(reply=reply).delete()
    mentioned_usernames = extract_mentions(new_content)
    if mentioned_usernames:
        _create_mentions(reply, mentioned_usernames)

    return reply


def remove_reply(reply: ForumReply) -> None:
    reply.is_removed = True
    reply.save(update_fields=["is_removed", "updated_at"])


# ---------------------------------------------------------------------------
# Likes
# ---------------------------------------------------------------------------


@transaction.atomic
def toggle_like(reply: ForumReply, user: AbstractBaseUser) -> bool:
    """Toggle like on a reply. Returns True if liked, False if unliked."""
    deleted, _ = ForumLike.objects.filter(reply=reply, user=user).delete()
    if deleted:
        ForumReply.objects.filter(pk=reply.pk).update(likes_count=F("likes_count") - 1)
        return False
    ForumLike.objects.create(reply=reply, user=user)
    ForumReply.objects.filter(pk=reply.pk).update(likes_count=F("likes_count") + 1)
    _publish_event(
        "forum.like_received",
        {"reply_id": reply.pk, "user_id": user.pk, "author_id": reply.user_id},  # type: ignore[attr-defined]
    )
    return True


# ---------------------------------------------------------------------------
# Favorites
# ---------------------------------------------------------------------------


def toggle_favorite(topic: ForumTopic, user: AbstractBaseUser) -> bool:
    """Toggle favorite on a topic. Returns True if added, False if removed."""
    deleted, _ = ForumTopicFavorite.objects.filter(topic=topic, user=user).delete()
    if deleted:
        return False
    ForumTopicFavorite.objects.create(topic=topic, user=user)
    return True


# ---------------------------------------------------------------------------
# Bookmarks (read position)
# ---------------------------------------------------------------------------


def update_bookmark(
    topic: ForumTopic, user: AbstractBaseUser, reply_number: int
) -> None:
    ForumBookmark.objects.update_or_create(
        topic=topic,
        user=user,
        defaults={"reply_number": reply_number},
    )


def get_bookmark(topic: ForumTopic, user: AbstractBaseUser) -> int:
    bm = ForumBookmark.objects.filter(topic=topic, user=user).first()
    return bm.reply_number if bm else 0


# ---------------------------------------------------------------------------
# Polls
# ---------------------------------------------------------------------------


@transaction.atomic
def create_poll(
    *,
    topic: ForumTopic,
    title: str,
    choices: list[str],
    mode: str = PollMode.SINGLE,
    is_secret: bool = False,
    close_at: str | None = None,
) -> ForumPoll:
    from django.utils.dateparse import parse_datetime

    poll = ForumPoll.objects.create(
        topic=topic,
        title=title,
        mode=mode,
        is_secret=is_secret,
        close_at=parse_datetime(close_at) if close_at else None,
    )
    for i, desc in enumerate(choices):
        ForumPollChoice.objects.create(poll=poll, description=desc, sort_order=i)
    return poll


@transaction.atomic
def cast_vote(
    poll: ForumPoll, choice: ForumPollChoice, user: AbstractBaseUser
) -> ForumPollVote | None:
    if not poll.is_open:
        return None
    # Single mode: remove existing vote first
    if poll.mode == PollMode.SINGLE:
        existing = ForumPollVote.objects.filter(poll=poll, user=user).select_related(
            "choice"
        )
        for v in existing:
            ForumPollChoice.objects.filter(pk=v.choice_id).update(  # type: ignore[attr-defined]
                vote_count=F("vote_count") - 1
            )
        existing.delete()

    # Multiple mode: check if already voted for this choice
    if poll.mode == PollMode.MULTIPLE:
        if ForumPollVote.objects.filter(poll=poll, choice=choice, user=user).exists():
            return None

    vote = ForumPollVote.objects.create(poll=poll, choice=choice, user=user)
    ForumPollChoice.objects.filter(pk=choice.pk).update(vote_count=F("vote_count") + 1)
    ForumPoll.objects.filter(pk=poll.pk).update(vote_count=F("vote_count") + 1)
    return vote


# ---------------------------------------------------------------------------
# Private topics
# ---------------------------------------------------------------------------


@transaction.atomic
def create_private_topic(
    *,
    user: AbstractBaseUser,
    category: ForumCategory,
    title: str,
    content: str,
    invite_user_ids: list[int],
    ip_address: str | None = None,
) -> ForumTopic:
    topic = create_topic(
        user=user,
        category=category,
        title=title,
        content=content,
        ip_address=ip_address,
    )
    private = ForumPrivateTopic.objects.create(user=user, topic=topic)
    # Creator is always a participant
    ForumPrivateTopicUser.objects.create(private_topic=private, user=user)
    for uid in invite_user_ids:
        if uid != user.pk:
            ForumPrivateTopicUser.objects.create(private_topic=private, user_id=uid)
    return topic


def can_view_topic(topic: ForumTopic, user: AbstractBaseUser | None) -> bool:
    """Check if user can view the topic (handles private topics)."""
    if not hasattr(topic, "private_info"):
        try:
            topic.private_info  # type: ignore[attr-defined]  # noqa: B018 — triggers the query
        except ForumPrivateTopic.DoesNotExist:
            # Public topic
            return not topic.is_removed

    private = getattr(topic, "private_info", None)
    if private is None:
        return not topic.is_removed
    if user is None or not user.is_authenticated:
        return False
    if user.is_staff:  # type: ignore[union-attr]
        return True
    return ForumPrivateTopicUser.objects.filter(
        private_topic=private, user=user
    ).exists()


# ---------------------------------------------------------------------------
# Subscriptions
# ---------------------------------------------------------------------------


def subscribe(
    topic: ForumTopic,
    user: AbstractBaseUser,
    frequency: str = NotifyFrequency.IMMEDIATELY,
) -> ForumTopicSubscription:
    sub, _ = ForumTopicSubscription.objects.update_or_create(
        topic=topic,
        user=user,
        defaults={"frequency": frequency},
    )
    return sub


def unsubscribe(topic: ForumTopic, user: AbstractBaseUser) -> None:
    ForumTopicSubscription.objects.filter(topic=topic, user=user).delete()


# ---------------------------------------------------------------------------
# Flagging
# ---------------------------------------------------------------------------


def create_flag(
    *,
    user: AbstractBaseUser,
    topic: ForumTopic | None = None,
    reply: ForumReply | None = None,
    reason: str,
    detail: str = "",
) -> ForumFlag:
    return ForumFlag.objects.create(
        user=user,
        topic=topic,
        reply=reply,
        reason=reason,
        detail=detail,
    )


# ---------------------------------------------------------------------------
# Attachments
# ---------------------------------------------------------------------------


def create_attachment(
    *,
    reply: ForumReply,
    user: AbstractBaseUser,
    file: object,
    filename: str,
    content_type: str = "",
    file_size: int = 0,
) -> ForumAttachment:
    return ForumAttachment.objects.create(
        reply=reply,
        user=user,
        file=file,  # type: ignore[arg-type]
        filename=filename,
        content_type=content_type,
        file_size=file_size,
    )


# ---------------------------------------------------------------------------
# Search (PostgreSQL FTS)
# ---------------------------------------------------------------------------


def search_topics(query: str, limit: int = 20) -> QuerySet[ForumTopic]:
    """Basic search using icontains. Can be upgraded to PostgreSQL FTS later."""
    return (
        ForumTopic.objects.filter(
            models.Q(title__icontains=query) | models.Q(content__icontains=query),
            is_removed=False,
        )
        .select_related("category", "user")
        .order_by("-last_active")[:limit]
    )


# ---------------------------------------------------------------------------
# Increment view count
# ---------------------------------------------------------------------------


def increment_view_count(topic: ForumTopic) -> None:
    ForumTopic.objects.filter(pk=topic.pk).update(view_count=F("view_count") + 1)


# ---------------------------------------------------------------------------
# Mentions helper
# ---------------------------------------------------------------------------


def _create_mentions(reply: ForumReply, usernames: list[str]) -> None:
    from django.contrib.auth import get_user_model

    User = get_user_model()
    users = User.objects.filter(username__in=usernames)
    mentions = [
        ForumMention(reply=reply, user=u)
        for u in users
        if u.pk != reply.user_id  # type: ignore[attr-defined]
    ]
    ForumMention.objects.bulk_create(mentions, ignore_conflicts=True)

    # Publish events for each mention
    for m in mentions:
        _publish_event(
            "forum.mention",
            {
                "reply_id": reply.pk,
                "mentioned_user_id": m.user_id,  # type: ignore[attr-defined]
                "by_user_id": reply.user_id,  # type: ignore[attr-defined]
            },
        )


# ---------------------------------------------------------------------------
# EventBus helper
# ---------------------------------------------------------------------------


def _publish_event(event_type: str, data: dict[str, object]) -> None:
    try:
        from apps.core.events.bus import event_bus

        event_bus.publish(event_type, data)
    except Exception:
        logger.debug("Failed to publish event %s", event_type, exc_info=True)
