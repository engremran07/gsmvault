---
name: test-factory-boy-related
description: "Related factories: SubFactory, RelatedFactory, post_generation. Use when: creating test objects with FK/M2M relationships, nested object graphs."
---

# factory_boy Related Factories

## When to Use

- Creating test objects with ForeignKey relationships
- Building Many-to-Many test data
- Setting up complex object graphs for integration tests

## Rules

### SubFactory for ForeignKey

```python
import factory

class BrandFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "firmwares.Brand"
    name = factory.Faker("company")

class ModelFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "firmwares.Model"
    brand = factory.SubFactory(BrandFactory)
    name = factory.Faker("word")

class FirmwareFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "firmwares.Firmware"
    model = factory.SubFactory(ModelFactory)
    version = factory.Sequence(lambda n: f"1.0.{n}")
```

### Override Nested Attributes

```python
@pytest.mark.django_db
def test_firmware_brand():
    fw = FirmwareFactory(model__brand__name="Samsung")
    assert fw.model.brand.name == "Samsung"
```

### RelatedFactory for Reverse Relations

```python
class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "users.User"
    username = factory.Sequence(lambda n: f"user_{n}")

class UserWithProfileFactory(UserFactory):
    profile = factory.RelatedFactory(
        "tests.factories.UserProfileFactory",
        factory_related_name="user",
    )
```

### post_generation for M2M

```python
class TopicFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "forum.ForumTopic"
    title = factory.Faker("sentence")
    category = factory.SubFactory(CategoryFactory)

    @factory.post_generation
    def tags(self, create, extracted, **kwargs):
        if not create:
            return
        if extracted:
            self.tags.add(*extracted)

# Usage:
@pytest.mark.django_db
def test_topic_with_tags():
    tag1 = TagFactory()
    tag2 = TagFactory()
    topic = TopicFactory(tags=[tag1, tag2])
    assert topic.tags.count() == 2
```

### LazyAttribute with Related Fields

```python
class DownloadTokenFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = "firmwares.DownloadToken"
    user = factory.SubFactory(UserFactory)
    firmware = factory.SubFactory(FirmwareFactory)
    token = factory.LazyAttribute(
        lambda o: f"dl_{o.user.pk}_{o.firmware.pk}"
    )
```

## Red Flags

- Creating related objects manually in every test — use SubFactory
- Missing `factory_related_name` in RelatedFactory — creates orphaned objects
- Not using `__` syntax for nested overrides — creates unnecessary objects
- `post_generation` without checking `create` flag — breaks `.build()`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
