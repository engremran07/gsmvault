from __future__ import annotations

from django.conf import settings
from django.db import models
from django.db.models import QuerySet
from django.utils import timezone
from django.utils.text import slugify

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------


class TopicAction(models.IntegerChoices):
    COMMENT = 0, "Comment"
    MOVED = 1, "Moved"
    CLOSED = 2, "Closed"
    UNCLOSED = 3, "Unclosed"
    PINNED = 4, "Pinned"
    UNPINNED = 5, "Unpinned"


class NotifyFrequency(models.TextChoices):
    NEVER = "never", "Never"
    IMMEDIATELY = "immediately", "Immediately"
    WEEKLY = "weekly", "Weekly digest"


class PollMode(models.TextChoices):
    SINGLE = "single", "Single choice"
    MULTIPLE = "multiple", "Multiple choice"


# ---------------------------------------------------------------------------
# QuerySet managers
# ---------------------------------------------------------------------------


class CategoryQuerySet(QuerySet["ForumCategory"]):
    def visible(self) -> CategoryQuerySet:
        return self.filter(is_removed=False, is_visible=True)

    def public(self) -> CategoryQuerySet:
        return self.visible().filter(is_private=False)

    def root(self) -> CategoryQuerySet:
        return self.filter(parent__isnull=True)


class TopicQuerySet(QuerySet["ForumTopic"]):
    def visible(self) -> TopicQuerySet:
        return self.filter(is_removed=False)

    def public(self) -> TopicQuerySet:
        return self.visible().filter(category__is_private=False)

    def pinned_first(self) -> TopicQuerySet:
        return self.order_by("-is_globally_pinned", "-is_pinned", "-last_active")


class ReplyQuerySet(QuerySet["ForumReply"]):
    def visible(self) -> ReplyQuerySet:
        return self.filter(is_removed=False)


# ---------------------------------------------------------------------------
# Category
# ---------------------------------------------------------------------------


class ForumCategory(models.Model):
    parent = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="children",
    )
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=280, unique=True)
    description = models.TextField(blank=True, default="")
    color = models.CharField(
        max_length=7, blank=True, default="#6366f1", help_text="Hex colour"
    )
    icon = models.CharField(
        max_length=64,
        blank=True,
        default="message-circle",
        help_text="Lucide icon name",
    )
    sort_order = models.PositiveIntegerField(default=0)
    is_closed = models.BooleanField(default=False, help_text="No new topics allowed")
    is_visible = models.BooleanField(default=True)
    is_removed = models.BooleanField(default=False)
    is_private = models.BooleanField(
        default=False, help_text="Only invited users can see"
    )

    # Denormalised counts
    topic_count = models.PositiveIntegerField(default=0)
    reply_count = models.PositiveIntegerField(default=0)
    last_active = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = CategoryQuerySet.as_manager()

    class Meta:
        ordering = ["sort_order", "title"]
        verbose_name = "Forum Category"
        verbose_name_plural = "Forum Categories"
        db_table = "forum_forumcategory"

    def __str__(self) -> str:
        return self.title

    def save(self, *args: object, **kwargs: object) -> None:
        if not self.slug:
            self.slug = slugify(self.title)
        super().save(*args, **kwargs)


# ---------------------------------------------------------------------------
# Topic
# ---------------------------------------------------------------------------


