from django.apps import AppConfig


class ForumConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.forum"
    label = "forum"
    verbose_name = "Forum"

    def ready(self) -> None:
        from . import signals  # noqa: F401
