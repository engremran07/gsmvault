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
    ForumBestAnswer,
    ForumBookmark,
    ForumCategory,
    ForumCategorySubscription,
    ForumChangelog,
    ForumFAQEntry,
    ForumFlag,
    ForumIPBan,
    ForumLike,
    ForumMention,
    ForumOnlineUser,
    ForumPoll,
    ForumPollChoice,
    ForumPollVote,
    ForumPrivateTopic,
    ForumPrivateTopicUser,
    ForumReaction,
    ForumReply,
    ForumReplyHistory,
    ForumReplyReaction,
    ForumTopic,
    ForumTopicFavorite,
    ForumTopicMergeLog,
    ForumTopicMoveLog,
    ForumTopicRating,
    ForumTopicSubscription,
    ForumTopicTag,
    ForumTrustLevel,
    ForumUsefulPost,
    ForumUserProfile,
    ForumWarning,
    ForumWikiHeaderHistory,
    NotifyFrequency,
    PollMode,
    TopicAction,
    TrustLevelChoices,
)

if TYPE_CHECKING:
    from django.contrib.auth.base_user import AbstractBaseUser
    from django.db.models import QuerySet

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Trust level enforcement
# ---------------------------------------------------------------------------


class ForumPermissionError(PermissionError):
    """Raised when a user's trust level doesn't permit the action."""


def _get_user_trust_config(user: AbstractBaseUser) -> ForumTrustLevel | None:
    """Return the ForumTrustLevel config for the user's current level."""
    profile = ForumUserProfile.objects.filter(user=user).first()
    level = profile.trust_level if profile else TrustLevelChoices.NEW_USER
    return ForumTrustLevel.objects.filter(level=level).first()


def _check_daily_topic_limit(user: AbstractBaseUser) -> None:
    """Raise ForumPermissionError if user has exceeded daily topic limit."""
    trust_cfg = _get_user_trust_config(user)
    if not trust_cfg:
        return  # No trust levels configured — allow all
    today = timezone.now().date()
    today_count = ForumTopic.objects.filter(user=user, created_at__date=today).count()
    if today_count >= trust_cfg.max_daily_topics:
        raise ForumPermissionError(
            f"Daily topic limit reached ({trust_cfg.max_daily_topics}). "
            "Try again tomorrow or increase your trust level."
        )


def _check_daily_reply_limit(user: AbstractBaseUser) -> None:
    """Raise ForumPermissionError if user has exceeded daily reply limit."""
    trust_cfg = _get_user_trust_config(user)
    if not trust_cfg:
        return
    today = timezone.now().date()
    today_count = ForumReply.objects.filter(user=user, created_at__date=today).count()
    if today_count >= trust_cfg.max_daily_replies:
        raise ForumPermissionError(
            f"Daily reply limit reached ({trust_cfg.max_daily_replies}). "
            "Try again tomorrow or increase your trust level."
        )


def _check_poll_permission(user: AbstractBaseUser) -> None:
    """Raise ForumPermissionError if user's trust level forbids poll creation."""
    trust_cfg = _get_user_trust_config(user)
    if trust_cfg and not trust_cfg.can_create_polls:
        raise ForumPermissionError("Your trust level does not allow creating polls.")


def _check_attachment_permission(user: AbstractBaseUser) -> None:
    """Raise ForumPermissionError if user's trust level forbids uploading attachments."""
    trust_cfg = _get_user_trust_config(user)
    if trust_cfg and not trust_cfg.can_upload_attachments:
        raise ForumPermissionError(
            "Your trust level does not allow uploading attachments."
        )


def _check_banned(user: AbstractBaseUser) -> None:
    """Raise ForumPermissionError if user is forum-banned."""
    profile = ForumUserProfile.objects.filter(user=user).first()
    if profile and profile.is_currently_banned:
        raise ForumPermissionError("You are currently banned from the forum.")


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
    _check_banned(user)
    _check_daily_topic_limit(user)
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
    _check_banned(user)
    _check_daily_reply_limit(user)
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
# Forum User Profile helpers
# ---------------------------------------------------------------------------