class ForumTopic(models.Model):
    category = models.ForeignKey(
        ForumCategory,
        on_delete=models.CASCADE,
        related_name="topics",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_topics",
    )
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=280, blank=True)
    content = models.TextField(help_text="Markdown source")
    content_html = models.TextField(
        blank=True, default="", help_text="Rendered & sanitized HTML"
    )

    # Flags
    is_pinned = models.BooleanField(default=False)
    is_globally_pinned = models.BooleanField(default=False)
    is_closed = models.BooleanField(default=False)
    is_removed = models.BooleanField(default=False)

    # Denormalised stats
    view_count = models.PositiveIntegerField(default=0)
    reply_count = models.PositiveIntegerField(default=0)
    last_active = models.DateTimeField(auto_now_add=True)
    last_reply_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="forum_last_replies",
    )

    # FTS
    search_vector = models.TextField(
        blank=True, default="", help_text="Populated for PostgreSQL full-text search"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = TopicQuerySet.as_manager()

    class Meta:
        ordering = ["-last_active"]
        verbose_name = "Forum Topic"
        verbose_name_plural = "Forum Topics"
        db_table = "forum_forumtopic"
        indexes = [
            models.Index(
                fields=["category", "-last_active"], name="forum_topic_cat_active"
            ),
            models.Index(
                fields=["user", "-created_at"], name="forum_topic_user_created"
            ),
            models.Index(
                fields=["-is_globally_pinned", "-is_pinned", "-last_active"],
                name="forum_topic_pin_order",
            ),
        ]

    def __str__(self) -> str:
        return self.title

    def save(self, *args: object, **kwargs: object) -> None:
        if not self.slug:
            self.slug = slugify(self.title)[:280]
        super().save(*args, **kwargs)


# ---------------------------------------------------------------------------
# Reply (Comment in Spirit terminology)
# ---------------------------------------------------------------------------


class ForumReply(models.Model):
    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="replies",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_replies",
    )
    content = models.TextField(help_text="Markdown source")
    content_html = models.TextField(
        blank=True, default="", help_text="Rendered & sanitized HTML"
    )
    action = models.IntegerField(
        choices=TopicAction.choices,
        default=TopicAction.COMMENT,
    )

    # Edit tracking
    is_removed = models.BooleanField(default=False)
    is_modified = models.BooleanField(default=False)
    modified_count = models.PositiveIntegerField(default=0)

    # Denormalised
    likes_count = models.PositiveIntegerField(default=0)

    ip_address = models.GenericIPAddressField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = ReplyQuerySet.as_manager()

    class Meta:
        ordering = ["created_at"]
        verbose_name = "Forum Reply"
        verbose_name_plural = "Forum Replies"
        db_table = "forum_forumreply"
        indexes = [
            models.Index(fields=["topic", "created_at"], name="forum_reply_topic_date"),
        ]

    def __str__(self) -> str:
        return f"Reply by {self.user_id} on topic {self.topic_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Bookmark / Waypoint (read position tracking)
# ---------------------------------------------------------------------------


