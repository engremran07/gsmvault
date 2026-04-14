---
name: test-factory-boy-model
description: "factory_boy ModelFactory: Faker, LazyAttribute, SubFactory. Use when: creating test data factories, model instances for tests, replacing manual object creation."
---

# factory_boy Model Factories

## When to Use

- Creating test model instances without manual field specification
- Generating realistic fake data for tests
- Replacing repetitive `Model.objects.create()` calls

## Rules

### Basic ModelFactory

```python
import factory
from apps.users.models import User

class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f"user_{n}")
    email = factory.LazyAttribute(lambda o: f"{o.username}@example.com")
    password = factory.PostGenerationMethodCall("set_password", "testpass123")
    is_active = True
```

### Faker Integration

```python
class DeviceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "devices.Device"  # String reference avoids import issues

    brand = factory.Faker("company")
    model_name = factory.Faker("word")
    slug = factory.LazyAttribute(lambda o: f"{o.brand}-{o.model_name}".lower())
    description = factory.Faker("paragraph", nb_sentences=3)
    release_date = factory.Faker("date_this_decade")
    is_active = True
```

### Sequence for Unique Fields

```python
class FirmwareFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "firmwares.Firmware"

    version = factory.Sequence(lambda n: f"1.0.{n}")
    build_number = factory.Sequence(lambda n: 1000 + n)
    file_size = factory.Faker("random_int", min=1024, max=1048576)
```

### LazyAttribute for Computed Fields

```python
class PostFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "blog.Post"

    title = factory.Faker("sentence", nb_words=6)
    slug = factory.LazyAttribute(
        lambda o: o.title.lower().replace(" ", "-")[:50]
    )
    content = factory.Faker("text", max_nb_chars=500)
    author = factory.SubFactory(UserFactory)
```

### Usage in Tests

```python
@pytest.mark.django_db
def test_firmware_str():
    fw = FirmwareFactory(version="2.0.1")
    assert "2.0.1" in str(fw)

@pytest.mark.django_db
def test_batch_create():
    firmwares = FirmwareFactory.create_batch(5)
    assert len(firmwares) == 5

@pytest.mark.django_db
def test_build_without_saving():
    fw = FirmwareFactory.build()  # Not saved to DB
    assert fw.pk is None
```

## Red Flags

- Using `Model.objects.create()` with 10+ fields — use a factory instead
- Factories without `Sequence` on unique fields — `IntegrityError` on batch creates
- Hardcoding test data instead of Faker — fragile, less readable
- Importing models at module level in factory files — circular import risk

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
