"""
Admin Suite Extended Views - Additional App Management

Views for:
- i18n (Languages, Translations)
- Devices (Device Settings, Policies)
- AI (Endpoints, Knowledge Bases, Workflows)
- Core (Feature Toggles)
"""

from __future__ import annotations

import logging

from django.conf import settings
from django.contrib.admin.views.decorators import staff_member_required
from django.http import HttpRequest, HttpResponse
from django.utils import timezone
from django.views.decorators.csrf import csrf_protect

from .views_shared import (
    _ADMIN_DISABLED,
    _admin_paginate,
    _admin_search,
    _admin_sort,
    _make_breadcrumb,
    _render_admin,
)

logger = logging.getLogger(__name__)


# =============================================================================
# I18N / LOCALIZATION MANAGEMENT
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_i18n(request: HttpRequest) -> HttpResponse:
    """Internationalization dashboard - Languages, Translations."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    stats = {
        "total_languages": 0,
        "active_languages": 0,
        "total_keys": 0,
        "total_translations": 0,
        "missing_translations": 0,
        "translation_coverage": 0,
    }
    languages = []
    recent_missing = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.i18n.models import Language  # type: ignore[import-not-found]

            if action == "toggle_language":
                lang_id = request.POST.get("language_id")
                lang = Language.objects.filter(pk=lang_id).first()
                if lang:
                    lang.is_active = not lang.is_active
                    lang.save(update_fields=["is_active"])
                    message = f"Language {'enabled' if lang.is_active else 'disabled'}."
            elif action == "create_language":
                code = (request.POST.get("code") or "").strip()[:10]
                name = (request.POST.get("name") or "").strip()[:64]
                native_name = (request.POST.get("native_name") or "").strip()[:64]
                if code and name:
                    Language.objects.create(
                        code=code,
                        name=name,
                        native_name=native_name or name,
                        is_active=True,
                    )
                    message = f"Language '{name}' created."
        except Exception as exc:
            logger.warning("i18n admin action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.i18n.models import (  # type: ignore[import-not-found]
            Language,
            MissingTranslation,
            Translation,
            TranslationKey,
        )

        all_languages = Language.objects.all().order_by("-is_active", "name")
        stats["total_languages"] = all_languages.count()
        stats["active_languages"] = all_languages.filter(is_active=True).count()
        stats["total_keys"] = TranslationKey.objects.count()
        stats["total_translations"] = Translation.objects.count()
        stats["missing_translations"] = MissingTranslation.objects.filter(
            is_resolved=False
        ).count()

        if stats["total_keys"] > 0 and stats["active_languages"] > 0:
            expected = stats["total_keys"] * stats["active_languages"]
            stats["translation_coverage"] = (
                round((stats["total_translations"] / expected) * 100, 1)
                if expected > 0
                else 0
            )

        languages = list(
            all_languages[:50].values(
                "id", "code", "name", "native_name", "is_active", "is_rtl", "flag_emoji"
            )
        )

        recent_missing = list(
            MissingTranslation.objects.filter(is_resolved=False)
            .select_related("language")
            .order_by("-created_at")[:20]
            .values("id", "key", "language__code", "context", "created_at")
        )
    except Exception as exc:
        logger.debug("Failed to load i18n data: %s", exc)

    return _render_admin(
        request,
        "admin_suite/i18n.html",
        {
            "stats": stats,
            "languages": languages,
            "recent_missing": recent_missing,
            "message": message,
        },
        nav_active="i18n",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Localization", None),
        ),
        subtitle="Languages & Translations",
    )


@csrf_protect
@staff_member_required
def admin_suite_i18n_translations(request: HttpRequest) -> HttpResponse:
    """Translation management view."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    query = (request.GET.get("q") or "").strip()
    lang_filter = (request.GET.get("lang") or "").strip()
    page = max(1, int(request.GET.get("page", "1") or "1"))
    page_size = 50
    offset = (page - 1) * page_size

    translations = []
    languages = []
    keys = []
    total_count = 0
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.i18n.models import (  # type: ignore[import-not-found]
                Language,
                Translation,
                TranslationKey,
            )

            if action == "save_translation":
                key_id = request.POST.get("key_id")
                lang_id = request.POST.get("language_id")
                value = request.POST.get("value", "")
                key = TranslationKey.objects.filter(pk=key_id).first()
                lang = Language.objects.filter(pk=lang_id).first()
                if key and lang:
                    Translation.objects.update_or_create(
                        key=key, language=lang, defaults={"value": value}
                    )
                    message = "Translation saved."
        except Exception as exc:
            logger.warning("Translation action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.i18n.models import (  # type: ignore[import-not-found]
            Language,
            Translation,
            TranslationKey,
        )

        languages = list(
            Language.objects.filter(is_active=True)
            .order_by("name")
            .values("id", "code", "name")
        )

        qs = TranslationKey.objects.all()
        if query:
            qs = qs.filter(key__icontains=query)

        total_count = qs.count()
        keys = list(
            qs.order_by("key")[offset : offset + page_size].values(
                "id", "key", "context", "created_at"
            )
        )

        # Get translations for these keys
        key_ids = [k["id"] for k in keys]
        trans_qs = Translation.objects.filter(key_id__in=key_ids).select_related(
            "language"
        )
        translations = {}
        for t in trans_qs:
            if t.key_id not in translations:
                translations[t.key_id] = {}
            translations[t.key_id][t.language.code] = t.value
    except Exception as exc:
        logger.debug("Failed to load translations: %s", exc)

    return _render_admin(
        request,
        "admin_suite/i18n_translations.html",
        {
            "keys": keys,
            "translations": translations,
            "languages": languages,
            "total_count": total_count,
            "query": query,
            "lang_filter": lang_filter,
            "page": page,
            "page_size": page_size,
            "message": message,
        },
        nav_active="i18n",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Localization", "admin_suite:i18n"),
            ("Translations", None),
        ),
        subtitle="Translation Strings",
    )


