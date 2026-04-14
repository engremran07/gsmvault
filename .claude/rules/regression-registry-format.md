---
paths: ["REGRESSION_REGISTRY.md"]
---

# Regression Registry Format Rules

Rules for maintaining the `REGRESSION_REGISTRY.md` root document.

## Entry Format

Every entry MUST follow this table format:

```markdown
| ID | Status | Date | Category | Description | Guard | Root Cause |
```

- **ID**: `RR-NNN` — sequential, never reused.
- **Status**: `OPEN` (unguarded) or `CLOSED` (guard verified).
- **Date**: `YYYY-MM-DD` — date the regression was identified.
- **Category**: One of: Security, Frontend, Architecture, Quality, Database, Performance.
- **Description**: One sentence describing the regression.
- **Guard**: Specific `file:function` or `file:class` reference where the guard lives.
- **Root Cause**: Brief explanation of why the regression happened.

## Status Lifecycle

1. Regression discovered → create `OPEN` entry.
2. Guard implemented and verified → update to `CLOSED`.
3. Guard removed and regression recurs → update to `OPEN (RECURRED)`.

## Rules

- NEVER close an entry without verifying the guard code exists AND passes tests.
- NEVER delete entries — they are permanent records.
- ALWAYS link to specific file + line/function where the guard lives.
- Every `OPEN` entry MUST block deployment until resolved.
- Review the registry during every regression agent scan.
- The `regression-guardian` agent is responsible for maintaining this file.

## When to Add Entries

Add a new entry when:
- A bug is found that should have been caught by a guard.
- A guard is discovered to be missing (e.g., no sanitization on a model).
- An existing guard is accidentally removed.
- A pattern violation is detected that needs permanent tracking.
