from django.contrib import admin

from .models import (
    BlockedIP,
    CSPViolationReport,
    RateLimitRule,
    SecurityConfig,
    SecurityEvent,
)


@admin.register(SecurityConfig)
class SecurityConfigAdmin(admin.ModelAdmin[SecurityConfig]):
    pass


@admin.register(SecurityEvent)
class SecurityEventAdmin(admin.ModelAdmin[SecurityEvent]):
    list_display = ["event_type", "severity", "user", "ip", "created_at"]
    list_filter = ["event_type", "severity"]
    search_fields = ["ip", "user__email"]
    readonly_fields = ["created_at"]


@admin.register(RateLimitRule)
class RateLimitRuleAdmin(admin.ModelAdmin[RateLimitRule]):
    list_display = ["path_pattern", "limit", "window_seconds", "action", "is_active"]


@admin.register(BlockedIP)
class BlockedIPAdmin(admin.ModelAdmin[BlockedIP]):
    list_display = ["ip", "reason", "blocked_until", "is_active", "created_at"]


@admin.register(CSPViolationReport)
class CSPViolationReportAdmin(admin.ModelAdmin[CSPViolationReport]):
    list_display = ["violated_directive", "document_uri", "created_at"]
    readonly_fields = ["created_at"]