# =============================================================================
# DEVICES MANAGEMENT (Extended)
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_devices_settings(request: HttpRequest) -> HttpResponse:
    """Device settings and policies management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    device_settings = None
    policies = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.devices.models import (  # type: ignore[attr-defined]
                DevicePolicy,  # type: ignore[attr-defined]
                DeviceSettings,  # type: ignore[attr-defined]
            )

            if action == "save_settings":
                ds = DeviceSettings.get_solo()
                ds.max_devices_per_user = int(request.POST.get("max_devices", 5))
                ds.device_timeout_days = int(request.POST.get("timeout_days", 30))
                ds.require_device_verification = bool(
                    request.POST.get("require_verification")
                )
                ds.save()
                message = "Device settings saved."
            elif action == "create_policy":
                app_label = (request.POST.get("app_label") or "").strip()[:64]
                max_devices = int(request.POST.get("max_devices", 3))
                if app_label:
                    DevicePolicy.objects.create(
                        app_label=app_label,
                        max_devices=max_devices,
                        is_active=True,
                    )
                    message = f"Policy for '{app_label}' created."
            elif action == "toggle_policy":
                policy_id = request.POST.get("policy_id")
                policy = DevicePolicy.objects.filter(pk=policy_id).first()
                if policy:
                    policy.is_active = not policy.is_active
                    policy.save(update_fields=["is_active"])
                    message = f"Policy {'enabled' if policy.is_active else 'disabled'}."
        except Exception as exc:
            logger.warning("Device settings action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.devices.models import (  # type: ignore[attr-defined]
            DevicePolicy,  # type: ignore[attr-defined]
            DeviceSettings,  # type: ignore[attr-defined]
        )

        device_settings = DeviceSettings.get_solo()
        policies = list(
            DevicePolicy.objects.all()
            .order_by("app_label")
            .values("id", "app_label", "max_devices", "is_active", "created_at")
        )
    except Exception as exc:
        logger.debug("Failed to load device settings: %s", exc)

    return _render_admin(
        request,
        "admin_suite/devices_settings.html",
        {
            "device_settings": device_settings,
            "policies": policies,
            "message": message,
        },
        nav_active="devices",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Devices", "admin_suite:devices"),
            ("Settings", None),
        ),
        subtitle="Device Policies & Settings",
    )


# =============================================================================
# AI MANAGEMENT (Extended)
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_ai_endpoints(request: HttpRequest) -> HttpResponse:
    """AI Endpoints management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    endpoints = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.ai.models import AIEndpoint  # type: ignore[attr-defined]

            if action == "toggle_endpoint":
                endpoint_id = request.POST.get("endpoint_id")
                ep = AIEndpoint.objects.filter(pk=endpoint_id).first()
                if ep:
                    ep.is_active = not ep.is_active
                    ep.save(update_fields=["is_active"])
                    message = f"Endpoint {'enabled' if ep.is_active else 'disabled'}."
            elif action == "create_endpoint":
                name = (request.POST.get("name") or "").strip()[:128]
                provider = (request.POST.get("provider") or "").strip()[:64]
                model_id = (request.POST.get("model_id") or "").strip()[:128]
                endpoint_url = (request.POST.get("endpoint_url") or "").strip()[:512]
                if name and provider:
                    AIEndpoint.objects.create(
                        name=name,
                        provider=provider,
                        model_id=model_id,
                        endpoint_url=endpoint_url,
                        is_active=True,
                    )
                    message = f"Endpoint '{name}' created."
            elif action == "delete_endpoint":
                endpoint_id = request.POST.get("endpoint_id")
                AIEndpoint.objects.filter(pk=endpoint_id).delete()
                message = "Endpoint deleted."
        except Exception as exc:
            logger.warning("AI endpoint action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.ai.models import AIEndpoint  # type: ignore[attr-defined]

        endpoints = list(
            AIEndpoint.objects.all()
            .order_by("-is_active", "name")
            .values(
                "id",
                "name",
                "provider",
                "model_id",
                "endpoint_url",
                "is_active",
                "total_requests",
                "total_tokens",
                "average_latency_ms",
                "created_at",
            )
        )
    except Exception as exc:
        logger.debug("Failed to load AI endpoints: %s", exc)

    return _render_admin(
        request,
        "admin_suite/ai_endpoints.html",
        {
            "endpoints": endpoints,
            "message": message,
        },
        nav_active="ai",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("AI Settings", "admin_suite:ai_settings"),
            ("Endpoints", None),
        ),
        subtitle="AI Model Endpoints",
    )


