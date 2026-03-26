"""Public bounty views — list, detail, create, submit solution, confirm."""

from __future__ import annotations

import logging

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import Count, Q, QuerySet
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, redirect, render

from . import services as bounty_services
from .models import BountyRequest, BountySubmission

logger = logging.getLogger(__name__)


def bounty_list(request: HttpRequest) -> HttpResponse:
    """List bounties with tab filtering: all / firmware / support."""
    tab = request.GET.get("tab", "all")
    q = request.GET.get("q", "").strip()

    qs: QuerySet[BountyRequest] = BountyRequest.objects.select_related(
        "user", "brand", "device_model"
    ).annotate(submissions_count=Count("submissions"))

    if tab == "firmware":
        qs = qs.filter(request_type=BountyRequest.RequestType.FIRMWARE)
    elif tab == "support":
        qs = qs.filter(request_type=BountyRequest.RequestType.SUPPORT)

    if q:
        qs = qs.filter(
            Q(title__icontains=q)
            | Q(description__icontains=q)
            | Q(fw_version_wanted__icontains=q)
        )

    # Status filter
    status_filter = request.GET.get("status", "")
    if status_filter:
        qs = qs.filter(status=status_filter)

    # HTMX fragment support
    template = "bounty/bounty_list.html"
    if request.headers.get("HX-Request"):
        template = "bounty/fragments/bounty_cards.html"

    context = {
        "bounties": qs[:50],
        "active_tab": tab,
        "search_query": q,
        "status_filter": status_filter,
        "status_choices": BountyRequest.Status.choices,
    }
    return render(request, template, context)


def bounty_detail(request: HttpRequest, pk: int) -> HttpResponse:
    """Bounty detail with all submissions/solutions."""
    bounty = get_object_or_404(
        BountyRequest.objects.select_related(
            "user", "brand", "device_model", "forum_topic"
        ),
        pk=pk,
    )
    submissions = (
        bounty.submissions.select_related("user", "firmware")  # type: ignore[attr-defined]
        .prefetch_related("peer_reviews")
        .order_by("-is_confirmed", "-created_at")
    )

    is_owner = request.user.is_authenticated and request.user == bounty.user
    has_submitted = (
        request.user.is_authenticated and submissions.filter(user=request.user).exists()
    )

    # Forum discussion link
    forum_discussion_url = None
    if bounty.forum_topic_id:  # type: ignore[attr-defined]
        try:
            from django.urls import reverse

            topic = bounty.forum_topic
            forum_discussion_url = reverse(
                "forum:topic_detail",
                kwargs={"pk": topic.pk, "slug": topic.slug},  # type: ignore[union-attr]
            )
        except Exception:  # noqa: S110
            pass

    # Escrow info
    escrow = None
    try:
        escrow = bounty.escrow  # type: ignore[attr-defined]
    except Exception:  # noqa: S110
        pass

    context = {
        "bounty": bounty,
        "submissions": submissions,
        "is_owner": is_owner,
        "has_submitted": has_submitted,
        "forum_discussion_url": forum_discussion_url,
        "escrow": escrow,
    }
    return render(request, "bounty/bounty_detail.html", context)


@login_required
def bounty_create(request: HttpRequest) -> HttpResponse:
    """Create a new bounty request (firmware or support)."""
    if request.method == "POST":
        request_type = request.POST.get("request_type", "firmware")
        title = request.POST.get("title", "").strip()
        description = request.POST.get("description", "").strip()
        what_tried = request.POST.get("what_tried", "").strip()
        fw_version = request.POST.get("fw_version_wanted", "").strip()
        reward = request.POST.get("reward_amount", "0")

        if not title or not description:
            messages.error(request, "Title and description are required.")
            return render(
                request,
                "bounty/bounty_create.html",
                {
                    "request_type_choices": BountyRequest.RequestType.choices,
                    "brands": _get_brands(),
                },
            )

        # Optional brand/model linking
        brand_id = request.POST.get("brand") or None
        model_id = request.POST.get("device_model") or None

        try:
            from apps.wallet.services import InsufficientFundsError

            bounty = bounty_services.create_bounty(
                user=request.user,  # type: ignore[arg-type]
                title=title,
                request_type=request_type,
                description=description,
                what_tried=what_tried,
                fw_version_wanted=fw_version,
                reward_amount=reward,
                brand_id=brand_id,
                device_model_id=model_id,
            )
        except InsufficientFundsError:
            messages.error(
                request,
                "Insufficient wallet balance to escrow the reward amount. "
                "Please top up your wallet or reduce the reward.",
            )
            return render(
                request,
                "bounty/bounty_create.html",
                {
                    "request_type_choices": BountyRequest.RequestType.choices,
                    "brands": _get_brands(),
                },
            )

        messages.success(request, f"Bounty '{bounty.title}' created successfully!")
        return redirect("bounty:bounty_detail", pk=bounty.pk)

    # GET — show form
    context = {
        "request_type_choices": BountyRequest.RequestType.choices,
        "brands": _get_brands(),
    }
    return render(request, "bounty/bounty_create.html", context)


