from __future__ import annotations

import logging
from datetime import timedelta
from functools import wraps
from typing import TYPE_CHECKING, cast

from django.contrib import messages
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.db.models import Exists, OuterRef, Prefetch
from django.http import HttpRequest, HttpResponse, HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_POST

from apps.core.utils.ip import get_client_ip as get_request_ip
from apps.users.services.rate_limit import allow_action

if TYPE_CHECKING:
    from django.contrib.auth.base_user import AbstractBaseUser

from . import services
from .forms import (
    ChangelogEntryForm,
    DeviceLinkForm,
    FAQEntryForm,
    FlagForm,
    IPBanForm,
    PollVoteForm,
    PrivateTopicForm,
    ReplyCreateForm,
    ReplyEditForm,
    SearchForm,
    SignatureForm,
    TopicCreateForm,
    TopicMergeForm,
    TopicMoveForm,
    TopicRatingForm,
    TopicTagForm,
    TopicTypeForm,
    WarningForm,
    WikiHeaderForm,
)
from .models import (
    ForumAttachment,
    ForumBestAnswer,
    ForumCategory,
    ForumCategorySubscription,
    ForumChangelog,
    ForumFAQEntry,
    ForumIPBan,
    ForumLike,
    ForumOnlineUser,
    ForumPoll,
    ForumPollChoice,
    ForumPrivateTopicUser,
    ForumReaction,
    ForumReply,
    ForumReplyReaction,
    ForumTopic,
    ForumTopicFavorite,
    ForumTopicRating,
    ForumTopicSubscription,
    ForumTopicTag,
    ForumUsefulPost,
    ForumUserProfile,
    ForumWarning,
    ForumWikiHeaderHistory,
)

logger = logging.getLogger(__name__)
User = get_user_model()


def _user(request: HttpRequest) -> AbstractBaseUser:
    """Cast request.user for type checker — only call after @login_required."""
    return cast("AbstractBaseUser", request.user)


def _forum_rate_limit(
    *,
    scope: str,
    max_attempts: int = 20,
    window_seconds: int = 60,
):
    """Apply per-user/IP rate limiting to forum mutation views."""

    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request: HttpRequest, *args, **kwargs):
            key_parts = [f"scope:{scope}"]
            if request.user.is_authenticated:
                key_parts.append(f"user:{request.user.pk}")
            key_parts.append(f"ip:{get_request_ip(request) or 'anon'}")
            key = "forum:rl:" + ":".join(key_parts)

            if not allow_action(
                key,
                max_attempts=max_attempts,
                window_seconds=window_seconds,
            ):
                return HttpResponse("Too many requests.", status=429)

            return view_func(request, *args, **kwargs)

        return wrapper

    return decorator


# ---------------------------------------------------------------------------
# Forum index (category listing)
# ---------------------------------------------------------------------------


def forum_index(request: HttpRequest) -> HttpResponse:
    categories = (
        ForumCategory.objects.filter(
            parent__isnull=True, is_removed=False, is_visible=True
        )
        .prefetch_related(
            Prefetch(
                "children",
                queryset=ForumCategory.objects.filter(
                    is_removed=False, is_visible=True
                ).order_by("sort_order"),
            )
        )
        .order_by("sort_order")
    )

    # Filter private categories for non-authenticated users
    if not request.user.is_authenticated:
        categories = categories.filter(is_private=False)

    template = "forum/forum_index.html"
    if request.headers.get("HX-Request"):
        template = "forum/fragments/category_cards.html"

    # Landing page enrichment data
    stats = services.get_forum_stats()
    trending = services.get_trending_topics()
    recent_topics = services.get_recent_topics()
    latest_replies = services.get_latest_replies()
    online_users = services.get_online_users()

    return render(
        request,
        template,
        {
            "categories": categories,
            "stats": stats,
            "trending_topics": trending,
            "recent_topics": recent_topics,
            "latest_replies": latest_replies,
            "online_users": online_users,
        },
    )


# ---------------------------------------------------------------------------
# Category detail (topic listing)
# ---------------------------------------------------------------------------


def category_detail(request: HttpRequest, slug: str) -> HttpResponse:
    category = get_object_or_404(
        ForumCategory, slug=slug, is_removed=False, is_visible=True
    )

    if category.is_private and (
        not request.user.is_authenticated or not request.user.is_staff  # type: ignore[union-attr]
    ):
        return HttpResponseForbidden("This category is private.")

    topics = (
        ForumTopic.objects.filter(category=category, is_removed=False)
        .select_related("user", "last_reply_user")
        .order_by("-is_globally_pinned", "-is_pinned", "-last_active")
    )

    # Subcategories
    subcategories = category.children.filter(  # type: ignore[attr-defined]
        is_removed=False, is_visible=True
    ).order_by("sort_order")  # type: ignore[attr-defined]

    # Search within category
    q = request.GET.get("q", "").strip()
    if q:
        topics = topics.filter(title__icontains=q)

    template = "forum/category_detail.html"
    if request.headers.get("HX-Request"):
        template = "forum/fragments/topic_list.html"

    return render(
        request,
        template,
        {
            "category": category,
            "subcategories": subcategories,
            "topics": topics[:50],
            "search_query": q,
        },
    )