@csrf_protect
@staff_member_required
def admin_suite_ai_knowledge(request: HttpRequest) -> HttpResponse:
    """AI Knowledge Bases management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    knowledge_bases = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.ai.models import AIKnowledgeBase  # type: ignore[attr-defined]

            if action == "toggle_kb":
                kb_id = request.POST.get("kb_id")
                kb = AIKnowledgeBase.objects.filter(pk=kb_id).first()
                if kb:
                    kb.is_active = not kb.is_active
                    kb.save(update_fields=["is_active"])
                    message = (
                        f"Knowledge base {'enabled' if kb.is_active else 'disabled'}."
                    )
            elif action == "create_kb":
                name = (request.POST.get("name") or "").strip()[:128]
                description = (request.POST.get("description") or "").strip()
                if name:
                    AIKnowledgeBase.objects.create(
                        name=name,
                        description=description,
                        is_active=True,
                    )
                    message = f"Knowledge base '{name}' created."
        except Exception as exc:
            logger.warning("AI knowledge base action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.ai.models import AIKnowledgeBase  # type: ignore[attr-defined]

        knowledge_bases = list(
            AIKnowledgeBase.objects.all()
            .order_by("-is_active", "name")
            .values(
                "id",
                "name",
                "description",
                "is_active",
                "document_count",
                "total_chunks",
                "last_indexed_at",
                "created_at",
            )
        )
    except Exception as exc:
        logger.debug("Failed to load AI knowledge bases: %s", exc)

    return _render_admin(
        request,
        "admin_suite/ai_knowledge.html",
        {
            "knowledge_bases": knowledge_bases,
            "message": message,
        },
        nav_active="ai",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("AI Settings", "admin_suite:ai_settings"),
            ("Knowledge Bases", None),
        ),
        subtitle="RAG Knowledge Bases",
    )


@csrf_protect
@staff_member_required
def admin_suite_ai_workflows(request: HttpRequest) -> HttpResponse:
    """AI Workflows management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    workflows = []
    recent_runs = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.ai.models import AIWorkflow  # type: ignore[attr-defined]

            if action == "toggle_workflow":
                wf_id = request.POST.get("workflow_id")
                wf = AIWorkflow.objects.filter(pk=wf_id).first()
                if wf:
                    wf.is_active = not wf.is_active
                    wf.save(update_fields=["is_active"])
                    message = f"Workflow {'enabled' if wf.is_active else 'disabled'}."
        except Exception as exc:
            logger.warning("AI workflow action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.ai.models import (  # type: ignore[attr-defined]
            AIWorkflow,  # type: ignore[attr-defined]
            AIWorkflowRun,  # type: ignore[attr-defined]
        )

        workflows = list(
            AIWorkflow.objects.all()
            .order_by("-is_active", "name")
            .values(
                "id", "name", "description", "is_active", "trigger_type", "created_at"
            )
        )

        recent_runs = list(
            AIWorkflowRun.objects.select_related("workflow")
            .order_by("-started_at")[:30]
            .values(
                "id",
                "workflow__name",
                "status",
                "started_at",
                "completed_at",
                "error_message",
            )
        )
    except Exception as exc:
        logger.debug("Failed to load AI workflows: %s", exc)

    return _render_admin(
        request,
        "admin_suite/ai_workflows.html",
        {
            "workflows": workflows,
            "recent_runs": recent_runs,
            "message": message,
        },
        nav_active="ai",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("AI Settings", "admin_suite:ai_settings"),
            ("Workflows", None),
        ),
        subtitle="AI Automation Pipelines",
    )