@login_required
def bounty_submit_solution(request: HttpRequest, pk: int) -> HttpResponse:
    """Submit a solution/contribution to a bounty."""
    bounty = get_object_or_404(BountyRequest, pk=pk)

    if bounty.user == request.user:
        messages.error(request, "You cannot submit a solution to your own bounty.")
        return redirect("bounty:bounty_detail", pk=pk)

    if bounty.status not in (
        BountyRequest.Status.OPEN,
        BountyRequest.Status.IN_PROGRESS,
    ):
        messages.error(request, "This bounty is no longer accepting solutions.")
        return redirect("bounty:bounty_detail", pk=pk)

    # Check if user already submitted
    if BountySubmission.objects.filter(request=bounty, user=request.user).exists():
        messages.info(request, "You have already submitted a solution to this bounty.")
        return redirect("bounty:bounty_detail", pk=pk)

    if request.method == "POST":
        notes = request.POST.get("notes", "").strip()
        if not notes:
            messages.error(request, "Please describe your solution.")
            return render(request, "bounty/bounty_submit.html", {"bounty": bounty})

        BountySubmission.objects.create(
            request=bounty,
            user=request.user,
            notes=notes,
        )

        # Move bounty to in_progress if first submission
        if bounty.status == BountyRequest.Status.OPEN:
            bounty.status = BountyRequest.Status.IN_PROGRESS
            bounty.save(update_fields=["status", "updated_at"])

        messages.success(request, "Your solution has been submitted!")
        return redirect("bounty:bounty_detail", pk=pk)

    return render(request, "bounty/bounty_submit.html", {"bounty": bounty})


@login_required
def bounty_confirm_solution(
    request: HttpRequest, pk: int, submission_id: int
) -> HttpResponse:
    """Bounty owner confirms a submission helped resolve the issue."""
    bounty = get_object_or_404(BountyRequest, pk=pk)

    if bounty.user != request.user:
        messages.error(request, "Only the bounty creator can confirm solutions.")
        return redirect("bounty:bounty_detail", pk=pk)

    submission = get_object_or_404(BountySubmission, pk=submission_id, request=bounty)

    if request.method == "POST":
        action = request.POST.get("action", "")

        if action == "confirm":
            submission.is_confirmed = True
            submission.status = BountySubmission.Status.ACCEPTED
            submission.save(update_fields=["is_confirmed", "status"])
            messages.success(
                request, f"Confirmed {submission.user}'s solution as helpful!"
            )

        elif action == "reject":
            submission.status = BountySubmission.Status.REJECTED
            submission.save(update_fields=["status"])
            messages.info(request, "Submission marked as not helpful.")

    return redirect("bounty:bounty_detail", pk=pk)


@login_required
def bounty_resolve(request: HttpRequest, pk: int) -> HttpResponse:
    """Bounty owner marks the bounty as resolved with resolution details."""
    bounty = get_object_or_404(BountyRequest, pk=pk)

    if bounty.user != request.user:
        messages.error(request, "Only the bounty creator can resolve this bounty.")
        return redirect("bounty:bounty_detail", pk=pk)

    if request.method == "POST":
        resolution_type = request.POST.get("resolution_type", "single")
        resolution_note = request.POST.get("resolution_note", "").strip()

        bounty_services.resolve_bounty(
            bounty,
            resolution_type=resolution_type,
            resolution_note=resolution_note,
        )

        messages.success(request, "Bounty has been marked as resolved!")

    return redirect("bounty:bounty_detail", pk=pk)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _get_brands() -> list[dict[str, object]]:
    """Return a lightweight brand list for the create form."""
    try:
        from apps.firmwares.models import Brand

        return list(Brand.objects.order_by("name").values("id", "name"))
    except Exception:  # noqa: S110
        return []
