from django.contrib import admin

from .models import APIEndpoint, APIKey, APIUsageLog


@admin.register(APIKey)
class APIKeyAdmin(admin.ModelAdmin):
    list_display = [
        "name",
        "user",
        "key_prefix",
        "is_active",
        "last_used_at",
        "created_at",
    ]
    list_filter = ["is_active"]
    search_fields = ["name", "user__email", "key_prefix"]
    readonly_fields = ["key_hash", "key_prefix", "created_at"]


@admin.register(APIEndpoint)
class APIEndpointAdmin(admin.ModelAdmin):
    list_display = ["method", "path", "rate_limit", "is_deprecated"]
    list_filter = ["method", "is_deprecated"]


@admin.register(APIUsageLog)
class APIUsageLogAdmin(admin.ModelAdmin):
    list_display = ["endpoint", "method", "response_code", "latency_ms", "timestamp"]
    list_filter = ["response_code", "method"]
    readonly_fields = ["timestamp"]
