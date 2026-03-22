from django.contrib import admin

from .models import Appeal, ModerationAction, ModerationItem, ModerationRule


@admin.register(ModerationRule)
class ModerationRuleAdmin(admin.ModelAdmin):
    list_display = ["name", "action", "severity", "is_active", "created_at"]
    list_filter = ["action", "is_active"]
    search_fields = ["name"]


@admin.register(ModerationItem)
class ModerationItemAdmin(admin.ModelAdmin):
    list_display = [
        "pk",
        "content_type",
        "object_id",
        "status",
        "reporter",
        "created_at",
    ]
    list_filter = ["status", "auto_flagged"]
    readonly_fields = ["created_at"]


@admin.register(ModerationAction)
class ModerationActionAdmin(admin.ModelAdmin):
    list_display = ["item", "action", "moderator", "created_at"]
    readonly_fields = ["created_at"]


@admin.register(Appeal)
class AppealAdmin(admin.ModelAdmin):
    list_display = ["item", "user", "status", "reviewer", "created_at"]
    list_filter = ["status"]
