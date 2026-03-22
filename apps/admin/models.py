"""
apps.admin — Custom admin panel models.
AuditLog, AdminAction, FieldChange merged from apps.admin_audit.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models


class AuditLog(models.Model):
    """Immutable record of every create/update/delete performed via the admin."""

    class Action(models.TextChoices):
        CREATE = "create", "Create"
        UPDATE = "update", "Update"
        DELETE = "delete", "Delete"
        BULK_UPDATE = "bulk_update", "Bulk Update"
        BULK_DELETE = "bulk_delete", "Bulk Delete"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="audit_logs",
    )
    action = models.CharField(max_length=14, choices=Action.choices, db_index=True)
    model_name = models.CharField(max_length=100, db_index=True)
    app_label = models.CharField(max_length=50)
    object_id = models.BigIntegerField(null=True, blank=True, db_index=True)
    object_repr = models.CharField(max_length=255)
    before = models.JSONField(default=dict, blank=True)
    after = models.JSONField(default=dict, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=255, blank=True, default="")
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = "admin_audit_auditlog"
        verbose_name = "Audit Log"
        verbose_name_plural = "Audit Logs"
        ordering = ["-timestamp"]
        indexes = [
            models.Index(
                fields=["model_name", "object_id"],
                name="audit_model_obj_idx",
            ),
            models.Index(
                fields=["user", "timestamp"],
                name="audit_user_ts_idx",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.action} on {self.model_name}#{self.object_id} by {self.user}"


class AdminAction(models.Model):
    """Lightweight record of an admin user performing a named action."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="admin_actions",
    )
    action_type = models.CharField(max_length=50)
    target_model = models.CharField(max_length=100)
    target_pk = models.BigIntegerField(null=True, blank=True)
    details = models.JSONField(default=dict, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = "admin_audit_adminaction"
        verbose_name = "Admin Action"
        verbose_name_plural = "Admin Actions"
        ordering = ["-timestamp"]

    def __str__(self) -> str:
        return f"{self.user} — {self.action_type} on {self.target_model}"


class FieldChange(models.Model):
    """Individual field delta recorded as part of an AuditLog UPDATE entry."""

    audit_log = models.ForeignKey(
        AuditLog, on_delete=models.CASCADE, related_name="field_changes"
    )
    field_name = models.CharField(max_length=100)
    old_value = models.TextField(blank=True, default="")
    new_value = models.TextField(blank=True, default="")

    class Meta:
        db_table = "admin_audit_fieldchange"
        verbose_name = "Field Change"
        verbose_name_plural = "Field Changes"

    def __str__(self) -> str:
        return f"{self.field_name}: {self.old_value!r} → {self.new_value!r}"
