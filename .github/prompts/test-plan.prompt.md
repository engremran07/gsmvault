---
agent: 'agent'
description: 'Create a comprehensive test plan for an app or feature: model validation, view permissions, API endpoints, services, templates.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Test Plan

Generate a comprehensive test plan and pytest test stubs for a given app or feature.

## Step 1 — Scope Discovery

1. Identify the target app or feature from the user's request.
2. Read all source files in the app: `models.py`, `services.py`, `views.py`, `urls.py`, `api.py`, `admin.py`, `forms.py`, `tasks.py`.
3. Check if tests already exist: look for `tests.py`, `tests/` directory, or `test_*.py` files.
4. Read existing tests to understand current coverage and patterns.

## Step 2 — Model Tests

For each model in `models.py`, plan tests for:

- **Creation**: Object creates successfully with valid data.
- **`__str__`**: Returns expected string representation.
- **Validation**: `full_clean()` raises `ValidationError` for invalid data.
- **Constraints**: `unique_together`, `UniqueConstraint`, `CheckConstraint` enforced at DB level.
- **Relationships**: FK and M2M relationships work correctly, `related_name` resolves.
- **Defaults**: Default field values are correct.
- **Ordering**: `Meta.ordering` produces correct query order.
- **Soft delete**: If model extends `SoftDeleteModel`, test `is_deleted` filtering.
- **Timestamps**: If model extends `TimestampedModel`, verify `created_at`/`updated_at` auto-set.

## Step 3 — Service Tests

For each function in `services.py`, plan tests for:

- **Happy path**: Correct input produces correct output.
- **Edge cases**: Empty input, boundary values, None values.
- **Error handling**: Invalid input raises appropriate exceptions.
- **Transaction safety**: If `@transaction.atomic` is used, verify rollback on error.
- **Financial safety**: If `select_for_update()` is used, verify locking behavior.
- **Cross-app events**: If `EventBus` is used, verify events are emitted.
- **Sanitization**: If user HTML input is processed, verify nh3 sanitization is applied.

## Step 4 — View Tests

For each view function/class, plan tests for:

- **GET 200**: Authenticated user gets correct template and context.
- **POST success**: Valid form submission creates/updates object and redirects.
- **POST failure**: Invalid data re-renders form with errors.
- **Auth required**: Unauthenticated user redirected to login (302).
- **Staff required**: Non-staff user gets 403 Forbidden.
- **Ownership**: User cannot access another user's resources.
- **HTMX**: Request with `HX-Request` header returns fragment template (no `{% extends %}`).
- **CSRF**: POST without CSRF token returns 403.
- **Pagination**: List view paginates correctly.

## Step 5 — API Tests

For each DRF endpoint in `api.py`, plan tests for:

- **CRUD**: List, create, retrieve, update, delete operations.
- **Authentication**: Unauthenticated requests return 401.
- **Permissions**: Wrong role returns 403.
- **Serializer validation**: Invalid data returns 400 with field errors.
- **Pagination**: List endpoint paginates (cursor-based preferred).
- **Filtering**: Query params filter results correctly.
- **Throttling**: Exceeding rate limit returns 429.
- **Error format**: Errors follow `{"error": "...", "code": "..."}` format.

## Step 6 — Template Tests

For templates, plan tests for:

- **Rendering**: Template renders without errors.
- **Context variables**: Required variables are present.
- **Component usage**: Verify `{% include "components/_*.html" %}` is used (not inline).
- **Alpine.js**: Elements with `x-show`/`x-if` have `x-cloak`.
- **HTMX fragments**: Fragment templates do NOT use `{% extends %}`.

## Step 7 — Celery Task Tests

For each task in `tasks.py`, plan tests for:

- **Execution**: `task.apply()` runs successfully.
- **Retry logic**: Task retries on transient failure.
- **Error handling**: Task handles permanent failures gracefully.

## Step 8 — Output Test Stubs

Generate pytest test file(s) with proper structure:

```python
"""Tests for apps.<app_name>."""

import pytest
from django.test import RequestFactory, TestCase

from apps.<app>.models import MyModel
from apps.<app>.services import my_service_function


@pytest.mark.django_db
class TestMyModel:
    """Tests for MyModel."""

    def test_create_valid(self) -> None:
        """Model creates with valid data."""
        ...

    def test_str_representation(self) -> None:
        """__str__ returns expected format."""
        ...

    def test_validation_rejects_invalid(self) -> None:
        """full_clean() raises ValidationError for invalid data."""
        ...


@pytest.mark.django_db
class TestMyService:
    """Tests for service layer."""

    def test_happy_path(self) -> None:
        """Service returns correct result for valid input."""
        ...

    def test_handles_edge_case(self) -> None:
        """Service handles edge case correctly."""
        ...


@pytest.mark.django_db
class TestMyView:
    """Tests for views."""

    def test_get_authenticated(self, client, django_user_model) -> None:
        """Authenticated GET returns 200."""
        ...

    def test_get_unauthenticated(self, client) -> None:
        """Unauthenticated GET redirects to login."""
        ...
```

List the total number of test cases planned and categorize by layer (model/service/view/API/template/task).
