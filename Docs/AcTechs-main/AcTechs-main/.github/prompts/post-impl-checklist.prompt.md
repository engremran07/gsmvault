---
mode: agent
description: Post-implementation gate checklist. Runs all required verification steps and reports pass/fail.
---

# /post-impl — Post-Implementation Gate Checklist

Run each gate **sequentially**. Report pass ✅ or fail ❌ for each. If any gate fails, stop and report the failure details before proceeding.

## Gate 1 — Static Analysis
```
flutter analyze --no-pub
```
Expected: `No issues found!`
Fail condition: any error or warning output.

## Gate 2 — Unit Tests
```
flutter test
```
Expected: all tests pass, zero failures.
Fail condition: any test failure or error.

## Gate 3 — Firestore Rules Lint
```
cd scripts && npm run lint:firestore-rules
```
Expected: exit code 0, no warnings.
Fail condition: any lint warning or error.

## Gate 4 — Firestore Rules Emulator Tests
```
cd scripts && npm test
```
Expected: all emulator test cases pass.
Fail condition: any test failure.

## Gate 5 — Code Generation Check
Run `dart run build_runner build --delete-conflicting-outputs` and verify it exits 0 with no unresolved outputs.
Expected: no new generated files differ from committed files.

## Gate 6 — Localisation Check
```
flutter gen-l10n
```
Expected: exits 0, no missing keys.
Fail condition: any missing ARB key or generation error.

## Gate 7 — Version Consistency
Read `pubspec.yaml` version field. Confirm:
- versionCode (number after `+`) ≥ 16
- versionCode is an integer

## Gate 8 — Firestore Rules: teamMemberIds guard present
Grep `firestore.rules` for `teamMemberIds.size() <= 10` — must exist.
Grep for `authUidOrEmpty() in resource.data.teamMemberIds` — must exist.
Grep for `allow list: if isAdmin() || isActiveUser()` in the users block — must exist.

## Gate 9 — No Hard Deletes in Tech Repositories
Grep `lib/features/expenses/data/` for `\.delete()` — must return zero matches.
Fail condition: any `.delete()` call present in expense/earning/ac_install repositories.

## Gate 10 — Archive Test Coverage
Confirm `test/unit/expenses/archive_lifecycle_test.dart` exists.
Fail condition: file missing.

## Summary Report
After all gates:
```
| Gate | Name                        | Status |
|------|-----------------------------|--------|
| 1    | Flutter Analyse             | ✅/❌  |
| 2    | Unit Tests                  | ✅/❌  |
| 3    | Firestore Rules Lint        | ✅/❌  |
| 4    | Firestore Emulator Tests    | ✅/❌  |
| 5    | Code Generation             | ✅/❌  |
| 6    | Localisation                | ✅/❌  |
| 7    | Version Consistency         | ✅/❌  |
| 8    | Rules Guards Present        | ✅/❌  |
| 9    | No Hard Deletes             | ✅/❌  |
| 10   | Archive Test Coverage       | ✅/❌  |
| 11   | Collection Name Consistency | ✅/❌  |
| 12   | isDeleted Query Anti-pattern| ✅/❌  |
| 13   | Settlement Amount in Rules  | ✅/❌  |
| 14   | Bottom Nav Docs Correct     | ✅/❌  |
| 15   | PDF Not on Main Thread      | ✅/❌  |
| 16   | Archive Rules: Status Guard | ✅/❌  |
| 17   | Archive Rules: deletedAt Type| ✅/❌ |
| 18   | Shared Install Provider Limit| ✅/❌ |
| 19   | Detail Routes Use push()    | ✅/❌  |
| 20   | No Colors.white in Screens  | ✅/❌  |
| 21   | Shell Back Docs Present     | ✅/❌  |
| 22   | Weekly Audit Workflow Exists| ✅/❌  |
```

## Gate 11 — Collection Name Consistency
Grep all `.md` files in `.claude/` and `.github/instructions/` for `ac_installations` — must return ZERO.
Expected: no matches. Fail condition: any `.md` file says `ac_installations` instead of `ac_installs`.

## Gate 12 — isDeleted Query Anti-Pattern
Grep `lib/features/expenses/data/` for `where.*isDeleted` — must return zero.
Expected: isDeleted filtering happens in Dart stream mapper, not in Firestore query.
Fail condition: any Firestore query filters by isDeleted field.

## Gate 13 — Settlement Amount in markJobsAsPaid
Grep `lib/features/jobs/data/job_repository.dart` for `settlementAmount` — must exist.
Fail condition: missing (means payment amount is not recorded on settlement).

## Gate 14 — Bottom Nav Documentation Correct
Grep `.claude/rules/ui-conventions.md` for pattern `4 tabs per role` or `tech.*4 tabs` — must return ZERO.
Fail condition: documentation says tech has 4 tabs when it has 5.

## Gate 15 — PDF Not on Main Thread
Grep `lib/features/admin/presentation/analytics_screen.dart` and `lib/features/expenses/presentation/daily_in_out_screen.dart` for `await PdfGenerator.` — must be zero direct calls.
Fail condition: any direct `await PdfGenerator.*` not wrapped in `compute()`.

## Gate 16 — Archive Rules: Approved Record Status Guard
Grep `firestore.rules` for `resource.data.status != 'approved'` — must appear at least 3 times (once per archivable collection: expenses, earnings, ac_installs).
Fail condition: any archive rule missing the status guard allows tech to soft-delete approved ledger records.

## Gate 17 — Archive Rules: deletedAt Type Validation
Grep `firestore.rules` for `deletedAt is timestamp` — must appear at least 3 times.
Fail condition: archive rules accept any value for deletedAt (string, null, etc.).

## Gate 18 — Shared Install Provider Limit
Grep `lib/features/jobs/providers/shared_install_providers.dart` for `.limit(` — must exist.
Fail condition: unbounded Firestore query on shared_install_aggregates accumulates all historical records.

## Gate 19 — Detail Routes Use push()
Grep `lib/` for `context.go()` targeting detail or settings routes such as `/admin/settings`, `/admin/companies`, `/admin/settlements`, `/admin/import`, `/tech/summary`, `/tech/settlements`.
Fail condition: any of those routes use `context.go()` instead of `context.push()`.

## Gate 20 — No Colors.white in Presentation Screens
Grep `lib/features/*/presentation/` for `Colors.white`.
Fail condition: any user-facing presentation screen hardcodes `Colors.white` instead of theme colors.

## Gate 21 — Shell Back Docs Present
Confirm `.claude/CLAUDE.md` documents `ShellBackNavigationScope` usage and shell-route back-navigation rules.
Fail condition: docs omit the shared shell back-navigation pattern.

## Gate 22 — Weekly Audit Workflow Exists
Confirm `.github/workflows/audit.yml` exists.
Fail condition: no scheduled audit workflow is present.

If any gate is ❌, provide the exact error output and the recommended fix.
