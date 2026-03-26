from __future__ import annotations

from datetime import timedelta

from django.conf import settings
from django.contrib.admin.views.decorators import staff_member_required
from django.db.models import Q
from django.http import Http404, HttpRequest, HttpResponse
from django.utils import timezone
from django.views.decorators.csrf import csrf_protect

from apps.admin.views_shared import (
    _ADMIN_DISABLED,
    _make_breadcrumb,
    _render_admin,
    logger,
)
from apps.core.models import AppRegistry
from apps.distribution.api import get_settings as dist_get_settings
from apps.distribution.forms import SocialAccountForm
from apps.distribution.models import (
    ContentVariant,
    GeneratedVideo,
    ShareJob,
    ShareLog,
    SharePlan,
    SocialAccount,
)
from apps.distribution.tasks import enqueue_pending_for_account
from apps.users.models_social import SocialPostingAccount

__all__ = [
    "admin_suite_distribution",
    "admin_suite_distribution_settings",
    "admin_suite_social_posting",
    "admin_suite_social_posting_detail",
    "admin_suite_social_posting_oauth_callback",
]


@csrf_protect
@staff_member_required
def admin_suite_distribution(request: HttpRequest) -> HttpResponse:
    """Distribution overview with SocialAccount editor and job controls."""
    if not getattr(AppRegistry.get_solo(), "distribution_enabled", True):
        raise _ADMIN_DISABLED

    stats = {
        "accounts": 0,
        "plans": 0,
        "jobs_pending": 0,
        "jobs_failed": 0,
        "logs_24h": 0,
    }
    message = ""
    active_tab = request.GET.get("tab", "accounts")
    query = (request.GET.get("q") or "").strip()
    account_form = SocialAccountForm()

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            if action == "disable_account":
                aid = request.POST.get("account_id")
                SocialAccount.objects.filter(pk=aid).update(is_active=False)
                message = "Account disabled."
            elif action == "enable_account":
                aid = request.POST.get("account_id")
                SocialAccount.objects.filter(pk=aid).update(is_active=True)
                message = "Account enabled."
            elif action == "save_account":
                aid = request.POST.get("account_id")
                instance = SocialAccount.objects.filter(pk=aid).first() if aid else None
                form = SocialAccountForm(request.POST, instance=instance)
                if form.is_valid():
                    acc = form.save()
                    try:
                        enqueue_pending_for_account(acc)
                    except Exception:
                        logger.debug(
                            "enqueue_pending_for_account failed", exc_info=True
                        )
                    message = "Account saved."
                else:
                    message = "Invalid account form."
            elif action == "retry_job":
                jid = request.POST.get("job_id")
                ShareJob.objects.filter(pk=jid).update(status="pending", last_error="")
                message = "Job retried."
            elif action == "cancel_job":
                jid = request.POST.get("job_id")
                ShareJob.objects.filter(pk=jid).update(status="cancelled")
                message = "Job cancelled."
            elif action == "create_posting_account":
                platform = request.POST.get("platform", "").strip()
                acct_name = request.POST.get("posting_account_name", "").strip()
                if not platform:
                    message = "Platform is required."
                elif not acct_name:
                    message = "Account name is required."
                else:
                    auth_info = SocialPostingAccount.get_auth_info(platform)
                    auth_type = auth_info.get("auth_type", "oauth2")
                    acct = SocialPostingAccount.objects.create(
                        platform=platform,
                        account_name=acct_name,
                        auth_type=auth_type,
                        destination_type=request.POST.get("destination_type", "page"),
                        destination_name=request.POST.get(
                            "destination_name", ""
                        ).strip(),
                        destination_id=request.POST.get("destination_id", "").strip(),
                        status="unconfigured",
                        created_by=request.user,
                    )
                    # Set credentials based on auth type
                    if auth_type == "api_token":
                        bot_token = request.POST.get("bot_token", "").strip()
                        if bot_token:
                            acct.set_bot_token(bot_token)
                            acct.status = "active"
                    elif auth_type == "webhook":
                        webhook_url = request.POST.get("webhook_url", "").strip()
                        if webhook_url:
                            acct.set_webhook_url(webhook_url)
                            acct.status = "active"
                    elif auth_type == "access_token":
                        access_token = request.POST.get(
                            "posting_access_token", ""
                        ).strip()
                        if access_token:
                            acct.set_access_token(access_token)
                            acct.status = "active"
                    elif auth_type in ("api_key_secret", "oauth2"):
                        api_key = request.POST.get("api_key", "").strip()
                        api_secret = request.POST.get("api_secret", "").strip()
                        if api_key:
                            acct.set_api_key(api_key)
                        if api_secret:
                            acct.set_api_secret(api_secret)
                    acct.save()
                    if auth_info.get("requires_oauth"):
                        message = f"Created {acct.get_platform_display()}. Configure OAuth in account settings."  # type: ignore[attr-defined]
                    else:
                        message = f"Created {acct.get_platform_display()} account."  # type: ignore[attr-defined]
            elif action == "toggle_posting_account":
                paid = request.POST.get("posting_account_id")
                pa = SocialPostingAccount.objects.filter(id=paid).first()
                if pa:
                    pa.is_enabled = not pa.is_enabled
                    if not pa.is_enabled:
                        pa.status = "disabled"
                    elif pa.has_credentials:
                        pa.status = "active"
                    pa.save(update_fields=["is_enabled", "status", "updated_at"])
                    state = "enabled" if pa.is_enabled else "disabled"
                    message = f"{pa.account_name} {state}."
            elif action == "test_posting_connection":
                paid = request.POST.get("posting_account_id")
                pa = SocialPostingAccount.objects.filter(id=paid).first()
                if pa:
                    _ok, msg = pa.test_connection()
                    message = f"{pa.get_platform_display()}: {msg}"  # type: ignore[attr-defined]
            elif action == "generate_video":
                post_id = request.POST.get("post_id")
                if post_id:
                    from apps.blog.models import Post as BlogPost
                    from apps.distribution.services import (
                        create_video_variants_for_post,
                    )

                    post_obj = BlogPost.objects.filter(pk=int(post_id)).first()
                    if post_obj:
                        results = create_video_variants_for_post(post_obj)
                        message = f"Generated {len(results)} video script(s)."
                    else:
                        message = f"Post {post_id} not found."
                else:
                    message = "Post ID required for video generation."
            elif action == "bulk_generate_video":
                post_ids = request.POST.getlist("video_post_ids")
                if post_ids:
                    from apps.blog.models import Post as BlogPost
                    from apps.distribution.services import (
                        create_video_variants_for_post,
                    )

                    count = 0
                    for pid in post_ids:
                        post_obj = BlogPost.objects.filter(pk=int(pid)).first()
                        if post_obj:
                            create_video_variants_for_post(post_obj)
                            count += 1
                    message = f"Generated video scripts for {count} post(s)."
                else:
                    message = "Select at least one topic."
            elif action == "toggle_distribution_setting":
                from apps.distribution.models import DistributionSettings

                field = request.POST.get("field", "")
                allowed = {
                    "distribution_enabled",
                    "auto_fanout_on_publish",
                    "allow_indexing_jobs",
                    "enable_firmware_auto_distribution",
                    "require_admin_approval",
                }
                if field in allowed:
                    ds = DistributionSettings.get_solo()
                    current = getattr(ds, field, False)
                    setattr(ds, field, not current)
                    ds.save(update_fields=[field])
                    state = "enabled" if not current else "disabled"
                    label = field.replace("_", " ").title()
                    message = f"{label} {state}."
                else:
                    message = "Unknown setting."
            elif action == "delete_video_script":
                vid = request.POST.get("video_script_id")
                if vid:
                    deleted = ContentVariant.objects.filter(
                        pk=vid, variant_type="video_script"
                    ).delete()
                    message = (
                        "Video script deleted." if deleted[0] else "Script not found."
                    )
            elif action == "render_video":
                active_tab = "video"
                post_id = request.POST.get("post_id")
                platform = request.POST.get("platform", "").strip()
                auto_pub = bool(request.POST.get("auto_publish"))
                if post_id:
                    from apps.blog.models import Post as BlogPost
                    from apps.distribution.video_generator import (
                        generate_all_platform_videos as gen_all_videos,
                    )
                    from apps.distribution.video_generator import (
                        generate_video_for_post,
                    )

                    post_obj = BlogPost.objects.filter(pk=int(post_id)).first()
                    if post_obj:
                        if platform:
                            video = generate_video_for_post(
                                post_obj,
                                platform,
                                auto_publish=auto_pub,
                                created_by=request.user,
                            )
                            message = f"Video rendered for {platform} (ID: {video.pk})."
                        else:
                            videos = gen_all_videos(
                                post_obj,
                                auto_publish=auto_pub,
                                created_by=request.user,
                            )
                            message = (
                                f"Rendered {len(videos)} video(s) across platforms."
                            )
                    else:
                        message = f"Post {post_id} not found."
                else:
                    message = "Post ID required."
            elif action == "bulk_render_videos":
                active_tab = "video"
                post_ids = request.POST.getlist("video_post_ids")
                if post_ids:
                    from apps.blog.models import Post as BlogPost
                    from apps.distribution.video_generator import (
                        generate_all_platform_videos as gen_all_videos,
                    )

                    count = 0
                    for pid in post_ids:
                        post_obj = BlogPost.objects.filter(pk=int(pid)).first()
                        if post_obj:
                            gen_all_videos(post_obj, created_by=request.user)
                            count += 1
                    message = (
                        f"Rendered videos for {count} post(s) across all platforms."
                    )
                else:
                    message = "Select at least one post."
            elif action == "rerender_video":
                active_tab = "video"
                vid = request.POST.get("video_id")
                if vid:
                    gv = (
                        GeneratedVideo.objects.filter(pk=vid)
                        .select_related("post")
                        .first()
                    )
                    if gv:
                        from apps.distribution.video_generator import (
                            generate_video_for_post,
                        )

                        video = generate_video_for_post(
                            gv.post,
                            gv.platform,
                            created_by=request.user,
                        )
                        message = (
                            f"Re-rendered {gv.get_platform_display()} (ID: {video.pk})."  # type: ignore[attr-defined]
                        )
                    else:
                        message = "Video not found."
            elif action == "delete_video":
                active_tab = "video"
                vid = request.POST.get("video_id")
                if vid:
                    gv = GeneratedVideo.objects.filter(pk=vid).first()
                    if gv:
                        # Delete the file from storage
                        if gv.video_file:
                            gv.video_file.delete(save=False)
                        if gv.thumbnail:
                            gv.thumbnail.delete(save=False)
                        gv.delete()
                        message = "Video deleted."
                    else:
                        message = "Video not found."
            elif action == "publish_video":
                active_tab = "video"
                vid = request.POST.get("video_id")
                if vid:
                    gv = GeneratedVideo.objects.filter(pk=vid).first()
                    if gv:
                        gv.publish_queued = True
                        gv.save(update_fields=["publish_queued"])
                        message = f"Video queued for publishing to {gv.get_platform_display()}."  # type: ignore[attr-defined]
                    else:
                        message = "Video not found."
        except Exception as exc:
            logger.warning("Admin suite distribution action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        dist_settings = dist_get_settings()
        stats["accounts"] = SocialAccount.objects.count()
        stats["posting_accounts"] = SocialPostingAccount.objects.count()
        stats["posting_active"] = SocialPostingAccount.objects.filter(
            status="active"
        ).count()
        stats["plans"] = SharePlan.objects.count()
        stats["jobs_pending"] = ShareJob.objects.filter(status="pending").count()
        stats["jobs_failed"] = ShareJob.objects.filter(status="failed").count()

        since = timezone.now() - timedelta(hours=24)
        stats["logs_24h"] = ShareLog.objects.filter(created_at__gte=since).count()

        account_qs = SocialAccount.objects.order_by("channel", "account_name")
        posting_account_qs = SocialPostingAccount.objects.order_by(
            "platform", "account_name"
        )
        plan_qs = SharePlan.objects.order_by("-created_at")
        jobs_qs = ShareJob.objects.order_by("-created_at")
        logs_qs = ShareLog.objects.order_by("-created_at")
        if query:
            account_qs = account_qs.filter(
                Q(channel__icontains=query) | Q(account_name__icontains=query)
            )
            posting_account_qs = posting_account_qs.filter(
                Q(platform__icontains=query) | Q(account_name__icontains=query)
            )
            plan_qs = plan_qs.filter(Q(post__title__icontains=query))
            jobs_qs = jobs_qs.filter(
                Q(channel__icontains=query) | Q(status__icontains=query)
            )
            logs_qs = logs_qs.filter(
                Q(level__icontains=query) | Q(message__icontains=query)
            )

        accounts = account_qs[:50]
        posting_accounts = list(posting_account_qs[:50])
        plans = plan_qs[:50]
        jobs = jobs_qs[:50]
        logs = logs_qs[:50]

        # Group posting accounts by platform
        posting_by_platform: dict[str, list[SocialPostingAccount]] = {}
        for pa in posting_accounts:
            posting_by_platform.setdefault(pa.platform, []).append(pa)

        # Platform info for creation form
        platform_info = {
            key: SocialPostingAccount.get_auth_info(key)
            for key, _ in SocialPostingAccount.PLATFORM_CHOICES
        }

        video_scripts = (
            ContentVariant.objects.filter(variant_type="video_script")
            .select_related("post")
            .order_by("-generated_at")[:50]
        )
        stats["video_scripts"] = ContentVariant.objects.filter(
            variant_type="video_script"
        ).count()

        # Generated videos (actual rendered video files)
        generated_videos = GeneratedVideo.objects.select_related("post").order_by(
            "-created_at"
        )[:50]
        stats["videos_total"] = GeneratedVideo.objects.count()
        stats["videos_completed"] = GeneratedVideo.objects.filter(
            status="completed"
        ).count()
        stats["videos_rendering"] = GeneratedVideo.objects.filter(
            status__in=["rendering", "processing"]
        ).count()
        stats["videos_queued"] = GeneratedVideo.objects.filter(status="queued").count()
        stats["videos_failed"] = GeneratedVideo.objects.filter(status="failed").count()
    except Exception as exc:
        logger.warning(
            "Admin suite distribution snapshot failed: %s", exc, exc_info=True
        )
        dist_settings = {}
        accounts = plans = jobs = logs = video_scripts = []
        generated_videos = []
        posting_accounts = []
        posting_by_platform = {}
        platform_info = {}
        message = f"Unable to load distribution data: {exc}"

    # Trending topics for video generation
    trending_posts: list[object] = []
    trending_topics: list[object] = []
    try:
        from apps.blog.models import Post

        trending_posts = list(
            Post.objects.filter(status="published")
            .order_by("-views_count")[:15]
            .values("id", "title", "views_count", "created_at")
        )
    except Exception:
        logger.debug("Failed to load trending posts", exc_info=True)

    try:
        from apps.forum.models import ForumTopic

        trending_topics = list(
            ForumTopic.objects.filter(is_removed=False)
            .order_by("-view_count", "-reply_count")[:15]
            .values("id", "title", "view_count", "reply_count", "created_at")
        )
    except Exception:
        logger.debug("Failed to load trending forum topics", exc_info=True)

    return _render_admin(
        request,
        "admin_suite/distribution.html",
        {
            "stats": stats,
            "accounts": accounts,
            "posting_accounts": posting_accounts,
            "posting_by_platform": posting_by_platform,
            "platform_choices": SocialPostingAccount.PLATFORM_CHOICES,
            "platform_info": platform_info,
            "destination_choices": SocialPostingAccount.DESTINATION_TYPE_CHOICES,
            "plans": plans,
            "jobs": jobs,
            "logs": logs,
            "video_scripts": video_scripts,
            "generated_videos": generated_videos,
            "trending_posts": trending_posts,
            "trending_topics": trending_topics,
            "q": query,
            "message": message,
            "active_tab": active_tab,
            "dist_settings": dist_settings,
            "account_form": account_form,
        },
        nav_active="distribution",
        breadcrumb=_make_breadcrumb(("Distribution", None)),
    )


# ==============================================================================
# Social Posting Account Management
# ==============================================================================


@csrf_protect
@staff_member_required
def admin_suite_social_posting(request: HttpRequest) -> HttpResponse:
    """
    Social media posting accounts management for auto-posting content.

    Configure accounts for:
    - Facebook (Pages/Groups)
    - Twitter/X
    - LinkedIn (Company/Personal)
    - Telegram (Channels/Groups)
    - WhatsApp Business
    - Instagram (via Facebook)
    - Discord (Webhooks)
    - And more...
    """
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        account_id = request.POST.get("account_id")

        try:
            if action == "create_account":
                platform = request.POST.get("platform")
                account_name = request.POST.get("account_name", "").strip()

                if not platform:
                    message = "Platform is required."
                elif not account_name:
                    message = "Account name is required."
                else:
                    auth_info = SocialPostingAccount.get_auth_info(platform)
                    auth_type = auth_info.get("auth_type", "oauth2")

                    account = SocialPostingAccount.objects.create(
                        platform=platform,
                        account_name=account_name,
                        auth_type=auth_type,
                        destination_type=request.POST.get("destination_type", "page"),
                        destination_name=request.POST.get(
                            "destination_name", ""
                        ).strip(),
                        destination_id=request.POST.get("destination_id", "").strip(),
                        status="unconfigured",
                        created_by=request.user,
                    )

                    # Handle credentials based on platform type
                    if auth_type == "api_token":
                        # Telegram bot token
                        bot_token = request.POST.get("bot_token", "").strip()
                        if bot_token:
                            account.set_bot_token(bot_token)
                            account.status = "active"
                    elif auth_type == "webhook":
                        # Discord webhook
                        webhook_url = request.POST.get("webhook_url", "").strip()
                        if webhook_url:
                            account.set_webhook_url(webhook_url)
                            account.status = "active"
                    elif auth_type == "access_token":
                        # Medium integration token
                        access_token = request.POST.get("access_token", "").strip()
                        if access_token:
                            account.set_access_token(access_token)
                            account.status = "active"
                    elif auth_type == "api_key_secret":
                        # Twitter API keys
                        api_key = request.POST.get("api_key", "").strip()
                        api_secret = request.POST.get("api_secret", "").strip()
                        if api_key:
                            account.set_api_key(api_key)
                        if api_secret:
                            account.set_api_secret(api_secret)

                    account.save()

                    # For OAuth platforms, redirect to auth
                    if auth_info.get("requires_oauth"):
                        message = f"Created {account.get_platform_display()}. Click 'Connect' to authorize via OAuth."  # type: ignore[attr-defined]
                    else:
                        message = f"Created {account.get_platform_display()} account."  # type: ignore[attr-defined]

            elif action == "test_connection" and account_id:
                account = SocialPostingAccount.objects.filter(id=account_id).first()
                if account:
                    _success, msg = account.test_connection()
                    message = f"{account.get_platform_display()}: {msg}"  # type: ignore[attr-defined]

            elif action == "toggle_account" and account_id:
                account = SocialPostingAccount.objects.filter(id=account_id).first()
                if account:
                    account.is_enabled = not account.is_enabled
                    if not account.is_enabled:
                        account.status = "disabled"
                    elif account.has_credentials:
                        account.status = "active"
                    account.save(update_fields=["is_enabled", "status", "updated_at"])
                    message = f"{account.account_name} {'enabled' if account.is_enabled else 'disabled'}."

            elif action == "delete_account" and account_id:
                if not getattr(request.user, "is_superuser", False):
                    message = "Superuser required to delete accounts."
                else:
                    account = SocialPostingAccount.objects.filter(id=account_id).first()
                    if account:
                        name = (
                            f"{account.get_platform_display()} - {account.account_name}"  # type: ignore[attr-defined]
                        )
                        account.delete()
                        message = f"Deleted {name}."

            elif action == "send_test_post" and account_id:
                account = SocialPostingAccount.objects.filter(id=account_id).first()
                if account:
                    if account.status != "active":
                        message = "Account must be active to send test post."
                    elif not account.can_post_now:
                        message = "Cannot post now (rate limited or disabled)."
                    else:
                        # Send test post
                        test_content = account.format_post(
                            title="Test Post from Admin",
                            excerpt="This is a test post to verify the connection is working.",
                            url="https://example.com/test",
                            tags=["test"],
                        )
                        message = (
                            f"Test post prepared: {test_content['content'][:100]}..."
                        )

        except Exception as exc:
            logger.warning("Social posting action failed: %s", exc)
            message = f"Action failed: {exc}"

    # Get all configured accounts
    accounts = list(SocialPostingAccount.objects.order_by("platform", "account_name"))

    # Group accounts by platform
    accounts_by_platform = {}
    for account in accounts:
        platform = account.platform
        if platform not in accounts_by_platform:
            accounts_by_platform[platform] = []
        accounts_by_platform[platform].append(account)

    # Platform info for adding new accounts
    platform_info = {
        key: SocialPostingAccount.get_auth_info(key)
        for key, _ in SocialPostingAccount.PLATFORM_CHOICES
    }

    # Stats
    stats = {
        "total_accounts": len(accounts),
        "active_accounts": sum(1 for a in accounts if a.status == "active"),
        "total_posts": sum(a.total_posts for a in accounts),
        "successful_posts": sum(a.successful_posts for a in accounts),
    }

    return _render_admin(
        request,
        "admin_suite/social_posting.html",
        {
            "accounts": accounts,
            "accounts_by_platform": accounts_by_platform,
            "platform_choices": SocialPostingAccount.PLATFORM_CHOICES,
            "platform_info": platform_info,
            "destination_choices": SocialPostingAccount.DESTINATION_TYPE_CHOICES,
            "content_type_choices": SocialPostingAccount.POST_CONTENT_CHOICES,
            "stats": stats,
            "message": message,
        },
        nav_active="distribution",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Distribution", "admin_suite:distribution"),
            ("Social Posting", None),
        ),
        subtitle="Configure social media accounts for auto-posting",
    )


