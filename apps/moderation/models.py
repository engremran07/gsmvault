"""apps.moderation — Content moderation: rules, queues, appeals."""

from __future__ import annotations

from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.db import models


class ModerationStatus(models.TextChoices):
    PENDING = "pending", "Pending Review"
    APPROVED = "approved", "Approved"
    REJECTED = "rejected", "Rejected"
    APPEALED = "appealed", "Under Appeal"
    ESCALATED = "escalated", "Escalated"


class ModerationRule(models.Model):
    """Automated content moderation rule."""

    class Action(models.TextChoices):
        FLAG = "flag", "Flag for Review"
        REMOVE = "remove", "Auto-Remove"
        BAN = "ban", "Ban User"
        SHADOW = "shadow", "Shadow Ban"

    name = models.CharField(max_length=100, unique=True)
    pattern = models.TextField(help_text="Regex pattern or keyword list (one per line)")
    match_mode = models.CharField(
        max_length=10,
        choices=[("regex", "Regex"), ("keywords", "Keywords"), ("ml", "ML Model")],
        default="keywords",
    )
    action = models.CharField(
        max_length=10, choices=Action.choices, default=Action.FLAG
    )
    severity = models.SmallIntegerField(default=1, help_text="1=low … 5=critical")
    applies_to = models.CharField(
        max_length=40,
        default="comment",
        help_text="content type label the rule applies to",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Moderation Rule"
        verbose_name_plural = "Moderation Rules"
        ordering = ["-severity"]

    def __str__(self) -> str:
        return f"{self.name} [{self.action}]"


class ModerationItem(models.Model):
    """A piece of content queued for moderation (generic FK)."""

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.BigIntegerField(db_index=True)
    content_object = GenericForeignKey("content_type", "object_id")

    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="reported_items",
    )
    report_reason = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(
        max_length=12,
        choices=ModerationStatus.choices,
        default=ModerationStatus.PENDING,
        db_index=True,
    )
    auto_flagged = models.BooleanField(default=False)
    rule_triggered = models.ForeignKey(
        ModerationRule, null=True, blank=True, on_delete=models.SET_NULL
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Moderation Item"
        verbose_name_plural = "Moderation Items"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["status", "content_type"], name="mod_item_status_ct_idx"
            ),
        ]

    def __str__(self) -> str:
        return f"#{self.pk} {self.content_type} [{self.status}]"


class ModerationAction(models.Model):
    """Moderator decision record."""

    item = models.ForeignKey(
        ModerationItem, on_delete=models.CASCADE, related_name="actions"
    )
    moderator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="moderation_actions",
    )
    action = models.CharField(max_length=12, choices=ModerationStatus.choices)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Moderation Action"
        verbose_name_plural = "Moderation Actions"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Action {self.action} on #{self.item_id} by {self.moderator}"  # type: ignore[attr-defined]


class Appeal(models.Model):
    """User appeal against a moderation decision."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACCEPTED = "accepted", "Accepted"
        DENIED = "denied", "Denied"

    item = models.ForeignKey(
        ModerationItem, on_delete=models.CASCADE, related_name="appeals"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="moderation_appeals",
    )
    reason = models.TextField()
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="reviewed_appeals",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Appeal"
        verbose_name_plural = "Appeals"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Appeal on #{self.item_id} [{self.status}]"  # type: ignore[attr-defined]
