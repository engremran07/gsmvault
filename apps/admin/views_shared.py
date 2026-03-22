"""
Admin Suite shared imports and helpers.

All admin views are staff-gated via STAFF_ONLY unless explicitly public (e.g., login/recovery).
"""

from __future__ import annotations

import logging
import secrets  # noqa: F401
from typing import Any

from django import forms  # noqa: F401
from django.conf import settings  # noqa: F401
from django.contrib import messages  # noqa: F401
from django.contrib.admin.views.decorators import (
    staff_member_required as django_staff_member_required,
)
from django.contrib.auth import get_user_model, logout  # noqa: F401
from django.contrib.auth.forms import SetPasswordForm  # noqa: F401
from django.contrib.auth.views import LoginView  # noqa: F401
from django.core.cache import cache  # noqa: F401
from django.core.mail import send_mail  # noqa: F401
from django.core.paginator import EmptyPage, PageNotAnInteger, Paginator  # noqa: F401
from django.db import models  # noqa: F401
from django.http import (
    Http404,
    HttpRequest,
    HttpResponse,
    JsonResponse,  # noqa: F401
)
from django.shortcuts import redirect, render  # noqa: F401
from django.urls import reverse, reverse_lazy
from django.views.decorators.csrf import csrf_protect, ensure_csrf_cookie  # noqa: F401

logger = logging.getLogger(__name__)

_ADMIN_DISABLED = Http404("Admin suite is disabled.")
_ADMIN_LOGIN_URL = reverse_lazy("admin_suite:admin_suite_login")


# Provide a consistent staff-only decorator that points to the Admin Suite login,
# not the Django admin login (admin:login), to avoid incorrect redirects.
def staff_member_required(
    view_func=None, redirect_field_name="", login_url=_ADMIN_LOGIN_URL
):
    return django_staff_member_required(
        view_func=view_func,
        redirect_field_name=redirect_field_name,
        login_url=login_url,
    )


STAFF_ONLY = staff_member_required


def _make_breadcrumb(*items: tuple[str, str | None]) -> list[dict[str, str | None]]:
    """
    Build a breadcrumb list from (label, url_name) pairs.
    url_name may be None to render as plain text.
    """
    breadcrumb: list[dict[str, str | None]] = []
    for label, url_name in items:
        url = None
        if url_name:
            try:
                url = reverse(url_name)
            except Exception:
                url = None
        breadcrumb.append({"label": label, "url": url})
    return breadcrumb


def _render_admin(
    request: HttpRequest,
    template: str,
    context: dict[str, Any],
    nav_active: str,
    breadcrumb: list[dict[str, str | None]],
    subtitle: str | None = None,
) -> HttpResponse:
    payload = {
        "nav_active": nav_active,
        "breadcrumb": breadcrumb,
        "subtitle": subtitle,
    }
    payload.update(context or {})
    return render(request, template, payload)


def _admin_sort(
    request: HttpRequest,
    queryset: Any,
    allowed_fields: dict[str, str],
    default_sort: str = "-pk",
) -> tuple[Any, str, str]:
    """Sort a queryset by request params. Returns (sorted_qs, sort_field, sort_dir)."""
    sort = request.GET.get("sort", "")
    direction = request.GET.get("dir", "asc")
    if sort in allowed_fields:
        orm_field = allowed_fields[sort]
        if direction == "desc":
            orm_field = f"-{orm_field}"
        return queryset.order_by(orm_field), sort, direction
    return queryset.order_by(default_sort), "", "asc"


def _admin_paginate(
    request: HttpRequest,
    queryset: Any,
    per_page: int = 25,
    page_param: str = "page",
) -> Any:
    """Paginate a queryset, returns a Page object."""
    paginator = Paginator(queryset, per_page)
    page_num = request.GET.get(page_param, "1")
    try:
        return paginator.page(page_num)
    except PageNotAnInteger:
        return paginator.page(1)
    except EmptyPage:
        return paginator.page(paginator.num_pages)


def _admin_search(request: HttpRequest) -> str:
    """Extract search query from request."""
    return (request.GET.get("q") or "").strip()