@csrf_protect
@staff_member_required
def admin_suite_social_posting_detail(
    request: HttpRequest, account_id: str
) -> HttpResponse:
    """
    Detailed view for a single social posting account.
    """
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    try:
        account = SocialPostingAccount.objects.get(id=account_id)
    except SocialPostingAccount.DoesNotExist:
        raise Http404("Account not found")  # noqa: B904

    message = ""

    if request.method == "POST":
        action = request.POST.get("action")

        try:
            if action == "update_credentials":
                # Update credentials based on auth type
                if account.auth_type == "api_token":
                    bot_token = request.POST.get("bot_token", "").strip()
                    if bot_token:
                        account.set_bot_token(bot_token)
                    chat_id = request.POST.get("destination_id", "").strip()
                    if chat_id:
                        account.destination_id = chat_id

                elif account.auth_type == "webhook":
                    webhook_url = request.POST.get("webhook_url", "").strip()
                    if webhook_url:
                        account.set_webhook_url(webhook_url)

                elif account.auth_type == "access_token":
                    access_token = request.POST.get("access_token", "").strip()
                    if access_token:
                        account.set_access_token(access_token)

                elif account.auth_type in ["api_key_secret", "oauth2"]:
                    api_key = request.POST.get("api_key", "").strip()
                    api_secret = request.POST.get("api_secret", "").strip()
                    if api_key:
                        account.set_api_key(api_key)
                    if api_secret:
                        account.set_api_secret(api_secret)

                # Update account info
                account.account_name = (
                    request.POST.get("account_name", "").strip() or account.account_name
                )
                account.destination_type = request.POST.get(
                    "destination_type", account.destination_type
                )
                account.destination_id = (
                    request.POST.get("destination_id", "").strip()
                    or account.destination_id
                )
                account.destination_name = (
                    request.POST.get("destination_name", "").strip()
                    or account.destination_name
                )
                account.destination_url = (
                    request.POST.get("destination_url", "").strip()
                    or account.destination_url
                )

                if account.has_credentials:
                    account.status = "active"

                account.save()
                message = "Credentials updated."

            elif action == "update_posting_settings":
                account.auto_post_enabled = (
                    request.POST.get("auto_post_enabled") == "on"
                )
                account.post_content_types = request.POST.get(
                    "post_content_types", "both"
                )
                account.post_template = request.POST.get("post_template", "").strip()
                account.include_image = request.POST.get("include_image") == "on"
                account.include_link = request.POST.get("include_link") == "on"
                account.hashtags = request.POST.get("hashtags", "").strip()

                # Rate limiting
                try:
                    account.min_post_interval_minutes = int(
                        request.POST.get("min_post_interval", 60)
                    )
                except (ValueError, TypeError):
                    pass
                try:
                    account.daily_post_limit = int(
                        request.POST.get("daily_post_limit", 10)
                    )
                except (ValueError, TypeError):
                    pass

                account.notes = request.POST.get("notes", "").strip()
                account.save()
                message = "Posting settings updated."

            elif action == "test_connection":
                _success, msg = account.test_connection()
                message = msg

            elif action == "send_test_post":
                if account.status != "active":
                    message = "Account must be active to send test post."
                else:
                    test_content = account.format_post(
                        title="Test Post from Admin",
                        excerpt="This is a test post to verify the social posting connection is working correctly.",
                        url=f"https://{request.get_host()}/",
                        tags=["test", "platform"],
                    )
                    # In reality, this would call the posting service
                    message = f"Test post content: {test_content['content'][:200]}..."

            elif action == "reset_counters":
                account.posts_today = 0
                account.consecutive_failures = 0
                account.save(
                    update_fields=["posts_today", "consecutive_failures", "updated_at"]
                )
                message = "Counters reset."

            elif action == "start_oauth":
                # Generate OAuth URL for the platform
                auth_info = account.auth_info
                if auth_info.get("requires_oauth"):
                    # Store state for OAuth callback
                    import secrets

                    oauth_state = secrets.token_urlsafe(32)
                    request.session[f"oauth_state_{account.id}"] = oauth_state
                    message = f"OAuth flow would redirect to: {auth_info.get('oauth_url', 'N/A')}"
                else:
                    message = "This platform does not require OAuth."

            elif action == "delete_account":
                if not getattr(request.user, "is_superuser", False):
                    message = "Superuser required to delete accounts."
                else:
                    from django.shortcuts import redirect

                    account.delete()
                    return redirect("admin_suite:social_posting")

        except Exception as exc:
            logger.warning("Social posting detail action failed: %s", exc)
            message = f"Action failed: {exc}"

    # Get auth info for this platform
    auth_info = account.auth_info

    return _render_admin(
        request,
        "admin_suite/social_posting_detail.html",
        {
            "account": account,
            "auth_info": auth_info,
            "destination_choices": SocialPostingAccount.DESTINATION_TYPE_CHOICES,
            "content_type_choices": SocialPostingAccount.POST_CONTENT_CHOICES,
            "default_template": account.get_default_template(),
            "message": message,
        },
        nav_active="distribution",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Distribution", "admin_suite:distribution"),
            ("Social Posting", "admin_suite:social_posting"),
            (f"{account.get_platform_display()} - {account.account_name}", None),  # type: ignore[attr-defined]
        ),
        subtitle=f"Configure {account.get_platform_display()} posting",  # type: ignore[attr-defined]
    )