# =============================================================================
# CORE / FEATURE TOGGLES
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_features(request: HttpRequest) -> HttpResponse:
    """Feature toggles management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    feature_settings = None
    feature_fields = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.core.models import FeatureSettings  # type: ignore[attr-defined]

            if action == "save_features":
                fs = FeatureSettings.get_solo()
                # Update all boolean feature flags from POST
                for field in fs._meta.get_fields():
                    if (
                        hasattr(field, "get_internal_type")
                        and field.get_internal_type() == "BooleanField"
                    ):
                        field_name = field.name
                        if field_name in request.POST:
                            setattr(fs, field_name, True)
                        else:
                            setattr(fs, field_name, False)
                fs.save()
                message = "Feature settings saved."
        except Exception as exc:
            logger.warning("Feature settings action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.core.models import FeatureSettings  # type: ignore[attr-defined]

        feature_settings = FeatureSettings.get_solo()

        # Build list of feature fields for template (can't access _meta in templates)
        for field in feature_settings._meta.get_fields():
            if (
                hasattr(field, "get_internal_type")
                and field.get_internal_type() == "BooleanField"
            ):
                feature_fields.append(
                    {
                        "name": field.name,
                        "verbose_name": getattr(field, "verbose_name", field.name)
                        .replace("_", " ")
                        .title(),
                        "help_text": getattr(field, "help_text", ""),
                        "value": getattr(feature_settings, field.name, False),
                    }
                )
    except Exception as exc:
        logger.debug("Failed to load feature settings: %s", exc)

    return _render_admin(
        request,
        "admin_suite/features.html",
        {
            "feature_settings": feature_settings,
            "feature_fields": feature_fields,
            "message": message,
        },
        nav_active="features",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Feature Toggles", None),
        ),
        subtitle="Enable/Disable Features",
    )


# =============================================================================
# BLOG MANAGEMENT (Extended)
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_blog_posts(request: HttpRequest) -> HttpResponse:
    """Blog posts management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    posts = None
    categories = []
    status_filter = (request.GET.get("status") or "").strip()
    total_count = 0
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.blog.models import Post

            if action == "toggle_publish":
                post_id = request.POST.get("post_id")
                post = Post.objects.filter(pk=post_id).first()
                if post:
                    post.is_published = not post.is_published
                    post.save(update_fields=["is_published"])
                    message = (
                        f"Post {'published' if post.is_published else 'unpublished'}."
                    )
            elif action == "delete_post":
                post_id = request.POST.get("post_id")
                Post.objects.filter(pk=post_id).delete()
                message = "Post deleted."
            elif action == "bulk_publish":
                ids = request.POST.getlist("post_ids")
                if ids:
                    count = Post.objects.filter(pk__in=ids).update(is_published=True)
                    message = f"{count} post(s) published."
            elif action == "bulk_unpublish":
                ids = request.POST.getlist("post_ids")
                if ids:
                    count = Post.objects.filter(pk__in=ids).update(is_published=False)
                    message = f"{count} post(s) unpublished."
            elif action == "bulk_delete":
                ids = request.POST.getlist("post_ids")
                if ids:
                    count, _ = Post.objects.filter(pk__in=ids).delete()
                    message = f"{count} post(s) deleted."
        except Exception as exc:
            logger.warning("Blog post action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.blog.models import Category, Post

        categories = list(
            Category.objects.all().order_by("name").values("id", "name", "slug")
        )

        qs = Post.objects.select_related("author", "category").all()
        q = _admin_search(request)
        if q:
            qs = qs.filter(title__icontains=q)
        if status_filter == "published":
            qs = qs.filter(is_published=True)
        elif status_filter == "draft":
            qs = qs.filter(is_published=False)

        total_count = qs.count()
        qs, sort_field, sort_dir = _admin_sort(
            request,
            qs,
            {
                "title": "title",
                "author": "author__email",
                "category": "category__name",
                "created": "created_at",
                "views": "view_count",
            },
            default_sort="-created_at",
        )
        posts = _admin_paginate(request, qs, per_page=25)
    except Exception as exc:
        logger.debug("Failed to load blog posts: %s", exc)
        q = ""
        sort_field = ""
        sort_dir = "asc"

    return _render_admin(
        request,
        "admin_suite/blog_posts.html",
        {
            "posts": posts,
            "page_obj": posts,
            "categories": categories,
            "total_count": total_count,
            "q": q,
            "sort": sort_field,
            "dir": sort_dir,
            "status_filter": status_filter,
            "message": message,
        },
        nav_active="blog",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Blog", "admin_suite:blog"),
            ("Posts", None),
        ),
        subtitle="Blog Post Management",
    )