# ---------------------------------------------------------------------------
# Topic detail (reply listing)
# ---------------------------------------------------------------------------


def topic_detail(request: HttpRequest, pk: int, slug: str = "") -> HttpResponse:
    topic = get_object_or_404(
        ForumTopic.objects.select_related("category", "user", "last_reply_user"),
        pk=pk,
        is_removed=False,
    )

    # Access check for private topics
    if not services.can_view_topic(
        topic, _user(request) if request.user.is_authenticated else None
    ):
        return HttpResponseForbidden("You don't have access to this topic.")

    # Increment view
    services.increment_view_count(topic)

    replies = (
        ForumReply.objects.filter(topic=topic)
        .visible()  # type: ignore[attr-defined]
        .select_related("user")
        .order_by("created_at")
    )

    # Annotate likes for current user
    if request.user.is_authenticated:
        replies = replies.annotate(
            user_liked=Exists(
                ForumLike.objects.filter(reply=OuterRef("pk"), user=request.user)
            )
        )

    # Get bookmark position
    bookmark_pos = 0
    if request.user.is_authenticated:
        bookmark_pos = services.get_bookmark(topic, _user(request))

    # Polls
    polls = ForumPoll.objects.filter(topic=topic).prefetch_related("choices")

    # User state
    is_favorited = False
    is_subscribed = False
    if request.user.is_authenticated:
        is_favorited = ForumTopicFavorite.objects.filter(
            topic=topic, user=request.user
        ).exists()
        is_subscribed = ForumTopicSubscription.objects.filter(
            topic=topic, user=request.user
        ).exists()

    # Best answer
    best_answer = ForumBestAnswer.objects.filter(topic=topic).first()

    # Topic tags
    topic_tags = ForumTopicTag.objects.filter(topic=topic)

    # User's rating
    user_rating = None
    if request.user.is_authenticated:
        user_rating = ForumTopicRating.objects.filter(
            topic=topic, user=request.user
        ).first()

    # Similar topics
    similar_topics = services.find_similar_topics(topic, limit=5)

    # Reactions (available types)
    available_reactions = ForumReaction.objects.filter(is_active=True)

    # User reactions map (reply_id -> reaction_id)
    user_reactions: dict[int, int] = {}
    if request.user.is_authenticated:
        user_reactions = dict(
            ForumReplyReaction.objects.filter(
                reply__topic=topic, user=request.user
            ).values_list("reply_id", "reaction_id")
        )

    # Online users count (for the sidebar)
    online_count = ForumOnlineUser.objects.filter(
        last_seen__gte=timezone.now() - timedelta(minutes=15)
    ).count()

    # Update online presence
    if request.user.is_authenticated:
        services.update_online_presence(
            _user(request), location=f"Viewing: {topic.title}"
        )

    # 4PDA — Useful post counts
    useful_counts: dict[int, int] = {}
    user_useful_marks: set[int] = set()
    if request.user.is_authenticated:
        user_useful_marks = set(
            ForumUsefulPost.objects.filter(
                reply__topic=topic, user=request.user
            ).values_list("reply_id", flat=True)
        )
    for reply_obj in replies:
        useful_counts[reply_obj.pk] = ForumUsefulPost.objects.filter(
            reply_id=reply_obj.pk
        ).count()

    # 4PDA — FAQ entries
    faq_entries = ForumFAQEntry.objects.filter(topic=topic).select_related(
        "reply", "reply__user"
    )

    # 4PDA — Changelog
    changelog_entries = ForumChangelog.objects.filter(topic=topic)

    # 4PDA — Wiki header history count
    wiki_edit_count = ForumWikiHeaderHistory.objects.filter(topic=topic).count()

    template = "forum/topic_detail.html"
    if request.headers.get("HX-Request") and request.GET.get("fragment") == "replies":
        template = "forum/fragments/reply_list.html"

    return render(
        request,
        template,
        {
            "topic": topic,
            "replies": replies,
            "bookmark_pos": bookmark_pos,
            "polls": polls,
            "is_favorited": is_favorited,
            "is_subscribed": is_subscribed,
            "reply_form": ReplyCreateForm(),
            "flag_form": FlagForm(),
            "best_answer": best_answer,
            "topic_tags": topic_tags,
            "user_rating": user_rating,
            "similar_topics": similar_topics,
            "available_reactions": available_reactions,
            "user_reactions": user_reactions,
            "online_count": online_count,
            "rating_form": TopicRatingForm(),
            # 4PDA context
            "useful_counts": useful_counts,
            "user_useful_marks": user_useful_marks,
            "faq_entries": faq_entries,
            "changelog_entries": changelog_entries,
            "wiki_edit_count": wiki_edit_count,
            "wiki_header_form": WikiHeaderForm(initial={"content": topic.wiki_header}),
            "changelog_form": ChangelogEntryForm(),
            "faq_form": FAQEntryForm(),
        },
    )


