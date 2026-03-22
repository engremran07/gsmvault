from django.urls import path

from . import views
from .views_sitemap import (
    sitemap_all_view,
    sitemap_index_view,
    sitemap_section_view,
)

app_name = "pages"

urlpatterns = [
    path("robots.txt", views.robots_txt, name="robots"),
    # Categorized sitemap index (default — sections per content type)
    path("sitemap.xml", sitemap_index_view, name="sitemap"),
    path("sitemap_index.xml", sitemap_index_view, name="sitemap_index"),
    # Per-section sitemaps (e.g. sitemap-blog.xml, sitemap-brands.xml)
    path("sitemap-<section>.xml", sitemap_section_view, name="sitemap_section"),
    # Flat aggregate (all URLs in one file, for legacy consumers)
    path("sitemap-all.xml", sitemap_all_view, name="sitemap_all"),
    # CMS pages (slug-based only, home is handled in main urls.py)
    path("<slug:slug>/", views.page_detail, name="page"),
]
