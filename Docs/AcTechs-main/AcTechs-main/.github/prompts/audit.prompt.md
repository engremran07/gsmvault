---
mode: agent
description: Full cross-team audit. Launches 7 specialised subagents concurrently then synthesises findings.
---

# /audit — AC Techs Full System Audit

Launch **seven** subagents concurrently using `runSubagent`. Each agent must search the actual codebase — do **not** guess.

## Subagent 1 — backend-engineer
Audit scope:
- Firestore security rules: verify no `doc.delete()` paths for tech-owned records (expenses, earnings, installs); verify `teamMemberIds` present on every new aggregate create payload; verify all optional settlement fields use `.get('field', null)` safe access; verify ALL 3 archive rules have `resource.data.status != 'approved'` guard AND `request.resource.data.deletedAt is timestamp` validation
- Repositories: confirm `archiveExpense`, `archiveEarning`, `archiveInstall` exist (not `delete`); confirm stream mappers filter `isDeleted != true`; confirm `pendingSharedInstallAggregatesProvider` has `.limit()`
- Indexes: verify `firestore.indexes.json` includes `shared_install_aggregates → teamMemberIds`
- Report: list of findings with file path + line number

## Subagent 2 — frontend-engineer
Audit scope:
- `submit_job_screen.dart`: confirm `_selectedTeamMembers` list exists (not `_sharedTeamSize` int); team selector UI present; delivery split = `rawDelivery / (_selectedTeamMembers.length + 1)`
- `daily_in_out_screen.dart`: confirm swipe/dismiss calls `archiveExpense/Earning` (not `delete`); undo SnackBar present; PDF calls wrapped in `compute()` (not direct `await PdfGenerator.*`)
- `analytics_screen.dart`: confirm PDF calls wrapped in `compute()`
- All user-facing strings via `context.l10n` — no hardcoded strings
- RTL layout check for Urdu/Arabic locales
- Report: list of findings with file path + line number

## Subagent 3 — qa-engineer
Audit scope:
- `flutter analyze` output — zero issues required
- `flutter test` — all tests pass; `test/unit/expenses/archive_lifecycle_test.dart` exists with stream exclusion tests
- `test/unit/jobs/job_repository_shared_install_test.dart` — check for teamMemberIds[0]=createdBy test, second tech joining test, max team size test
- All providers handle loading/error/data states
- Report: list of findings, test counts, coverage gaps

## Subagent 4 — security-auditor
Audit scope:
- Confirm no `doc.delete()` in tech-accessible repositories
- Confirm `teamMemberIds` size ≤ 10 guard exists in rules
- Confirm ALL archive rules check `resource.data.status != 'approved'`
- Confirm `allow list` on `/users/{userId}` is scoped to `isActiveUser() || isAdmin()` only
- Confirm App Check is active on Android; note if web App Check is missing
- Confirm no PII leaked to client logs
- Report: list of findings with severity (CRITICAL / HIGH / MEDIUM / LOW)

## Subagent 5 — Explore (documentation accuracy)
Audit scope:
- Search ALL `.md` files in `.claude/` and `.github/instructions/` for `ac_installations` — must return ZERO matches (correct name is `ac_installs`)
- Check `.claude/rules/ui-conventions.md` for bottom nav — must say Tech has 5 tabs
- Check `.claude/CLAUDE.md` for `Breakage Chain Reference` section — must exist
- Check `docs/error-messages.md` for `PeriodException` / `period_locked` — must exist
- Check `.claude/rules/firebase.md` for free-tier daily limits (50K reads / 20K writes) — must exist
- Report: exact file + line for each finding, PASS/FAIL per check

## Subagent 6 — Explore (free-tier cost analysis)
Audit scope:
- Find all `StreamProvider` definitions across `lib/features/` — list each with collection and filter applied
- Identify any stream with no `techId` filter or no date filter (potential unbounded listener)
- Check `shared_install_providers.dart` for `.limit()` — must exist
- Check if settlement/history screens use `FutureProvider` (correct) or `StreamProvider` (wrong)
- Estimate daily read budget usage based on stream count × typical doc count
- Report: stream inventory, budget estimate, any unbounded streams

## Subagent 7 — Explore (i18n completeness)
Audit scope:
- Extract all keys from `lib/l10n/app_en.arb`, `lib/l10n/app_ur.arb`, `lib/l10n/app_ar.arb`
- Report any key present in en but missing in ur or ar (or vice versa)
- Check that all settlement status labels are localised (settlementPending, settlementConfirmed, etc.)
- Report: parity table, missing keys per locale

## Synthesis
After all 7 subagents complete:
1. Aggregate all CRITICAL and HIGH findings first
2. Produce a closure matrix table: `| Item | Status | File | Line |`
3. List any items that are OPEN (not yet implemented)
4. List any items RULED OUT (code already correct despite the finding)
5. Recommend next implementation priority

## Mandatory Cross-Cutting Checks
- Verify `ShellBackNavigationScope` is used by both shell roots and that shell `_currentIndex()` returns `-1` for pushed non-tab routes.
- Verify `SwipeActionCard` is rendered with stable keys at call sites.
- Verify no user-facing presentation files hardcode `Colors.white` where theme colors should be used.
- Verify release/build workflows include analyzer, tests, rules lint, rules tests, and artifact verification.
- Verify audit and post-implementation prompts remain in sync with current CI gates.
