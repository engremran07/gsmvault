from django.apps import AppConfig


class ForumConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.forum"
    label = "forum"
    verbose_name = "Forum"

    def ready(self) -> None:
        from . import signals  # noqa: F401

        # Connect blog→forum auto-link (creates ForumTopic on blog publish)
        try:
            from apps.core.signals import blog_post_published

            from .event_handlers import handle_post_published

            blog_post_published.connect(handle_post_published)
        except Exception:  # noqa: S110
            pass

        # Register forum sitemaps
        try:
            from apps.pages.sitemap_registry import register_sitemap

            from .sitemaps import ForumCategorySitemap, ForumTopicSitemap

            register_sitemap("forum-categories", ForumCategorySitemap)
            register_sitemap("forum-topics", ForumTopicSitemap)
        except Exception:  # noqa: S110
            pass
