from __future__ import annotations

from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.db import models
from django.utils.text import slugify
from solo.models import SingletonModel

from apps.core.models import AuditFieldsModel, SoftDeleteModel, TimestampedModel


class SEOModel(TimestampedModel, SoftDeleteModel, AuditFieldsModel):
    """
    Generic container for SEO-related data tied to any model instance.
    """

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey("content_type", "object_id")
    locked = models.BooleanField(default=False)
    ai_generated = models.BooleanField(default=False)

    class Meta:
        unique_together = ("content_type", "object_id")

    def __str__(self) -> str:
        return f"SEO:{self.content_type}#{self.object_id}"


class Metadata(TimestampedModel):
    seo = models.OneToOneField(
        SEOModel, on_delete=models.CASCADE, related_name="metadata"
    )
    meta_title = models.CharField(max_length=255, blank=True, default="")
    meta_description = models.CharField(max_length=320, blank=True, default="")
    focus_keywords = models.JSONField(default=list, blank=True)
    canonical_url = models.URLField(blank=True, default="")
    robots_directives = models.CharField(max_length=255, blank=True, default="")
    social_title = models.CharField(max_length=255, blank=True, default="")
    social_description = models.CharField(max_length=320, blank=True, default="")
    social_image = models.URLField(blank=True, default="")
    noindex = models.BooleanField(default=False)
    nofollow = models.BooleanField(default=False)
    content_hash = models.CharField(max_length=64, blank=True, default="")
    ai_score = models.FloatField(default=0.0)
    schema_json = models.JSONField(default=dict, blank=True)
    proposed_json = models.JSONField(default=dict, blank=True)
    auto_apply_suggestions = models.BooleanField(default=False)
    generated_at = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> str:
        return self.meta_title or f"Metadata for {self.seo}"


class SchemaEntry(TimestampedModel):
    seo = models.ForeignKey(SEOModel, on_delete=models.CASCADE, related_name="schemas")
    schema_type = models.CharField(max_length=100)
    payload = models.JSONField(default=dict, blank=True)
    locked = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return f"{self.schema_type} schema for {self.seo}"


class SitemapEntry(TimestampedModel):
    url = models.URLField(unique=True)
    lastmod = models.DateTimeField(null=True, blank=True)
    changefreq = models.CharField(max_length=20, blank=True, default="")
    priority = models.FloatField(default=0.5)
    is_active = models.BooleanField(default=True)
    last_status = models.PositiveIntegerField(null=True, blank=True)
    last_checked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return self.url


class Redirect(TimestampedModel):
    source = models.CharField(max_length=255, unique=True)
    target = models.CharField(max_length=255)
    is_permanent = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["source"]

    def __str__(self) -> str:
        return f"{self.source} → {self.target}"


class LinkableEntity(TimestampedModel):
    """
    Registry of linkable content for internal linking.
    """

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey("content_type", "object_id")
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, blank=True, db_index=True)
    aliases = models.JSONField(default=list, blank=True)
    entity_type = models.CharField(max_length=100, blank=True, default="")
    url = models.URLField()
    keywords = models.JSONField(default=list, blank=True)
    embedding = models.BinaryField(null=True, blank=True)
    vector = models.BinaryField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("content_type", "object_id")
        indexes = [models.Index(fields=["content_type", "object_id"])]

    def __str__(self) -> str:
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            base = slugify(self.title)[:240]
            self.slug = base or f"entity-{self.pk or ''}"
        super().save(*args, **kwargs)


class LinkSuggestion(TimestampedModel):
    """
    Stable suggestions for internal linking. Not auto-applied unless requested.
    """

    source = models.ForeignKey(
        LinkableEntity, on_delete=models.CASCADE, related_name="suggestions_from"
    )
    target = models.ForeignKey(
        LinkableEntity, on_delete=models.CASCADE, related_name="suggestions_to"
    )
    score = models.FloatField(default=0.0)
    is_applied = models.BooleanField(default=False)
    locked = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("source", "target")

    def __str__(self) -> str:
        return f"{self.source} → {self.target} ({self.score:.2f})"


