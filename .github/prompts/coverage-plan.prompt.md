---
agent: 'agent'
description: 'Analyze test coverage gaps across the codebase. Identify critical untested paths and suggest high-value test additions.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Coverage Plan

Analyze test coverage gaps and produce a prioritized plan for adding the most valuable tests.

## Step 1 — Inventory Test Files

1. Search for all test files: `file_search` for `**/test*.py` and `**/tests/**/*.py`.
2. Search for `conftest.py` files to understand shared fixtures.
3. List all apps in `apps/` and categorize each as:
   - **Has tests**: Test file(s) exist with actual test functions.
   - **Has stubs**: Test file exists but only has `pass` or empty classes.
   - **No tests**: No test file at all.

## Step 2 — Critical Path Analysis

Identify the most critical untested code by risk category:

### P0 — Financial / Security (Must Test)
- `apps/wallet/` — All credit/debit operations must have `select_for_update()` tests.
- `apps/shop/` — Order lifecycle, payment processing.
- `apps/marketplace/` — Escrow hold/release/dispute operations.
- `apps/bounty/` — Bounty claim and payout workflow.
- `apps/security/` — WAF rate limiting, IP blocking, crawler rules.
- `apps/firmwares/download_service.py` — Download token creation, validation, ad gate completion.
- `apps/users/` — Authentication, JWT, MFA, password handling.
- `apps/consent/` — Privacy enforcement, consent checks.

### P1 — Data Integrity (Should Test)
- All `services.py` files — Business logic must be verified.
- Model `clean()` methods and constraints.
- `apps/firmwares/` — Scraper approval workflow (IngestionJob status transitions).
- `apps/devices/` — Trust score calculation, behavior insights.
- `apps/core/sanitizers.py` — nh3 sanitization functions.
- `apps/core/throttling.py` — DRF throttle classes.

### P2 — User-Facing (Should Test)
- View response codes (200, 302, 403, 404).
- HTMX fragment rendering (HX-Request detection).
- Form validation and error display.
- Template rendering without errors.
- Admin view access control.

### P3 — Nice to Have
- Celery task execution.
- API serializer validation.
- Template tag/filter output.
- Management command execution.

## Step 3 — Per-App Gap Analysis

For each app with source code, check:

1. Read `models.py` — count models. Check if each model has at least one test.
2. Read `services.py` — count public functions. Check if each has a test.
3. Read `views.py` — count view functions. Check if auth/permission tests exist.
4. Read `api.py` — count API endpoints. Check if CRUD + auth tests exist.
5. Read `tasks.py` — count Celery tasks. Check if any are tested.

## Step 4 — Run Coverage Report (if pytest-cov available)

```powershell
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing --no-header -q 2>&1 | Select-Object -Last 50
```

If coverage data is available, identify:
- Files with 0% coverage.
- Files below 50% coverage.
- Files with critical code at 0% (financial, auth, security modules).

## Step 5 — Output the Coverage Plan

Generate a prioritized list:

```markdown
## Coverage Gap Analysis

### Summary
- Total apps: X
- Apps with tests: Y
- Apps without tests: Z
- Estimated coverage: ~N%

### Priority Additions

| Priority | App | Module | What to Test | Test Count | Effort |
|----------|-----|--------|-------------|------------|--------|
| P0 | wallet | services.py | credit/debit atomicity | 8 | M |
| P0 | security | middleware.py | rate limit enforcement | 5 | S |
| P1 | firmwares | download_service.py | token lifecycle | 10 | L |
| ... | ... | ... | ... | ... | ... |

### Recommended Test File Structure
- `apps/<app>/tests/test_models.py`
- `apps/<app>/tests/test_services.py`
- `apps/<app>/tests/test_views.py`
- `apps/<app>/tests/test_api.py`
```

Focus on tests that prevent real-world failures, not tests that just inflate coverage numbers.