# =============================================================================
# CRAWLER GUARD MANAGEMENT
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_crawler_rules(request: HttpRequest) -> HttpResponse:
    """Crawler guard rules management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    rules = []
    recent_logs = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.security.models import CrawlerRule

            if action == "toggle_rule":
                rule_id = request.POST.get("rule_id")
                rule = CrawlerRule.objects.filter(pk=rule_id).first()
                if rule:
                    rule.is_active = not rule.is_active  # type: ignore[attr-defined]
                    rule.save(update_fields=["is_active"])
                    message = f"Rule {'enabled' if rule.is_active else 'disabled'}."  # type: ignore[attr-defined]
            elif action == "create_rule":
                name = (request.POST.get("name") or "").strip()[:128]
                pattern = (request.POST.get("pattern") or "").strip()
                action_type = (request.POST.get("action_type") or "block").strip()
                if name and pattern:
                    CrawlerRule.objects.create(
                        name=name,
                        user_agent_pattern=pattern,
                        action=action_type,
                        is_active=True,
                    )
                    message = f"Rule '{name}' created."
        except Exception as exc:
            logger.warning("Crawler rule action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.security.models import CrawlerLog, CrawlerRule

        rules = list(
            CrawlerRule.objects.all()
            .order_by("-is_active", "name")
            .values(
                "id",
                "name",
                "user_agent_pattern",
                "ip_pattern",
                "action",
                "is_active",
                "hit_count",
                "created_at",
            )
        )

        recent_logs = list(
            CrawlerLog.objects.order_by("-created_at")[:50].values(
                "id", "user_agent", "ip_address", "path", "action_taken", "created_at"
            )
        )
    except Exception as exc:
        logger.debug("Failed to load crawler rules: %s", exc)

    return _render_admin(
        request,
        "admin_suite/crawler_rules.html",
        {
            "rules": rules,
            "recent_logs": recent_logs,
            "message": message,
        },
        nav_active="crawlers",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Security", "admin_suite:security"),
            ("Crawler Rules", None),
        ),
        subtitle="Bot Detection Rules",
    )


# =============================================================================
# CREDIT & ECONOMY PRICING
# =============================================================================

_CREDIT_FIELDS = [
    (
        "signup_bonus_credits",
        "Signup Bonus",
        "coins",
        "Credits awarded to new users upon registration",
    ),
    (
        "referral_reward_credits",
        "Referral Reward",
        "user-plus",
        "Credits awarded to referrer when referee completes signup",
    ),
    (
        "referee_bonus_credits",
        "Referee Bonus",
        "gift",
        "Credits awarded to referred user as welcome bonus",
    ),
    (
        "bounty_base_reward",
        "Bounty Base Reward",
        "target",
        "Default credit reward for fulfilling a firmware bounty",
    ),
    (
        "download_cost_credits",
        "Download Cost",
        "download",
        "Credits deducted per firmware download (0 = free)",
    ),
    (
        "profile_completion_bonus",
        "Profile Completion Bonus",
        "user-check",
        "Credits awarded when user completes profile",
    ),
    (
        "daily_login_reward",
        "Daily Login Reward",
        "calendar-check",
        "Credits awarded for daily login streak",
    ),
    (
        "credit_to_currency_rate",
        "Credit → USD Rate",
        "banknote",
        "Exchange rate: 1 credit = X USD (for payouts)",
    ),
    (
        "min_payout_credits",
        "Minimum Payout",
        "wallet",
        "Minimum credit balance required to request a payout",
    ),
]


@csrf_protect
@staff_member_required
def admin_suite_credit_pricing(request: HttpRequest) -> HttpResponse:
    """Credit & economy pricing configuration."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from decimal import Decimal, InvalidOperation

    message = ""
    msg_type = ""

    try:
        from apps.site_settings.models import SiteSettings

        site = SiteSettings.get_solo()
    except Exception as exc:
        logger.warning("Failed to load SiteSettings: %s", exc)
        return _render_admin(
            request,
            "admin_suite/credit_pricing.html",
            {
                "credit_fields": [],
                "message": f"Settings unavailable: {exc}",
                "msg_type": "error",
            },
            nav_active="credit_pricing",
            breadcrumb=_make_breadcrumb(
                ("Admin Home", "admin_suite:admin_suite"),
                ("Credit Pricing", None),
            ),
            subtitle="Credit & Economy Configuration",
        )

    if request.method == "POST":
        action = request.POST.get("action")
        if action == "save_pricing":
            changed = 0
            for field_name, *_ in _CREDIT_FIELDS:
                raw = (request.POST.get(field_name) or "").strip()
                if raw:
                    try:
                        val = Decimal(raw)
                        if val != getattr(site, field_name):
                            setattr(site, field_name, val)
                            changed += 1
                    except (InvalidOperation, ValueError):
                        message = f"Invalid value for {field_name}: {raw}"
                        msg_type = "error"
                        break
            if not message:
                if changed:
                    site.save()
                    message = f"Credit pricing updated ({changed} field(s) changed)."
                    msg_type = "success"
                else:
                    message = "No changes detected."
                    msg_type = "info"

    # Build field data for template
    credit_fields = []
    for field_name, label, icon, help_text in _CREDIT_FIELDS:
        credit_fields.append(
            {
                "name": field_name,
                "label": label,
                "icon": icon,
                "help_text": help_text,
                "value": getattr(site, field_name, 0),
            }
        )

    # Wallet stats
    wallet_stats = {
        "total_wallets": 0,
        "total_balance": Decimal("0"),
        "total_locked": Decimal("0"),
        "frozen_wallets": 0,
    }
    try:
        from django.db.models import Sum

        from apps.wallet.models import Wallet

        qs = Wallet.objects.all()
        wallet_stats["total_wallets"] = qs.count()
        agg = qs.aggregate(
            total_balance=Sum("balance"),
            total_locked=Sum("locked_balance"),
        )
        wallet_stats["total_balance"] = agg["total_balance"] or Decimal("0")
        wallet_stats["total_locked"] = agg["total_locked"] or Decimal("0")
        wallet_stats["frozen_wallets"] = qs.filter(is_frozen=True).count()
    except Exception:
        logger.exception("Failed to aggregate wallet stats")

    return _render_admin(
        request,
        "admin_suite/credit_pricing.html",
        {
            "credit_fields": credit_fields,
            "wallet_stats": wallet_stats,
            "message": message,
            "msg_type": msg_type,
        },
        nav_active="credit_pricing",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Credit Pricing", None),
        ),
        subtitle="Credit & Economy Configuration",
    )


