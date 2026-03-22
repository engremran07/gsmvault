from django.contrib import admin

from .models import (
    Badge,
    Leaderboard,
    LeaderboardEntry,
    Level,
    Streak,
    UserBadge,
    XPTransaction,
)


@admin.register(Level)
class LevelAdmin(admin.ModelAdmin):
    list_display = ["number", "name", "min_xp"]


@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ["name", "slug", "xp_value", "is_active"]
    prepopulated_fields = {"slug": ["name"]}


@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ["user", "badge", "earned_at"]


@admin.register(XPTransaction)
class XPTransactionAdmin(admin.ModelAdmin):
    list_display = ["user", "amount", "reason", "created_at"]
    readonly_fields = ["created_at"]


@admin.register(Streak)
class StreakAdmin(admin.ModelAdmin):
    list_display = ["user", "count", "longest_streak", "last_activity_date"]


@admin.register(Leaderboard)
class LeaderboardAdmin(admin.ModelAdmin):
    list_display = ["period_type", "scope", "updated_at"]


@admin.register(LeaderboardEntry)
class LeaderboardEntryAdmin(admin.ModelAdmin):
    list_display = ["leaderboard", "rank", "user", "score"]
