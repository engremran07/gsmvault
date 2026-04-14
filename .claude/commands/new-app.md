# /new-app â€” Scaffold New Django App

Scaffold a fully-structured new Django app named $ARGUMENTS following all project conventions.

## Scaffolding Checklist

Create the app at `apps/$ARGUMENTS/` with all required files:

### Required Files

1. **`apps.py`**
   - `name = "apps.$ARGUMENTS"`
   - `default_auto_field = "django.db.models.BigAutoField"`
   - `verbose_name = "<Human Readable Name>"`

2. **`models.py`**
   - Import `TimestampedModel` from `apps.core.models`
   - Empty placeholder or first model with `__str__`, `Meta` (db_table, verbose_name, ordering)

3. **`views.py`** â€” empty skeleton with docstring

4. **`urls.py`**
   - `app_name = "$ARGUMENTS"`
   - Empty `urlpatterns = []`

5. **`admin.py`**
   - Register any new models with a typed `ModelAdmin[Model]` class

6. **`api.py`** â€” DRF ViewSets/Serializers skeleton (if the app needs an API)

7. **`services.py`** â€” service functions skeleton

8. **`tasks.py`** â€” Celery tasks skeleton (if async work needed)

9. **`tests.py`** â€” pytest test class with at least one placeholder test

10. **`migrations/__init__.py`** â€” empty

11. **`__init__.py`** â€” empty

### Registration

After creating the app:

1. Add `"apps.$ARGUMENTS"` to `INSTALLED_APPS` in `app/settings.py`
2. Add URL include to `app/urls.py`:
   ```python
   path("$ARGUMENTS/", include("apps.$ARGUMENTS.urls", namespace="$ARGUMENTS")),
   ```
3. Run `makemigrations`:
   ```powershell
   & .\.venv\Scripts\python.exe manage.py makemigrations $ARGUMENTS --settings=app.settings_dev
   ```
4. Run quality gate: `/qa`

### Documentation

After scaffold is complete, update:
- `README.md` â€” add brief description to the app list
- `AGENTS.md` â€” add to architecture table
- `.github/copilot-instructions.md` â€” update "Architecture at a Glance" section

## Constraints

- Never cross app boundaries in `models.py` (only `apps.core`, `apps.site_settings`, `AUTH_USER_MODEL`)
- Business logic goes in `services.py` only
- Templates in `templates/$ARGUMENTS/` (create the directory)
- HTMX fragments in `templates/$ARGUMENTS/fragments/`
