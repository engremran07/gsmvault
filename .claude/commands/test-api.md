# /test-api â€” Run API test suite

Execute all tests for the DRF API layer covering authentication, pagination, permissions, serializer validation, and error responses.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run API Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/api/ -v --settings=app.settings_dev`

- [ ] Specific app API: `& .\.venv\Scripts\python.exe -m pytest apps/$ARGUMENTS/ -v -k "api" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/api/ -v --cov=apps/api --cov-report=term-missing`

- [ ] All app APIs: `& .\.venv\Scripts\python.exe -m pytest apps/ -v -k "api" --settings=app.settings_dev`

### Step 2: Verify API Standards

- [ ] Authentication: JWT token issuance, refresh, expiry, invalid token handling

- [ ] Permissions: anonymous vs authenticated vs staff access on all endpoints

- [ ] Pagination: cursor-based pagination on list endpoints, page size limits

- [ ] Serializer validation: required fields, type coercion, custom validators

- [ ] Error responses: consistent `{"error": "message", "code": "ERROR_CODE"}` format

- [ ] Versioning: `/api/v1/` prefix on all endpoints

- [ ] Throttling: DRF rate limit classes applied (UploadRateThrottle, DownloadRateThrottle, APIRateThrottle)

- [ ] CORS: proper headers on API responses

- [ ] Content negotiation: JSON responses, proper Content-Type headers

### Step 3: Check Results

- [ ] All tests pass (zero failures)

- [ ] No 500 errors in any test scenario (all errors return proper 4xx)

- [ ] Coverage above project threshold

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/api/`