def get_or_create_forum_profile(user: AbstractBaseUser) -> ForumUserProfile:
    profile, _ = ForumUserProfile.objects.get_or_create(user=user)
    return profile


def update_online_presence(user: AbstractBaseUser, location: str = "") -> None:
    ForumOnlineUser.objects.update_or_create(user=user, defaults={"location": location})


def get_online_users(minutes: int = 15) -> QuerySet[ForumOnlineUser]:
    from datetime import timedelta

    threshold = timezone.now() - timedelta(minutes=minutes)
    return ForumOnlineUser.objects.filter(last_seen__gte=threshold).select_related(
        "user"
    )


# ---------------------------------------------------------------------------
# Trust Level system (Discourse-style auto-promotion)
# ---------------------------------------------------------------------------


def evaluate_trust_level(user: AbstractBaseUser) -> int:
    """Evaluate what trust level a user qualifies for based on their activity."""
    profile = get_or_create_forum_profile(user)
    levels = ForumTrustLevel.objects.order_by("-level")

    for level_def in levels:
        if (
            profile.topic_count >= level_def.min_topics_created
            and profile.reply_count >= level_def.min_replies_posted
            and profile.likes_received >= level_def.min_likes_received
            and profile.likes_given >= level_def.min_likes_given
            and profile.days_visited >= level_def.min_days_visited
            and profile.topics_read >= level_def.min_topics_read
        ):
            return level_def.level

    return TrustLevelChoices.NEW_USER


def auto_promote_user(user: AbstractBaseUser) -> bool:
    """Check and promote user trust level if they qualify. Returns True if promoted."""
    new_level = evaluate_trust_level(user)
    profile = get_or_create_forum_profile(user)
    if new_level > profile.trust_level:
        profile.trust_level = new_level
        profile.save(update_fields=["trust_level", "updated_at"])
        _publish_event(
            "forum.trust_level_changed",
            {"user_id": user.pk, "new_level": new_level},
        )
        return True
    return False


def check_trust_permission(user: AbstractBaseUser, permission: str) -> bool:
    """Check if user's trust level grants a specific permission."""
    profile = get_or_create_forum_profile(user)
    level_def = ForumTrustLevel.objects.filter(level=profile.trust_level).first()
    if not level_def:
        return False
    return bool(getattr(level_def, permission, False))


# ---------------------------------------------------------------------------
# Reactions (XenForo-style)
# ---------------------------------------------------------------------------


@transaction.atomic
def set_reaction(
    reply: ForumReply, user: AbstractBaseUser, reaction: ForumReaction
) -> ForumReplyReaction:
    """Set or change user's reaction on a reply. Only one reaction per user per reply."""
    existing = ForumReplyReaction.objects.filter(reply=reply, user=user).first()
    if existing:
        old_reaction = existing.reaction
        existing.reaction = reaction
        existing.save(update_fields=["reaction"])
        # Adjust reputation: remove old, add new
        if old_reaction.pk != reaction.pk:
            _adjust_reputation(reply.user, -old_reaction.score)  # type: ignore[arg-type]
            _adjust_reputation(reply.user, reaction.score)  # type: ignore[arg-type]
        return existing

    new_reaction = ForumReplyReaction.objects.create(
        reply=reply, user=user, reaction=reaction
    )
    ForumReply.objects.filter(pk=reply.pk).update(
        reaction_count=F("reaction_count") + 1
    )
    _adjust_reputation(reply.user, reaction.score)  # type: ignore[arg-type]
    return new_reaction


