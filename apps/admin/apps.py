from django.apps import AppConfig


class AdminSuiteConfig(AppConfig):
    name = "apps.admin"
    label = "admin_suite"
    verbose_name = "Admin Panel"
    default_auto_field = "django.db.models.BigAutoField"
