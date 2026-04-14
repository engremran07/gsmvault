---
paths: ["apps/*/tests*.py", "tests/**"]
---

# Tests Layer Rules

Testing uses pytest with factory_boy. All new code MUST have corresponding tests. Quality is enforced by CI.

## Framework & Setup

- Use pytest as the test runner — NEVER use Django's `manage.py test`.
- Use `factory_boy` for test data — preferred over JSON fixtures for flexibility and readability.
- ALWAYS decorate tests that access the database with `@pytest.mark.django_db`.
- Use `TransactionTestCase` (or `pytest.mark.django_db(transaction=True)`) for tests involving `select_for_update()` or concurrent access.
- Project-level `conftest.py` at repo root — app-level `conftest.py` for app-specific fixtures.

## Coverage Requirements

- Minimum 60% coverage floor — aim for 80%+ on business-critical code (services, download gating, wallet).
- ALWAYS run with `--cov=apps --cov-report=term-missing` to identify untested lines.
- NEVER write tests that simply assert `True` — every test must verify meaningful behavior.

## What to Test

- **Models**: field validation, constraints, `__str__()`, `Meta` ordering, custom manager methods, save/delete behavior.
- **Views**: HTTP status codes, permission checks (logged-in vs anonymous vs staff), HTMX response detection, redirect targets.
- **Services**: business logic, edge cases, transaction atomicity, error handling, return values.
- **Forms**: valid/invalid data, `clean_*()` methods, file upload validation, sanitization.
- **API endpoints**: serialization, permissions, pagination, error response format.
- **Tasks**: idempotency, retry behavior, side effects (mock external deps).

## Test Organization

- One test file per app module: `test_models.py`, `test_views.py`, `test_services.py`, `test_forms.py`, `test_api.py`.
- Use descriptive test names: `test_download_token_expires_after_24_hours` not `test_token`.
- Group related tests in classes: `class TestFirmwareDownload:`.
- Use `@pytest.fixture` for reusable test setup — NEVER use `setUp()` / `tearDown()`.

## Mocking & Isolation

- Mock external services (email, storage, AI, payment) — NEVER hit real APIs in tests.
- Use `unittest.mock.patch` for dependency injection in tests.
- Mock Celery tasks with `@override_settings(CELERY_ALWAYS_EAGER=True)` or `task.apply()`.
- NEVER mock Django's ORM — test against the real (test) database.

## Anti-Patterns

- NEVER commit tests with `@pytest.mark.skip` without a linked issue for re-enabling.
- NEVER test implementation details (private methods, internal state) — test public interfaces.
- NEVER write tests that depend on execution order — each test must be independently runnable.
- NEVER hardcode dates/times — use `freezegun` or `time_machine` for deterministic time testing.
