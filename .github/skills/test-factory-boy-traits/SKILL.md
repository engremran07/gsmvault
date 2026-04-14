---
name: test-factory-boy-traits
description: "Factory traits for test object variations. Use when: creating different states of the same model (active/inactive, admin/regular, published/draft)."
---

# factory_boy Traits

## When to Use

- Same model needs different states in different tests
- Avoiding multiple factory subclasses for minor variations
- Creating readable, self-documenting test data

## Rules

### Basic Traits

```python
import factory
from django.utils import timezone

class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "users.User"

    username = factory.Sequence(lambda n: f"user_{n}")
    email = factory.LazyAttribute(lambda o: f"{o.username}@example.com")
    is_active = True
    is_staff = False

    class Params:
        admin = factory.Trait(
            is_staff=True,
            is_superuser=True,
            username=factory.Sequence(lambda n: f"admin_{n}"),
        )
        inactive = factory.Trait(
            is_active=False,
        )

# Usage:
@pytest.mark.django_db
def test_admin_user():
    admin = UserFactory(admin=True)
    assert admin.is_staff is True
    assert admin.is_superuser is True

@pytest.mark.django_db
def test_inactive_user():
    user = UserFactory(inactive=True)
    assert user.is_active is False
```

### Traits with Relationships

```python
class FirmwareFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "firmwares.Firmware"

    version = factory.Sequence(lambda n: f"1.0.{n}")
    is_active = True
    verified_at = None

    class Params:
        verified = factory.Trait(
            verified_at=factory.LazyFunction(timezone.now),
        )
        with_downloads = factory.Trait(
            download_count=factory.Faker("random_int", min=100, max=10000),
        )

@pytest.mark.django_db
def test_verified_firmware():
    fw = FirmwareFactory(verified=True)
    assert fw.verified_at is not None
```

### Combining Traits

```python
@pytest.mark.django_db
def test_verified_popular_firmware():
    fw = FirmwareFactory(verified=True, with_downloads=True)
    assert fw.verified_at is not None
    assert fw.download_count >= 100
```

### Traits with Post-Generation

```python
class PostFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "blog.Post"

    title = factory.Faker("sentence")
    status = "draft"

    class Params:
        published = factory.Trait(
            status="published",
            published_at=factory.LazyFunction(timezone.now),
        )

    @factory.post_generation
    def categories(self, create, extracted, **kwargs):
        if not create:
            return
        if extracted:
            self.categories.add(*extracted)
```

## Red Flags

- Creating separate factory classes for each model state — use traits instead
- Traits that conflict with each other — document incompatible combinations
- Overriding trait values at call site — defeats the purpose of traits
- Too many traits on one factory — consider separate factories

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