# ---------------------------------------------------------------------------
# Topic CRUD
# ---------------------------------------------------------------------------


@login_required
def topic_create(request: HttpRequest, category_slug: str) -> HttpResponse:
    category = get_object_or_404(
        ForumCategory, slug=category_slug, is_removed=False, is_visible=True
    )

    if category.is_closed:
        messages.error(request, "This category is closed for new topics.")
        return redirect("forum:category_detail", slug=category.slug)

    if request.method == "POST":
        form = TopicCreateForm(request.POST)
        if form.is_valid():
            ip = _get_client_ip(request)
            topic = services.create_topic(
                user=_user(request),
                category=category,
                title=form.cleaned_data["title"],
                content=form.cleaned_data["content"],
                ip_address=ip,
            )
            # Create poll if provided
            poll_title = form.cleaned_data.get("poll_title")
            poll_choices = form.cleaned_data.get("poll_choices")
            if poll_title and poll_choices:
                services.create_poll(
                    topic=topic,
                    title=poll_title,
                    choices=poll_choices,
                    mode=form.cleaned_data.get("poll_mode", "single"),
                    is_secret=form.cleaned_data.get("poll_secret", False),
                    close_at=form.cleaned_data.get("poll_close_at"),
                )

            messages.success(request, "Topic created!")
            return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)
    else:
        form = TopicCreateForm()

    return render(
        request,
        "forum/topic_create.html",
        {
            "category": category,
            "form": form,
        },
    )


# ---------------------------------------------------------------------------
# Replies
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="reply_create", max_attempts=10, window_seconds=60)
def reply_create(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk, is_removed=False)

    if topic.is_closed:
        messages.error(request, "This topic is closed.")
        return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)

    form = ReplyCreateForm(request.POST)
    if form.is_valid():
        ip = _get_client_ip(request)
        reply = services.create_reply(
            topic=topic,
            user=_user(request),
            content=form.cleaned_data["content"],
            ip_address=ip,
        )
        if request.headers.get("HX-Request"):
            return render(
                request,
                "forum/fragments/reply_item.html",
                {"reply": reply, "topic": topic},
            )
        return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)

    messages.error(request, "Please correct the errors below.")
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
def reply_edit(request: HttpRequest, pk: int) -> HttpResponse:
    reply = get_object_or_404(ForumReply, pk=pk, is_removed=False)

    if reply.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden("You can only edit your own replies.")

    if request.method == "POST":
        form = ReplyEditForm(request.POST)
        if form.is_valid():
            services.edit_reply(
                reply, user=_user(request), new_content=form.cleaned_data["content"]
            )
            if request.headers.get("HX-Request"):
                reply.refresh_from_db()
                return render(
                    request,
                    "forum/fragments/reply_item.html",
                    {"reply": reply, "topic": reply.topic},
                )
            return redirect(
                "forum:topic_detail", pk=reply.topic.pk, slug=reply.topic.slug
            )
    else:
        form = ReplyEditForm(initial={"content": reply.content})

    if request.headers.get("HX-Request"):
        return render(
            request,
            "forum/fragments/reply_edit_form.html",
            {"form": form, "reply": reply},
        )

    return render(request, "forum/reply_edit.html", {"form": form, "reply": reply})


# ---------------------------------------------------------------------------
# Reply history
# ---------------------------------------------------------------------------


def reply_history(request: HttpRequest, pk: int) -> HttpResponse:
    reply = get_object_or_404(ForumReply, pk=pk)
    history = reply.history.all()  # type: ignore[attr-defined]
    return render(
        request,
        "forum/fragments/reply_history.html",
        {"reply": reply, "history": history},
    )


# ---------------------------------------------------------------------------
# Likes
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="toggle_like", max_attempts=60, window_seconds=60)
def toggle_like(request: HttpRequest, reply_pk: int) -> HttpResponse:
    reply = get_object_or_404(ForumReply, pk=reply_pk, is_removed=False)
    is_liked = services.toggle_like(reply, _user(request))
    reply.refresh_from_db(fields=["likes_count"])

    if request.headers.get("HX-Request"):
        return render(
            request,
            "forum/fragments/like_button.html",
            {
                "reply": reply,
                "user_liked": is_liked,
            },
        )
    return redirect("forum:topic_detail", pk=reply.topic.pk, slug=reply.topic.slug)


# ---------------------------------------------------------------------------
# Favorites
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="toggle_favorite", max_attempts=30, window_seconds=60)
def toggle_favorite(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk, is_removed=False)
    is_fav = services.toggle_favorite(topic, _user(request))

    if request.headers.get("HX-Request"):
        return render(
            request,
            "forum/fragments/favorite_button.html",
            {
                "topic": topic,
                "is_favorited": is_fav,
            },
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# Bookmarks (silent HTMX)
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="bookmark_update", max_attempts=30, window_seconds=60)
def bookmark_update(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)
    try:
        reply_number = int(request.POST.get("reply_number", 0))
    except (ValueError, TypeError):
        reply_number = 0
    services.update_bookmark(topic, _user(request), reply_number)
    return HttpResponse(status=204)