@transaction.atomic
def remove_reaction(reply: ForumReply, user: AbstractBaseUser) -> bool:
    """Remove user's reaction from a reply. Returns True if removed."""
    existing = ForumReplyReaction.objects.filter(reply=reply, user=user).first()
    if not existing:
        return False
    _adjust_reputation(reply.user, -existing.reaction.score)  # type: ignore[arg-type]
    existing.delete()
    ForumReply.objects.filter(pk=reply.pk).update(
        reaction_count=models.F("reaction_count") - 1
    )
    return True


def _adjust_reputation(user: AbstractBaseUser, amount: int) -> None:
    if amount == 0:
        return
    ForumUserProfile.objects.filter(user=user).update(
        reputation=F("reputation") + amount
    )


# ---------------------------------------------------------------------------
# Best Answer / Solution
# ---------------------------------------------------------------------------


@transaction.atomic
def mark_best_answer(
    topic: ForumTopic,
    reply: ForumReply,
    marked_by: AbstractBaseUser,
) -> ForumBestAnswer:
    """Mark a reply as the best answer for a topic."""
    # Remove existing if any
    ForumBestAnswer.objects.filter(topic=topic).delete()
    best = ForumBestAnswer.objects.create(topic=topic, reply=reply, marked_by=marked_by)
    ForumTopic.objects.filter(pk=topic.pk).update(has_solution=True)
    # Award reputation and stats
    ForumUserProfile.objects.filter(user=reply.user).update(
        solutions_count=F("solutions_count") + 1,
        reputation=F("reputation") + 15,
    )
    _publish_event(
        "forum.solution_marked",
        {"topic_id": topic.pk, "reply_id": reply.pk, "user_id": reply.user_id},  # type: ignore[attr-defined]
    )
    return best


@transaction.atomic
def unmark_best_answer(topic: ForumTopic) -> None:
    """Remove best answer status from a topic."""
    best = ForumBestAnswer.objects.filter(topic=topic).select_related("reply").first()
    if best:
        ForumUserProfile.objects.filter(user=best.reply.user).update(
            solutions_count=models.F("solutions_count") - 1,
            reputation=models.F("reputation") - 15,
        )
        best.delete()
    ForumTopic.objects.filter(pk=topic.pk).update(has_solution=False)


# ---------------------------------------------------------------------------
# Topic Rating (vBulletin star rating)
# ---------------------------------------------------------------------------


@transaction.atomic
def rate_topic(
    topic: ForumTopic, user: AbstractBaseUser, score: int
) -> ForumTopicRating:
    """Rate a topic 1-5 stars. Updates or creates rating."""
    score = max(1, min(5, score))
    rating, created = ForumTopicRating.objects.update_or_create(
        topic=topic,
        user=user,
        defaults={"score": score},
    )
    # Recalculate average
    from django.db.models import Avg, Count

    agg = ForumTopicRating.objects.filter(topic=topic).aggregate(
        avg=Avg("score"), cnt=Count("id")
    )
    ForumTopic.objects.filter(pk=topic.pk).update(
        rating_score=agg["avg"] or 0.0,
        rating_count=agg["cnt"] or 0,
    )
    return rating


# ---------------------------------------------------------------------------
# Topic Tags
# ---------------------------------------------------------------------------


def set_topic_tags(topic: ForumTopic, tag_names: list[str]) -> list[ForumTopicTag]:
    """Replace all tags on a topic with the given list."""
    ForumTopicTag.objects.filter(topic=topic).delete()
    tags = []
    for name in tag_names[:10]:  # Limit to 10 tags
        name = name.strip()
        if name:
            tag = ForumTopicTag(topic=topic, name=name)
            tag.save()
            tags.append(tag)
    return tags


# ---------------------------------------------------------------------------
# Warning System
# ---------------------------------------------------------------------------


