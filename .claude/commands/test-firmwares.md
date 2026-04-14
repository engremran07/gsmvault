# /test-firmwares â€” Run firmwares app test suite

Execute all tests for the firmware mega-app covering upload, verification, scraper, download tokens, and GSMArena sync.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Firmwares Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/firmwares/ -v --settings=app.settings_dev`

- [ ] Specific test: `& .\.venv\Scripts\python.exe -m pytest apps/firmwares/ -v -k "$ARGUMENTS" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/firmwares/ -v --cov=apps/firmwares --cov-report=term-missing`

### Step 2: Verify Feature Coverage

- [ ] Firmware CRUD: create, update, delete, file types (Official, Engineering, Readback, Modified, Other)

- [ ] Brand/Model/Variant catalog: hierarchy management, slug generation

- [ ] Upload: file validation (MIME, extension, size), storage integration

- [ ] Verification: TrustedTester, VerificationReport, TestResult, VerificationCredit

- [ ] OEM scraper: OEMSource, ScraperConfig, ScraperRun, IngestionJob workflow

- [ ] Scraper approval: pending â†’ approved â†’ processing â†’ done/failed flow

- [ ] Download tokens: HMAC signing, expiry, status transitions (active/used/expired/revoked)

- [ ] Download sessions: lifecycle tracking (bytes_delivered, start/complete/fail)

- [ ] Ad-gate: AdGateLog, watched_seconds, credits_earned, gate completion

- [ ] Hotlink protection: domain validation, referrer checks

- [ ] GSMArena sync: GSMArenaDevice, SyncRun, SyncConflict resolution

- [ ] Download service: `create_download_token()`, `validate_download_token()`, `check_rate_limit()`

### Step 3: Check Results

- [ ] All tests pass (zero failures)

- [ ] No file system artifacts left after tests (cleanup temp uploads)

- [ ] Coverage above project threshold

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/firmwares/`