@csrf_protect
@staff_member_required
def admin_suite_social_posting_oauth_callback(
    request: HttpRequest, platform: str
) -> HttpResponse:
    """
    OAuth callback handler for social posting platforms.

    After user authorizes in the browser, the platform redirects here with
    the authorization code which we exchange for access tokens.
    """
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from django.shortcuts import redirect

    code = request.GET.get("code")
    request.GET.get("state")
    error = request.GET.get("error")

    if error:
        # OAuth was denied or failed
        logger.warning(f"OAuth error for {platform}: {error}")
        # Redirect back to social posting with error
        return redirect("admin_suite:social_posting")

    if not code:
        logger.warning(f"OAuth callback for {platform} missing code")
        return redirect("admin_suite:social_posting")

    # Find the account that initiated this OAuth flow
    # In a real implementation, we'd validate the state parameter
    # and exchange the code for tokens

    try:
        # Exchange code for tokens (platform-specific)
        # This is a placeholder - real implementation would call the platform's token endpoint
        logger.info(f"OAuth callback received for {platform} with code: {code[:10]}...")

        # Example token exchange would go here
        # tokens = exchange_code_for_tokens(platform, code)
        # account.set_access_token(tokens['access_token'])
        # account.set_refresh_token(tokens.get('refresh_token', ''))
        # account.token_expiry = calculate_expiry(tokens)
        # account.status = 'active'
        # account.save()

    except Exception as exc:
        logger.error(f"OAuth token exchange failed for {platform}: {exc}")

    return redirect("admin_suite:social_posting")