# ---------------------------------------------------------------------------
# Subscriptions
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="toggle_subscription", max_attempts=30, window_seconds=60)
def toggle_subscription(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)
    sub = ForumTopicSubscription.objects.filter(topic=topic, user=request.user).first()
    if sub:
        sub.delete()
        is_subscribed = False
    else:
        services.subscribe(topic, _user(request))
        is_subscribed = True

    if request.headers.get("HX-Request"):
        return render(
            request,
            "forum/fragments/subscribe_button.html",
            {
                "topic": topic,
                "is_subscribed": is_subscribed,
            },
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# Polls
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="poll_vote", max_attempts=20, window_seconds=60)
def poll_vote(request: HttpRequest, poll_pk: int) -> HttpResponse:
    poll = get_object_or_404(ForumPoll.objects.prefetch_related("choices"), pk=poll_pk)

    form = PollVoteForm(request.POST)
    if form.is_valid():
        choice_id = form.cleaned_data.get("choice_id")
        choice = get_object_or_404(ForumPollChoice, pk=choice_id, poll=poll)
        services.cast_vote(poll, choice, _user(request))

    poll.refresh_from_db()
    if request.headers.get("HX-Request"):
        return render(request, "forum/fragments/poll_results.html", {"poll": poll})
    return redirect("forum:topic_detail", pk=poll.topic.pk, slug=poll.topic.slug)


# ---------------------------------------------------------------------------
# Flagging
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="flag_content", max_attempts=10, window_seconds=60)
def flag_content(request: HttpRequest) -> HttpResponse:
    form = FlagForm(request.POST)
    if form.is_valid():
        topic_pk = request.POST.get("topic_pk")
        reply_pk = request.POST.get("reply_pk")
        topic = ForumTopic.objects.filter(pk=topic_pk).first() if topic_pk else None
        reply = ForumReply.objects.filter(pk=reply_pk).first() if reply_pk else None

        services.create_flag(
            user=_user(request),
            topic=topic,
            reply=reply,
            reason=form.cleaned_data["reason"],
            detail=form.cleaned_data["detail"],
        )
        messages.success(request, "Content flagged for review. Thank you.")

    if request.headers.get("HX-Request"):
        return HttpResponse('<span class="text-green-400">Flagged</span>')

    # Redirect back
    referer = request.META.get("HTTP_REFERER", "/forum/")
    return redirect(referer)


# ---------------------------------------------------------------------------
# Private topics
# ---------------------------------------------------------------------------


@login_required
def private_topics_list(request: HttpRequest) -> HttpResponse:
    memberships = ForumPrivateTopicUser.objects.filter(
        user=request.user
    ).select_related("private_topic__topic__user", "private_topic__topic__category")

    topics = [m.private_topic.topic for m in memberships]

    template = "forum/private_topics.html"
    if request.headers.get("HX-Request"):
        template = "forum/fragments/private_topic_list.html"

    return render(request, template, {"topics": topics})


@login_required
def private_topic_create(request: HttpRequest) -> HttpResponse:
    # Need a private category — get or create one
    private_cat, _ = ForumCategory.objects.get_or_create(
        slug="private-messages",
        defaults={
            "title": "Private Messages",
            "is_private": True,
            "is_visible": False,
            "icon": "lock",
        },
    )

    if request.method == "POST":
        form = PrivateTopicForm(request.POST)
        if form.is_valid():
            usernames = form.cleaned_data["invite_usernames"]
            users = User.objects.filter(username__in=usernames)
            if not users.exists():
                messages.error(request, "No valid users found.")
            else:
                user_ids = list(users.values_list("pk", flat=True))
                topic = services.create_private_topic(
                    user=_user(request),
                    category=private_cat,
                    title=form.cleaned_data["title"],
                    content=form.cleaned_data["content"],
                    invite_user_ids=user_ids,
                    ip_address=_get_client_ip(request),
                )
                messages.success(request, "Private conversation started!")
                return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)
    else:
        form = PrivateTopicForm()

    return render(request, "forum/private_topic_create.html", {"form": form})


# ---------------------------------------------------------------------------
# Search
# ---------------------------------------------------------------------------


def forum_search(request: HttpRequest) -> HttpResponse:
    form = SearchForm(request.GET or None)
    results = []
    query = ""
    if form.is_valid():
        query = form.cleaned_data["q"]
        results = list(services.search_topics(query))

    template = "forum/search.html"
    if request.headers.get("HX-Request"):
        template = "forum/fragments/search_results.html"

    return render(request, template, {"form": form, "results": results, "query": query})


# ---------------------------------------------------------------------------
# User topics
# ---------------------------------------------------------------------------


