from django.apps import AppConfig


class WalletConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.wallet"
    label = "wallet"
    verbose_name = "Wallet"

    def ready(self) -> None:
        import apps.wallet.signals  # noqa: F401
