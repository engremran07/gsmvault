from rest_framework import permissions, serializers, viewsets

from .models import BackupFile, BackupSchedule


class BackupScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = BackupSchedule
        fields = [
            "id",
            "name",
            "backup_type",
            "frequency_hours",
            "destination",
            "is_active",
            "last_run",
        ]


class BackupFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = BackupFile
        fields = [
            "id",
            "schedule",
            "file_path",
            "size_bytes",
            "status",
            "started_at",
            "completed_at",
        ]
        read_only_fields = fields


class BackupScheduleViewSet(viewsets.ModelViewSet):
    queryset = BackupSchedule.objects.all()
    serializer_class = BackupScheduleSerializer
    permission_classes = [permissions.IsAdminUser]


class BackupFileViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = BackupFile.objects.all()
    serializer_class = BackupFileSerializer
    permission_classes = [permissions.IsAdminUser]
