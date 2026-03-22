"""apps.referral.views — Referral landing page and code validation."""

from __future__ import annotations

import logging

from django.http import HttpRequest, HttpResponse, JsonResponse
from django.shortcuts import redirect
from django.views.decorators.http import require_GET

from .services import record_referral_click, validate_referral_code

logger = logging.getLogger(__name__)


@require_GET
def referral_landing(request: HttpRequest, code: str) -> HttpResponse:
    """
    Landing page for referral links: /ref/<code>/
    Records an anonymized click, stores the code in session, then redirects to signup.
    """
    ref_code = validate_referral_code(code)
    if not ref_code:
        return redirect("users:account_signup")

    # Record click
    try:
        record_referral_click(ref_code, request)
    except Exception:
        logger.exception("Failed to record referral click for code=%s", code)

    # Store in session for use during signup
    request.session["referral_code"] = ref_code.code

    return redirect("users:account_signup")


@require_GET
def validate_code_api(request: HttpRequest) -> JsonResponse:
    """AJAX endpoint to validate a referral code in real-time."""
    code = (request.GET.get("code") or "").strip()
    if not code:
        return JsonResponse({"valid": False, "error": "No code provided."})

    ref_code = validate_referral_code(code)
    if ref_code:
        return JsonResponse(
            {
                "valid": True,
                "referrer": ref_code.user.get_full_name(),
            }
        )
    return JsonResponse({"valid": False, "error": "Invalid or expired referral code."})
