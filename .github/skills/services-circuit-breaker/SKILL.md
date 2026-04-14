---
name: services-circuit-breaker
description: "Circuit breaker pattern for external service calls. Use when: calling external APIs, protecting against cascading failures, managing external service health."
---

# Circuit Breaker Patterns

## When to Use
- Calling external APIs (OEM firmware sources, payment gateways, GeoIP services)
- Protecting against slow/failing external services
- Preventing cascade failures when a dependency is down
- Graceful degradation when external services are unavailable

## Rules
- Implement three states: CLOSED (normal), OPEN (failing), HALF-OPEN (testing)
- Use Redis/cache for circuit state — shared across workers
- Configure failure threshold, reset timeout, and half-open max attempts
- Always provide a fallback for when circuit is open
- Log all state transitions for monitoring

## Patterns

### Cache-Based Circuit Breaker
```python
import logging
import time
from django.core.cache import cache
from enum import Enum

logger = logging.getLogger(__name__)

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    """Cache-backed circuit breaker for external service calls."""

    def __init__(
        self,
        service_name: str,
        failure_threshold: int = 5,
        reset_timeout: int = 60,
        half_open_max: int = 1,
    ):
        self.service_name = service_name
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.half_open_max = half_open_max

    def _cache_key(self, suffix: str) -> str:
        return f"circuit:{self.service_name}:{suffix}"

    @property
    def state(self) -> CircuitState:
        if cache.get(self._cache_key("open")):
            opened_at = cache.get(self._cache_key("opened_at"), 0)
            if time.time() - opened_at > self.reset_timeout:
                return CircuitState.HALF_OPEN
            return CircuitState.OPEN
        return CircuitState.CLOSED

    def record_success(self) -> None:
        cache.delete(self._cache_key("open"))
        cache.delete(self._cache_key("failures"))
        cache.delete(self._cache_key("opened_at"))

    def record_failure(self) -> None:
        failures = cache.get(self._cache_key("failures"), 0) + 1
        cache.set(self._cache_key("failures"), failures, timeout=self.reset_timeout * 2)
        if failures >= self.failure_threshold:
            cache.set(self._cache_key("open"), True, timeout=self.reset_timeout * 2)
            cache.set(self._cache_key("opened_at"), time.time(), timeout=self.reset_timeout * 2)
            logger.warning("Circuit OPEN for %s after %d failures", self.service_name, failures)

    def can_execute(self) -> bool:
        state = self.state
        if state == CircuitState.CLOSED:
            return True
        if state == CircuitState.HALF_OPEN:
            return True
        return False
```

### Using the Circuit Breaker
```python
import requests

gsmarena_circuit = CircuitBreaker("gsmarena_api", failure_threshold=3, reset_timeout=300)

def fetch_gsmarena_specs(device_slug: str) -> dict | None:
    """Fetch device specs with circuit breaker protection."""
    if not gsmarena_circuit.can_execute():
        logger.info("Circuit open for GSMArena — returning cached/None")
        return _get_cached_specs(device_slug)
    try:
        response = requests.get(
            f"https://api.gsmarena.com/devices/{device_slug}",
            timeout=10,
        )
        response.raise_for_status()
        gsmarena_circuit.record_success()
        return response.json()
    except (requests.RequestException, Exception) as exc:
        gsmarena_circuit.record_failure()
        logger.warning("GSMArena API call failed: %s", exc)
        return _get_cached_specs(device_slug)
```

### Circuit Breaker as Decorator
```python
from functools import wraps

def circuit_protected(breaker: CircuitBreaker, fallback=None):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not breaker.can_execute():
                logger.info("Circuit open for %s, using fallback", breaker.service_name)
                return fallback(*args, **kwargs) if callable(fallback) else fallback
            try:
                result = func(*args, **kwargs)
                breaker.record_success()
                return result
            except Exception as exc:
                breaker.record_failure()
                raise
        return wrapper
    return decorator

# Usage:
@circuit_protected(gsmarena_circuit, fallback=lambda slug: None)
def fetch_device_data(slug: str) -> dict | None:
    ...
```

## Anti-Patterns
- No circuit breaker on external API calls — cascading failures
- Circuit breaker without fallback — just fails differently
- In-memory circuit state — not shared across workers
- Reset timeout too short — circuit never stays open long enough

## Red Flags
- External API call with no timeout AND no circuit breaker
- `requests.get()` without both `timeout` and error handling
- No fallback strategy when external service is down

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
