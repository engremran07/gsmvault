from __future__ import annotations

from django.contrib import admin
from django.db.models import QuerySet
from django.http import HttpRequest

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
