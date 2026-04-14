# MASTER_BLUEPRINT

## Snapshot

- Project: AC Techs
- Date: 2026-07-11
- Current app version: 1.4.0+44
- Release surfaces: Android APK and Flutter web
- Backend: Firebase Auth, Cloud Firestore, Hosting, App Check

## Product domains

| Domain | Collections | Models | Feature ownership |
| --- | --- | --- | --- |
| Jobs | `jobs`, `invoice_claims`, `shared_install_aggregates` | `JobModel`, `SharedInstallAggregate` | `lib/features/jobs/` plus technician/admin presentation |
| In/Out | `expenses`, `earnings` | `ExpenseModel`, `EarningModel` | `lib/features/expenses/` |
| AC installs | `ac_installs` | `AcInstallModel` | `lib/features/expenses/` |

These domains are intentionally separate. Expense and earning data never live inside a job document, and job-domain providers are not used by In/Out screens.

## Navigation model

- Technician shell routes are root tabs: `/tech`, `/tech/submit`, `/tech/inout`, `/tech/history`, `/tech/settings`
- Admin shell routes are root tabs: `/admin`, `/admin/approvals`, `/admin/analytics`, `/admin/team`
- Detail or pushed routes must preserve back stack with `context.push()` or `context.pop()`
- Shell-root tab changes use `context.go()`

## State and data rules

- Firestore access belongs in repositories
- Riverpod `StreamProvider` is used for real-time Firestore data; derived day views reuse monthly listeners
- Soft delete is the default for technician-owned records
- User-facing errors come from typed app exceptions or localized feedback helpers

## Security model

- Firestore rules are fail-closed and backed by emulator tests in `scripts/tests/`
- Technician writes require both Firebase Auth and active-user checks
- Admin-only flows stay backed by both route guards and Firestore rules
- Shared-install ownership and settlement transitions are enforced at repository and rules layers

## Release gates

1. `flutter analyze --no-pub`
2. `flutter test --coverage`
3. `npm run lint:firestore-rules` in `scripts/`
4. `npm test` in `scripts/`
5. `flutter build web --release --no-wasm-dry-run`
6. `flutter build apk --release --no-tree-shake-icons`

## Governance files

- `MASTER_BLUEPRINT.md` — architecture handoff and operating constraints
- `REGRESSION_REGISTRY.md` — previously fixed bugs and their guard rails
- `SESSION_LOG.md` — session-by-session implementation ledger
- `CHANGELOG.md` — human-readable release history

## Current implementation focus

- Custom zoom drawer navigation integrated into both TechShell and AdminShell
- Stale shared install cleanup feature added to admin dashboard
- Comprehensive backend + security audits completed; all critical findings remediated
- AC installs Firestore rules hardened: auto-approved edit path, soft-archive exception
- 6 dead repository methods removed to reduce unnecessary Firestore listener risk
- 424 tests passing (25 new tests added)
- Zero analyzer issues, zero Problems-panel errors
- Firestore rules pending deploy before APK build
