---
paths: ["apps/*/services*.py"]
---

# Services Layer Rules

These rules apply to all service files (`services.py`, `services/`, `services_*.py`) in every Django app.

## Core Principle: Thin Views, Fat Services

All business logic MUST live in `services.py`. Views are orchestrators — they:
1. Parse the request.
2. Call service functions.
3. Return the response.

**Views must never contain database queries, ORM calls, or business rules.**

## Transaction Safety

- All service functions that write to more than one model MUST be decorated with `@transaction.atomic`.
- If a function calls another service function that is also atomic, the inner transaction is savepointed automatically — this is fine.
- Wallet operations: wrap in `@transaction.atomic` AND use `select_for_update()` on the wallet object before any read-modify-write.

## Query Efficiency

- Use `select_related()` for FK traversals in the same query.
- Use `prefetch_related()` for reverse FK or M2M traversals.
- Never trigger N+1 queries: if you loop over a queryset and access a related object, you MUST prefetch it outside the loop.
- Use `only()` or `values()` for read-heavy queries that don't need full model instances.

## Exception Handling

- Raise domain-specific exceptions from services, not HTTP exceptions (`Http404`, `HttpResponse`).
- Define custom exceptions at the top of `services.py` or in a companion `exceptions.py`.
- Services MUST NOT import `HttpResponse`, `JsonResponse`, or anything from `django.http`.
- Log warnings/errors before re-raising: `logger.warning("...", exc_info=True)`.
- Never bare `except Exception: pass` or `except Exception: continue` — always log and either re-raise or handle explicitly.

## Return Values

- Return domain objects (model instances, dataclasses, typed dicts) — not HTTP responses.
- For operations that might fail, use explicit return types or raise exceptions.
- Avoid returning `True`/`False` for complex outcomes — raise exceptions for failure states.

## Cross-App Boundaries

- **Service-to-service calls across app boundaries are FORBIDDEN.**
- Use `apps.core.events.EventBus` to publish events that other apps can subscribe to.
- Use Django signals (`post_save`, `m2m_changed`, etc.) for reactive behaviour.
- Use Celery tasks for async cross-app work.
- The ONLY exceptions: `apps.core.*` infrastructure, `apps.site_settings.*` config.

## Type Annotations

- All public service functions MUST have full type hints: parameters AND return type.
- Use `Optional[T]` or `T | None` for nullable results.
- Use `QuerySet[MyModel]` as return type for queryset-returning functions.
- Never `# type: ignore` without a specific error code: `[attr-defined]`, `[union-attr]`, etc.