@transaction.atomic
def issue_warning(
    *,
    user: AbstractBaseUser,
    issued_by: AbstractBaseUser,
    reason: str,
    severity: str = "minor",
    points: int = 1,
    topic: ForumTopic | None = None,
    reply: ForumReply | None = None,
    expires_at: object = None,
) -> ForumWarning:
    warning = ForumWarning.objects.create(
        user=user,
        issued_by=issued_by,
        topic=topic,
        reply=reply,
        severity=severity,
        reason=reason,
        points=points,
        expires_at=expires_at,
    )
    ForumUserProfile.objects.filter(user=user).update(
        warning_level=F("warning_level") + points
    )
    _publish_event(
        "forum.warning_issued",
        {
            "user_id": user.pk,
            "issued_by_id": issued_by.pk,
            "severity": severity,
            "warning_id": warning.pk,
        },
    )
    return warning


def get_active_warnings(user: AbstractBaseUser) -> QuerySet[ForumWarning]:
    return ForumWarning.objects.filter(
        user=user,
    ).filter(
        models.Q(expires_at__isnull=True) | models.Q(expires_at__gt=timezone.now())
    )


# ---------------------------------------------------------------------------
# IP Bans
# ---------------------------------------------------------------------------


def ban_ip(
    *,
    ip_address: str,
    banned_by: AbstractBaseUser,
    reason: str = "",
    expires_at: object = None,
) -> ForumIPBan:
    ban, _ = ForumIPBan.objects.update_or_create(
        ip_address=ip_address,
        defaults={
            "banned_by": banned_by,
            "reason": reason,
            "expires_at": expires_at,
            "is_active": True,
        },
    )
    return ban


def unban_ip(ip_address: str) -> None:
    ForumIPBan.objects.filter(ip_address=ip_address).update(is_active=False)


def is_ip_banned(ip_address: str) -> bool:
    return (
        ForumIPBan.objects.filter(
            ip_address=ip_address,
            is_active=True,
        )
        .filter(
            models.Q(expires_at__isnull=True) | models.Q(expires_at__gt=timezone.now())
        )
        .exists()
    )


# ---------------------------------------------------------------------------
# User Bans
# ---------------------------------------------------------------------------


@transaction.atomic
def ban_user(
    user: AbstractBaseUser,
    *,
    reason: str = "",
    expires_at: object = None,
) -> None:
    profile = get_or_create_forum_profile(user)
    profile.is_banned = True
    profile.ban_reason = reason
    profile.ban_expires_at = expires_at  # type: ignore[assignment]
    profile.save(
        update_fields=["is_banned", "ban_reason", "ban_expires_at", "updated_at"]
    )


def unban_user(user: AbstractBaseUser) -> None:
    ForumUserProfile.objects.filter(user=user).update(
        is_banned=False, ban_reason="", ban_expires_at=None
    )


def is_user_banned(user: AbstractBaseUser) -> bool:
    profile = ForumUserProfile.objects.filter(user=user).first()
    if not profile:
        return False
    return profile.is_currently_banned


# ---------------------------------------------------------------------------
# Category Subscriptions (XenForo "Watch Forum")
# ---------------------------------------------------------------------------


def subscribe_category(
    category: ForumCategory,
    user: AbstractBaseUser,
    notify_topics: bool = True,
    notify_replies: bool = False,
) -> ForumCategorySubscription:
    sub, _ = ForumCategorySubscription.objects.update_or_create(
        category=category,
        user=user,
        defaults={
            "notify_new_topics": notify_topics,
            "notify_new_replies": notify_replies,
        },
    )
    return sub


def unsubscribe_category(category: ForumCategory, user: AbstractBaseUser) -> None:
    ForumCategorySubscription.objects.filter(category=category, user=user).delete()


# ---------------------------------------------------------------------------
# Topic Move (moderation)
# ---------------------------------------------------------------------------