# =============================================================================
# SHOP — OVERVIEW / PACKAGE TIERS / ORDERS / SUBSCRIPTIONS / USER PACKAGES
# =============================================================================


@staff_member_required
def admin_suite_shop(request: HttpRequest) -> HttpResponse:
    """Shop overview dashboard with KPIs."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.shop.services import get_shop_stats

    stats = get_shop_stats()

    return _render_admin(
        request,
        "admin_suite/shop_overview.html",
        {"stats": stats},
        nav_active="shop",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Shop", None),
        ),
        subtitle="Shop & Packages Dashboard",
    )


@csrf_protect
@staff_member_required
def admin_suite_shop_packages(request: HttpRequest) -> HttpResponse:
    """Package tier management — list, create, edit, toggle."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from decimal import Decimal, InvalidOperation

    from apps.shop.models import PackageTier

    message = ""
    msg_type = ""

    if request.method == "POST":
        action = request.POST.get("action")

        if action == "toggle_tier":
            tier_id = request.POST.get("tier_id")
            try:
                tier = PackageTier.objects.get(pk=tier_id)
                tier.is_active = not tier.is_active
                tier.save(update_fields=["is_active"])
                state = "activated" if tier.is_active else "deactivated"
                message = f"Package '{tier.name}' {state}."
                msg_type = "success"
            except PackageTier.DoesNotExist:
                message = "Package tier not found."
                msg_type = "error"

        elif action == "save_tier":
            tier_id = request.POST.get("tier_id")
            try:
                if tier_id:
                    tier = PackageTier.objects.get(pk=tier_id)
                else:
                    tier = PackageTier()

                # String fields
                tier.name = (request.POST.get("name") or "").strip()
                tier.slug = (request.POST.get("slug") or "").strip()
                tier.tier_level = request.POST.get("tier_level", "free")
                tier.description = (request.POST.get("description") or "").strip()
                tier.badge_color = (request.POST.get("badge_color") or "blue").strip()
                tier.badge_icon = (request.POST.get("badge_icon") or "package").strip()

                # Decimal fields
                decimal_fields = [
                    "price_monthly",
                    "price_quarterly",
                    "price_yearly",
                    "price_lifetime",
                    "credit_price",
                ]
                for fname in decimal_fields:
                    raw = (request.POST.get(fname) or "0").strip()
                    try:
                        setattr(tier, fname, Decimal(raw))
                    except (InvalidOperation, ValueError):
                        message = f"Invalid decimal for {fname}: {raw}"
                        msg_type = "error"
                        break

                # Integer fields
                if not message:
                    int_fields = [
                        "trial_days",
                        "daily_download_limit",
                        "monthly_download_limit",
                        "max_file_size_mb",
                        "daily_bandwidth_mb",
                        "monthly_bandwidth_mb",
                        "max_download_speed_kbps",
                        "max_concurrent_downloads",
                        "cooldown_seconds",
                        "sort_order",
                    ]
                    for fname in int_fields:
                        raw = (request.POST.get(fname) or "0").strip()
                        try:
                            setattr(tier, fname, int(raw))
                        except ValueError:
                            message = f"Invalid integer for {fname}: {raw}"
                            msg_type = "error"
                            break

                # Boolean fields
                if not message:
                    bool_fields = [
                        "ad_free",
                        "priority_queue",
                        "resume_support",
                        "api_access",
                        "early_access",
                        "direct_links",
                        "access_official",
                        "access_engineering",
                        "access_readback",
                        "access_modified",
                        "is_active",
                        "is_default",
                        "is_featured",
                    ]
                    for fname in bool_fields:
                        setattr(tier, fname, request.POST.get(fname) == "on")

                if not message:
                    tier.save()
                    verb = "updated" if tier_id else "created"
                    message = f"Package '{tier.name}' {verb} successfully."
                    msg_type = "success"
            except PackageTier.DoesNotExist:
                message = "Package tier not found."
                msg_type = "error"
            except Exception as exc:
                message = f"Error saving tier: {exc}"
                msg_type = "error"

    tiers = PackageTier.objects.all().order_by("sort_order", "price_monthly")

    return _render_admin(
        request,
        "admin_suite/shop_packages.html",
        {
            "tiers": tiers,
            "tier_levels": PackageTier.TierLevel.choices,
            "message": message,
            "msg_type": msg_type,
        },
        nav_active="shop_packages",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Shop", "admin_suite:shop"),
            ("Packages", None),
        ),
        subtitle="Package Tier Management",
    )


