# /test-devices â€” Run devices app test suite

Execute all tests for the device catalog covering fingerprinting, trust scoring, quota tiers, and behavior insights.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Devices Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/devices/ -v --settings=app.settings_dev`

- [ ] Specific test: `& .\.venv\Scripts\python.exe -m pytest apps/devices/ -v -k "$ARGUMENTS" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/devices/ -v --cov=apps/devices --cov-report=term-missing`

### Step 2: Verify Feature Coverage

- [ ] Device CRUD: registration, OS/browser detection, last_seen tracking

- [ ] DeviceConfig: fingerprinting policy, quotas, MFA rules, AI risk scoring

- [ ] DeviceFingerprint: OS, browser, device type, trust level, bot detection

- [ ] TrustScore: computed score, signal tracking, threshold checks

- [ ] QuotaTier: daily/hourly limits, requires_ad, can_bypass_captcha per tier

- [ ] BehaviorInsight: AI-flagged anomalies, severity levels (low/medium/high/critical)

- [ ] DeviceEvent: activity log types (login, download_attempt, policy_violation)

- [ ] Tier progression: Free â†’ Registered â†’ Subscriber â†’ Premium

### Step 3: Check Results

- [ ] All tests pass (zero failures)

- [ ] Trust score calculations are deterministic in tests

- [ ] Coverage above project threshold

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/devices/`
