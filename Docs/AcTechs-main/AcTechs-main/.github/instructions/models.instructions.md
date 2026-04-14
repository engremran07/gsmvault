---
applyTo: lib/core/models/**/*.dart
---

# Model Conventions — AC Techs

## Required Structure
Every data model MUST:
1. Use `@freezed` annotation — no plain Dart classes for models
2. Implement `fromFirestore(DocumentSnapshot doc)` factory
3. Implement `toFirestore()` method (via Freezed extension or manual)
4. Use `@JsonKey(fromJson: ..., toJson: ...)` for Timestamp ↔ DateTime fields
5. Use `@Default(...)` or `@JsonKey(defaultValue: ...)` for optional fields so legacy Firestore docs without the field deserialise without error

## New Field Checklist
When adding a new field to any model, evaluate ALL of the following:

### 1 — Firestore Rules Impact
- Does the field need to be in `validJobCreatePayload()` keys list?
- Does the field need to be added to `technicianMutableJobUpdate()` affected keys?
- Is the field mutable by techs? If yes: add to the tech update allow-list in rules.
- Is the field mutable by admins only? If yes: verify admin-only rule branch covers it.
- Is the field optional? If yes: use `.get('field', null)` in any rule comparison involving it.

### 2 — Settlement System Impact
- Does the field change between settlement states? If yes:
  - Add it to `settlementFieldsOnlyChanged()` if it's settlement-only
  - Add it to `settlementFieldsUnchanged()` if it must stay immutable during settlement

### 3 — Serialisation
- Firestore stores `null` differently from a missing key — always use `@Default` so old docs parse cleanly
- Timestamps must use `_timestampFromJson` / `_timestampToJson` helpers (not `DateTime.toIso8601String`)
- Enums must use `@JsonValue('snake_case')` annotations

### 4 — Tests
- Unit test for default value on missing key (simulates old Firestore doc)
- Unit test for round-trip serialisation

## Archive Fields Pattern
For soft-deletable models, always add:
```dart
@JsonKey(defaultValue: false) @Default(false) bool isDeleted,
@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? deletedAt,
```

## Shared Install Team Fields Pattern
For models that participate in a shared install roster, the aggregate model must include:
```dart
List<String> teamMemberIds,  // element[0] is always createdBy uid
List<String> teamMemberNames, // parallel array, same index order
```
Maximum team size is 10. Guard this in both rules (`teamMemberIds.size() <= 10`) and UI.

## Domain Separation — CRITICAL

There are THREE completely separate model domains. NEVER add fields from one domain to another:

| Domain | Models | Firestore Collection |
|--------|--------|---------------------|
| **Jobs** | `JobModel` | `jobs/` |
| **In/Out** | `ExpenseModel`, `EarningModel` | `expenses/`, `earnings/` |
| **AC Installs** | `AcInstallModel` | `ac_installs/` |

- `JobModel` does NOT have expense/earning sub-documents
- `ExpenseModel` and `EarningModel` are NOT related to job submissions
- When adding a field to `ExpenseModel`/`EarningModel`, do NOT add corresponding job fields
- `ExpenseModel`/`EarningModel` have their own approval flow (`EarningApprovalStatus`) — separate from `JobStatus`

### ExpenseModel / EarningModel Specific Rules
- Both have `isDeleted: bool` and `deletedAt: DateTime?` for soft delete (archive pattern)
- Both have `status` field using approval enum — auto-approved when `inOutApprovalRequired == false`
- `expenseType` on `ExpenseModel` distinguishes `work` vs `home` expenses
- **New field checklist**: add to `validExpenseCreatePayload()` / `validEarningCreatePayload()` in `firestore.rules` — NOT `validJobCreatePayload()`