@transaction.atomic
def move_topic(
    topic: ForumTopic,
    *,
    to_category: ForumCategory,
    moved_by: AbstractBaseUser,
    reason: str = "",
) -> ForumTopicMoveLog:
    old_category = topic.category
    ForumTopicMoveLog.objects.create(
        topic=topic,
        from_category=old_category,
        to_category=to_category,
        moved_by=moved_by,
        reason=reason,
    )
    topic.category = to_category
    topic.save(update_fields=["category", "updated_at"])
    # Recount both categories
    recount_category(old_category)
    recount_category(to_category)
    # Add system reply
    ForumReply.objects.create(
        topic=topic,
        user=moved_by,
        content="",
        content_html="",
        action=TopicAction.MOVED,
    )
    return ForumTopicMoveLog.objects.filter(topic=topic).latest("created_at")


# ---------------------------------------------------------------------------
# Topic Merge (moderation)
# ---------------------------------------------------------------------------


@transaction.atomic
def merge_topics(
    source: ForumTopic,
    target: ForumTopic,
    *,
    merged_by: AbstractBaseUser,
) -> ForumTopicMergeLog:
    """Merge source topic into target — moves all replies, then soft-deletes source."""
    reply_count = ForumReply.objects.filter(topic=source, is_removed=False).update(
        topic=target
    )
    ForumTopicMergeLog.objects.create(
        source_topic_title=source.title,
        target_topic=target,
        merged_by=merged_by,
        replies_moved=reply_count,
    )
    # Soft-delete source
    source.is_removed = True
    source.save(update_fields=["is_removed", "updated_at"])
    # Recount target
    target.reply_count = ForumReply.objects.filter(
        topic=target, is_removed=False
    ).count()
    target.save(update_fields=["reply_count", "updated_at"])
    recount_category(target.category)
    if source.category_id != target.category_id:  # type: ignore[attr-defined]
        recount_category(source.category)
    return ForumTopicMergeLog.objects.filter(target_topic=target).latest("created_at")


# ---------------------------------------------------------------------------
# Similar Topics
# ---------------------------------------------------------------------------


def find_similar_topics(topic: ForumTopic, limit: int = 5) -> QuerySet[ForumTopic]:
    """Find topics with similar titles in the same or related categories."""
    words = [w for w in topic.title.split() if len(w) > 3]
    if not words:
        return ForumTopic.objects.none()
    q = models.Q()
    for word in words[:5]:
        q |= models.Q(title__icontains=word)
    return (
        ForumTopic.objects.filter(q, is_removed=False)
        .exclude(pk=topic.pk)
        .select_related("category", "user")
        .order_by("-reply_count")[:limit]
    )


# ---------------------------------------------------------------------------
# Increment profile stats
# ---------------------------------------------------------------------------


def increment_profile_stat(user: AbstractBaseUser, field: str, amount: int = 1) -> None:
    """Increment a denormalized stat on the user's forum profile."""
    profile, _ = ForumUserProfile.objects.get_or_create(user=user)
    ForumUserProfile.objects.filter(pk=profile.pk).update(**{field: F(field) + amount})


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


# ---------------------------------------------------------------------------
# 4PDA — Wiki Header (шапка) operations
# ---------------------------------------------------------------------------


@transaction.atomic
def update_wiki_header(
    topic: ForumTopic, *, user: AbstractBaseUser, content: str
) -> None:
    """Update the wiki-style header post. Saves history of previous version."""
    if topic.wiki_header:
        ForumWikiHeaderHistory.objects.create(
            topic=topic,
            content=topic.wiki_header,
            content_html=topic.wiki_header_html,
            edited_by=user,
        )
    topic.wiki_header = content
    topic.wiki_header_html = render_markdown(content)
    topic.wiki_header_updated_at = timezone.now()
    topic.wiki_header_updated_by = user  # type: ignore[assignment]
    topic.save(
        update_fields=[
            "wiki_header",
            "wiki_header_html",
            "wiki_header_updated_at",
            "wiki_header_updated_by",
            "updated_at",
        ]
    )


# ---------------------------------------------------------------------------
# 4PDA — Useful post toggle
# ---------------------------------------------------------------------------