class ForumBookmark(models.Model):
    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="bookmarks",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_bookmarks",
    )
    reply_number = models.PositiveIntegerField(
        default=0, help_text="Last-read reply position"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [("topic", "user")]
        verbose_name = "Forum Bookmark"
        verbose_name_plural = "Forum Bookmarks"
        db_table = "forum_forumbookmark"

    def __str__(self) -> str:
        return f"Bookmark: user {self.user_id} at reply #{self.reply_number}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Like (on replies)
# ---------------------------------------------------------------------------


class ForumLike(models.Model):
    reply = models.ForeignKey(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="likes",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_likes",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("reply", "user")]
        verbose_name = "Forum Like"
        verbose_name_plural = "Forum Likes"
        db_table = "forum_forumlike"

    def __str__(self) -> str:
        return f"Like by {self.user_id} on reply {self.reply_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Favourite (on topics)
# ---------------------------------------------------------------------------


class ForumTopicFavorite(models.Model):
    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="favorites",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_favorites",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("topic", "user")]
        verbose_name = "Forum Favorite"
        verbose_name_plural = "Forum Favorites"
        db_table = "forum_forumtopicfavorite"

    def __str__(self) -> str:
        return f"Favorite by {self.user_id} on topic {self.topic_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Poll system (multi-poll, secret ballot, auto-close)
# ---------------------------------------------------------------------------


class ForumPoll(models.Model):
    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="polls",
    )
    title = models.CharField(max_length=255, help_text="Poll question")
    mode = models.CharField(
        max_length=10, choices=PollMode.choices, default=PollMode.SINGLE
    )
    is_secret = models.BooleanField(default=False, help_text="Hide who voted")
    close_at = models.DateTimeField(
        null=True, blank=True, help_text="Auto-close datetime"
    )
    is_closed = models.BooleanField(default=False)
    vote_count = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        verbose_name = "Forum Poll"
        verbose_name_plural = "Forum Polls"
        db_table = "forum_forumpoll"

    def __str__(self) -> str:
        return self.title

    @property
    def is_open(self) -> bool:
        if self.is_closed:
            return False
        if self.close_at and timezone.now() >= self.close_at:
            return False
        return True


class ForumPollChoice(models.Model):
    poll = models.ForeignKey(
        ForumPoll,
        on_delete=models.CASCADE,
        related_name="choices",
    )
    description = models.CharField(max_length=255)
    vote_count = models.PositiveIntegerField(default=0)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order"]
        verbose_name = "Forum Poll Choice"
        verbose_name_plural = "Forum Poll Choices"
        db_table = "forum_forumpollchoice"

    def __str__(self) -> str:
        return self.description


class ForumPollVote(models.Model):
    poll = models.ForeignKey(
        ForumPoll,
        on_delete=models.CASCADE,
        related_name="votes",
    )
    choice = models.ForeignKey(
        ForumPollChoice,
        on_delete=models.CASCADE,
        related_name="votes",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_poll_votes",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Forum Poll Vote"
        verbose_name_plural = "Forum Poll Votes"
        db_table = "forum_forumpollvote"
        constraints = [
            models.UniqueConstraint(
                fields=["poll", "choice", "user"],
                name="forum_poll_vote_unique",
            ),
        ]

    def __str__(self) -> str:
        return f"Vote by {self.user_id} on {self.choice_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Private topics (PM system)
# ---------------------------------------------------------------------------


class ForumPrivateTopic(models.Model):
    """A private conversation visible only to invited users."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_private_topics_created",
    )
    topic = models.OneToOneField(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="private_info",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Forum Private Topic"
        verbose_name_plural = "Forum Private Topics"
        db_table = "forum_forumprivatetopic"

    def __str__(self) -> str:
        return f"Private: {self.topic}"


class ForumPrivateTopicUser(models.Model):
    """Membership relation: which users are invited to a private topic."""

    private_topic = models.ForeignKey(
        ForumPrivateTopic,
        on_delete=models.CASCADE,
        related_name="participants",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_private_memberships",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("private_topic", "user")]
        verbose_name = "Forum Private Topic Participant"
        verbose_name_plural = "Forum Private Topic Participants"
        db_table = "forum_forumprivatetopicuser"

    def __str__(self) -> str:
        return f"User {self.user_id} in private topic {self.private_topic_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Edit History
# ---------------------------------------------------------------------------


class ForumReplyHistory(models.Model):
    reply = models.ForeignKey(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="history",
    )
    content = models.TextField(help_text="Markdown content before edit")
    content_html = models.TextField(help_text="Rendered HTML before edit")
    edited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_reply_edits",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Forum Reply History"
        verbose_name_plural = "Forum Reply Histories"
        db_table = "forum_forumreplyhistory"

    def __str__(self) -> str:
        return f"History for reply {self.reply_id} at {self.created_at}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# @Mentions
# ---------------------------------------------------------------------------


class ForumMention(models.Model):
    reply = models.ForeignKey(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="mentions",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_mentions_received",
        help_text="The mentioned user",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("reply", "user")]
        verbose_name = "Forum Mention"
        verbose_name_plural = "Forum Mentions"
        db_table = "forum_forummention"

    def __str__(self) -> str:
        return f"@{self.user_id} in reply {self.reply_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Topic Subscription (notification preferences per topic)
# ---------------------------------------------------------------------------


class ForumTopicSubscription(models.Model):
    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="subscriptions",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_subscriptions",
    )
    frequency = models.CharField(
        max_length=15,
        choices=NotifyFrequency.choices,
        default=NotifyFrequency.IMMEDIATELY,
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("topic", "user")]
        verbose_name = "Forum Topic Subscription"
        verbose_name_plural = "Forum Topic Subscriptions"
        db_table = "forum_forumtopicsubscription"

    def __str__(self) -> str:
        return f"Sub: {self.user_id} \u2192 topic {self.topic_id} ({self.frequency})"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# File/Image Attachments
# ---------------------------------------------------------------------------


class ForumAttachment(models.Model):
    reply = models.ForeignKey(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="attachments",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_attachments",
    )
    file = models.FileField(upload_to="forum/attachments/%Y/%m/")
    filename = models.CharField(max_length=255)
    content_type = models.CharField(max_length=100, blank=True, default="")
    file_size = models.PositiveIntegerField(default=0, help_text="Bytes")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        verbose_name = "Forum Attachment"
        verbose_name_plural = "Forum Attachments"
        db_table = "forum_forumattachment"

    def __str__(self) -> str:
        return self.filename


# ---------------------------------------------------------------------------
# Flag / Report (for moderation queue)
# ---------------------------------------------------------------------------


class ForumFlag(models.Model):
    class Reason(models.TextChoices):
        SPAM = "spam", "Spam"
        OFFENSIVE = "offensive", "Offensive or abusive"
        OFF_TOPIC = "off_topic", "Off-topic"
        OTHER = "other", "Other"

    # GenericFK-style: can flag topics or replies
    topic = models.ForeignKey(
        ForumTopic,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="flags",
    )
    reply = models.ForeignKey(
        ForumReply,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="flags",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_flags",
    )
    reason = models.CharField(
        max_length=20, choices=Reason.choices, default=Reason.SPAM
    )
    detail = models.TextField(blank=True, default="")
    is_resolved = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Forum Flag"
        verbose_name_plural = "Forum Flags"
        db_table = "forum_forumflag"

    def __str__(self) -> str:
        target = f"topic {self.topic_id}" if self.topic_id else f"reply {self.reply_id}"  # type: ignore[attr-defined]
        return f"Flag on {target} by {self.user_id}"  # type: ignore[attr-defined]
