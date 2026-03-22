"""
Admin Suite API — DRF viewsets merged from apps.admin_audit.
"""

from __future__ import annotations

from rest_framework import permissions, serializers, viewsets

from .models import AdminAction, AuditLog, FieldChange


class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = ["id", "action", "model_name", "object_id", "user", "ip", "timestamp"]
        read_only_fields = fields


class AdminActionSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminAction
        fields = ["id", "user", "action_type", "description", "timestamp"]
        read_only_fields = fields


class FieldChangeSerializer(serializers.ModelSerializer):
    class Meta:
        model = FieldChange
        fields = ["id", "audit_log", "field_name", "old_value", "new_value"]
        read_only_fields = fields


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAdminUser]


class AdminActionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AdminAction.objects.all()
    serializer_class = AdminActionSerializer
    permission_classes = [permissions.IsAdminUser]
