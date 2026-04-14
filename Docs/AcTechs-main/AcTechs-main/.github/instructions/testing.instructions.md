---
applyTo: test/**/*.dart
---

# Testing Conventions — AC Techs

## Required Coverage Rules

### Models
- Every new field added to a Freezed model MUST have at least one unit test verifying:
  - Default value for old docs (Firestore docs without the field)
  - Correct deserialization from Firestore map
  - Correct serialization back to Firestore map (round-trip)
- Freezed `copyWith` behaviour must be covered for any new optional field

### Repositories
- Every new repository method MUST have a behavioural test covering:
  - Happy path (correct data, correct state)
  - Period-lock rejection (if the method is date-gated)
  - Approved-record-locked rejection (if the method checks status)
  - FirebaseException → domain exception translation

### Firestore Rules
- Every new or modified rule function MUST have a corresponding emulator test in `scripts/tests/`
- Rule tests must cover: allowed path (positive) AND denied path (negative)
- Test file naming: `<feature>.test.js` matching the feature name

## Test Structure

```dart
// Unit test file template
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureName', () {
    group('methodName', () {
      test('description of what it does', () {
        // arrange
        // act
        // assert
      });
    });
  });
}
```

## What NOT to test
- Third-party package internals (Riverpod, Freezed generated code)
- Firebase SDK internals
- Widget rendering details (prefer behaviour tests over pixel tests)

## Archive / Soft-Delete Testing
Any archive or restore operation must be covered by:
1. `archives the record (isDeleted: true)` test
2. `stream filters out archived records` test
3. `restore sets isDeleted: false` test
4. `cannot archive an approved record` test (verifies period/status guard)
