from rest_framework import permissions, serializers, viewsets

from .models import ActivityFeed, Following, Profile, Reputation


class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = [
            "id",
            "user",
            "bio",
            "website",
            "location",
            "social_links",
            "is_public",
            "updated_at",
        ]
        read_only_fields = ["id", "user"]


class ReputationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reputation
        fields = ["id", "user", "total_score", "fw_contributions", "downloads_helped"]
        read_only_fields = fields


class FollowingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Following
        fields = ["id", "follower", "following", "created_at"]
        read_only_fields = ["id", "follower", "created_at"]


class ActivityFeedSerializer(serializers.ModelSerializer):
    class Meta:
        model = ActivityFeed
        fields = ["id", "action_type", "object_id", "metadata", "created_at"]
        read_only_fields = fields


class ProfileViewSet(viewsets.ModelViewSet):
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return Profile.objects.all()
        return Profile.objects.filter(user=self.request.user)


class FollowingViewSet(viewsets.ModelViewSet):
    serializer_class = FollowingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Following.objects.filter(follower=self.request.user)

    def perform_create(self, serializer):
        serializer.save(follower=self.request.user)


class ActivityFeedViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ActivityFeedSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ActivityFeed.objects.filter(user=self.request.user)
