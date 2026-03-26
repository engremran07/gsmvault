from __future__ import annotations

from datetime import timedelta

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


class TopicType(models.TextChoices):
    """4PDA-style topic type classification."""

    DISCUSSION = "discussion", "Discussion"
    FIRMWARE = "firmware", "Firmware"
    FAQ = "faq", "FAQ"
    GUIDE = "guide", "Guide"
    NEWS = "news", "News"
    REVIEW = "review", "Review"
    BUG_REPORT = "bug_report", "Bug Report"


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

    # Optional device-scope links (naming convention: title = marketing name only)
    brand_link = models.ForeignKey(
        "firmwares.Brand",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="forum_categories",
        help_text="Link to firmware brand — category title should be brand marketing name only (e.g. 'Samsung', not 'Samsung Firmware')",
    )
    model_link = models.ForeignKey(
        "firmwares.Model",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="forum_model_categories",
        help_text="Link to firmware model — category title should be model marketing name only (e.g. 'Galaxy S24 Ultra')",
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

    # Thread prefix (vBulletin-style)
    prefix = models.ForeignKey(
        "ForumTopicPrefix",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="topics",
    )

    # 4PDA-style topic type
    topic_type = models.CharField(
        max_length=20,
        choices=TopicType.choices,
        default=TopicType.DISCUSSION,
        help_text="4PDA-style topic classification",
    )

    # 4PDA wiki-style header post (шапка)
    wiki_header = models.TextField(
        blank=True, default="", help_text="Wiki-style editable header (Markdown)"
    )
    wiki_header_html = models.TextField(
        blank=True, default="", help_text="Rendered wiki header HTML"
    )
    wiki_header_updated_at = models.DateTimeField(null=True, blank=True)
    wiki_header_updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="forum_wiki_edits",
    )

    # 4PDA device linking
    linked_device = models.ForeignKey(
        "firmwares.Model",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="forum_topics",
        help_text="4PDA-style device link for this topic",
    )

    # Flags
    is_pinned = models.BooleanField(default=False)
    is_globally_pinned = models.BooleanField(default=False)
    is_closed = models.BooleanField(default=False)
    is_removed = models.BooleanField(default=False)
    has_solution = models.BooleanField(
        default=False, help_text="Has an accepted best answer"
    )

    # Denormalised stats
    view_count = models.PositiveIntegerField(default=0)
    reply_count = models.PositiveIntegerField(default=0)
    rating_score = models.FloatField(default=0.0, help_text="Average star rating")
    rating_count = models.PositiveIntegerField(default=0)
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
    reaction_count = models.PositiveIntegerField(
        default=0, help_text="Total reactions (all types)"
    )

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
    download_count = models.PositiveIntegerField(
        default=0, help_text="4PDA-style download counter"
    )

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


# ---------------------------------------------------------------------------
# Trust Levels (Discourse-inspired auto-promotion system)
# ---------------------------------------------------------------------------


class TrustLevelChoices(models.IntegerChoices):
    NEW_USER = 0, "New User"
    BASIC = 1, "Basic"
    MEMBER = 2, "Member"
    REGULAR = 3, "Regular"
    LEADER = 4, "Leader"


class ForumTrustLevel(models.Model):
    """Defines thresholds for automatic trust-level promotion."""

    level = models.IntegerField(
        choices=TrustLevelChoices.choices,
        unique=True,
    )
    title = models.CharField(max_length=50, help_text="Display title for this level")
    color = models.CharField(max_length=7, default="#6366f1", help_text="Badge colour")
    min_topics_created = models.PositiveIntegerField(default=0)
    min_replies_posted = models.PositiveIntegerField(default=0)
    min_likes_received = models.PositiveIntegerField(default=0)
    min_likes_given = models.PositiveIntegerField(default=0)
    min_days_visited = models.PositiveIntegerField(default=0)
    min_topics_read = models.PositiveIntegerField(default=0)
    can_flag = models.BooleanField(default=False)
    can_create_polls = models.BooleanField(default=False)
    can_upload_attachments = models.BooleanField(default=False)
    can_send_private_messages = models.BooleanField(default=False)
    can_edit_own_posts = models.BooleanField(default=True)
    max_daily_topics = models.PositiveIntegerField(default=5)
    max_daily_replies = models.PositiveIntegerField(default=20)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["level"]
        verbose_name = "Forum Trust Level"
        verbose_name_plural = "Forum Trust Levels"
        db_table = "forum_forumtrustlevel"

    def __str__(self) -> str:
        return f"Level {self.level}: {self.title}"


