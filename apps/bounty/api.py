from rest_framework import permissions, serializers, viewsets

from .models import BountyRequest, BountySubmission, PeerReview


class BountyRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = BountyRequest
        fields = [
            "id",
            "title",
            "request_type",
            "user",
            "device",
            "brand",
            "device_model",
            "fw_version_wanted",
            "description",
            "what_tried",
            "reward_amount",
            "status",
            "resolution_type",
            "resolution_note",
            "created_at",
        ]
        read_only_fields = ["id", "user", "status", "resolution_type", "created_at"]


class BountySubmissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = BountySubmission
        fields = [
            "id",
            "request",
            "user",
            "firmware",
            "notes",
            "is_confirmed",
            "status",
            "created_at",
        ]
        read_only_fields = ["id", "user", "status", "is_confirmed", "created_at"]


class PeerReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = PeerReview
        fields = ["id", "submission", "reviewer", "verdict", "notes", "created_at"]
        read_only_fields = ["id", "reviewer", "created_at"]


class BountyRequestViewSet(viewsets.ModelViewSet):
    queryset = BountyRequest.objects.all()
    serializer_class = BountyRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class BountySubmissionViewSet(viewsets.ModelViewSet):
    queryset = BountySubmission.objects.all()
    serializer_class = BountySubmissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class PeerReviewViewSet(viewsets.ModelViewSet):
    queryset = PeerReview.objects.all()
    serializer_class = PeerReviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(reviewer=self.request.user)
