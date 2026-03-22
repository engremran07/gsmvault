from rest_framework import permissions, serializers, viewsets

from .models import Appeal, ModerationItem, ModerationRule


class ModerationRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = ModerationRule
        fields = ["id", "name", "action", "severity", "is_active"]


class ModerationItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ModerationItem
        fields = [
            "id",
            "content_type",
            "object_id",
            "status",
            "report_reason",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class AppealSerializer(serializers.ModelSerializer):
    class Meta:
        model = Appeal
        fields = ["id", "item", "user", "reason", "status", "created_at"]
        read_only_fields = ["id", "created_at"]


class ModerationRuleViewSet(viewsets.ModelViewSet):
    queryset = ModerationRule.objects.all()
    serializer_class = ModerationRuleSerializer
    permission_classes = [permissions.IsAdminUser]


class ModerationItemViewSet(viewsets.ModelViewSet):
    queryset = ModerationItem.objects.all()
    serializer_class = ModerationItemSerializer
    permission_classes = [permissions.IsAdminUser]


class AppealViewSet(viewsets.ModelViewSet):
    queryset = Appeal.objects.all()
    serializer_class = AppealSerializer
    permission_classes = [permissions.IsAdminUser]
