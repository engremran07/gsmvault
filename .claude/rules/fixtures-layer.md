---
paths: ["apps/*/fixtures/*.json"]
---

# Fixtures Layer Rules

Test data uses factory_boy as the primary mechanism. JSON fixtures are reserved for essential reference data only.

## Factory Boy (Preferred)

- ALWAYS use `factory_boy` for test data generation — preferred over JSON fixtures.
- Define factories in `tests/factories.py` or `apps/<appname>/tests/factories.py`.
- Use `factory.Faker()` for realistic field values — NEVER hardcode test data inline.
- Use `factory.SubFactory()` for FK relationships.
- Use `factory.LazyAttribute()` for computed fields.
- Example:
  ```python
  class FirmwareFactory(factory.django.DjangoModelFactory):
      class Meta:
          model = Firmware
      name = factory.Faker("file_name", extension="zip")
      brand = factory.SubFactory(BrandFactory)
      size = factory.Faker("random_int", min=1000, max=50000000)
  ```

## JSON Fixtures

- Use JSON format for fixture files — NEVER use YAML or XML fixtures.
- Fixtures are for essential reference data only: default tiers, initial categories, system config.
- Keep fixtures minimal — only data that MUST exist for the app to function.
- NEVER commit PII (real names, emails, passwords, IP addresses) in fixture files.
- Use generic placeholder data: `user@example.com`, `Test User`, etc.

## Seed Commands

- Seed commands follow the naming pattern: `manage.py seed_<appname>`.
- Seed commands MUST be idempotent — safe to run multiple times.
- Use `get_or_create()` to prevent duplicates on re-run.
- Seed commands create visually rich data for development and smoke testing.
- Include representative samples: multiple categories, varied statuses, edge cases.

## Data Integrity

- Fixture data MUST satisfy all model constraints: unique fields, required fields, FK references.
- Fixture natural keys (`natural_key()`) are preferred over hardcoded PKs for portability.
- NEVER reference auto-generated IDs across fixture files — use natural keys or let Django assign PKs.
- Test that fixtures load cleanly: `manage.py loaddata <fixture>` must succeed without errors.

## Security

- NEVER include real credentials, API keys, or tokens in fixture files.
- Use `make_password("testpass123")` for password fixtures — NEVER store plaintext.
- NEVER include production data in fixtures, even anonymized — create synthetic data instead.
- Fixture files MUST be committed to version control (they are reference data, not secrets).
