---
paths: ["**"]
---

# No Versioned Files

AI agents MUST NEVER create versioned copies of files. This is the single most damaging
anti-pattern in AI-assisted development.

## FORBIDDEN Patterns

- `file_v2.py`, `file_v3.py`, `file_new.py`, `file_backup.py`
- `utils_updated.py`, `services_refactored.py`, `views_improved.py`
- `component_v2.html`, `styles_new.css`, `script_clean.js`
- `models_old.py`, `models_original.py`
- Any file with `_v\d+`, `_new`, `_old`, `_backup`, `_copy`, `_updated`, `_refactored`, `_improved`, `_clean`, `_original` suffix

## REQUIRED Behaviour

- ALWAYS edit the existing file in place
- Use `replace_string_in_file` or `multi_replace_string_in_file` to update code
- If a file needs major changes, edit it in sections — never create a parallel version
- Git provides versioning — the filesystem does not need it
- Python module names MUST remain standard and generic (`models.py`, `views.py`, `services.py`, `tasks.py`, `api.py`, `urls.py`, `admin.py`) unless a clear established pattern already exists
- For `apps/seo`, `apps/distribution`, and `apps/ads`, features MUST be added by enhancing existing modules and models, never by creating alternate "v2" modules

## Why This Matters

Versioned files cause:
1. **Import confusion** — which version does `from module import X` resolve to?
2. **Stale code** — the "old" version never gets deleted, diverges silently
3. **Test gaps** — tests reference one version, production imports another
4. **Audit burden** — every duplicated file doubles the review surface

## Exceptions

- `settings.py` / `settings_dev.py` / `settings_production.py` — these are environment splits, not versions
- Migration files (`0001_initial.py`, `0002_add_field.py`) — these are sequential by design
- Changelog entries with dates — `CHANGELOG.md` entries are append-only records
