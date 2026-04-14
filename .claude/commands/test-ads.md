# /test-ads â€” Run ads app test suite

Execute all tests for the ads and affiliate marketing system covering campaigns, placement rotation, targeting, affiliate links, and rewarded ads.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Ads Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/ads/ -v --settings=app.settings_dev`

- [ ] Specific test: `& .\.venv\Scripts\python.exe -m pytest apps/ads/ -v -k "$ARGUMENTS" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/ads/ -v --cov=apps/ads --cov-report=term-missing`

### Step 2: Verify Feature Coverage

- [ ] Campaign CRUD: create, budget caps, scheduling, status transitions

- [ ] Placement rotation: weighted rotation, priority, lock controls

- [ ] Targeting: geo, device type, user segment, time-of-day rules

- [ ] Ad networks: 18 network types, priority ordering, status management

- [ ] Ad units: format types (banner/interstitial/native/video/rewarded/sticky)

- [ ] Ad events: impression, click, viewable, conversion tracking

- [ ] Rewarded ads: credits earned, cooldown, daily limits, completion tracking

- [ ] Affiliate providers: Amazon, AliExpress, Banggood, CJ, ShareASale, etc.

- [ ] Affiliate links: UTM parameters, click attribution, deep links

- [ ] Affiliate product matching: auto-match firmware devices to products

- [ ] AI optimizer: placement optimization, creative scoring

- [ ] Celery tasks: event aggregation, cleanup, template scanning

### Step 3: Check Results

- [ ] All tests pass (zero failures)

- [ ] No stale ad event data left in test DB

- [ ] Coverage above project threshold

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/ads/`
