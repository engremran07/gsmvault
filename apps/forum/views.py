from __future__ import annotations

import logging
from typing import TYPE_CHECKING, cast

from django.contrib import messages
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.db.models import Exists, OuterRef, Prefetch
from django.http import HttpRequest, HttpResponse, HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

if TYPE_CHECKING:
    from django.contrib.auth.base_user import AbstractBaseUser

from . import services
from .forms import (
    FlagForm,
    PollVoteForm,
    PrivateTopicForm,
    ReplyCreateForm,
    ReplyEditForm,
    SearchForm,
    TopicCreateForm,
)
from .models import (
    ForumCategory,
    ForumLike,
    ForumPoll,
    ForumPollChoice,
    ForumPrivateTopicUser,
    ForumReply,
    ForumTopic,
    ForumTopicFavorite,
    ForumTopicSubscription,
)

logger = logging.getLogger(__name__)
User = get_user_model()


def _user(request: HttpRequest) -> AbstractBaseUser:
    """Cast request.user for type checker — only call after @login_required."""
    return cast("AbstractBaseUser", request.user)


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

    return render(request, template, {"categories": categories})


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
    xff = request.META.get("HTTP_X_FORWARDED_FOR")
    if xff:
        return xff.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")
