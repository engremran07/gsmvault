from __future__ import annotations

from django.contrib import admin
from django.db.models import QuerySet
from django.http import HttpRequest

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
    ForumTopicPrefix,
    ForumTopicRating,
    ForumTopicSubscription,
    ForumTopicTag,
    ForumTrustLevel,
    ForumUsefulPost,
    ForumUserProfile,
    ForumWarning,
    ForumWikiHeaderHistory,
)


class ForumPollChoiceInline(admin.TabularInline[ForumPollChoice, ForumPoll]):
    model = ForumPollChoice
    extra = 0


@admin.register(ForumCategory)
class ForumCategoryAdmin(admin.ModelAdmin[ForumCategory]):
    list_display = [
        "title",
        "parent",
        "sort_order",
        "is_closed",
        "is_private",
        "is_visible",
        "topic_count",
    ]
    list_filter = ["is_closed", "is_private", "is_visible"]
    search_fields = ["title", "slug"]
    prepopulated_fields = {"slug": ("title",)}
    list_editable = ["sort_order", "is_closed", "is_visible"]

    def get_queryset(self, request: HttpRequest) -> QuerySet[ForumCategory]:
        return super().get_queryset(request).select_related("parent")


@admin.register(ForumTopic)
class ForumTopicAdmin(admin.ModelAdmin[ForumTopic]):
    list_display = [
        "title",
        "category",
        "user",
        "is_pinned",
        "is_closed",
        "is_removed",
        "reply_count",
        "view_count",
        "created_at",
    ]
    list_filter = ["is_pinned", "is_closed", "is_removed", "category"]
    search_fields = ["title", "content"]
    raw_id_fields = ["user", "category", "last_reply_user"]
    date_hierarchy = "created_at"

    def get_queryset(self, request: HttpRequest) -> QuerySet[ForumTopic]:
        return super().get_queryset(request).select_related("category", "user")


@admin.register(ForumReply)
class ForumReplyAdmin(admin.ModelAdmin[ForumReply]):
    list_display = [
        "__str__",
        "topic",
        "user",
        "action",
        "is_removed",
        "likes_count",
        "created_at",
    ]
    list_filter = ["action", "is_removed"]
    search_fields = ["content"]
    raw_id_fields = ["user", "topic"]
    date_hierarchy = "created_at"

    def get_queryset(self, request: HttpRequest) -> QuerySet[ForumReply]:
        return super().get_queryset(request).select_related("topic", "user")


@admin.register(ForumPoll)
class ForumPollAdmin(admin.ModelAdmin[ForumPoll]):
    list_display = [
        "title",
        "topic",
        "mode",
        "is_secret",
        "is_closed",
        "vote_count",
        "created_at",
    ]
    list_filter = ["mode", "is_secret", "is_closed"]
    inlines = [ForumPollChoiceInline]
    raw_id_fields = ["topic"]


@admin.register(ForumFlag)
class ForumFlagAdmin(admin.ModelAdmin[ForumFlag]):
    list_display = ["__str__", "reason", "user", "is_resolved", "created_at"]
    list_filter = ["reason", "is_resolved"]
    raw_id_fields = ["user", "topic", "reply"]
    date_hierarchy = "created_at"


@admin.register(ForumBookmark)
class ForumBookmarkAdmin(admin.ModelAdmin[ForumBookmark]):
    list_display = ["user", "topic", "reply_number", "updated_at"]
    raw_id_fields = ["user", "topic"]


@admin.register(ForumLike)
class ForumLikeAdmin(admin.ModelAdmin[ForumLike]):
    list_display = ["user", "reply", "created_at"]
    raw_id_fields = ["user", "reply"]


@admin.register(ForumTopicFavorite)
class ForumTopicFavoriteAdmin(admin.ModelAdmin[ForumTopicFavorite]):
    list_display = ["user", "topic", "created_at"]
    raw_id_fields = ["user", "topic"]


