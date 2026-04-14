# CHANGELOG

## 1.4.0+44

- Added custom zoom drawer navigation for both technician and admin shells
- Added stale shared install cleanup feature with admin dashboard card and batch archive
- Fixed AC installs Firestore rules: auto-approved edit path and soft-archive exception for auto-approved entries
- Removed 6 dead repository methods (todaysJobs, todaysExpenses, todaysWorkExpenses, todaysHomeExpenses, todaysEarnings, watchTodaysInstalls)
- Added FirebaseException error handling to ApprovalConfigRepository
- Added firebase_options.dart to .gitignore for security
- Fixed RTL compliance across 18+ files with AlignmentDirectional/EdgeInsetsDirectional
- Fixed Matrix4 deprecated member warnings in zoom drawer
- Fixed BuildContext async gap in admin dashboard stale install cleanup
- Deleted temporary artifacts (debug scripts, PDF samples, analysis output, fix plan)
- Added 25 new tests: stale aggregates, zoom drawer controller, approval config model + repository
- Total test count: 424 (up from 399)

## 1.3.5+41

- Fixed settlement PERMISSION_DENIED for locked-period jobs (REG-011)
- Added edit re-approval sub-flow: approved jobs can request correction (REG-012)
- Added admin hard delete with dual-confirm UI and emulator regression test
- Added unified history status filter with Shared as 5th chip
- Added bracket and uninstall filtered job list screens from dashboard stat cards
- Added invoice reconciliation screen: compare Excel report against DB jobs, mark matched as paid
- Hardened Firestore rules: settlement path and edit re-approval transition
- Hardened all governance docs, agent/skill files with zero-problems policy and Firestore alignment blocking rules
- Added web build parity to CI and release workflows so web and APK are validated from the same source tree
- Added governance continuity file enforcement to CI hygiene and weekly audit gates
- Updated weekly audit gates to distinguish shell-root navigation from pushed detail routes
- Added governance continuity files: blueprint, regression registry, session log, and changelog
- Fixed technician dashboard settings navigation to preserve back stack
- Made technician dashboard bracket and uninstall summary cards actionable
- Removed the global circular FAB shape override so extended FAB labels stay readable on-device
- Added a dashboard widget regression test covering settings navigation, summary-card taps, and the New Job FAB
- Replaced the last hardcoded approval-config document ID with the shared `AppConstants` constant
- Fixed BulkActionBar background color drift across themes (was hardcoded surface, now theme-aware)

## 1.3.4+40

- Fixed Daily In/Out FAB overlap with list content
- Added undo feedback helper for archive actions
- Added job soft-delete model fields and archive/restore support
- Tightened job archive Firestore rules
- Improved submit screen company loading error state
- Added CI coverage-file existence verification

## 1.3.3+39

- Previous stable baseline before the April 2026 audit remediation cycle
