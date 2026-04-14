# ❄️ AC Techs

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](#-stack)
[![Firebase](https://img.shields.io/badge/Firebase-Spark%20Only-FFCA28?logo=firebase&logoColor=black)](#-platform-constraints)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20Web-0A84FF)](#-build--release)
[![State](https://img.shields.io/badge/State-Riverpod%203-00C2B8)](#architecture)
[![License](https://img.shields.io/badge/Repo-Private-informational)](https://github.com/engremran07/AcTechs)

Production Flutter operations app for AC installation teams in Saudi Arabia. The system supports technicians in the field and admins in the office with invoice-based job capture, shared installs, IN/OUT tracking, approvals, analytics, branded exports, historical imports, and controlled destructive maintenance flows.

The data model is intentionally split into three separate business domains: Jobs, In/Out, and AC installs. They are adjacent in the product, but they do not share collections or provider ownership.

> [!IMPORTANT]
> This repository is intentionally Spark-only.
> Supported backend surface: Firebase Auth, Cloud Firestore, Hosting, and client-side App Check.
> Do not add Cloud Functions or any Firebase feature that requires Blaze.

## 📚 Table of Contents

- [Overview](#-overview)
- [Stack](#-stack)
- [Platform Constraints](#-platform-constraints)
- [Core Workflows](#-core-workflows)
- [Architecture](#architecture)
- [Domain Boundaries](#-domain-boundaries)
- [Firestore Model](#firestore-model)
- [Security and Rules](#-security-and-rules)
- [Versioning Policy](#-versioning-policy)
- [Local Cache and Uninstall Behavior](#-local-cache-and-uninstall-behavior)
- [Database Flush Scope](#-database-flush-scope)
- [Build and Release](#-build--release)
- [Developer Commands](#developer-commands)
- [Testing](#-testing)
- [Governance Files](#-governance-files)
- [Operational Notes](#-operational-notes)

## ✨ Overview

AC Techs is built around two primary roles:

| Role | Capabilities |
| --- | --- |
| Technician | Submit jobs, shared installs, AC installation records, earnings, expenses, and export personal history |
| Admin | Approve or reject records, manage users and companies, import historical data, export analytics, and run controlled maintenance operations |

The product targets Android first and also ships a Flutter web build.

## 🧰 Stack

| Area | Technology |
| --- | --- |
| Framework | Flutter 3.x |
| Language | Dart 3 |
| Backend | Firebase Auth + Cloud Firestore + Hosting |
| App Integrity | Firebase App Check |
| State | Riverpod 3 |
| Navigation | GoRouter |
| Serialization | Freezed + json_serializable |
| Localization | `gen-l10n` with English, Urdu, Arabic |
| Reports | PDF + Excel |

## 🚧 Platform Constraints

The following constraints are intentional and must remain true:

- Spark-tier safe only
- No Cloud Functions dependency
- Repository-mediated Firestore writes for sensitive workflows
- No raw Firebase error text exposed to users
- Approval logic must match UI, repository logic, and Firestore rules

## 🔄 Core Workflows

### Technician

- Submit invoice-based AC jobs
- Attach multiple unit types to one invoice
- Record bracket and delivery charges
- Submit shared installs with per-tech contribution shares
- Track daily earnings and expenses
- View history and monthly summaries
- Export reports
- Switch theme and language preferences

### Admin

- Approve or reject jobs, earnings, expenses, and AC installs
- Bulk review pending work
- Review invoice conflicts and shared-install context
- Manage users and activation state
- Manage companies, invoice prefixes, and logos
- Import historical workbooks
- Export Excel and PDF reports
- Run guarded database flush operations

## Architecture

```text
lib/
  core/
    constants/
    models/
    providers/
    services/
    theme/
    utils/
    widgets/
  features/
    admin/
    auth/
    expenses/
    jobs/
    settings/
    technician/
  l10n/
  routing/
docs/
scripts/
```

### Architecture Rules

- Firestore access belongs in repositories.
- Shared-install writes must stay transaction-based.
- Widgets must not expose raw backend exceptions.
- User-visible strings must come from localization or typed exceptions.
- Rules, repositories, and UI behavior must stay aligned.

## 🧱 Domain Boundaries

| Domain | Collections | Primary models | Feature ownership |
| --- | --- | --- | --- |
| Jobs | `jobs`, `invoice_claims`, `shared_install_aggregates` | `JobModel`, `SharedInstallAggregate` | `lib/features/jobs/` plus technician/admin job screens |
| In/Out | `expenses`, `earnings` | `ExpenseModel`, `EarningModel` | `lib/features/expenses/` |
| AC installs | `ac_installs` | `AcInstallModel` | `lib/features/expenses/` |

If a change crosses one of these boundaries, review repositories, providers, screens, and Firestore rules together.

### Feature highlights

#### Jobs

- Invoice normalization via `InvoiceUtils`
- Split, window, freestanding, cassette, and uninstall support
- `pending`, `approved`, and `rejected` workflow states
- Approval history subcollections

#### Shared installs

- Capacity tracked in `shared_install_aggregates`
- Invoice ownership tracked in `invoice_claims`
- Cross-company duplicate protection
- Rejection releases reservations
- **Team Roster Model:** Each aggregate stores `teamMemberIds` (list of UIDs, element[0] = creator) and `teamMemberNames` (parallel array). Technicians select teammates from a live dropdown — no manual count entry. Any team member can submit their contribution. Max team size: 10.
- Aggregate `consumed*` counters are append-only. Archiving a shared install job does NOT decrement them. Admin flush + rebuild is the reconciliation path if discrepancy is detected.

#### Historical import

- Multi-sheet Excel parsing
- Technician mapping
- Sheet-aware notes and period metadata
- Admin-safe import rules
- Company-prefix stripping during import normalization

#### Analytics and exports

- Job summaries and productivity metrics
- Shared-install invoice-aware totals
- Branded PDF and Excel exports

## Firestore Model

Primary collections:

| Collection | Purpose |
| --- | --- |
| `users` | Auth-linked user profiles |
| `jobs` | Invoice-based job records |
| `jobs/{jobId}/history` | Approval audit trail |
| `expenses` | OUT records |
| `expenses/{expenseId}/history` | Expense audit trail |
| `earnings` | IN records |
| `earnings/{earningId}/history` | Earning audit trail |
| `ac_installs` | AC install unit records |
| `ac_installs/{installId}/history` | Install audit trail |
| `companies` | Customer companies and invoice prefixes |
| `shared_install_aggregates` | Shared invoice capacity ledger |
| `invoice_claims` | Invoice uniqueness ownership registry |
| `app_settings/approval_config` | Approval and period-lock settings |
| `app_settings/company_branding` | App-level company branding |

## 🔐 Security and Rules

### Current guarantees

- Technicians can create only their own jobs and IN/OUT records.
- Technicians cannot self-approve records.
- Admins can approve, reject, and import historical records.
- Shared installs enforce invoice ownership and capacity limits.
- Historical admin imports are allowed through rules even when imported invoice claims carry technician ownership metadata.
- Period locks prevent create, edit, approve, reject, and delete operations before the configured date.

### Rules coverage checked in this repo

- Job create and update permissions
- Expense and earning approval constraints
- AC install approval constraints
- Shared-install aggregate update limits
- Invoice-claim duplicate protection
- Admin historical import path

## 🔢 Versioning Policy

Versioning is centralized in `scripts/versioning.ps1` and shared by:

- `scripts/bump_version.ps1`
- `.git/hooks/pre-commit.ps1`

### Policy

- Every release action increments the build number automatically.
- Build number is strictly monotonic and never resets.
- Patch/minor/major changes are managed separately from build monotonicity.

### Examples

| Current | Next |
| --- | --- |
| `1.0.1+1` | `1.0.1+2` |
| `1.0.9+15` | `1.0.9+16` |
| `1.0.1+10` | `1.0.1+11` |

Minimum next versionCode in this repo: **16**.

## 🧹 Local Cache and Uninstall Behavior

### What happens on sign-out

- Riverpod session-scoped providers are invalidated.
- Firebase Auth signs out.
- Saved login reminder keys are removed.
- A Firestore persistence wipe is scheduled for the next cold launch.

### What happens on uninstall

- Android removes the app sandbox, including app-private local storage and cached Firestore data.
- The app cannot execute code during uninstall.
- Uninstall does **not** delete server-side Firestore data.

### If you want zero traces everywhere

- Uninstall clears device-local app data.
- Database Flush clears server-side operational data.

## 💥 Database Flush Scope

Full database flush currently removes:

- `jobs`
- `expenses`
- `earnings`
- `ac_installs`
- `shared_install_aggregates`
- `invoice_claims`
- `companies`

Optional behavior:

- Non-admin user documents can also be **archived** (set `isActive: false`) when explicitly selected — not hard-deleted.

### Soft Archive (Expenses, Earnings, AC Installs)

Technician-owned records are never hard-deleted. Instead:

- Swipe-to-dismiss marks the record with `isDeleted: true` + `deletedAt` timestamp
- A 4-second undo SnackBar lets the tech immediately reverse the action
- Admins can restore soft-archived records from the admin panel
- Archived records are filtered out on the client in Dart (no new Firestore index required)

> [!WARNING]
> Flush is destructive and intentionally guarded by countdown and password confirmation.

## 🚀 Build & Release

Release this repo as one surface. If dashboards, navigation, auth, localization, reports, or Firebase behavior changed, web, APK, and rules must come from the same source tree.

### Required release order

```powershell
flutter analyze
flutter test
Set-Location scripts
npm run lint:firestore-rules
npm run test:firestore-rules
Set-Location ..
flutter build web --release
firebase deploy --only hosting,firestore:rules,firestore:indexes --project actechs-d415e
flutter build apk --release
```

Only install the APK after the gates above are green and only claim web/APK/backend are in sync when all three were built or deployed from that same revision.

### Recommended release command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 -Build -Web -Install
```

### Commit and push in the same flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 -Build -Web -Install -Commit -Push
```

### What the script does

- Bumps version using the shared policy
- Builds release APK when `-Build` is used
- Builds release web when `-Web` is used
- Installs the built APK when `-Install` is used
- Commits with the bumped version when `-Commit` is used
- Pushes the commit when `-Push` is used

## Developer Commands

| Command | Purpose |
| --- | --- |
| `flutter pub get` | Install Dart and Flutter dependencies |
| `flutter analyze` | Static analysis |
| `flutter test` | Flutter tests |
| `dart run build_runner build --delete-conflicting-outputs` | Code generation |
| `flutter gen-l10n` | Localization generation |
| `flutter build apk --release` | Release APK |
| `flutter build web --release` | Release web bundle |
| `powershell -ExecutionPolicy Bypass -File .\scripts\install-hooks.ps1` | Install git hooks |
| `cd scripts; npm run test:firestore-rules` | Emulator-backed rules tests |

## ✅ Testing

Recommended validation before shipping:

```powershell
flutter analyze
flutter test
Set-Location scripts
npm run lint:firestore-rules
npm run test:firestore-rules
```

Focused checks commonly used in this repo:

- Router regression tests
- Shared-install repository tests
- Firestore rule regression tests
- PDF export sample validation

Additional references:

- `docs/testing-strategy.md`
- `docs/firestore-rules-guide.md`

## 🗂 Governance Files

| File | Purpose |
| --- | --- |
| `MASTER_BLUEPRINT.md` | Current architecture and operating constraints |
| `REGRESSION_REGISTRY.md` | Previously fixed regressions and their guard rails |
| `SESSION_LOG.md` | Session-by-session implementation ledger |
| `CHANGELOG.md` | Human-readable release history |
| `docs/domain-architecture.md` | Human-readable domain and ownership guide |
| `docs/audits/README.md` | Index of audit artifacts |
| `.github/workflows/README.md` | Workflow summary and local equivalents |

## 🧭 Operational Notes

### Invoice prefix handling

- New job submissions store invoice numbers without forcing `INV-`.
- Historical import now strips the selected company prefix from imported invoice numbers when present.
- Legacy invoice normalization is no longer exposed from the admin dashboard.
- If older prefixed rows still exist, the supported cleanup path is flush plus re-import, not an in-app migration step.

### Approval behavior

- Jobs, earnings, expenses, and AC installs respect approval settings in `approval_config`.
- Period lock enforcement applies across create, update, approve, reject, and delete flows.
- Approved records are intentionally harder to mutate or delete.

### Spark-only discipline

- Prefer repository reads that avoid unnecessary always-on listeners.
- Keep batch operations chunked.
- Avoid backend architecture that assumes privileged server transforms.

---

If you change approval logic, invoice ownership, import behavior, or destructive maintenance flows, review all three layers together:

1. UI behavior
2. Repository enforcement
3. Firestore rules

Key Firestore path:

- `app_settings/company_branding`

Important implementation notes:

- shared-install aggregate writes are blocked to normal clients and coordinated through repository transactions
- active-user checks are enforced in Firestore rules for technician writes
- approval history documents are immutable once created
- admin flush operations depend on both rules and repository code staying aligned

## Security Model

Security is layered across the client and Firestore rules.

Current protections:

- Firebase Auth for sign-in
- Firestore `isActiveUser()` gating for technician writes
- admin-only review transitions for approvals
- App Check enabled on Android
- repository-layer validation before writes
- localized typed exceptions instead of raw backend messages

Files to review before changing security-sensitive behavior:

- `firestore.rules`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/jobs/data/job_repository.dart`

## Localization and UI

Supported locales:

- English
- Urdu
- Arabic

UI characteristics:

- Material 3
- Arctic-themed styling
- RTL support for Urdu and Arabic
- locale-aware fonts
- shimmer and animated transitions for loading and UI polish

Localization sources live in `lib/l10n/` and generate `lib/l10n/app_localizations.dart`.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.x |
| Backend | Firebase Auth, Cloud Firestore, Hosting, App Check |
| State | Riverpod 3.x |
| Routing | GoRouter |
| Models | Freezed, json_serializable |
| Charts | fl_chart |
| Reporting | excel, pdf, printing, share_plus |
| File handling | file_picker |
| Rendering | flutter_svg, shimmer, flutter_animate |

## Setup

### Prerequisites

- Flutter SDK matching the repo Dart/Flutter constraints
- Android SDK for device builds and installs
- Firebase CLI for rules, indexes, and hosting deployment

### Install dependencies

```bash
flutter pub get
```

### Generate code and localization

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Run the app

### Android

```bash
flutter run -d <deviceId>
```

### Web

```bash
flutter run -d chrome
```

### List devices

```bash
flutter devices
```

## Validation workflow

Recommended local validation order:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
```

For backend and platform-sensitive changes also run:

```bash
flutter build apk --release
```

## Build and install

### Release APK

```bash
flutter build apk --release
```

### Release web

```bash
flutter build web --release
```

### Install release APK to a device

```bash
flutter install -d <deviceId> --release
```

Or manually:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Firebase deployment

### Firestore rules and indexes

```bash
firebase deploy --only firestore --project actechs-d415e
```

This repository is Spark-only. Do not deploy or add Cloud Functions.

## CI and automation

GitHub workflows currently cover:

- static analysis
- generated-code step
- tests
- debug APK build
- manual APK build workflow

Relevant files:

- `.github/workflows/ci.yml`
- `.github/workflows/build-apk.yml`
- `.github/workflows/release.yml`

The repo also includes release/version helpers under `scripts/` for bumping version numbers, building artifacts, installing builds, and pushing release changes.

## High-risk change areas

These parts of the repo need extra care because a narrow change can cascade across rules, repository logic, exports, and approvals:

- shared installs
- approval settings and approval history
- Firestore rules
- analytics summaries
- import/export formatting
- localization keys and RTL rendering

When touching any of those, update code and docs together and rerun the full validation workflow.

## Documentation

- `docs/firebase-setup-guide.md`
- `docs/error-messages.md`
- `docs/ultimate_master_audit_report_v6.txt`
- `docs/ultimate_master_fix_plan_v1.md`

## Current source of truth

`main` is the canonical branch for this repository.

If you change approval behavior, shared-install rules, model fields, or backend payloads, treat the following as a single contract that must stay synchronized:

- Flutter models
- repository write logic
- Firestore rules
- indexes
- tests
- operational documentation

## 🛟 Troubleshooting

### PERMISSION_DENIED on shared install submit

- Verify the aggregate `teamMemberIds` field includes the submitting tech's UID
- Verify `allow list` on `/users/{userId}` is deployed to Firestore (`firebase deploy --only firestore`)
- Check `shared_install_aggregates` composite index on `teamMemberIds` exists in `firestore.indexes.json`

### Period lock errors on delete

- The record's `date` field falls within the locked period. Admin must unlock the period in app settings before archiving old records.

### Shared group totals mismatch error

- Two techs submitted the same invoice number with different `sharedInvoice*` values.
- The first submission owns the totals — subsequent submitters must use the same invoice totals.
- Admin can correct totals via the aggregate admin update payload.

### Archived record still showing in list

- Stream mapper filter may be missing. Verify `isDeleted != true` Dart-layer filter in the repository stream.
- If using Firestore offline cache, a full sign-out + sign-in cycle clears stale cached data.

### versionCode must increase error in CI

- The `pubspec.yaml` build number (after `+`) must be strictly greater than the previous tag.
- Run `scripts/bump_version.ps1 -Build` to increment automatically.
- Minimum next versionCode: **16**.