# ---------------------------------------------------------------------------
# Forum User Profile (per-user forum stats, signature, rank)
# ---------------------------------------------------------------------------


class ForumUserProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_profile",
    )
    trust_level = models.IntegerField(
        choices=TrustLevelChoices.choices,
        default=TrustLevelChoices.NEW_USER,
    )
    custom_title = models.CharField(
        max_length=100, blank=True, default="", help_text="Custom rank title"
    )
    signature = models.TextField(
        blank=True, default="", help_text="Post signature (Markdown)"
    )
    signature_html = models.TextField(blank=True, default="")
    website = models.URLField(blank=True, default="")
    location = models.CharField(max_length=100, blank=True, default="")

    # Denormalized stats
    topic_count = models.PositiveIntegerField(default=0)
    reply_count = models.PositiveIntegerField(default=0)
    likes_received = models.PositiveIntegerField(default=0)
    likes_given = models.PositiveIntegerField(default=0)
    solutions_count = models.PositiveIntegerField(default=0)
    days_visited = models.PositiveIntegerField(default=0)
    topics_read = models.PositiveIntegerField(default=0)

    # Reputation (vBulletin-style, earned from likes/solutions/activity)
    reputation = models.IntegerField(default=0)

    # Moderation
    is_banned = models.BooleanField(default=False)
    ban_reason = models.TextField(blank=True, default="")
    ban_expires_at = models.DateTimeField(null=True, blank=True)
    warning_level = models.PositiveIntegerField(default=0)

    last_active_at = models.DateTimeField(null=True, blank=True)
    last_posted_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Forum User Profile"
        verbose_name_plural = "Forum User Profiles"
        db_table = "forum_forumuserprofile"

    def __str__(self) -> str:
        return f"Forum profile: {self.user_id}"  # type: ignore[attr-defined]

    @property
    def display_title(self) -> str:
        if self.custom_title:
            return self.custom_title
        return str(TrustLevelChoices(self.trust_level).label)

    @property
    def is_currently_banned(self) -> bool:
        if not self.is_banned:
            return False
        if self.ban_expires_at and timezone.now() >= self.ban_expires_at:
            return False
        return True


# ---------------------------------------------------------------------------
# Reactions (XenForo-style — multiple reaction types beyond just "like")
# ---------------------------------------------------------------------------


class ForumReaction(models.Model):
    """Defines available reaction types."""

    name = models.CharField(max_length=50, unique=True)
    emoji = models.CharField(max_length=10, help_text="Emoji character")
    icon = models.CharField(
        max_length=64, blank=True, default="", help_text="Lucide icon name"
    )
    score = models.IntegerField(
        default=1, help_text="Reputation points awarded (+/- for negative)"
    )
    sort_order = models.PositiveIntegerField(default=0)
    is_positive = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order"]
        verbose_name = "Forum Reaction"
        verbose_name_plural = "Forum Reactions"
        db_table = "forum_forumreaction"

    def __str__(self) -> str:
        return f"{self.emoji} {self.name}"


class ForumReplyReaction(models.Model):
    """A user's reaction on a reply."""

    reply = models.ForeignKey(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="reactions",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_reactions_given",
    )
    reaction = models.ForeignKey(
        ForumReaction,
        on_delete=models.CASCADE,
        related_name="reply_reactions",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("reply", "user")]
        verbose_name = "Forum Reply Reaction"
        verbose_name_plural = "Forum Reply Reactions"
        db_table = "forum_forumreplyreaction"

    def __str__(self) -> str:
        return f"{self.reaction} by {self.user_id} on reply {self.reply_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Topic Tags / Prefixes (Flarum tags + vBulletin thread prefixes)
# ---------------------------------------------------------------------------


class ForumTopicPrefix(models.Model):
    """Thread prefix (e.g. [SOLVED], [HELP], [GUIDE], [ROM], [MOD])."""

    name = models.CharField(max_length=50, unique=True)
    slug = models.SlugField(max_length=60, unique=True)
    color = models.CharField(max_length=7, default="#6366f1")
    is_active = models.BooleanField(default=True)
    # Categories that allow this prefix (blank = all)
    categories = models.ManyToManyField(
        ForumCategory,
        blank=True,
        related_name="allowed_prefixes",
    )

    class Meta:
        ordering = ["name"]
        verbose_name = "Forum Topic Prefix"
        verbose_name_plural = "Forum Topic Prefixes"
        db_table = "forum_forumtopicprefix"

    def __str__(self) -> str:
        return self.name


