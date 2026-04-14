# REGRESSION_REGISTRY

This file records previously fixed regressions that must not be reintroduced.

| ID | Area | Regression | Root cause | Current guard |
| --- | --- | --- | --- | --- |
| REG-001 | In/Out providers | Day-level providers opened extra Firestore listeners | Single-day views were implemented as standalone `StreamProvider`s | Derived day/today providers plus workflow gate in `audit.yml` |
| REG-002 | In/Out navigation | History cards opened `/tech/summary` instead of day detail | Day history and month summary were conflated | Route rules in `.claude` and provider-model instructions |
| REG-003 | Job submission | Company could be skipped even when active companies existed | Company selector allowed “no company” choice | Runtime guard plus workflow gate in `audit.yml` |
| REG-004 | Shared installs | Completed shared aggregates stayed visible forever | Pending aggregate list did not filter `isFullyConsumed` | Provider filter plus workflow gate |
| REG-005 | Auth state | Auth errors were swallowed and looked like sign-out | `Stream.value(null)` masked session and network failures | Current user provider must propagate errors |
| REG-006 | Navigation | Detail routes used `context.go()` and destroyed back stack | Shell-root and detail-route semantics were mixed | Route policy in docs plus weekly audit grep gate |
| REG-007 | Job archive model | Jobs lacked soft-delete fields while other technician records had them | `JobModel` and rules drifted from archive conventions | `JobModel` fields, archive rules, and repository methods |
| REG-008 | Daily In/Out FAB overlap | Floating button covered the last visible item | List bottom padding was too small | Extra bottom padding in `daily_in_out_screen.dart` |
| REG-009 | Dashboard FAB layout | Extended FAB collapsed into a circular shape and clipped label | Global FAB theme forced `CircleBorder()` for all FAB variants | Theme fix plus dashboard widget test |
| REG-010 | Dashboard affordance | Summary cards looked tappable but some did nothing | Visual affordance exceeded actual interaction wiring | Dashboard stat-card tap fixes and widget regression tests |
| REG-011 | Settlement flow | Techs could not respond to settlement requests for jobs in locked periods | `technicianSettlementUpdate()` included `dateIsUnlocked()` guard, blocking settlement responses after period lock | Removed `dateIsUnlocked` from settlement-response path; emulator regression test REG-011 added |
| REG-012 | Edit re-approval | Approved jobs could not re-enter the approval flow for correction | No Firestore rule branch existed for approved→pending status transition initiated by technician | Added 4th branch to `technicianApprovalFlowUpdate()` for re-approval; `editRequestedAt` timestamp enforced |

## Use

- Add a new entry whenever a regression is fixed.
- Update the guard column when a workflow gate, rule, or test is added.
- Cross-check this file before broad AI-assisted edits.
