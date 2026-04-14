# /test-distribution â€” Run distribution app test suite

Execute all tests for the content syndication system covering social posting, WebSub, and platform integrations.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Distribution Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/distribution/ -v --settings=app.settings_dev`

- [ ] Specific test: `& .\.venv\Scripts\python.exe -m pytest apps/distribution/ -v -k "$ARGUMENTS" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/distribution/ -v --cov=apps/distribution --cov-report=term-missing`

### Step 2: Verify Feature Coverage

- [ ] Content syndication: blog post distribution to social platforms

- [ ] Twitter/X integration: post formatting, character limits, media attachments

- [ ] LinkedIn integration: article sharing, professional formatting

- [ ] WebSub: hub notification, subscriber management, content delivery

- [ ] Scheduling: deferred posting, queue management, retry logic

- [ ] Template rendering: per-platform content formatting

- [ ] Error handling: API failures, rate limits, credential expiry

### Step 3: Check Results

- [ ] All tests pass (zero failures)

- [ ] No external API calls made during tests (mock all social platform APIs)

- [ ] Coverage above project threshold

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/distribution/`
