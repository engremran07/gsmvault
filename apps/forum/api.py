"""Forum REST API — DRF serializers + viewsets."""

from __future__ import annotations

from typing import TYPE_CHECKING, cast

from rest_framework import permissions, serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response

from . import services

if TYPE_CHECKING:
    from django.contrib.auth.base_user import AbstractBaseUser
from .models import (
    ForumCategory,
    ForumPoll,
    ForumPollChoice,
    ForumReply,
    ForumTopic,
    ForumTopicSubscription,
)

# ---------------------------------------------------------------------------
# Serializers
# ---------------------------------------------------------------------------


class CategorySerializer(serializers.ModelSerializer[ForumCategory]):
    children = serializers.SerializerMethodField()

    class Meta:
        model = ForumCategory
        fields = [
            "id",
            "parent",
            "title",
            "slug",
            "description",
            "color",
            "icon",
            "sort_order",
            "is_closed",
            "is_private",
            "topic_count",
            "reply_count",
            "last_active",
            "children",
            "created_at",
        ]
        read_only_fields = ["topic_count", "reply_count", "last_active", "created_at"]

    def get_children(self, obj: ForumCategory) -> list[dict[str, object]]:
        children = ForumCategory.objects.filter(
            parent=obj, is_removed=False, is_visible=True
        )
        return CategorySerializer(children, many=True).data  # type: ignore[return-value]


class TopicListSerializer(serializers.ModelSerializer[ForumTopic]):
    username = serializers.CharField(source="user.username", read_only=True)
    category_title = serializers.CharField(source="category.title", read_only=True)
    category_slug = serializers.CharField(source="category.slug", read_only=True)

    class Meta:
        model = ForumTopic
        fields = [
            "id",
            "title",
            "slug",
            "category",
            "category_title",
            "category_slug",
            "user",
            "username",
            "is_pinned",
            "is_globally_pinned",
            "is_closed",
            "view_count",
            "reply_count",
            "last_active",
            "created_at",
        ]
        read_only_fields = fields


class TopicDetailSerializer(serializers.ModelSerializer[ForumTopic]):
    username = serializers.CharField(source="user.username", read_only=True)
    category_title = serializers.CharField(source="category.title", read_only=True)

    class Meta:
        model = ForumTopic
        fields = [
            "id",
            "title",
            "slug",
            "content",
            "content_html",
            "category",
            "category_title",
            "user",
            "username",
            "is_pinned",
            "is_globally_pinned",
            "is_closed",
            "view_count",
            "reply_count",
            "last_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "slug",
            "content_html",
            "user",
            "username",
            "view_count",
            "reply_count",
            "last_active",
            "created_at",
            "updated_at",
        ]


class TopicCreateSerializer(serializers.Serializer):  # type: ignore[type-arg]
    title = serializers.CharField(max_length=255)
    content = serializers.CharField()
    category_id = serializers.IntegerField()


class ReplySerializer(serializers.ModelSerializer[ForumReply]):
    username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = ForumReply
        fields = [
            "id",
            "topic",
            "user",
            "username",
            "content",
            "content_html",
            "action",
            "is_modified",
            "modified_count",
            "likes_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "topic",
            "user",
            "username",
            "content_html",
            "action",
            "is_modified",
            "modified_count",
            "likes_count",
            "created_at",
            "updated_at",
        ]


class ReplyCreateSerializer(serializers.Serializer):  # type: ignore[type-arg]
    content = serializers.CharField()


class PollChoiceSerializer(serializers.ModelSerializer[ForumPollChoice]):
    class Meta:
        model = ForumPollChoice
        fields = ["id", "description", "vote_count", "sort_order"]
        read_only_fields = fields


class PollSerializer(serializers.ModelSerializer[ForumPoll]):
    choices = PollChoiceSerializer(many=True, read_only=True)

    class Meta:
        model = ForumPoll
        fields = [
            "id",
            "topic",
            "title",
            "mode",
            "is_secret",
            "close_at",
            "is_closed",
            "vote_count",
            "choices",
            "created_at",
        ]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------