@staff_member_required
def admin_suite_shop_orders(request: HttpRequest) -> HttpResponse:
    """Order management list for admin."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.shop.models import Order
    from apps.shop.services import get_order_list

    search = _admin_search(request)
    status_filter = request.GET.get("status", "")
    qs = get_order_list(search=search, status_filter=status_filter)
    qs, sort_field, sort_dir = _admin_sort(
        request,
        qs,
        {
            "date": "created_at",
            "total": "total",
            "status": "status",
            "user": "user__email",
        },
        default_sort="-created_at",
    )
    page = _admin_paginate(request, qs, per_page=25)

    return _render_admin(
        request,
        "admin_suite/shop_orders.html",
        {
            "orders": page,
            "search": search,
            "status_filter": status_filter,
            "status_choices": Order.Status.choices,
            "sort_field": sort_field,
            "sort_dir": sort_dir,
        },
        nav_active="shop_orders",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Shop", "admin_suite:shop"),
            ("Orders", None),
        ),
        subtitle="Order Management",
    )


@staff_member_required
def admin_suite_shop_subscriptions(request: HttpRequest) -> HttpResponse:
    """Subscription list for admin."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.shop.models import Subscription
    from apps.shop.services import get_subscription_list

    search = _admin_search(request)
    status_filter = request.GET.get("status", "")
    qs = get_subscription_list(search=search, status_filter=status_filter)
    qs, sort_field, sort_dir = _admin_sort(
        request,
        qs,
        {
            "date": "started_at",
            "status": "status",
            "user": "user__email",
            "plan": "plan__name",
        },
        default_sort="-started_at",
    )
    page = _admin_paginate(request, qs, per_page=25)

    return _render_admin(
        request,
        "admin_suite/shop_subscriptions.html",
        {
            "subscriptions": page,
            "search": search,
            "status_filter": status_filter,
            "status_choices": Subscription.Status.choices,
            "sort_field": sort_field,
            "sort_dir": sort_dir,
        },
        nav_active="shop_subscriptions",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Shop", "admin_suite:shop"),
            ("Subscriptions", None),
        ),
        subtitle="Subscription Management",
    )


@staff_member_required
def admin_suite_shop_user_packages(request: HttpRequest) -> HttpResponse:
    """User package assignment list for admin."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.shop.models import UserPackage
    from apps.shop.services import get_user_package_list

    search = _admin_search(request)
    status_filter = request.GET.get("status", "")
    qs = get_user_package_list(search=search, status_filter=status_filter)
    qs, sort_field, sort_dir = _admin_sort(
        request,
        qs,
        {
            "date": "started_at",
            "status": "status",
            "user": "user__email",
            "package": "package__name",
        },
        default_sort="-started_at",
    )
    page = _admin_paginate(request, qs, per_page=25)

    return _render_admin(
        request,
        "admin_suite/shop_user_packages.html",
        {
            "user_packages": page,
            "search": search,
            "status_filter": status_filter,
            "status_choices": UserPackage.Status.choices,
            "sort_field": sort_field,
            "sort_dir": sort_dir,
        },
        nav_active="shop_user_packages",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Shop", "admin_suite:shop"),
            ("User Packages", None),
        ),
        subtitle="User Package Assignments",
    )


# =============================================================================
# MARKETPLACE — OVERVIEW / SELLERS / LISTINGS / VERIFICATIONS
# =============================================================================


@staff_member_required
def admin_suite_marketplace(request: HttpRequest) -> HttpResponse:
    """Marketplace overview dashboard."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.marketplace.services import get_marketplace_stats

    stats = get_marketplace_stats()

    return _render_admin(
        request,
        "admin_suite/marketplace_overview.html",
        {"stats": stats},
        nav_active="marketplace",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Marketplace", None),
        ),
        subtitle="Marketplace Dashboard",
    )


