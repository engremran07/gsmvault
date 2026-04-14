---
paths: ["apps/*/apps.py"]
---

# App Configuration Rules

Every Django app in `apps/` MUST have a properly configured `AppConfig` in `apps.py`.

## Required Fields

- ALWAYS set `name = "apps.<appname>"` — must match the app's location in the `apps/` directory.
- ALWAYS set `default_auto_field = "django.db.models.BigAutoField"` — consistent primary key type across all apps.
- ALWAYS set `verbose_name = "Human Readable Name"` — displayed in Django admin and management output.
- The class name MUST follow `<Appname>Config` pattern: `class FirmwaresConfig(AppConfig):`.

## Signal Registration

- Import signal handlers in the `ready()` method — NEVER at module level:
  ```python
  def ready(self) -> None:
      import apps.myapp.signals  # noqa: F401
  ```
- The `noqa: F401` comment is required since the import is for side effects only.
- NEVER put signal handler registration in `__init__.py` or `models.py`.
- If the app has no signals, omit the `ready()` method entirely — don't add an empty one.

## INSTALLED_APPS

- Register every app in `INSTALLED_APPS` in `app/settings.py` using the full dotted path: `"apps.firmwares"`.
- Order: Django built-in → third-party → `apps.core` → `apps.site_settings` → all other apps.
- NEVER register an app by its `AppConfig` class path unless Django requires it for disambiguation.
- When dissolving an app, remove it from `INSTALLED_APPS` and run `manage.py check` immediately.

## App Dependencies

- Apps MUST NOT declare hard dependencies on other apps in `apps.py`.
- Cross-app dependencies are implicit through `ForeignKey` references, signal subscriptions, or EventBus.
- If an app requires another app's model via FK, use `settings.AUTH_USER_MODEL` pattern or string references.

## Naming Conventions

- App directory names are lowercase, underscore-separated: `user_profile`, `site_settings`.
- App labels (in `Meta.app_label`) MUST match the directory name.
- NEVER use hyphens in app names — Django doesn't support them.
