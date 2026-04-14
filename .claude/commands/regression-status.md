# /regression-status â€” Review regression registry status

Analyze REGRESSION_REGISTRY.md: count OPEN vs FIXED items, review recent entries, assess fix hypotheses, and verify resolution status.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Read Registry

- [ ] Read `REGRESSION_REGISTRY.md` in full

- [ ] Parse all regression entries

### Step 2: Status Summary

- [ ] Count entries by status: OPEN, FIXED, MONITORING

- [ ] Count entries by severity: Critical, High, Medium, Low

- [ ] Count entries by category (type safety, template, security, etc.)

- [ ] Print summary table: Status | Count

### Step 3: OPEN Items Review

- [ ] List all OPEN regressions with their descriptions

- [ ] For each OPEN item, review the fix hypothesis

- [ ] Check if the fix hypothesis has been attempted

- [ ] Assess if the regression is still reproducible

### Step 4: Recent Entries

- [ ] Identify entries added in the last 7 days

- [ ] Check if recent entries have fix hypotheses

- [ ] Verify recent entries follow the registry format

### Step 5: Verification

- [ ] For FIXED entries, spot-check that the fix is still in place

- [ ] Run quality gate to confirm no regressions reintroduced

- [ ] Check if any MONITORING entries can be promoted to FIXED

### Step 6: Report

- [ ] Print OPEN items requiring immediate attention

- [ ] List FIXED items that need verification

- [ ] Recommend next actions for each OPEN regression

- [ ] Note any entries that should be archived