def user_topics(request: HttpRequest, pk: int) -> HttpResponse:
    target_user = get_object_or_404(User, pk=pk)
    topics = (
        ForumTopic.objects.filter(user=target_user, is_removed=False)
        .select_related("category")
        .order_by("-created_at")[:50]
    )
    return render(
        request,
        "forum/user_topics.html",
        {"target_user": target_user, "topics": topics},
    )


# ---------------------------------------------------------------------------
# Moderation actions (staff only)
# ---------------------------------------------------------------------------


@login_required
@require_POST
def topic_close(request: HttpRequest, pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    topic = get_object_or_404(ForumTopic, pk=pk)
    services.close_topic(topic, user=_user(request))
    messages.success(request, "Topic closed.")
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
@require_POST
def topic_reopen(request: HttpRequest, pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    topic = get_object_or_404(ForumTopic, pk=pk)
    services.reopen_topic(topic, user=_user(request))
    messages.success(request, "Topic reopened.")
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
@require_POST
def topic_pin(request: HttpRequest, pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    topic = get_object_or_404(ForumTopic, pk=pk)
    globally = request.POST.get("globally") == "1"
    services.pin_topic(topic, user=_user(request), globally=globally)
    messages.success(request, "Topic pinned.")
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
@require_POST
def topic_unpin(request: HttpRequest, pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    topic = get_object_or_404(ForumTopic, pk=pk)
    services.unpin_topic(topic, user=_user(request))
    messages.success(request, "Topic unpinned.")
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
@require_POST
def reply_remove(request: HttpRequest, pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    reply = get_object_or_404(ForumReply, pk=pk)
    services.remove_reply(reply)
    messages.success(request, "Reply removed.")
    return redirect("forum:topic_detail", pk=reply.topic.pk, slug=reply.topic.slug)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _get_client_ip(request: HttpRequest) -> str | None:
    ip = get_request_ip(request)
    return ip or None


# ---------------------------------------------------------------------------
# Reactions (XenForo-style — set/change reaction on a reply)
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="set_reaction", max_attempts=60, window_seconds=60)
def set_reaction(request: HttpRequest, reply_pk: int) -> HttpResponse:
    reply = get_object_or_404(ForumReply, pk=reply_pk, is_removed=False)
    reaction_id = request.POST.get("reaction_id")

    if not reaction_id:
        services.remove_reaction(reply, _user(request))
    else:
        reaction = get_object_or_404(ForumReaction, pk=reaction_id, is_active=True)
        services.set_reaction(reply, _user(request), reaction)

    reply.refresh_from_db(fields=["reaction_count", "likes_count"])
    if request.headers.get("HX-Request"):
        reactions = ForumReplyReaction.objects.filter(reply=reply).select_related(
            "reaction"
        )
        user_reaction = ForumReplyReaction.objects.filter(
            reply=reply, user=request.user
        ).first()
        return render(
            request,
            "forum/fragments/reaction_bar.html",
            {
                "reply": reply,
                "reactions": reactions,
                "user_reaction": user_reaction,
                "available_reactions": ForumReaction.objects.filter(is_active=True),
            },
        )
    return redirect("forum:topic_detail", pk=reply.topic.pk, slug=reply.topic.slug)


# ---------------------------------------------------------------------------
# Best Answer / Solution
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="mark_solution", max_attempts=20, window_seconds=60)
def mark_solution(request: HttpRequest, reply_pk: int) -> HttpResponse:
    reply = get_object_or_404(ForumReply, pk=reply_pk, is_removed=False)
    topic = reply.topic

    # Only topic author or staff can mark solution
    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden(
            "Only the topic author or staff can mark a solution."
        )

    services.mark_best_answer(topic, reply, _user(request))
    messages.success(request, "Reply marked as best answer!")

    if request.headers.get("HX-Request"):
        return render(
            request,
            "forum/fragments/solution_badge.html",
            {"reply": reply, "is_solution": True},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
@require_POST
@_forum_rate_limit(scope="unmark_solution", max_attempts=20, window_seconds=60)
def unmark_solution(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)

    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    services.unmark_best_answer(topic)
    messages.success(request, "Best answer removed.")
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# Topic Rating (vBulletin star rating)
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="rate_topic", max_attempts=20, window_seconds=60)
def rate_topic(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk, is_removed=False)
    form = TopicRatingForm(request.POST)
    if form.is_valid():
        services.rate_topic(topic, _user(request), form.cleaned_data["score"])

    topic.refresh_from_db(fields=["rating_score", "rating_count"])
    if request.headers.get("HX-Request"):
        user_rating = ForumTopicRating.objects.filter(
            topic=topic, user=request.user
        ).first()
        return render(
            request,
            "forum/fragments/topic_rating.html",
            {"topic": topic, "user_rating": user_rating},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# Topic Tags
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="update_tags", max_attempts=20, window_seconds=60)
def update_tags(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)

    # Only topic author or staff
    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    form = TopicTagForm(request.POST)
    if form.is_valid():
        services.set_topic_tags(topic, form.cleaned_data["tags"])

    if request.headers.get("HX-Request"):
        tags = ForumTopicTag.objects.filter(topic=topic)
        return render(
            request,
            "forum/fragments/topic_tags.html",
            {"topic": topic, "topic_tags": tags},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# Topic Move (moderation)
# ---------------------------------------------------------------------------


@login_required
@require_POST
def topic_move(request: HttpRequest, pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    topic = get_object_or_404(ForumTopic, pk=pk)
    form = TopicMoveForm(request.POST)
    if form.is_valid():
        to_cat = get_object_or_404(ForumCategory, pk=form.cleaned_data["to_category"])
        services.move_topic(
            topic,
            to_category=to_cat,
            moved_by=_user(request),
            reason=form.cleaned_data.get("reason", ""),
        )
        messages.success(request, f"Topic moved to {to_cat.title}.")
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# Topic Merge (moderation)
# ---------------------------------------------------------------------------


@login_required
@require_POST
def topic_merge(request: HttpRequest, pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    source = get_object_or_404(ForumTopic, pk=pk)
    form = TopicMergeForm(request.POST)
    if form.is_valid():
        target = get_object_or_404(ForumTopic, pk=form.cleaned_data["target_topic_id"])
        services.merge_topics(source, target, merged_by=_user(request))
        messages.success(request, f"Topic merged into '{target.title}'.")
        return redirect("forum:topic_detail", pk=target.pk, slug=target.slug)
    return redirect("forum:topic_detail", pk=source.pk, slug=source.slug)


# ---------------------------------------------------------------------------
# Warning System (moderation)
# ---------------------------------------------------------------------------


@login_required
@require_POST
def issue_warning(request: HttpRequest) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    form = WarningForm(request.POST)
    if form.is_valid():
        target_user = get_object_or_404(User, pk=form.cleaned_data["user_id"])
        services.issue_warning(
            user=target_user,
            issued_by=_user(request),
            reason=form.cleaned_data["reason"],
            severity=form.cleaned_data["severity"],
            points=form.cleaned_data["points"],
        )
        messages.success(request, f"Warning issued to {target_user.username}.")  # type: ignore[attr-defined]

    referer = request.META.get("HTTP_REFERER", "/forum/")
    return redirect(referer)


# ---------------------------------------------------------------------------
# IP Ban (moderation)
# ---------------------------------------------------------------------------


@login_required
@require_POST
def ip_ban(request: HttpRequest) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    form = IPBanForm(request.POST)
    if form.is_valid():
        services.ban_ip(
            ip_address=form.cleaned_data["ip_address"],
            banned_by=_user(request),
            reason=form.cleaned_data.get("reason", ""),
        )
        messages.success(request, f"IP {form.cleaned_data['ip_address']} banned.")

    referer = request.META.get("HTTP_REFERER", "/forum/")
    return redirect(referer)


@login_required
@require_POST
def ip_unban(request: HttpRequest) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    ip = request.POST.get("ip_address", "")
    if ip:
        services.unban_ip(ip)
        messages.success(request, f"IP {ip} unbanned.")
    referer = request.META.get("HTTP_REFERER", "/forum/")
    return redirect(referer)


# ---------------------------------------------------------------------------
# User Ban (moderation)
# ---------------------------------------------------------------------------


@login_required
@require_POST
def ban_user(request: HttpRequest, user_pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    target = get_object_or_404(User, pk=user_pk)
    reason = request.POST.get("reason", "")
    services.ban_user(target, reason=reason)
    messages.success(request, f"User {target.username} banned from forum.")  # type: ignore[attr-defined]
    referer = request.META.get("HTTP_REFERER", "/forum/")
    return redirect(referer)


@login_required
@require_POST
def unban_user(request: HttpRequest, user_pk: int) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    target = get_object_or_404(User, pk=user_pk)
    services.unban_user(target)
    messages.success(request, f"User {target.username} unbanned.")  # type: ignore[attr-defined]
    referer = request.META.get("HTTP_REFERER", "/forum/")
    return redirect(referer)


# ---------------------------------------------------------------------------
# Category Subscription (XenForo "Watch Forum")
# ---------------------------------------------------------------------------


@login_required
@require_POST
def toggle_category_subscription(
    request: HttpRequest, category_slug: str
) -> HttpResponse:
    category = get_object_or_404(ForumCategory, slug=category_slug)
    existing = ForumCategorySubscription.objects.filter(
        category=category, user=request.user
    ).first()
    if existing:
        existing.delete()
        is_watching = False
    else:
        services.subscribe_category(category, _user(request))
        is_watching = True

    if request.headers.get("HX-Request"):
        return render(
            request,
            "forum/fragments/watch_category_button.html",
            {"category": category, "is_watching": is_watching},
        )
    return redirect("forum:category_detail", slug=category.slug)


# ---------------------------------------------------------------------------
# Forum Profile & Signature
# ---------------------------------------------------------------------------


@login_required
def edit_profile(request: HttpRequest) -> HttpResponse:
    profile = services.get_or_create_forum_profile(_user(request))

    if request.method == "POST":
        form = SignatureForm(request.POST)
        if form.is_valid():
            profile.signature = form.cleaned_data["signature"]
            profile.signature_html = services.render_markdown(
                form.cleaned_data["signature"]
            )
            profile.custom_title = form.cleaned_data.get("custom_title", "")
            profile.website = form.cleaned_data.get("website", "")
            profile.location = form.cleaned_data.get("location", "")
            profile.save(
                update_fields=[
                    "signature",
                    "signature_html",
                    "custom_title",
                    "website",
                    "location",
                    "updated_at",
                ]
            )
            messages.success(request, "Forum profile updated!")
            return redirect("forum:edit_profile")
    else:
        form = SignatureForm(
            initial={
                "signature": profile.signature,
                "custom_title": profile.custom_title,
                "website": profile.website,
                "location": profile.location,
            }
        )

    return render(
        request,
        "forum/edit_profile.html",
        {"form": form, "profile": profile},
    )


# ---------------------------------------------------------------------------
# Who's Online
# ---------------------------------------------------------------------------


def whos_online(request: HttpRequest) -> HttpResponse:
    online_users = services.get_online_users()
    template = "forum/whos_online.html"
    if request.headers.get("HX-Request"):
        template = "forum/fragments/online_users.html"
    return render(request, template, {"online_users": online_users})


# ---------------------------------------------------------------------------
# Leaderboard (reputation)
# ---------------------------------------------------------------------------


def leaderboard(request: HttpRequest) -> HttpResponse:
    top_users = ForumUserProfile.objects.select_related("user").order_by("-reputation")[
        :25
    ]
    return render(request, "forum/leaderboard.html", {"top_users": top_users})


# ---------------------------------------------------------------------------
# IP Ban List (staff only)
# ---------------------------------------------------------------------------


@login_required
def ip_ban_list(request: HttpRequest) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    bans = ForumIPBan.objects.filter(is_active=True).order_by("-created_at")
    return render(
        request,
        "forum/ip_ban_list.html",
        {"bans": bans, "form": IPBanForm()},
    )


# ---------------------------------------------------------------------------
# Warning List (staff only)
# ---------------------------------------------------------------------------


@login_required
def warning_list(request: HttpRequest) -> HttpResponse:
    if not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()
    warnings = ForumWarning.objects.select_related("user", "issued_by").order_by(
        "-created_at"
    )[:100]
    return render(
        request,
        "forum/warning_list.html",
        {"warnings": warnings, "form": WarningForm()},
    )


# ---------------------------------------------------------------------------
# 4PDA — Wiki Header (шапка)
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="edit_wiki_header", max_attempts=10, window_seconds=60)
def edit_wiki_header(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk, is_removed=False)

    # Only topic author or staff can edit wiki header
    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden(
            "Only the topic author or staff can edit the wiki header."
        )

    form = WikiHeaderForm(request.POST)
    if form.is_valid():
        services.update_wiki_header(
            topic, user=_user(request), content=form.cleaned_data["content"]
        )
        messages.success(request, "Wiki header updated!")

    if request.headers.get("HX-Request"):
        topic.refresh_from_db()
        return render(
            request,
            "forum/fragments/wiki_header.html",
            {"topic": topic},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


def wiki_header_history(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)
    history = ForumWikiHeaderHistory.objects.filter(topic=topic).select_related(
        "edited_by"
    )
    return render(
        request,
        "forum/fragments/wiki_header_history.html",
        {"topic": topic, "history": history},
    )


# ---------------------------------------------------------------------------
# 4PDA — Useful Post toggle
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="toggle_useful", max_attempts=30, window_seconds=60)
def toggle_useful(request: HttpRequest, reply_pk: int) -> HttpResponse:
    reply = get_object_or_404(ForumReply, pk=reply_pk, is_removed=False)
    is_useful = services.toggle_useful_post(reply, _user(request))
    useful_count = services.get_useful_count(reply)

    if request.headers.get("HX-Request"):
        return render(
            request,
            "forum/fragments/useful_button.html",
            {"reply": reply, "is_useful": is_useful, "useful_count": useful_count},
        )
    return redirect("forum:topic_detail", pk=reply.topic.pk, slug=reply.topic.slug)


# ---------------------------------------------------------------------------
# 4PDA — FAQ entries
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="add_faq", max_attempts=15, window_seconds=60)
def add_faq(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)

    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    form = FAQEntryForm(request.POST)
    if form.is_valid():
        reply = get_object_or_404(ForumReply, pk=form.cleaned_data["reply_id"])
        services.add_faq_entry(
            topic,
            reply,
            question=form.cleaned_data["question"],
            sort_order=form.cleaned_data.get("sort_order") or 0,
        )
        messages.success(request, "FAQ entry added!")

    if request.headers.get("HX-Request"):
        entries = services.get_faq_entries(topic)
        return render(
            request,
            "forum/fragments/faq_entries.html",
            {"topic": topic, "faq_entries": entries},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
@require_POST
@_forum_rate_limit(scope="remove_faq", max_attempts=15, window_seconds=60)
def remove_faq(request: HttpRequest, faq_pk: int) -> HttpResponse:
    faq = get_object_or_404(ForumFAQEntry, pk=faq_pk)
    topic = faq.topic

    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    services.remove_faq_entry(faq_pk)
    messages.success(request, "FAQ entry removed.")

    if request.headers.get("HX-Request"):
        entries = services.get_faq_entries(topic)
        return render(
            request,
            "forum/fragments/faq_entries.html",
            {"topic": topic, "faq_entries": entries},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# 4PDA — Changelog
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="add_changelog", max_attempts=15, window_seconds=60)
def add_changelog(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)

    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    form = ChangelogEntryForm(request.POST)
    if form.is_valid():
        services.add_changelog_entry(
            topic,
            user=_user(request),
            version=form.cleaned_data["version"],
            changes=form.cleaned_data["changes"],
            released_at=form.cleaned_data.get("released_at"),
        )
        messages.success(request, "Changelog entry added!")

    if request.headers.get("HX-Request"):
        entries = services.get_changelog(topic)
        return render(
            request,
            "forum/fragments/changelog.html",
            {"topic": topic, "changelog_entries": entries},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


@login_required
@require_POST
@_forum_rate_limit(scope="remove_changelog", max_attempts=15, window_seconds=60)
def remove_changelog(request: HttpRequest, entry_pk: int) -> HttpResponse:
    entry = get_object_or_404(ForumChangelog, pk=entry_pk)
    topic = entry.topic

    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    services.remove_changelog_entry(entry_pk)
    messages.success(request, "Changelog entry removed.")

    if request.headers.get("HX-Request"):
        entries = services.get_changelog(topic)
        return render(
            request,
            "forum/fragments/changelog.html",
            {"topic": topic, "changelog_entries": entries},
        )
    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# 4PDA — Topic type change
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="change_topic_type", max_attempts=10, window_seconds=60)
def change_topic_type(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)

    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    form = TopicTypeForm(request.POST)
    if form.is_valid():
        topic.topic_type = form.cleaned_data["topic_type"]
        topic.save(update_fields=["topic_type", "updated_at"])
        messages.success(request, "Topic type updated!")

    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# 4PDA — Device linking
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="link_device", max_attempts=10, window_seconds=60)
def link_device(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)

    if topic.user != request.user and not request.user.is_staff:  # type: ignore[union-attr]
        return HttpResponseForbidden()

    form = DeviceLinkForm(request.POST)
    if form.is_valid():
        device_id = form.cleaned_data.get("device_id")
        if device_id:
            from apps.firmwares.models import Model as DeviceModel

            device = DeviceModel.objects.filter(pk=device_id).first()
            topic.linked_device = device
        else:
            topic.linked_device = None
        topic.save(update_fields=["linked_device", "updated_at"])
        messages.success(request, "Device link updated!")

    return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)


# ---------------------------------------------------------------------------
# 4PDA — Attachment download counter
# ---------------------------------------------------------------------------


def download_attachment(request: HttpRequest, attachment_pk: int) -> HttpResponse:
    attachment = get_object_or_404(ForumAttachment, pk=attachment_pk)
    services.increment_download_count(attachment)
    return redirect(attachment.file.url)


# ---------------------------------------------------------------------------
# 4PDA — Attachment upload
# ---------------------------------------------------------------------------


@login_required
@require_POST
@_forum_rate_limit(scope="upload_attachment", max_attempts=10, window_seconds=60)
def upload_attachment(request: HttpRequest, reply_pk: int) -> HttpResponse:
    """Upload a file attachment to an existing reply."""
    from .forms import AttachmentUploadForm

    reply = get_object_or_404(ForumReply, pk=reply_pk)
    user = cast("AbstractBaseUser", request.user)

    # Permission check: only reply author or staff
    if reply.user_id != user.pk and not getattr(user, "is_staff", False):  # type: ignore[attr-defined]
        return HttpResponseForbidden("You cannot attach files to this reply.")

    # Trust level check
    try:
        services._check_attachment_permission(user)
    except services.ForumPermissionError as exc:
        messages.error(request, str(exc))
        return redirect("forum:topic_detail", pk=reply.topic.pk, slug=reply.topic.slug)  # type: ignore[union-attr]

    form = AttachmentUploadForm(request.POST, request.FILES)
    if form.is_valid():
        uploaded = form.cleaned_data["file"]
        ForumAttachment.objects.create(
            reply=reply,
            user=user,
            file=uploaded,
            filename=uploaded.name,
            content_type=getattr(uploaded, "content_type", ""),
            file_size=uploaded.size,
        )
        messages.success(request, "Attachment uploaded successfully.")
    else:
        for err in form.errors.values():
            messages.error(request, str(err[0]))

    return redirect("forum:topic_detail", pk=reply.topic.pk, slug=reply.topic.slug)  # type: ignore[union-attr]
