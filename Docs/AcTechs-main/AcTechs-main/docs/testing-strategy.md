# Testing Strategy

## Local gate order

1. `flutter analyze --no-pub`
2. `flutter test --coverage`
3. `npm run lint:firestore-rules` in `scripts/`
4. `npm test` in `scripts/`

## Test layers in this repo

| Layer | Location | Purpose |
| --- | --- | --- |
| Unit and provider tests | `test/unit/` | Business logic, providers, model serialization, regression checks |
| Widget tests | `test/widget/` | Screen-level interactions, async states, navigation behavior |
| Firestore rules tests | `scripts/tests/` | Emulator-backed security and transition checks |

## Current expectations

- Any new model field needs serialization coverage.
- Any new repository behavior should have a behavior test.
- Any Firestore rule change needs matching emulator coverage.
- Any regression fix on a user-facing screen should add a focused widget or rules test.

## Coverage notes

- CI enforces a 60% minimum line coverage floor.
- Coverage is treated as a regression floor, not a final target.
- Widget tests are preferred for navigation, tap targets, loading states, and layout regressions.
