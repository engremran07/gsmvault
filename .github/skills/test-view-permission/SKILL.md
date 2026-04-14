---
name: test-view-permission
description: "Permission tests: login_required, staff checks, 403 responses. Use when: testing access control, authentication guards, permission decorators, ownership checks."
---

# View Permission Tests

## When to Use

- Verifying `@login_required` redirects anonymous users
- Testing `@user_passes_test(lambda u: u.is_staff)` enforcement
- Checking ownership-based access control
- Testing 403 Forbidden responses

## Rules

### Testing login_required

```python
import pytest
from django.urls import reverse

@pytest.mark.django_db
def test_anonymous_redirected_to_login(client):
    url = reverse("firmwares:create")
    response = client.get(url)
    assert response.status_code == 302
    assert "/login/" in response.url

@pytest.mark.django_db
def test_authenticated_can_access(client):
    from tests.factories import UserFactory
    user = UserFactory()
    client.force_login(user)
    response = client.get(reverse("firmwares:list"))
    assert response.status_code == 200
```

### Testing Staff-Only Access

```python
@pytest.mark.django_db
def test_non_staff_gets_403(client):
    from tests.factories import UserFactory
    user = UserFactory(is_staff=False)
    client.force_login(user)
    response = client.get(reverse("admin:dashboard"))
    assert response.status_code in (302, 403)

@pytest.mark.django_db
def test_staff_can_access(client):
    from tests.factories import UserFactory
    user = UserFactory(is_staff=True)
    client.force_login(user)
    response = client.get(reverse("admin:dashboard"))
    assert response.status_code == 200
```

### Testing Ownership Checks

```python
@pytest.mark.django_db
def test_owner_can_edit(client):
    from tests.factories import UserFactory, PostFactory
    user = UserFactory()
    post = PostFactory(author=user)
    client.force_login(user)
    response = client.get(reverse("blog:edit", kwargs={"pk": post.pk}))
    assert response.status_code == 200

@pytest.mark.django_db
def test_non_owner_gets_403(client):
    from tests.factories import UserFactory, PostFactory
    owner = UserFactory()
    other = UserFactory()
    post = PostFactory(author=owner)
    client.force_login(other)
    response = client.get(reverse("blog:edit", kwargs={"pk": post.pk}))
    assert response.status_code in (403, 404)
```

### Permission Test Matrix

```python
@pytest.mark.django_db
@pytest.mark.parametrize("is_staff,is_active,expected", [
    (True, True, 200),
    (True, False, 302),   # Inactive → login redirect
    (False, True, 403),   # Non-staff → forbidden
    (False, False, 302),  # Inactive non-staff → login redirect
])
def test_admin_access_matrix(client, is_staff, is_active, expected):
    from tests.factories import UserFactory
    user = UserFactory(is_staff=is_staff, is_active=is_active)
    client.force_login(user)
    response = client.get(reverse("admin:dashboard"))
    assert response.status_code == expected
```

## Red Flags

- Only testing happy path (logged-in staff) — always test anonymous and non-staff
- Using `client.login()` without verifying it returns True — silent auth failure
- Not testing API endpoints for auth — DRF views need separate auth tests
- Hardcoded user PKs in ownership tests — use factory-created objects

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
