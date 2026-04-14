---
name: regression-detection
description: "General regression detection skill. Use when: performing broad regression scans, identifying patterns that indicate regressions, maintaining regression registry entries, classifying fix hypotheses."
---

# General Regression Detection

## When to Use

- As a meta-skill coordinating all other regression skills
- When performing a broad regression scan before deployment
- When updating the REGRESSION_REGISTRY.md
- When classifying whether a fix is a true fix vs a band-aid

## Regression Registry Format

```markdown
| ID | Status | Date | Category | Description | Guard | Root Cause |
|----|--------|------|----------|-------------|-------|------------|
| RR-001 | OPEN/CLOSED | YYYY-MM-DD | Security/Frontend/Arch/Quality | Brief desc | File:line guard code | Why it happened |
```

## Categories

| Category | Skills to Invoke |
|----------|-----------------|
| Security | regression-xss-prevention, regression-csrf-protection, regression-csp-enforcement, regression-auth-checks |
| Frontend | regression-template-safety |
| Architecture | regression-app-boundaries |
| Quality | regression-type-safety, regression-database-safety, regression-test-coverage |

## Band-Aid Detection (from Footwear Pattern)

A fix is a **band-aid** if ANY of these are true:
1. It addresses the symptom but not the root cause
2. It adds a workaround that will need to be removed later
3. It suppresses an error without fixing the underlying issue
4. It duplicates existing logic instead of reusing it
5. It adds a `try/except` that swallows exceptions silently

### Band-Aid Reversal Protocol

When a band-aid is detected:
1. Document it in the regression registry with status `OPEN`
2. Classify: `TEMPORARY_ACCEPTABLE` or `MUST_FIX_NOW`
3. For `MUST_FIX_NOW`: identify root cause, implement proper fix, remove band-aid
4. For `TEMPORARY_ACCEPTABLE`: set a deadline (max 2 weeks), add to sprint backlog
5. After proper fix: verify guard is in place, mark RR entry as `CLOSED`

## Procedure

1. Run all regression skill checks (see Categories table)
2. Compile findings into a unified report
3. For each finding, check against existing REGRESSION_REGISTRY.md entries
4. New findings → create draft RR entries
5. Existing entries → verify guard retention

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
