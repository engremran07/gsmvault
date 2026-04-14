from django.contrib import admin
from django.http import HttpRequest
from solo.admin import SingletonModelAdmin  # type: ignore[import-untyped]

from .models import (
    BatchOperation,
    InterlinkExclusion,
    LinkableEntity,
    LinkSuggestion,
    Metadata,
    Redirect,
    SchemaEntry,
    SeoEntity,
    SeoEntityEdge,
    SeoKeywordHistory,
    SEOModel,
    SEOSettings,
    SitemapEntry,
)


@admin.register(SEOModel)
class SEOModelAdmin(admin.ModelAdmin[SEOModel]):
    list_display = ("content_type", "object_id", "locked", "ai_generated", "updated_at")
    list_filter = ("locked", "ai_generated")


@admin.register(Metadata)
class MetadataAdmin(admin.ModelAdmin[Metadata]):
    list_display = ("seo", "meta_title", "noindex", "nofollow", "updated_at")
    search_fields = ("meta_title", "meta_description", "focus_keywords")


@admin.register(SchemaEntry)
class SchemaEntryAdmin(admin.ModelAdmin[SchemaEntry]):
    list_display = ("seo", "schema_type", "locked", "created_at")
    list_filter = ("schema_type", "locked")


@admin.register(SitemapEntry)
class SitemapEntryAdmin(admin.ModelAdmin[SitemapEntry]):
    list_display = ("url", "is_active", "priority", "lastmod")
    list_filter = ("is_active",)
    search_fields = ("url",)


@admin.register(Redirect)
class RedirectAdmin(admin.ModelAdmin[Redirect]):
    list_display = ("source", "target", "is_permanent", "is_active", "created_at")
    list_filter = ("is_permanent", "is_active")
    search_fields = ("source", "target")


@admin.register(LinkableEntity)
class LinkableEntityAdmin(admin.ModelAdmin[LinkableEntity]):
    list_display = ("title", "entity_type", "url", "is_active", "updated_at")
    list_filter = ("entity_type", "is_active")
    search_fields = ("title", "url", "keywords")


@admin.register(LinkSuggestion)
class LinkSuggestionAdmin(admin.ModelAdmin[LinkSuggestion]):
    list_display = (
        "source",
        "target",
        "score",
        "is_applied",
        "locked",
        "is_active",
        "created_at",
    )
    list_filter = ("is_applied", "locked", "is_active")


@admin.register(SEOSettings)
class SEOSettingsAdmin(SingletonModelAdmin):
    list_display = (
        "seo_enabled",
        "auto_meta_enabled",
        "auto_schema_enabled",
        "auto_linking_enabled",
    )
    fieldsets = (
        (None, {"fields": ("seo_enabled",)}),
        (
            "Automation",
            {
                "fields": (
                    "auto_meta_enabled",
                    "auto_schema_enabled",
                    "auto_linking_enabled",
                )
            },
        ),
    )

    def has_add_permission(self, request: HttpRequest) -> bool:
        return False


@admin.register(SeoKeywordHistory)
class SeoKeywordHistoryAdmin(admin.ModelAdmin[SeoKeywordHistory]):
    list_display = ("keyword", "target_url", "position", "intent", "created_at")
    list_filter = ("intent",)
    search_fields = ("keyword", "target_url")


@admin.register(SeoEntity)
class SeoEntityAdmin(admin.ModelAdmin[SeoEntity]):
    list_display = ("name", "slug", "entity_type", "is_active", "updated_at")
    list_filter = ("entity_type", "is_active")
    search_fields = ("name", "slug")


@admin.register(SeoEntityEdge)
class SeoEntityEdgeAdmin(admin.ModelAdmin[SeoEntityEdge]):
    list_display = ("source", "target", "relation_type", "weight", "created_at")
    list_filter = ("relation_type",)
    search_fields = ("source__name", "target__name")


@admin.register(InterlinkExclusion)
class InterlinkExclusionAdmin(admin.ModelAdmin[InterlinkExclusion]):
    list_display = ("phrase", "source_pattern", "target_pattern", "is_active")
    list_filter = ("is_active",)
    search_fields = ("phrase", "source_pattern", "target_pattern")


@admin.register(BatchOperation)
class BatchOperationAdmin(admin.ModelAdmin[BatchOperation]):
    list_display = (
        "operation_type",
        "status",
        "initiated_by",
        "started_at",
        "completed_at",
        "created_at",
    )
    list_filter = ("operation_type", "status")
    search_fields = ("operation_type", "status")