# ==============================================================================
# Distribution Settings
# ==============================================================================


@csrf_protect
@staff_member_required
def admin_suite_distribution_settings(request: HttpRequest) -> HttpResponse:
    """
    Global distribution settings configuration (django-solo singleton).
    """
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from apps.distribution.models import DistributionSettings

    dist_settings = DistributionSettings.get_solo()
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")

        if action == "save_settings":
            try:
                # General
                dist_settings.distribution_enabled = (
                    request.POST.get("distribution_enabled") == "on"
                )
                dist_settings.auto_fanout_on_publish = (
                    request.POST.get("auto_fanout_on_publish") == "on"
                )
                channels_raw = request.POST.get("default_channels", "").strip()
                dist_settings.default_channels = (
                    [c.strip() for c in channels_raw.split(",") if c.strip()]
                    if channels_raw
                    else []
                )

                # Platform limits
                for int_field in [
                    "max_platforms_per_content",
                    "distribution_frequency_hours",
                    "max_seo_title_length",
                    "max_seo_description_length",
                    "max_seo_tags",
                    "max_auto_tags",
                    "auto_tag_frequency_days",
                    "max_retries",
                    "retry_backoff_seconds",
                ]:
                    val = request.POST.get(int_field)
                    if val is not None:
                        try:
                            setattr(dist_settings, int_field, int(val))
                        except (ValueError, TypeError):
                            pass

                # Advanced
                dist_settings.allow_indexing_jobs = (
                    request.POST.get("allow_indexing_jobs") == "on"
                )
                dist_settings.require_admin_approval = (
                    request.POST.get("require_admin_approval") == "on"
                )
                dist_settings.enable_firmware_auto_distribution = (
                    request.POST.get("enable_firmware_auto_distribution") == "on"
                )

                dist_settings.save()
                message = "Settings saved successfully."
            except Exception as exc:
                logger.warning("Distribution settings save failed: %s", exc)
                message = f"Save failed: {exc}"

    return _render_admin(
        request,
        "admin_suite/distribution_settings.html",
        {
            "dist_settings": dist_settings,
            "message": message,
        },
        nav_active="distribution_settings",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Distribution", "admin_suite:distribution"),
            ("Settings", None),
        ),
        subtitle="Global distribution configuration and limits",
    )
