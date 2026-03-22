from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .api import CategoryViewSet, ReplyViewSet, TopicViewSet

router = DefaultRouter()
router.register(r"categories", CategoryViewSet, basename="forum-category")
router.register(r"topics", TopicViewSet, basename="forum-topic")
router.register(r"replies", ReplyViewSet, basename="forum-reply")

app_name = "forum_api"

urlpatterns = [
    path("", include(router.urls)),
]