@admin.register(ForumTopicSubscription)
class ForumTopicSubscriptionAdmin(admin.ModelAdmin[ForumTopicSubscription]):
    list_display = ["user", "topic", "frequency", "created_at"]
    list_filter = ["frequency"]
    raw_id_fields = ["user", "topic"]


@admin.register(ForumReplyHistory)
class ForumReplyHistoryAdmin(admin.ModelAdmin[ForumReplyHistory]):
    list_display = ["reply", "edited_by", "created_at"]
    raw_id_fields = ["reply", "edited_by"]


@admin.register(ForumMention)
class ForumMentionAdmin(admin.ModelAdmin[ForumMention]):
    list_display = ["reply", "user", "created_at"]
    raw_id_fields = ["reply", "user"]


@admin.register(ForumPrivateTopic)
class ForumPrivateTopicAdmin(admin.ModelAdmin[ForumPrivateTopic]):
    list_display = ["topic", "user", "created_at"]
    raw_id_fields = ["user", "topic"]


@admin.register(ForumPrivateTopicUser)
class ForumPrivateTopicUserAdmin(admin.ModelAdmin[ForumPrivateTopicUser]):
    list_display = ["private_topic", "user", "created_at"]
    raw_id_fields = ["private_topic", "user"]


@admin.register(ForumAttachment)
class ForumAttachmentAdmin(admin.ModelAdmin[ForumAttachment]):
    list_display = ["filename", "reply", "user", "file_size", "created_at"]
    raw_id_fields = ["reply", "user"]


@admin.register(ForumPollChoice)
class ForumPollChoiceAdmin(admin.ModelAdmin[ForumPollChoice]):
    list_display = ["description", "poll", "vote_count", "sort_order"]
    raw_id_fields = ["poll"]


@admin.register(ForumPollVote)
class ForumPollVoteAdmin(admin.ModelAdmin[ForumPollVote]):
    list_display = ["user", "poll", "choice", "created_at"]
    raw_id_fields = ["user", "poll", "choice"]


# ---------------------------------------------------------------------------
# Enrichment models
# ---------------------------------------------------------------------------


@admin.register(ForumTrustLevel)
class ForumTrustLevelAdmin(admin.ModelAdmin[ForumTrustLevel]):
    list_display = [
        "title",
        "level",
        "min_topics_created",
        "min_replies_posted",
        "min_days_visited",
        "can_flag",
        "can_create_polls",
    ]
    list_editable = ["min_topics_created", "min_replies_posted", "min_days_visited"]
    ordering = ["level"]


@admin.register(ForumUserProfile)
class ForumUserProfileAdmin(admin.ModelAdmin[ForumUserProfile]):
    list_display = [
        "user",
        "trust_level",
        "reputation",
        "topic_count",
        "reply_count",
        "is_banned",
        "warning_level",
    ]
    list_filter = ["trust_level", "is_banned"]
    search_fields = ["user__username", "custom_title"]
    raw_id_fields = ["user"]
    readonly_fields = ["reputation", "topic_count", "reply_count", "likes_received"]


@admin.register(ForumReaction)
class ForumReactionAdmin(admin.ModelAdmin[ForumReaction]):
    list_display = ["name", "emoji", "icon", "score", "sort_order", "is_active"]
    list_editable = ["sort_order", "is_active", "score"]
    ordering = ["sort_order"]


@admin.register(ForumReplyReaction)
class ForumReplyReactionAdmin(admin.ModelAdmin[ForumReplyReaction]):
    list_display = ["user", "reply", "reaction", "created_at"]
    raw_id_fields = ["user", "reply", "reaction"]


@admin.register(ForumTopicPrefix)
class ForumTopicPrefixAdmin(admin.ModelAdmin[ForumTopicPrefix]):
    list_display = ["name", "slug", "color", "is_active"]
    list_editable = ["is_active"]
    prepopulated_fields = {"slug": ("name",)}
    filter_horizontal = ["categories"]


@admin.register(ForumTopicTag)
class ForumTopicTagAdmin(admin.ModelAdmin[ForumTopicTag]):
    list_display = ["name", "slug", "topic"]
    search_fields = ["name"]
    raw_id_fields = ["topic"]


