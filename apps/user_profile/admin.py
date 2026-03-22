from django.contrib import admin

from .models import ActivityFeed, Following, Profile, Reputation


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin[Profile]):
    list_display = ["user", "is_public", "updated_at"]
    list_filter = ["is_public"]
    search_fields = ["user__email"]


@admin.register(Reputation)
class ReputationAdmin(admin.ModelAdmin[Reputation]):
    list_display = ["user", "total_score", "fw_contributions", "downloads_helped"]
    ordering = ["-total_score"]


@admin.register(Following)
class FollowingAdmin(admin.ModelAdmin[Following]):
    list_display = ["follower", "following", "created_at"]
    search_fields = ["follower__email", "following__email"]


@admin.register(ActivityFeed)
class ActivityFeedAdmin(admin.ModelAdmin[ActivityFeed]):
    list_display = ["user", "action_type", "created_at"]
    list_filter = ["action_type"]
    readonly_fields = ["created_at"]
