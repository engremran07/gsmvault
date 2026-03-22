from __future__ import annotations

from django.contrib.sitemaps.views import index, sitemap
from django.contrib.sites.models import Site
from django.http import Http404
from django.template.response import TemplateResponse

from apps.site_settings.models import SiteSettings

from .sitemap_registry import get_sitemaps


def sitemap_index_view(request):
    """Categorized sitemap index — default at /sitemap.xml."""
    settings = SiteSettings.get_solo()
    if not getattr(settings, "sitemap_index_enabled", True):
        raise Http404
    return index(
        request,
        sitemaps=get_sitemaps(),  # type: ignore[arg-type]
        sitemap_url_name="pages:sitemap_section",
        template_name="sitemap_index.xml",
    )


def sitemap_section_view(request, section):
    """Per-section sitemap (e.g. sitemap-blog.xml, sitemap-brands.xml)."""
    settings = SiteSettings.get_solo()
    if not getattr(settings, "sitemap_enabled", True):
        raise Http404
    sitemaps = get_sitemaps()
    if section not in sitemaps:
        raise Http404
    return sitemap(
        request,
        sitemaps=sitemaps,  # type: ignore[arg-type]
        section=section,
        template_name="sitemap.xml",
    )


def sitemap_all_view(request):
    """
    Aggregate all sitemap sections into a single urlset for consumers that prefer one file.
    Still honors enable/disable toggles.
    """
    settings = SiteSettings.get_solo()
    if not getattr(settings, "sitemap_enabled", True):
        raise Http404

    sitemaps = get_sitemaps()
    host = request.get_host() or ""
    protocol = (
        "https" if getattr(settings, "force_https", False) else request.scheme or "http"
    )
    # Use runtime host to avoid default example.com during local/dev usage
    site = Site(domain=host, name=host) if host else Site.objects.get_current()
    urls = []
    # instantiate and merge urls from each sitemap
    for sm in sitemaps.values():
        try:
            sm_instance = sm()
            urls.extend(
                sm_instance.get_urls(
                    site=site,
                    protocol=getattr(sm_instance, "protocol", None) or protocol,
                )
            )
        except Exception:  # noqa: S112
            continue

    return TemplateResponse(
        request,
        "sitemap.xml",
        {"urlset": urls},
        content_type="application/xml",
    )