@admin.register(ForumBestAnswer)
class ForumBestAnswerAdmin(admin.ModelAdmin[ForumBestAnswer]):
    list_display = ["topic", "reply", "marked_by", "created_at"]
    raw_id_fields = ["topic", "reply", "marked_by"]


@admin.register(ForumTopicRating)
class ForumTopicRatingAdmin(admin.ModelAdmin[ForumTopicRating]):
    list_display = ["topic", "user", "score", "created_at"]
    raw_id_fields = ["topic", "user"]


@admin.register(ForumWarning)
class ForumWarningAdmin(admin.ModelAdmin[ForumWarning]):
    list_display = [
        "user",
        "severity",
        "points",
        "issued_by",
        "is_acknowledged",
        "created_at",
        "expires_at",
    ]
    list_filter = ["severity", "is_acknowledged"]
    search_fields = ["user__username", "reason"]
    raw_id_fields = ["user", "issued_by"]
    date_hierarchy = "created_at"


@admin.register(ForumIPBan)
class ForumIPBanAdmin(admin.ModelAdmin[ForumIPBan]):
    list_display = ["ip_address", "banned_by", "is_active", "created_at", "expires_at"]
    list_filter = ["is_active"]
    search_fields = ["ip_address", "reason"]
    raw_id_fields = ["banned_by"]


@admin.register(ForumCategorySubscription)
class ForumCategorySubscriptionAdmin(admin.ModelAdmin[ForumCategorySubscription]):
    list_display = [
        "user",
        "category",
        "notify_new_topics",
        "notify_new_replies",
        "created_at",
    ]
    list_filter = ["notify_new_topics", "notify_new_replies"]
    raw_id_fields = ["user", "category"]


@admin.register(ForumOnlineUser)
class ForumOnlineUserAdmin(admin.ModelAdmin[ForumOnlineUser]):
    list_display = ["user", "last_seen", "location"]
    raw_id_fields = ["user"]


@admin.register(ForumTopicMoveLog)
class ForumTopicMoveLogAdmin(admin.ModelAdmin[ForumTopicMoveLog]):
    list_display = ["topic", "from_category", "to_category", "moved_by", "created_at"]
    raw_id_fields = ["topic", "from_category", "to_category", "moved_by"]
    date_hierarchy = "created_at"


@admin.register(ForumTopicMergeLog)
class ForumTopicMergeLogAdmin(admin.ModelAdmin[ForumTopicMergeLog]):
    list_display = [
        "source_topic_title",
        "target_topic",
        "merged_by",
        "replies_moved",
        "created_at",
    ]
    raw_id_fields = ["target_topic", "merged_by"]
    date_hierarchy = "created_at"


# ---------------------------------------------------------------------------
# 4PDA-style model admins
# ---------------------------------------------------------------------------


@admin.register(ForumUsefulPost)
class ForumUsefulPostAdmin(admin.ModelAdmin[ForumUsefulPost]):
    list_display = ["reply", "user", "created_at"]
    raw_id_fields = ["reply", "user"]


@admin.register(ForumFAQEntry)
class ForumFAQEntryAdmin(admin.ModelAdmin[ForumFAQEntry]):
    list_display = ["question", "topic", "reply", "sort_order", "created_at"]
    raw_id_fields = ["topic", "reply"]
    search_fields = ["question"]


@admin.register(ForumChangelog)
class ForumChangelogAdmin(admin.ModelAdmin[ForumChangelog]):
    list_display = ["version", "topic", "added_by", "released_at", "created_at"]
    raw_id_fields = ["topic", "added_by"]
    search_fields = ["version"]
    date_hierarchy = "created_at"


@admin.register(ForumWikiHeaderHistory)
class ForumWikiHeaderHistoryAdmin(admin.ModelAdmin[ForumWikiHeaderHistory]):
    list_display = ["topic", "edited_by", "created_at"]
    raw_id_fields = ["topic", "edited_by"]
    date_hierarchy = "created_at"
