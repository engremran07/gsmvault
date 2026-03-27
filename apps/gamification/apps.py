from django.apps import AppConfig


class GamificationConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.gamification"
    label = "gamification"
    verbose_name = "Gamification"

    def ready(self) -> None:
        from . import signals  # noqa: F401

        signals.register_event_handlers()