@transaction.atomic
def toggle_useful_post(reply: ForumReply, user: AbstractBaseUser) -> bool:
    """Toggle 'useful' mark on a reply. Returns True if marked, False if unmarked."""
    deleted, _ = ForumUsefulPost.objects.filter(reply=reply, user=user).delete()
    if deleted:
        return False
    ForumUsefulPost.objects.create(reply=reply, user=user)
    _adjust_reputation(reply.user, 2)  # type: ignore[arg-type]
    return True


def get_useful_count(reply: ForumReply) -> int:
    return ForumUsefulPost.objects.filter(reply=reply).count()


# ---------------------------------------------------------------------------
# 4PDA — FAQ entries
# ---------------------------------------------------------------------------


def add_faq_entry(
    topic: ForumTopic,
    reply: ForumReply,
    question: str,
    sort_order: int = 0,
) -> ForumFAQEntry:
    return ForumFAQEntry.objects.create(
        topic=topic, reply=reply, question=question, sort_order=sort_order
    )


def remove_faq_entry(faq_id: int) -> None:
    ForumFAQEntry.objects.filter(pk=faq_id).delete()


def get_faq_entries(topic: ForumTopic) -> QuerySet[ForumFAQEntry]:
    return ForumFAQEntry.objects.filter(topic=topic).select_related(
        "reply", "reply__user"
    )


# ---------------------------------------------------------------------------
# 4PDA — Changelog entries
# ---------------------------------------------------------------------------


def add_changelog_entry(
    topic: ForumTopic,
    *,
    user: AbstractBaseUser,
    version: str,
    changes: str,
    released_at: object = None,
) -> ForumChangelog:
    return ForumChangelog.objects.create(
        topic=topic,
        version=version,
        changes=changes,
        changes_html=render_markdown(changes),
        released_at=released_at,
        added_by=user,
    )


def get_changelog(topic: ForumTopic) -> QuerySet[ForumChangelog]:
    return ForumChangelog.objects.filter(topic=topic)


def remove_changelog_entry(entry_id: int) -> None:
    ForumChangelog.objects.filter(pk=entry_id).delete()


# ---------------------------------------------------------------------------
# 4PDA — Attachment download counter
# ---------------------------------------------------------------------------


def increment_download_count(attachment: ForumAttachment) -> None:
    ForumAttachment.objects.filter(pk=attachment.pk).update(
        download_count=F("download_count") + 1
    )


# ---------------------------------------------------------------------------
# Forum landing-page helpers
# ---------------------------------------------------------------------------


def get_forum_stats() -> dict[str, int]:
    """Aggregate stats for the forum landing-page header."""
    from django.contrib.auth import get_user_model

    _User = get_user_model()
    return {
        "total_topics": ForumTopic.objects.filter(is_removed=False).count(),
        "total_replies": ForumReply.objects.filter(is_removed=False).count(),
        "total_members": _User.objects.filter(is_active=True).count(),
        "online_count": get_online_users().count(),
    }


def get_trending_topics(limit: int = 5) -> QuerySet[ForumTopic]:
    """Topics with most activity in the last 7 days."""
    from datetime import timedelta as _td

    cutoff = timezone.now() - _td(days=7)
    return (
        ForumTopic.objects.filter(is_removed=False, last_active__gte=cutoff)
        .select_related("category", "user", "last_reply_user")
        .order_by("-reply_count", "-view_count")[:limit]
    )


def get_recent_topics(limit: int = 10) -> QuerySet[ForumTopic]:
    """Most recently active topics for the activity feed."""
    return (
        ForumTopic.objects.filter(is_removed=False)
        .select_related("category", "user", "last_reply_user")
        .order_by("-last_active")[:limit]
    )


def get_latest_replies(limit: int = 5) -> QuerySet[ForumReply]:
    """Latest replies across all topics."""
    return (
        ForumReply.objects.filter(is_removed=False)
        .select_related("topic", "topic__category", "user")
        .order_by("-created_at")[:limit]
    )
