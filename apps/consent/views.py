from __future__ import annotations

import json

from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse, HttpResponseRedirect
from django.shortcuts import render
from django.views.decorators.http import require_GET, require_POST

from apps.consent.models import ConsentDecision, ConsentEvent, ConsentPolicy
from apps.consent.utils import resolve_policy_url, set_consent_cookie
from apps.core.utils.ip import get_client_ip

_DEFAULT_CATEGORIES_SNAPSHOT = {
    "functional": {"required": True, "label": "Functional"},
    "analytics": {"required": False, "label": "Analytics"},
    "seo": {"required": False, "label": "SEO & Performance"},
    "ads": {"required": False, "label": "Advertising"},
}


def _consent_done(request: HttpRequest, categories: dict[str, bool]) -> HttpResponse:
    """Always redirect after consent action — never return JSON to the browser.

    Cookie is set on the redirect response. fetch() callers follow the redirect
    automatically and their .then() handler fires regardless of response type,
    so no JSON body is needed.
    """
    referer = request.META.get("HTTP_REFERER", "/")
    redirect = HttpResponseRedirect(referer)
    set_consent_cookie(redirect, categories)
    return redirect


def _get_or_create_active_policy() -> ConsentPolicy:
    """Return the active consent policy, auto-creating a default if none exists."""
    policy = (
        ConsentPolicy.objects.filter(is_active=True).order_by("-effective_from").first()
    )
    if policy:
        # Backfill any missing default categories into existing policies
        snapshot = policy.categories_snapshot or {}
        updated = False
        for slug, meta in _DEFAULT_CATEGORIES_SNAPSHOT.items():
            if slug not in snapshot:
                snapshot[slug] = meta
                updated = True
        if updated:
            policy.categories_snapshot = snapshot
            policy.save(update_fields=["categories_snapshot"])
        return policy
    policy, _ = ConsentPolicy.objects.get_or_create(
        version="default",
        defaults={
            "is_active": True,
            "banner_text": "We use cookies to improve your browsing experience.",
            "manage_text": "Manage your cookie preferences.",
            "categories_snapshot": _DEFAULT_CATEGORIES_SNAPSHOT,
        },
    )
    if not policy.is_active:
        policy.is_active = True
        policy.save(update_fields=["is_active"])
    return policy


@require_GET
def privacy_center(request):
    active_policy = (
        ConsentPolicy.objects.filter(is_active=True).order_by("-effective_from").first()
    )
    decisions = ConsentDecision.objects.none()
    if active_policy:
        if request.user.is_authenticated:
            decisions = ConsentDecision.objects.filter(
                user=request.user, policy=active_policy
            )
        else:
            sid = request.session.session_key
            if sid:
                decisions = ConsentDecision.objects.filter(
                    session_id=sid, policy=active_policy
                )
    return render(
        request,
        "consent/privacy_center.html",
        {
            "policy": active_policy,
            "decisions": decisions[:20],
            "policy_url": resolve_policy_url(active_policy, default_slug="privacy"),
        },
    )


@login_required
def privacy_center_authed(request):
    return privacy_center(request)


@require_POST
def accept_all(request: HttpRequest) -> HttpResponse:
    policy = _get_or_create_active_policy()
    if not request.session.session_key:
        request.session.create()
    snapshot = policy.categories_snapshot or {}
    if not snapshot:
        snapshot = {"functional": True}
    categories = dict.fromkeys(snapshot.keys(), True)
    decision = ConsentDecision.objects.create(
        user=request.user if request.user.is_authenticated else None,
        session_id=request.session.session_key or "",
        policy=policy,
        categories=categories,
    )
    decision.set_hashes(
        get_client_ip(request) or "", request.META.get("HTTP_USER_AGENT", "")
    )
    decision.save(update_fields=["ip_hash", "user_agent_hash"])
    ConsentEvent.objects.create(
        decision=decision,
        policy=policy,
        categories=categories,
        event_type="accepted_all",
        ip_hash=decision.ip_hash,
        user_agent_hash=decision.user_agent_hash,
    )
    return _consent_done(request, categories)


@require_POST
def reject_all(request: HttpRequest) -> HttpResponse:
    policy = _get_or_create_active_policy()
    if not request.session.session_key:
        request.session.create()
    snapshot = policy.categories_snapshot or {}
    if not snapshot:
        snapshot = {"functional": True}
    # Only required categories remain true; optional are false/omitted
    categories = {}
    for slug, meta in snapshot.items():
        required = False
        if isinstance(meta, dict):
            required = bool(meta.get("required", False))
        categories[slug] = True if required else False
    decision = ConsentDecision.objects.create(
        user=request.user if request.user.is_authenticated else None,
        session_id=request.session.session_key or "",
        policy=policy,
        categories=categories,
    )
    decision.set_hashes(
        get_client_ip(request) or "", request.META.get("HTTP_USER_AGENT", "")
    )
    decision.save(update_fields=["ip_hash", "user_agent_hash"])
    ConsentEvent.objects.create(
        decision=decision,
        policy=policy,
        categories=categories,
        event_type="rejected_all",
        ip_hash=decision.ip_hash,
        user_agent_hash=decision.user_agent_hash,
    )
    return _consent_done(request, categories)


@require_POST
def accept(request: HttpRequest) -> HttpResponse:
    policy = _get_or_create_active_policy()
    if not request.session.session_key:
        request.session.create()
    try:
        payload = json.loads(request.body.decode() or "{}")
        if not isinstance(payload, dict):
            raise ValueError
    except Exception:
        payload = {}
    snapshot = policy.categories_snapshot or {}
    if not snapshot:
        snapshot = {"functional": True}
    categories = {}
    for slug, val in snapshot.items():
        required = False
        if isinstance(val, dict):
            required = bool(val.get("required", False))
        incoming = payload.get(slug)
        categories[slug] = True if required else bool(incoming)
    decision = ConsentDecision.objects.create(
        user=request.user if request.user.is_authenticated else None,
        session_id=request.session.session_key or "",
        policy=policy,
        categories=categories,
    )
    decision.set_hashes(
        get_client_ip(request) or "", request.META.get("HTTP_USER_AGENT", "")
    )
    decision.save(update_fields=["ip_hash", "user_agent_hash"])
    ConsentEvent.objects.create(
        decision=decision,
        policy=policy,
        categories=categories,
        event_type="granular_accept",
        ip_hash=decision.ip_hash,
        user_agent_hash=decision.user_agent_hash,
    )
    return _consent_done(request, categories)


def banner(request: HttpRequest) -> HttpResponse:
    """
    Render the consent banner fragment for the frontend loader.
    Returns empty content if no active policy exists.
    """
    policy = _get_or_create_active_policy()

    # Format categories for template with proper structure
    categories_snapshot = policy.categories_snapshot or {}
    formatted_categories = {}
    for slug, meta in categories_snapshot.items():
        if isinstance(meta, dict):
            formatted_categories[slug] = {
                "name": meta.get("label", slug.replace("_", " ").title()),
                "required": meta.get("required", False),
                "checked": meta.get(
                    "required", False
                ),  # Required categories checked by default
            }
        else:
            formatted_categories[slug] = {
                "name": slug.replace("_", " ").title(),
                "required": False,
                "checked": False,
            }

    ctx = {
        "policy": policy,
        "consent_categories": formatted_categories,
        "consent_text": policy.banner_text
        or "We use cookies to improve your browsing experience.",
        "consent_version": policy.version,
    }
    return render(request, "consent/includes/banner.html", ctx)