@staff_member_required
def admin_suite_marketplace_sellers(request: HttpRequest) -> HttpResponse:
    """Seller management list."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.marketplace.services import get_seller_list

    search = _admin_search(request)
    verified_filter = request.GET.get("verified", "")
    qs = get_seller_list(search=search, verified_filter=verified_filter)
    qs, sort_field, sort_dir = _admin_sort(
        request,
        qs,
        {
            "name": "display_name",
            "sales": "total_sales",
            "rating": "rating",
            "date": "created_at",
        },
        default_sort="-total_sales",
    )
    page = _admin_paginate(request, qs, per_page=25)

    return _render_admin(
        request,
        "admin_suite/marketplace_sellers.html",
        {
            "sellers": page,
            "search": search,
            "verified_filter": verified_filter,
            "sort_field": sort_field,
            "sort_dir": sort_dir,
        },
        nav_active="marketplace_sellers",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Marketplace", "admin_suite:marketplace"),
            ("Sellers", None),
        ),
        subtitle="Seller Management",
    )


@staff_member_required
def admin_suite_marketplace_listings(request: HttpRequest) -> HttpResponse:
    """Listing management view."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.marketplace.services import get_listing_list

    search = _admin_search(request)
    status_filter = request.GET.get("status", "")
    qs = get_listing_list(search=search, status_filter=status_filter)
    qs, sort_field, sort_dir = _admin_sort(
        request,
        qs,
        {
            "title": "title",
            "price": "price",
            "sales": "sale_count",
            "views": "view_count",
            "date": "created_at",
        },
        default_sort="-created_at",
    )
    page = _admin_paginate(request, qs, per_page=25)

    return _render_admin(
        request,
        "admin_suite/marketplace_listings.html",
        {
            "listings": page,
            "search": search,
            "status_filter": status_filter,
            "sort_field": sort_field,
            "sort_dir": sort_dir,
        },
        nav_active="marketplace_listings",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Marketplace", "admin_suite:marketplace"),
            ("Listings", None),
        ),
        subtitle="Listing Management",
    )


@csrf_protect
@staff_member_required
def admin_suite_marketplace_verifications(request: HttpRequest) -> HttpResponse:
    """Seller verification requests — approve/reject."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.marketplace.models import SellerVerification
    from apps.marketplace.services import get_verification_list

    message = ""
    msg_type = ""

    if request.method == "POST":
        action = request.POST.get("action")
        ver_id = request.POST.get("verification_id")

        if action in ("approve", "reject") and ver_id:
            try:
                ver = SellerVerification.objects.select_related("seller").get(pk=ver_id)
                if action == "approve":
                    ver.status = "approved"
                    ver.reviewed_at = timezone.now()
                    ver.reviewer = request.user
                    ver.save(update_fields=["status", "reviewed_at", "reviewer"])
                    ver.seller.verified = True
                    ver.seller.save(update_fields=["verified"])
                    message = f"Seller '{ver.seller}' approved."
                    msg_type = "success"
                else:
                    ver.status = "rejected"
                    ver.reviewed_at = timezone.now()
                    ver.reviewer = request.user
                    notes = (request.POST.get("notes") or "").strip()
                    if notes:
                        ver.notes = notes
                    ver.save(
                        update_fields=[
                            "status",
                            "reviewed_at",
                            "reviewer",
                            "notes",
                        ]
                    )
                    message = f"Verification for '{ver.seller}' rejected."
                    msg_type = "warning"
            except SellerVerification.DoesNotExist:
                message = "Verification request not found."
                msg_type = "error"

    status_filter = request.GET.get("status", "")
    qs = get_verification_list(status_filter=status_filter)
    page = _admin_paginate(request, qs, per_page=25)

    return _render_admin(
        request,
        "admin_suite/marketplace_verifications.html",
        {
            "verifications": page,
            "status_filter": status_filter,
            "status_choices": SellerVerification.Status.choices,
            "message": message,
            "msg_type": msg_type,
        },
        nav_active="marketplace_verifications",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Marketplace", "admin_suite:marketplace"),
            ("Verifications", None),
        ),
        subtitle="Seller Verification Requests",
    )


__all__ = [
    # AI Extended
    "admin_suite_ai_endpoints",
    "admin_suite_ai_knowledge",
    "admin_suite_ai_workflows",
    # Blog Extended
    "admin_suite_blog_posts",
    # Crawler Guard
    "admin_suite_crawler_rules",
    # Credit Pricing
    "admin_suite_credit_pricing",
    # Devices
    "admin_suite_devices_settings",
    # Core
    "admin_suite_features",
    # i18n
    "admin_suite_i18n",
    "admin_suite_i18n_translations",
    # Shop
    "admin_suite_shop",
    "admin_suite_shop_packages",
    "admin_suite_shop_orders",
    "admin_suite_shop_subscriptions",
    "admin_suite_shop_user_packages",
    # Marketplace
    "admin_suite_marketplace",
    "admin_suite_marketplace_sellers",
    "admin_suite_marketplace_listings",
    "admin_suite_marketplace_verifications",
]
