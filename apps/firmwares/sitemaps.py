from __future__ import annotations

from django.contrib.sitemaps import Sitemap
from django.urls import reverse

from apps.site_settings.models import SiteSettings

from .models import Brand, Model


class FirmwareBrandsSitemap(Sitemap):
    """Sitemap for firmware brand pages (e.g. /firmwares/brand/samsung/)."""

    changefreq = "weekly"
    priority = 0.7

    def __init__(self) -> None:
        super().__init__()
        try:
            ss = SiteSettings.get_solo()
        except Exception:
            ss = None
        force_https = bool(getattr(ss, "force_https", False))
        self.protocol = "https" if force_https else "http"

    def items(self):
        return Brand.objects.order_by("name")

    def lastmod(self, obj: Brand):
        return getattr(obj, "updated_at", None)

    def location(self, obj: Brand) -> str:
        return reverse("firmwares:brand_detail", kwargs={"slug": obj.slug})


class FirmwareModelsSitemap(Sitemap):
    """Sitemap for firmware model pages (e.g. /firmwares/brand/samsung/galaxy-s23/)."""

    changefreq = "daily"
    priority = 0.8

    def __init__(self) -> None:
        super().__init__()
        try:
            ss = SiteSettings.get_solo()
        except Exception:
            ss = None
        force_https = bool(getattr(ss, "force_https", False))
        self.protocol = "https" if force_https else "http"

    def items(self):
        return (
            Model.objects.select_related("brand")
            .filter(brand__isnull=False)
            .order_by("brand__name", "name")
        )

    def lastmod(self, obj: Model):
        return getattr(obj, "updated_at", None)

    def location(self, obj: Model) -> str:
        return reverse(
            "firmwares:model_detail",
            kwargs={"brand_slug": obj.brand.slug, "model_slug": obj.slug},
        )
