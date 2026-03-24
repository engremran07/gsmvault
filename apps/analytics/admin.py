from __future__ import annotations

from django.contrib import admin

from .models import DailyMetrics, Event, PageView, RealtimeMetrics, UserAnalytics


@admin.register(PageView)
class PageViewAdmin(admin.ModelAdmin["PageView"]):
    list_display = ("path", "user", "ip_address", "created_at")
    list_filter = ("created_at",)
    search_fields = ("path", "ip_address")
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)


@admin.register(Event)
class EventAdmin(admin.ModelAdmin["Event"]):
    list_display = ("event_type", "event_name", "user", "created_at")
    list_filter = ("event_type", "created_at")
    search_fields = ("event_name",)
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)


@admin.register(DailyMetrics)
class DailyMetricsAdmin(admin.ModelAdmin["DailyMetrics"]):
    list_display = (
        "date",
        "total_page_views",
        "unique_visitors",
        "total_downloads",
    )
    list_filter = ("date",)
    ordering = ("-date",)


@admin.register(RealtimeMetrics)
class RealtimeMetricsAdmin(admin.ModelAdmin["RealtimeMetrics"]):
    list_display = (
        "timestamp",
        "active_users",
        "page_views_last_hour",
        "downloads_last_hour",
    )
    ordering = ("-timestamp",)


@admin.register(UserAnalytics)
class UserAnalyticsAdmin(admin.ModelAdmin["UserAnalytics"]):
    list_display = (
        "user",
        "total_page_views",
        "total_downloads",
        "last_active_at",
    )
    search_fields = ("user__email",)
    readonly_fields = ("created_at", "updated_at")
    ordering = ("-updated_at",)
