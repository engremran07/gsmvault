---
paths: ["**"]
---

# No Duplicate Patterns

NEVER duplicate existing infrastructure. Before creating anything new, search the codebase
for existing implementations.

## MANDATORY Pre-Creation Checks

Before creating ANY new file, function, class, or template:

1. **Search first**: `grep_search` or `semantic_search` for similar functionality
2. **Check components**: `templates/components/` has 23 reusable components — use them
3. **Check services**: `apps/core/` provides sanitization, caching, throttling, events, signals
4. **Check utilities**: `apps/core/utils/` has cross-app helpers

## FORBIDDEN Duplications

| Pattern | Fix |
|---------|-----|
| Inline KPI cards in admin templates | Use `{% include "components/_admin_kpi_card.html" %}` |
| Custom sanitization per-app | Use `apps.core.sanitizers.sanitize_html_content()` |
| Per-view CSRF handling for HTMX | Global `<body hx-headers>` already handles this |
| Custom pagination HTML | Use `{% include "components/_pagination.html" %}` |
| Ad-hoc error response formats | Use `apps.core.exceptions.json_error_response()` |
| Per-app rate limiting logic | Use `apps.core.throttling` DRF classes |
| Inline modal/dialog HTML | Use `{% include "components/_modal.html" %}` |
| Custom event dispatch | Use `apps.core.events.EventBus` |
| New static asset file for minor tweaks | Extend existing canonical static file first |
| Duplicate backend/frontend business logic | Keep business logic canonical in backend services |

## When Adding Similar Functionality

If existing code does 80%+ of what you need:

1. **Extend**, don't duplicate — add parameters to the existing function
2. **Compose**, don't copy — build on top of existing infrastructure
3. **Configure**, don't fork — use feature flags or settings for variations
4. **Synchronize**, don't split — when behavior changes are user-facing, deliver backend contract changes and frontend template/component changes together
5. **Preserve structure**, don't scatter — keep frontend/backend/static/database boundaries clean and cohesive

## Static File Discipline

- New static files are disallowed by default when an existing file can be extended.
- Split large static files only for verified performance/maintainability reasons.
- Any split must keep coherent module boundaries (domain/feature-based) and remove dead styles/scripts.

## Detection Signals

If you're about to create something and any of these are true, STOP and search:
- The name contains a common concept (sanitize, cache, paginate, validate, throttle, notify)
- Another app already handles similar data (e.g., don't build user-related models outside `apps.users`)
- A template component already handles similar UI (check `templates/components/`)
