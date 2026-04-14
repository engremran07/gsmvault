# /coverage-report â€” Generate detailed test coverage report

Run full test suite with coverage measurement and generate an HTML report highlighting files below threshold.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Tests with Coverage

- [ ] Full project: `& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=html --cov-report=term-missing --settings=app.settings_dev`

- [ ] Specific app: `& .\.venv\Scripts\python.exe -m pytest apps/$ARGUMENTS/ --cov=apps/$ARGUMENTS --cov-report=html --cov-report=term-missing`

- [ ] Output HTML to: `htmlcov/` directory

### Step 2: Analyze Coverage

- [ ] Review terminal summary for per-file coverage percentages

- [ ] Identify files below 80% coverage threshold

- [ ] Flag files with 0% coverage (completely untested)

- [ ] List uncovered lines per file (from `term-missing` report)

### Step 3: Identify Priority Gaps

- [ ] `services.py` files â€” business logic must be well-tested

- [ ] `views.py` / `views_*.py` â€” endpoint coverage

- [ ] `models.py` â€” model methods and property coverage

- [ ] `api.py` â€” serializer and viewset coverage

- [ ] `tasks.py` â€” Celery task coverage

- [ ] `download_service.py` â€” critical download flow coverage

### Step 4: Report

- [ ] Open HTML report: `Start-Process htmlcov\index.html`

- [ ] List top 10 files by uncovered line count

- [ ] Recommend which files to prioritize for test writing

- [ ] Note any apps with no test files at all