class ForumTopicTag(models.Model):
    """Free-form tag on a topic for categorization and search."""

    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="forum_tags",
    )
    name = models.CharField(max_length=50)
    slug = models.SlugField(max_length=60)

    class Meta:
        unique_together = [("topic", "slug")]
        verbose_name = "Forum Topic Tag"
        verbose_name_plural = "Forum Topic Tags"
        db_table = "forum_forumtopictag"

    def __str__(self) -> str:
        return self.name

    def save(self, *args: object, **kwargs: object) -> None:
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)


# ---------------------------------------------------------------------------
# Best Answer / Solution (XenForo / Stack Overflow style)
# ---------------------------------------------------------------------------


class ForumBestAnswer(models.Model):
    """Marks a single reply as the accepted solution for a topic."""

    topic = models.OneToOneField(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="best_answer",
    )
    reply = models.OneToOneField(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="is_best_answer",
    )
    marked_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_solutions_marked",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Forum Best Answer"
        verbose_name_plural = "Forum Best Answers"
        db_table = "forum_forumbestanswer"

    def __str__(self) -> str:
        return f"Solution for topic {self.topic_id}: reply {self.reply_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Topic Rating (vBulletin star rating system)
# ---------------------------------------------------------------------------


class ForumTopicRating(models.Model):
    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="ratings",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_topic_ratings",
    )
    score = models.PositiveSmallIntegerField(help_text="1 to 5 stars")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("topic", "user")]
        verbose_name = "Forum Topic Rating"
        verbose_name_plural = "Forum Topic Ratings"
        db_table = "forum_forumtopicrating"

    def __str__(self) -> str:
        return f"{self.score}★ by {self.user_id} on topic {self.topic_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Warning System (vBulletin/XenForo moderation warnings)
# ---------------------------------------------------------------------------


class ForumWarning(models.Model):
    class Severity(models.TextChoices):
        MINOR = "minor", "Minor"
        MODERATE = "moderate", "Moderate"
        SERIOUS = "serious", "Serious"
        FINAL = "final", "Final Warning"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_warnings",
    )
    issued_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_warnings_issued",
    )
    topic = models.ForeignKey(
        ForumTopic,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="warnings",
    )
    reply = models.ForeignKey(
        ForumReply,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="warnings",
    )
    severity = models.CharField(
        max_length=10, choices=Severity.choices, default=Severity.MINOR
    )
    reason = models.TextField()
    points = models.PositiveIntegerField(default=1, help_text="Warning points added")
    expires_at = models.DateTimeField(
        null=True, blank=True, help_text="Auto-expire date"
    )
    is_acknowledged = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Forum Warning"
        verbose_name_plural = "Forum Warnings"
        db_table = "forum_forumwarning"

    def __str__(self) -> str:
        return f"Warning ({self.severity}) to {self.user_id}"  # type: ignore[attr-defined]

    @property
    def is_active(self) -> bool:
        if self.expires_at and timezone.now() >= self.expires_at:
            return False
        return True


# ---------------------------------------------------------------------------
# IP Ban (forum-level IP blocking)
# ---------------------------------------------------------------------------


class ForumIPBan(models.Model):
    ip_address = models.GenericIPAddressField()
    reason = models.TextField(blank=True, default="")
    banned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_ip_bans_issued",
    )
    expires_at = models.DateTimeField(
        null=True, blank=True, help_text="Permanent if null"
    )
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Forum IP Ban"
        verbose_name_plural = "Forum IP Bans"
        db_table = "forum_forumipban"
        indexes = [
            models.Index(fields=["ip_address", "is_active"], name="forum_ipban_ip"),
        ]

    def __str__(self) -> str:
        return f"IP ban: {self.ip_address}"

    @property
    def is_currently_active(self) -> bool:
        if not self.is_active:
            return False
        if self.expires_at and timezone.now() >= self.expires_at:
            return False
        return True


# ---------------------------------------------------------------------------
# Category Subscription (XenForo "Watch Forum")
# ---------------------------------------------------------------------------


class ForumCategorySubscription(models.Model):
    category = models.ForeignKey(
        ForumCategory,
        on_delete=models.CASCADE,
        related_name="category_subscriptions",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_category_subscriptions",
    )
    notify_new_topics = models.BooleanField(default=True)
    notify_new_replies = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("category", "user")]
        verbose_name = "Forum Category Subscription"
        verbose_name_plural = "Forum Category Subscriptions"
        db_table = "forum_forumcategorysubscription"

    def __str__(self) -> str:
        return f"{self.user_id} watches {self.category_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Who's Online (vBulletin-style online presence tracking)
# ---------------------------------------------------------------------------


