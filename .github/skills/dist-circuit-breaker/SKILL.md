---
name: dist-circuit-breaker
description: "Circuit breaker for platform APIs. Use when: handling repeated API failures, preventing cascade failures, implementing open/half-open/closed states."
---

# Distribution Circuit Breaker

## When to Use
- Protecting against cascading failures when a platform API is down
- Implementing open/half-open/closed circuit states per connector
- Automatically disabling failing channels temporarily
- Recovering gracefully when APIs come back online

## Rules
- Circuit states: CLOSED (normal), OPEN (failing, skip calls), HALF-OPEN (testing)
- Track failure count per `SocialAccount` in `config["circuit_failures"]`
- Open threshold: 5 consecutive failures → circuit opens
- Open duration: 5 minutes → then half-open (try 1 request)
- Half-open success → close circuit; failure → reopen
- `DistributionSettings.max_retries` controls per-job retries (different from circuit)

## Patterns

### Circuit Breaker Implementation
```python
# apps/distribution/services/circuit_breaker.py
from django.utils import timezone
from apps.distribution.models import SocialAccount

FAILURE_THRESHOLD = 5
RECOVERY_TIMEOUT_SECONDS = 300  # 5 minutes

def is_circuit_open(account: SocialAccount) -> bool:
    """Check if circuit breaker is tripped for this account."""
    config = account.config or {}
    failures = config.get("circuit_failures", 0)
    if failures < FAILURE_THRESHOLD:
        return False
    last_failure = config.get("circuit_opened_at")
    if not last_failure:
        return True
    elapsed = (timezone.now() - timezone.datetime.fromisoformat(last_failure)).total_seconds()
    return elapsed < RECOVERY_TIMEOUT_SECONDS

def record_failure(account: SocialAccount) -> None:
    config = account.config or {}
    config["circuit_failures"] = config.get("circuit_failures", 0) + 1
    if config["circuit_failures"] >= FAILURE_THRESHOLD:
        config["circuit_opened_at"] = timezone.now().isoformat()
    account.config = config
    account.save(update_fields=["config"])

def record_success(account: SocialAccount) -> None:
    config = account.config or {}
    config["circuit_failures"] = 0
    config.pop("circuit_opened_at", None)
    account.config = config
    account.save(update_fields=["config"])
```

### Using Circuit Breaker in Connector
```python
def execute_job(*, job: ShareJob) -> dict:
    account = job.account
    if is_circuit_open(account):
        job.status = "skipped"
        job.last_error = "Circuit breaker open — channel temporarily disabled"
        job.save(update_fields=["status", "last_error"])
        return {"status": "circuit_open"}

    try:
        result = dispatch_to_connector(job=job)
        record_success(account)
        return result
    except Exception as e:
        record_failure(account)
        raise
```

## Anti-Patterns
- No circuit breaker — one failing API blocks the entire distribution pipeline
- Retrying immediately after API returns 503 — overwhelms recovering service
- Global circuit breaker instead of per-account — one bad account blocks all
- Not resetting failure count on success — circuit never closes

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
