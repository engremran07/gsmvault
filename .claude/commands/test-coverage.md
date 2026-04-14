# /test-coverage â€” Run pytest with coverage analysis

Run the full test suite with coverage measurement, highlight uncovered files, and compare against the 60% minimum threshold.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Tests with Coverage

- [ ] Run `& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing --tb=short`

- [ ] Capture overall coverage percentage

- [ ] If $ARGUMENTS specifies apps, run `& .\.venv\Scripts\python.exe -m pytest apps/$ARGUMENTS/ --cov=apps/$ARGUMENTS --cov-report=term-missing`

### Step 2: Identify Uncovered Files

- [ ] List files with 0% coverage (completely untested)

- [ ] List files below 30% coverage (critically undertested)

- [ ] List files below 60% coverage (below threshold)

- [ ] Prioritize: models.py, services.py, views.py, api.py in each app

### Step 3: Threshold Check

- [ ] Compare overall coverage against 60% minimum

- [ ] Flag any app entirely missing a `tests.py` or `tests/` directory

- [ ] Identify newly added code without corresponding tests

### Step 4: Coverage by App

- [ ] Break down coverage percentage per Django app

- [ ] Highlight apps with lowest coverage

- [ ] Note apps with critical business logic needing priority testing (wallet, firmwares, security, devices)

### Step 5: Report

- [ ] Print summary table: App | Coverage % | Status (PASS/FAIL)

- [ ] List top 10 uncovered functions/methods

- [ ] Recommend highest-impact test additions
