from django.contrib import admin

from .models import AdminAction, AuditLog, FieldChange


class FieldChangeInline(admin.TabularInline[FieldChange, AuditLog]):
    model = FieldChange
    extra = 0
    readonly_fields = ["field_name", "old_value", "new_value"]

    def has_add_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin[AuditLog]):
    list_display = [
        "timestamp",
        "user",
        "action",
        "app_label",
        "model_name",
        "object_id",
        "object_repr",
    ]
    list_filter = ["action", "app_label", "model_name"]
    search_fields = ["object_repr", "user__email", "user__username", "model_name"]
    readonly_fields = [
        "user",
        "action",
        "model_name",
        "app_label",
        "object_id",
        "object_repr",
        "before",
        "after",
        "ip",
        "user_agent",
        "timestamp",
    ]
    date_hierarchy = "timestamp"
    inlines = [FieldChangeInline]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(AdminAction)
class AdminActionAdmin(admin.ModelAdmin[AdminAction]):
    list_display = ["timestamp", "user", "action_type", "target_model", "target_pk"]
    list_filter = ["action_type", "target_model"]
    search_fields = ["user__email", "user__username", "action_type", "target_model"]
    readonly_fields = [
        "user",
        "action_type",
        "target_model",
        "target_pk",
        "details",
        "timestamp",
    ]
    date_hierarchy = "timestamp"

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(FieldChange)
class FieldChangeAdmin(admin.ModelAdmin[FieldChange]):
    list_display = ["audit_log", "field_name", "old_value", "new_value"]
    search_fields = ["field_name", "old_value", "new_value"]
    readonly_fields = ["audit_log", "field_name", "old_value", "new_value"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
