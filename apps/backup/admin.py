from django.contrib import admin

from .models import BackupFile, BackupRestoreLog, BackupSchedule


@admin.register(BackupSchedule)
class BackupScheduleAdmin(admin.ModelAdmin[BackupSchedule]):
    list_display = [
        "name",
        "backup_type",
        "frequency_hours",
        "destination",
        "is_active",
        "last_run",
    ]
    list_filter = ["backup_type", "is_active", "destination"]


@admin.register(BackupFile)
class BackupFileAdmin(admin.ModelAdmin[BackupFile]):
    list_display = ["file_path", "schedule", "status", "size_bytes", "started_at"]
    list_filter = ["status"]
    readonly_fields = ["started_at"]


@admin.register(BackupRestoreLog)
class BackupRestoreLogAdmin(admin.ModelAdmin[BackupRestoreLog]):
    list_display = ["backup_file", "initiated_by", "status", "started_at"]
    list_filter = ["status"]
    readonly_fields = ["started_at"]
