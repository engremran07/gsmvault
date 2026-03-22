from rest_framework import permissions, serializers, viewsets

from .models import APIEndpoint, APIKey, APIUsageLog


class APIKeySerializer(serializers.ModelSerializer):
    class Meta:
        model = APIKey
        fields = [
            "id",
            "name",
            "key_prefix",
            "scopes",
            "is_active",
            "last_used_at",
            "created_at",
        ]
        read_only_fields = ["id", "key_prefix", "last_used_at", "created_at"]


class APIEndpointSerializer(serializers.ModelSerializer):
    class Meta:
        model = APIEndpoint
        fields = ["id", "path", "method", "description", "rate_limit", "is_deprecated"]


class APIUsageLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = APIUsageLog
        fields = [
            "id",
            "endpoint",
            "method",
            "response_code",
            "latency_ms",
            "timestamp",
        ]
        read_only_fields = fields


class APIKeyViewSet(viewsets.ModelViewSet):
    serializer_class = APIKeySerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return APIKey.objects.all()
        return APIKey.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class APIEndpointViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = APIEndpoint.objects.filter(is_deprecated=False)
    serializer_class = APIEndpointSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
