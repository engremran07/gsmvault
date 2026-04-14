---
name: django-app-scaffold
description: "Scaffold a complete Django app with models, views, serializers, URLs, and tests. Use when: bootstrapping a new app from scratch, generating boilerplate, creating app structure following the platform conventions."
user-invocable: true
---

# Django App Scaffold

> Full reference: @.github/skills/django-app-scaffold/SKILL.md

## Checklist for Every New App

1. `apps/<appname>/apps.py` — `name = "apps.<appname>"`, `default_auto_field = "django.db.models.BigAutoField"`
2. `apps/<appname>/models.py` — extend `TimestampedModel`, `db_table`, `related_name`, `__str__`, full `Meta`
3. `apps/<appname>/services.py` — all business logic, `@transaction.atomic` on multi-model ops
4. `apps/<appname>/api.py` — DRF ViewSets, explicit `permission_classes`, cursor pagination
5. `apps/<appname>/urls.py` — `app_name = "<appname>"` namespace
6. Add to `INSTALLED_APPS` in `app/settings.py`
7. Wire namespace in `app/urls.py`
8. Run `manage.py makemigrations <appname>`
9. Document in `README.md`, `AGENTS.md`, `.github/copilot-instructions.md`

## Required Model Fields

```python
class Meta:
    db_table = "<appname>_<modelname>"
    verbose_name = "..."
    verbose_name_plural = "..."
    ordering = ["-created_at"]
```

## Never

- Cross-app imports in `models.py`/`services.py` — use EventBus or signals
- Skip `related_name` on any FK/M2M
- Inline business logic in views
