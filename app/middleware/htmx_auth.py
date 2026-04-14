"""
HTMX Auth Expiry Middleware.

Detects HTMX requests from users whose session has expired and returns an
HX-Redirect header telling the browser to navigate to the login page,
instead of injecting the login page HTML into the current partial target.

Place AFTER AuthenticationMiddleware in the MIDDLEWARE list.
"""

from __future__ import annotations

from django.conf import settings
from django.http import HttpResponse
from django.utils.deprecation import MiddlewareMixin


class HtmxAuthExpiryMiddleware(MiddlewareMixin):
    """Return HX-Redirect on HTMX requests from unauthenticated users."""

    # Paths that should never trigger this redirect (login, public pages, etc.)
    EXEMPT_PREFIXES: tuple[str, ...] = (
        "/accounts/",
        "/.well-known/",
        "/api/",
        "/consent/",
    )

    def process_response(self, request, response):
        # Only intercept HTMX requests
        if not request.headers.get("HX-Request"):
            return response

        # Skip if the user is authenticated
        if getattr(request, "user", None) and request.user.is_authenticated:
            return response

        # Skip exempt paths (login page itself, public APIs, etc.)
        path = request.path
        if any(path.startswith(prefix) for prefix in self.EXEMPT_PREFIXES):
            return response

        # Only intercept redirect-to-login responses (302 to login page)
        if response.status_code not in (301, 302):
            return response

        login_url = getattr(settings, "LOGIN_URL", "/accounts/login/")

        redirect_target = response.get("Location", "")
        if login_url not in redirect_target:
            return response

        # Replace the redirect with an HTMX-compatible redirect header
        htmx_response = HttpResponse(status=204)
        htmx_response["HX-Redirect"] = redirect_target
        return htmx_response
