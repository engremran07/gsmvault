from __future__ import annotations

from django.contrib.sitemaps import Sitemap
from django.db.models import QuerySet
from django.urls import reverse

from apps.site_settings.models import SiteSettings

from .models import ForumCategory, ForumTopic


class ForumCategorySitemap(Sitemap):
    """Sitemap for public forum categories."""

    changefreq = "weekly"
    priority = 0.6

    def __init__(self) -> None:
        super().__init__()
        try:
            ss = SiteSettings.get_solo()
        except Exception:
            ss = None
        force_https = bool(getattr(ss, "force_https", False))
        self.protocol = "https" if force_https else "http"

    def items(self) -> QuerySet[ForumCategory]:
        return ForumCategory.objects.filter(
            is_visible=True,
            is_private=False,
            is_removed=False,
        ).order_by("sort_order", "title")

    def lastmod(self, obj: ForumCategory):
        return obj.last_active or obj.updated_at

    def location(self, obj: ForumCategory) -> str:
        return reverse("forum:category_detail", kwargs={"slug": obj.slug})


class ForumTopicSitemap(Sitemap):
    """Sitemap for public forum topics."""

    changefreq = "daily"
    priority = 0.7
    limit = 5000

    def __init__(self) -> None:
        super().__init__()
        try:
            ss = SiteSettings.get_solo()
        except Exception:
            ss = None
        force_https = bool(getattr(ss, "force_https", False))
        self.protocol = "https" if force_https else "http"

    def items(self) -> QuerySet[ForumTopic]:
        return (
            ForumTopic.objects.select_related("category")
            .filter(
                is_removed=False,
                category__is_visible=True,
                category__is_private=False,
                category__is_removed=False,
            )
            .order_by("-last_active")
        )

    def lastmod(self, obj: ForumTopic):
        return obj.updated_at or obj.last_active

    def location(self, obj: ForumTopic) -> str:
        return reverse(
            "forum:topic_detail",
            kwargs={"pk": obj.pk, "slug": obj.slug},
        )