class ForumOnlineUser(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_online",
    )
    last_seen = models.DateTimeField(auto_now=True)
    location = models.CharField(
        max_length=255, blank=True, default="", help_text="Current page description"
    )

    class Meta:
        verbose_name = "Forum Online User"
        verbose_name_plural = "Forum Online Users"
        db_table = "forum_forumonlineuser"

    def __str__(self) -> str:
        return f"{self.user_id} online"  # type: ignore[attr-defined]

    @property
    def is_online(self) -> bool:
        threshold = timezone.now() - timedelta(minutes=15)
        return self.last_seen >= threshold


# ---------------------------------------------------------------------------
# Topic Move Log (moderation audit)
# ---------------------------------------------------------------------------


class ForumTopicMoveLog(models.Model):
    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="move_history",
    )
    from_category = models.ForeignKey(
        ForumCategory,
        on_delete=models.SET_NULL,
        null=True,
        related_name="+",
    )
    to_category = models.ForeignKey(
        ForumCategory,
        on_delete=models.SET_NULL,
        null=True,
        related_name="+",
    )
    moved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_moves",
    )
    reason = models.TextField(blank=True, default="")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Forum Topic Move"
        verbose_name_plural = "Forum Topic Moves"
        db_table = "forum_forumtopicmovelog"

    def __str__(self) -> str:
        return f"Topic {self.topic_id} moved"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Topic Merge Log
# ---------------------------------------------------------------------------


class ForumTopicMergeLog(models.Model):
    source_topic_title = models.CharField(max_length=255)
    target_topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="merge_history",
    )
    merged_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_merges",
    )
    replies_moved = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Forum Topic Merge"
        verbose_name_plural = "Forum Topic Merges"
        db_table = "forum_forumtopicmergelog"

    def __str__(self) -> str:
        return f"Merged '{self.source_topic_title}' into {self.target_topic_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# 4PDA-style "Useful" Post (multiple posts can be marked useful, unlike best answer)
# ---------------------------------------------------------------------------


class ForumUsefulPost(models.Model):
    """4PDA-style useful post marking — multiple replies can be marked useful."""

    reply = models.ForeignKey(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="useful_marks",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="forum_useful_marks",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("reply", "user")]
        verbose_name = "Forum Useful Post"
        verbose_name_plural = "Forum Useful Posts"
        db_table = "forum_forumusefulpost"

    def __str__(self) -> str:
        return f"Useful mark by {self.user_id} on reply {self.reply_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# 4PDA-style FAQ entry (topic author marks replies as FAQ entries)
# ---------------------------------------------------------------------------


class ForumFAQEntry(models.Model):
    """Mark a reply as an FAQ item within a topic (4PDA discussion шапка FAQ)."""

    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="faq_entries",
    )
    reply = models.ForeignKey(
        ForumReply,
        on_delete=models.CASCADE,
        related_name="faq_entry",
    )
    question = models.CharField(max_length=255, help_text="Short FAQ question label")
    sort_order = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["sort_order"]
        verbose_name = "Forum FAQ Entry"
        verbose_name_plural = "Forum FAQ Entries"
        db_table = "forum_forumfaqentry"

    def __str__(self) -> str:
        return f"FAQ: {self.question}"


# ---------------------------------------------------------------------------
# 4PDA-style Changelog (firmware threads track version history)
# ---------------------------------------------------------------------------


class ForumChangelog(models.Model):
    """Version changelog entry for firmware discussion topics."""

    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="changelog_entries",
    )
    version = models.CharField(max_length=50, help_text="Version string e.g. 1.2.3")
    changes = models.TextField(help_text="Markdown description of changes")
    changes_html = models.TextField(blank=True, default="")
    released_at = models.DateField(null=True, blank=True)
    added_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_changelog_entries",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Forum Changelog"
        verbose_name_plural = "Forum Changelogs"
        db_table = "forum_forumchangelog"

    def __str__(self) -> str:
        return f"v{self.version} — {self.topic_id}"  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# 4PDA Wiki Header History (track edits to the wiki шапка)
# ---------------------------------------------------------------------------


class ForumWikiHeaderHistory(models.Model):
    """Audit trail for wiki header edits on a topic."""

    topic = models.ForeignKey(
        ForumTopic,
        on_delete=models.CASCADE,
        related_name="wiki_header_history",
    )
    content = models.TextField(help_text="Previous wiki header markdown")
    content_html = models.TextField()
    edited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="forum_wiki_header_edits",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Forum Wiki Header History"
        verbose_name_plural = "Forum Wiki Header Histories"
        db_table = "forum_forumwikiheaderhistory"

    def __str__(self) -> str:
        return f"Wiki edit on topic {self.topic_id} at {self.created_at}"  # type: ignore[attr-defined]
