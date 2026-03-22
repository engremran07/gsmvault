from django.urls import path

from . import views

app_name = "forum"

urlpatterns = [
    # Index
    path("", views.forum_index, name="index"),
    # Search
    path("search/", views.forum_search, name="search"),
    # Private topics
    path("messages/", views.private_topics_list, name="private_topics"),
    path("messages/new/", views.private_topic_create, name="private_topic_create"),
    # Category
    path("c/<slug:slug>/", views.category_detail, name="category_detail"),
    path("c/<slug:category_slug>/new/", views.topic_create, name="topic_create"),
    # Topic
    path("t/<int:pk>/", views.topic_detail, name="topic_detail_short"),
    path("t/<int:pk>/<slug:slug>/", views.topic_detail, name="topic_detail"),
    # Topic actions
    path("t/<int:topic_pk>/reply/", views.reply_create, name="reply_create"),
    path("t/<int:topic_pk>/favorite/", views.toggle_favorite, name="toggle_favorite"),
    path("t/<int:topic_pk>/bookmark/", views.bookmark_update, name="bookmark_update"),
    path(
        "t/<int:topic_pk>/subscribe/",
        views.toggle_subscription,
        name="toggle_subscription",
    ),
    path("t/<int:pk>/close/", views.topic_close, name="topic_close"),
    path("t/<int:pk>/reopen/", views.topic_reopen, name="topic_reopen"),
    path("t/<int:pk>/pin/", views.topic_pin, name="topic_pin"),
    path("t/<int:pk>/unpin/", views.topic_unpin, name="topic_unpin"),
    # Reply actions
    path("reply/<int:pk>/edit/", views.reply_edit, name="reply_edit"),
    path("reply/<int:reply_pk>/like/", views.toggle_like, name="toggle_like"),
    path("reply/<int:pk>/history/", views.reply_history, name="reply_history"),
    path("reply/<int:pk>/remove/", views.reply_remove, name="reply_remove"),
    # Poll
    path("poll/<int:poll_pk>/vote/", views.poll_vote, name="poll_vote"),
    # Flag
    path("flag/", views.flag_content, name="flag_content"),
    # User
    path("user/<int:pk>/", views.user_topics, name="user_topics"),
]