class SEOSettings(SingletonModel):
    """
    Per-app settings for SEO so the app can be reused independently.
    """

    seo_enabled = models.BooleanField(default=True)
    auto_meta_enabled = models.BooleanField(default=False)
    auto_schema_enabled = models.BooleanField(default=False)
    auto_linking_enabled = models.BooleanField(default=False)

    class Meta:
        verbose_name = "SEO Settings"

    def __str__(self) -> str:
        return "SEO Settings"


class SeoKeywordHistory(TimestampedModel):
    class Intent(models.TextChoices):
        INFORMATIONAL = "informational", "Informational"
        TRANSACTIONAL = "transactional", "Transactional"
        NAVIGATIONAL = "navigational", "Navigational"
        COMMERCIAL = "commercial", "Commercial"
        UNKNOWN = "unknown", "Unknown"

    keyword = models.CharField(max_length=255, db_index=True)
    target_url = models.URLField(blank=True, default="")
    position = models.PositiveIntegerField(null=True, blank=True)
    search_volume = models.PositiveIntegerField(default=0)
    intent = models.CharField(
        max_length=20, choices=Intent.choices, default=Intent.UNKNOWN
    )
    source = models.CharField(max_length=100, blank=True, default="manual")

    class Meta:
        db_table = "seo_seokeywordhistory"
        verbose_name = "SEO Keyword History"
        verbose_name_plural = "SEO Keyword History"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.keyword} ({self.intent})"


class SeoEntity(TimestampedModel):
    name = models.CharField(max_length=255, db_index=True)
    slug = models.SlugField(max_length=255, unique=True)
    entity_type = models.CharField(max_length=100, blank=True, default="")
    attributes = models.JSONField(default=dict, blank=True)
    source_content_type = models.ForeignKey(
        ContentType,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="seo_entities",
    )
    source_object_id = models.PositiveIntegerField(null=True, blank=True)
    source_object = GenericForeignKey("source_content_type", "source_object_id")
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "seo_seoentity"
        verbose_name = "SEO Entity"
        verbose_name_plural = "SEO Entities"
        ordering = ["name"]
        indexes = [models.Index(fields=["entity_type", "is_active"])]

    def __str__(self) -> str:
        return self.name


class SeoEntityEdge(TimestampedModel):
    source = models.ForeignKey(
        SeoEntity, on_delete=models.CASCADE, related_name="outgoing_edges"
    )
    target = models.ForeignKey(
        SeoEntity, on_delete=models.CASCADE, related_name="incoming_edges"
    )
    relation_type = models.CharField(max_length=100, db_index=True)
    weight = models.FloatField(default=0.0)

    class Meta:
        db_table = "seo_seoentityedge"
        verbose_name = "SEO Entity Edge"
        verbose_name_plural = "SEO Entity Edges"
        ordering = ["-weight", "-created_at"]
        unique_together = ("source", "target", "relation_type")

    def __str__(self) -> str:
        return f"{self.source} -> {self.target} [{self.relation_type}]"


class InterlinkExclusion(TimestampedModel):
    phrase = models.CharField(max_length=255)
    source_pattern = models.CharField(max_length=255, blank=True, default="")
    target_pattern = models.CharField(max_length=255, blank=True, default="")
    reason = models.CharField(max_length=255, blank=True, default="")
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "seo_interlinkexclusion"
        verbose_name = "Interlink Exclusion"
        verbose_name_plural = "Interlink Exclusions"
        ordering = ["phrase"]
        unique_together = ("phrase", "source_pattern", "target_pattern")

    def __str__(self) -> str:
        return self.phrase


class BatchOperation(TimestampedModel):
    class OperationType(models.TextChoices):
        AUDIT = "audit", "Audit"
        METADATA = "metadata", "Metadata"
        INTERLINK = "interlink", "Interlink"
        KNOWLEDGE_GRAPH = "knowledge_graph", "Knowledge Graph"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        RUNNING = "running", "Running"
        COMPLETED = "completed", "Completed"
        FAILED = "failed", "Failed"
        CANCELLED = "cancelled", "Cancelled"

    operation_type = models.CharField(max_length=50, choices=OperationType.choices)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    payload = models.JSONField(default=dict, blank=True)
    result = models.JSONField(default=dict, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    initiated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="seo_batch_operations",
    )

    class Meta:
        db_table = "seo_batchoperation"
        verbose_name = "SEO Batch Operation"
        verbose_name_plural = "SEO Batch Operations"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.operation_type} ({self.status})"
