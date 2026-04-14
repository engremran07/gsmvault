---
paths: ["SESSION_LOG.md"]
---

# Session Log Format Rules

Rules for maintaining the `SESSION_LOG.md` root document.

## Entry Format

Every session entry MUST follow this structure:

```markdown
## SESSION-NNN — YYYY-MM-DD

**Scope**: Brief description of areas touched

**Changes**:

1. **Category Name**
   - Specific change description

**Verification**:

- ruff check result
- ruff format result
- manage.py check result
- VS Code Problems tab result

**Notes**:

- Observations and follow-up items
```

## Required Fields

- **Session ID**: `SESSION-NNN` — sequential, never reused.
- **Date**: `YYYY-MM-DD` — date of the session.
- **Scope**: One-line summary of what was worked on.
- **Changes**: Numbered categories with bulleted specific changes.
- **Verification**: Quality gate results (all 4 checks).
- **Notes**: Observations, discoveries, follow-up items.

## Rules

- ALWAYS create a new entry at the END of the file for each work session.
- NEVER modify previous entries (append-only ledger).
- ALWAYS include all 4 quality gate results in Verification.
- Changes MUST be specific enough to trace back to exact files.
- Notes SHOULD capture discoveries and lessons learned.
- If quality gate fails, document the failures and fixes in the same entry.

## When to Create Entries

- After every implementation session (creating/modifying code or governance files).
- NOT for read-only research or planning sessions.
- Combine related work within a single session into one entry.
