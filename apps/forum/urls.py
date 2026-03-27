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
    # --- Enrichment features ---
    # Reactions
    path("reply/<int:reply_pk>/react/", views.set_reaction, name="set_reaction"),
    # Best answer / solution
    path("reply/<int:reply_pk>/solution/", views.mark_solution, name="mark_solution"),
    path(
        "t/<int:topic_pk>/unsolution/",
        views.unmark_solution,
        name="unmark_solution",
    ),
    # Topic rating
    path("t/<int:topic_pk>/rate/", views.rate_topic, name="rate_topic"),
    # Topic tags
    path("t/<int:topic_pk>/tags/", views.update_tags, name="update_tags"),
    # Topic move / merge (moderation)
    path("t/<int:pk>/move/", views.topic_move, name="topic_move"),
    path("t/<int:pk>/merge/", views.topic_merge, name="topic_merge"),
    # Warnings (moderation)
    path("moderation/warn/", views.issue_warning, name="issue_warning"),
    path("moderation/warnings/", views.warning_list, name="warning_list"),
    # IP bans (moderation)
    path("moderation/ip-bans/", views.ip_ban_list, name="ip_ban_list"),
    path("moderation/ip-ban/", views.ip_ban, name="ip_ban"),
    path("moderation/ip-unban/", views.ip_unban, name="ip_unban"),
    # User ban
    path(
        "moderation/ban-user/<int:user_pk>/",
        views.ban_user,
        name="ban_user",
    ),
    path(
        "moderation/unban-user/<int:user_pk>/",
        views.unban_user,
        name="unban_user",
    ),
    # Category subscription (watch)
    path(
        "c/<slug:category_slug>/watch/",
        views.toggle_category_subscription,
        name="toggle_category_subscription",
    ),
    # Forum profile
    path("profile/edit/", views.edit_profile, name="edit_profile"),
    # Who's online
    path("online/", views.whos_online, name="whos_online"),
    # Leaderboard
    path("leaderboard/", views.leaderboard, name="leaderboard"),
    # --- 4PDA-style features ---
    # Wiki header (шапка)
    path(
        "t/<int:topic_pk>/wiki/edit/",
        views.edit_wiki_header,
        name="edit_wiki_header",
    ),
    path(
        "t/<int:topic_pk>/wiki/history/",
        views.wiki_header_history,
        name="wiki_header_history",
    ),
    # Useful post
    path(
        "reply/<int:reply_pk>/useful/",
        views.toggle_useful,
        name="toggle_useful",
    ),
    # FAQ entries
    path("t/<int:topic_pk>/faq/add/", views.add_faq, name="add_faq"),
    path("faq/<int:faq_pk>/remove/", views.remove_faq, name="remove_faq"),
    # Changelog
    path(
        "t/<int:topic_pk>/changelog/add/",
        views.add_changelog,
        name="add_changelog",
    ),
    path(
        "changelog/<int:entry_pk>/remove/",
        views.remove_changelog,
        name="remove_changelog",
    ),
    # Topic type
    path(
        "t/<int:topic_pk>/type/",
        views.change_topic_type,
        name="change_topic_type",
    ),
    # Device linking
    path(
        "t/<int:topic_pk>/device/link/",
        views.link_device,
        name="link_device",
    ),
    # Attachment download counter
    path(
        "attachment/<int:attachment_pk>/download/",
        views.download_attachment,
        name="download_attachment",
    ),
    # Attachment upload
    path(
        "reply/<int:reply_pk>/attachment/upload/",
        views.upload_attachment,
        name="upload_attachment",
    ),
]
