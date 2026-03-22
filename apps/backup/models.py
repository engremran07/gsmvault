"""apps.backup — Backup schedules, files, and restore logs."""

from __future__ import annotations

from django.conf import settings
from django.db import models


class BackupSchedule(models.Model):
    """Automated backup schedule definition."""

    class BackupType(models.TextChoices):
        FULL = "full", "Full"
        INCREMENTAL = "incremental", "Incremental"
        DB_ONLY = "db_only", "Database Only"
        MEDIA_ONLY = "media_only", "Media Only"

    name = models.CharField(max_length=100, unique=True)
    backup_type = models.CharField(max_length=15, choices=BackupType.choices)
    frequency_hours = models.PositiveIntegerField(default=24)
    retention_days = models.PositiveIntegerField(default=30)
    destination = models.CharField(
        max_length=20,
        choices=[
            ("gcs", "Google Cloud Storage"),
            ("local", "Local Disk"),
            ("s3", "AWS S3"),
        ],
        default="gcs",
    )
    destination_path = models.CharField(max_length=500, blank=True, default="")
    is_active = models.BooleanField(default=True)
    last_run = models.DateTimeField(null=True, blank=True)
    next_run = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Backup Schedule"
        verbose_name_plural = "Backup Schedules"
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.name} ({self.backup_type}) every {self.frequency_hours}h"


class BackupFile(models.Model):
    """Metadata record for a completed backup archive."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        RUNNING = "running", "Running"
        SUCCESS = "success", "Success"
        FAILED = "failed", "Failed"
        EXPIRED = "expired", "Expired"
        DELETED = "deleted", "Deleted"

    schedule = models.ForeignKey(
        BackupSchedule, on_delete=models.CASCADE, related_name="backup_files"
    )
    file_path = models.CharField(max_length=1000)
    size_bytes = models.BigIntegerField(default=0)
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True
    )
    checksum = models.CharField(max_length=128, blank=True, default="")
    error = models.TextField(blank=True, default="")
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Backup File"
        verbose_name_plural = "Backup Files"
        ordering = ["-started_at"]

    def __str__(self) -> str:
        return f"{self.file_path} [{self.status}] ({self.size_bytes} bytes)"


class BackupRestoreLog(models.Model):
    """Audit trail for every restore action performed."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        RUNNING = "running", "Running"
        SUCCESS = "success", "Success"
        FAILED = "failed", "Failed"

    backup_file = models.ForeignKey(
        BackupFile, on_delete=models.CASCADE, related_name="restore_logs"
    )
    initiated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL
    )
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING
    )
    notes = models.TextField(blank=True, default="")
    started_at = models.DateTimeField(auto_now_add=True)
    finished_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Backup Restore Log"
        verbose_name_plural = "Backup Restore Logs"
        ordering = ["-started_at"]

    def __str__(self) -> str:
        return f"Restore of {self.backup_file} [{self.status}]"