class IsStaffOrReadOnly(permissions.BasePermission):
    def has_permission(self, request: Request, view: object) -> bool:
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(request.user and request.user.is_staff)  # type: ignore[union-attr]


# ---------------------------------------------------------------------------
# ViewSets
# ---------------------------------------------------------------------------


class CategoryViewSet(viewsets.ModelViewSet[ForumCategory]):
    serializer_class = CategorySerializer
    permission_classes = [IsStaffOrReadOnly]
    lookup_field = "slug"

    def get_queryset(self):  # type: ignore[override]
        return ForumCategory.objects.filter(
            is_removed=False, is_visible=True, parent__isnull=True
        ).order_by("sort_order")


class TopicViewSet(viewsets.ModelViewSet[ForumTopic]):
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_serializer_class(self):  # type: ignore[override]
        if self.action == "create":
            return TopicCreateSerializer
        if self.action in ("list",):
            return TopicListSerializer
        return TopicDetailSerializer

    def get_queryset(self):  # type: ignore[override]
        qs = (
            ForumTopic.objects.filter(is_removed=False)
            .select_related("category", "user")
            .order_by("-last_active")
        )
        category = self.request.query_params.get("category")
        if category:
            qs = qs.filter(category__slug=category)
        return qs

    def create(self, request: Request, *args: object, **kwargs: object) -> Response:
        ser = TopicCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        category = ForumCategory.objects.filter(
            pk=ser.validated_data["category_id"]
        ).first()
        if not category:
            return Response(
                {"error": "Category not found"}, status=status.HTTP_404_NOT_FOUND
            )

        topic = services.create_topic(
            user=cast("AbstractBaseUser", request.user),
            category=category,
            title=ser.validated_data["title"],
            content=ser.validated_data["content"],
        )
        return Response(
            TopicDetailSerializer(topic).data, status=status.HTTP_201_CREATED
        )

    @action(
        detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated]
    )
    def favorite(self, request: Request, pk: int | None = None) -> Response:
        topic = self.get_object()
        is_fav = services.toggle_favorite(topic, cast("AbstractBaseUser", request.user))
        return Response({"is_favorited": is_fav})

    @action(
        detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated]
    )
    def subscribe(self, request: Request, pk: int | None = None) -> Response:
        topic = self.get_object()
        sub = ForumTopicSubscription.objects.filter(
            topic=topic, user=request.user
        ).first()
        if sub:
            sub.delete()
            return Response({"is_subscribed": False})
        services.subscribe(topic, cast("AbstractBaseUser", request.user))
        return Response({"is_subscribed": True})


class ReplyViewSet(viewsets.ModelViewSet[ForumReply]):
    serializer_class = ReplySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):  # type: ignore[override]
        qs = ForumReply.objects.filter(is_removed=False).select_related("user")
        topic = self.request.query_params.get("topic")
        if topic:
            qs = qs.filter(topic_id=topic)
        return qs.order_by("created_at")

    def create(self, request: Request, *args: object, **kwargs: object) -> Response:
        ser = ReplyCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        topic_id = request.data.get("topic")
        topic = ForumTopic.objects.filter(pk=topic_id, is_removed=False).first()
        if not topic:
            return Response(
                {"error": "Topic not found"}, status=status.HTTP_404_NOT_FOUND
            )

        reply = services.create_reply(
            topic=topic,
            user=cast("AbstractBaseUser", request.user),
            content=ser.validated_data["content"],
        )
        return Response(ReplySerializer(reply).data, status=status.HTTP_201_CREATED)

    @action(
        detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated]
    )
    def like(self, request: Request, pk: int | None = None) -> Response:
        reply = self.get_object()
        is_liked = services.toggle_like(reply, cast("AbstractBaseUser", request.user))
        reply.refresh_from_db(fields=["likes_count"])
        return Response({"is_liked": is_liked, "likes_count": reply.likes_count})
