"""
proxy_pool.py — Free proxy harvesting, validation, and rotation.

Harvests free proxies from multiple public proxy list APIs, validates
them against a test URL, and provides a thread-safe rotating pool.

No paid proxy service required — uses publicly available proxy lists
that are refreshed on-demand. Bad proxies are automatically evicted.

Usage:
    pool = ProxyPool()
    pool.harvest()  # fetch + validate proxies
    proxy = pool.next()  # get next working proxy URL
    pool.report_failure(proxy)  # mark a proxy as failed
"""

from __future__ import annotations

import logging
import random
import threading
import time
from dataclasses import dataclass
from typing import Any

logger = logging.getLogger(__name__)

# Public proxy list APIs (JSON endpoints — no scraping needed)
_PROXY_LIST_URLS: list[dict[str, str]] = [
    {
        "name": "proxyscrape",
        "url": "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies&proxy_format=protocolipport&format=json&limit=50&protocol=http&timeout=5000&anonymity=elite,anonymous",
        "type": "json_proxyscrape",
    },
    {
        "name": "geonode",
        "url": "https://proxylist.geonode.com/api/proxy-list?protocols=http,https&limit=50&page=1&sort_by=lastChecked&sort_type=desc&anonymityLevel=elite&anonymityLevel=anonymous",
        "type": "json_geonode",
    },
    {
        "name": "pubproxy",
        "url": "http://pubproxy.com/api/proxy?limit=20&format=json&type=http&level=anonymous",
        "type": "json_pubproxy",
    },
]

# Direct plain-text proxy list URLs (one proxy per line)
_PROXY_TEXT_URLS: list[str] = [
    "https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/http.txt",
    "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt",
    "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt",
]

# Test URL to validate proxies (small, fast, reliable)
_VALIDATION_URL = "https://httpbin.org/ip"
_VALIDATION_TIMEOUT = 8


@dataclass
class ProxyInfo:
    """A single proxy with health tracking."""

    url: str
    source: str = ""
    failures: int = 0
    successes: int = 0
    last_used: float = 0.0
    avg_latency_ms: float = 0.0

    @property
    def score(self) -> float:
        """Higher = better. Penalise failures, reward speed."""
        if self.successes + self.failures == 0:
            return 50.0  # untested
        success_rate = self.successes / max(1, self.successes + self.failures)
        latency_penalty = min(self.avg_latency_ms / 1000, 5.0)
        return (success_rate * 100) - latency_penalty


class ProxyPool:
    """
    Thread-safe rotating proxy pool with automatic harvesting.

    Usage:
        pool = ProxyPool()
        pool.harvest()  # optional — fetches free proxies
        pool.add("http://myproxy:3128")  # add custom proxies
        proxy = pool.next()  # get next proxy (round-robin)
    """

    def __init__(
        self,
        *,
        max_failures: int = 3,
        validate: bool = True,
        max_proxies: int = 100,
    ) -> None:
        self._proxies: list[ProxyInfo] = []
        self._lock = threading.Lock()
        self._index = 0
        self._max_failures = max_failures
        self._validate = validate
        self._max_proxies = max_proxies
        self._harvested = False

    @property
    def size(self) -> int:
        with self._lock:
            return len(self._proxies)

    @property
    def proxies(self) -> list[str]:
        with self._lock:
            return [p.url for p in self._proxies]

    def add(self, proxy_url: str, *, source: str = "manual") -> None:
        """Add a proxy to the pool (deduplicates)."""
        url = proxy_url.strip()
        if not url:
            return
        # Ensure it has a scheme
        if not url.startswith(("http://", "https://", "socks")):
            url = f"http://{url}"
        with self._lock:
            existing = {p.url for p in self._proxies}
            if url not in existing:
                self._proxies.append(ProxyInfo(url=url, source=source))

    def add_many(self, proxy_urls: list[str], *, source: str = "bulk") -> int:
        """Add many proxies at once. Returns count added."""
        added = 0
        for url in proxy_urls:
            before = self.size
            self.add(url, source=source)
            if self.size > before:
                added += 1
        return added

    def next(self) -> str | None:
        """Get next proxy URL via weighted round-robin. Returns None if empty."""
        with self._lock:
            alive = [p for p in self._proxies if p.failures < self._max_failures]
            if not alive:
                return None
            # Sort by score (best first), then rotate
            alive.sort(key=lambda p: p.score, reverse=True)
            self._index = (self._index + 1) % len(alive)
            proxy = alive[self._index]
            proxy.last_used = time.monotonic()
            return proxy.url

    def report_success(self, proxy_url: str, *, latency_ms: float = 0) -> None:
        """Report a successful use of a proxy."""
        with self._lock:
            for p in self._proxies:
                if p.url == proxy_url:
                    p.successes += 1
                    if latency_ms > 0:
                        # Running average
                        total = p.avg_latency_ms * max(1, p.successes - 1)
                        p.avg_latency_ms = (total + latency_ms) / p.successes
                    break

    def report_failure(self, proxy_url: str) -> None:
        """Report a failed proxy. Evicts after max_failures."""
        with self._lock:
            for p in self._proxies:
                if p.url == proxy_url:
                    p.failures += 1
                    break

    def evict_dead(self) -> int:
        """Remove proxies that exceeded max failures."""
        with self._lock:
            before = len(self._proxies)
            self._proxies = [
                p for p in self._proxies if p.failures < self._max_failures
            ]
            evicted = before - len(self._proxies)
            if evicted:
                logger.info("ProxyPool: evicted %d dead proxies", evicted)
            return evicted

    def harvest(self, *, validate_sample: int = 5) -> int:
        """
        Harvest free proxies from public APIs.

        Fetches from multiple proxy list APIs, optionally validates a sample,
        and adds working ones to the pool.

        Returns total proxies added.
        """
        if self._harvested and self.size >= 10:
            logger.debug("ProxyPool: already harvested (%d proxies)", self.size)
            return 0

        logger.info("ProxyPool: harvesting free proxies…")
        total_added = 0

        # Phase 1: Fetch from JSON APIs
        for api in _PROXY_LIST_URLS:
            try:
                proxies = self._fetch_from_api(api)
                added = self.add_many(proxies, source=api["name"])
                total_added += added
                logger.info(
                    "ProxyPool: %s → %d proxies fetched, %d new",
                    api["name"],
                    len(proxies),
                    added,
                )
            except Exception as exc:
                logger.debug("ProxyPool: %s failed: %s", api["name"], exc)

            if self.size >= self._max_proxies:
                break

        # Phase 2: Fetch from plain-text lists
        for text_url in _PROXY_TEXT_URLS:
            if self.size >= self._max_proxies:
                break
            try:
                proxies = self._fetch_text_list(text_url)
                source_name = text_url.split("/")[-1].replace(".txt", "")
                added = self.add_many(proxies, source=source_name)
                total_added += added
                logger.info(
                    "ProxyPool: %s → %d proxies, %d new",
                    source_name,
                    len(proxies),
                    added,
                )
            except Exception as exc:
                logger.debug("ProxyPool: text list failed: %s", exc)

        # Phase 3: Validate a sample to ensure quality
        if self._validate and validate_sample > 0:
            validated = self._validate_sample(validate_sample)
            logger.info(
                "ProxyPool: validated %d/%d sample proxies", validated, validate_sample
            )

        self._harvested = True
        logger.info("ProxyPool: harvest complete — %d total proxies in pool", self.size)
        return total_added

    def _fetch_from_api(self, api: dict[str, str]) -> list[str]:
        """Fetch proxies from a JSON API endpoint."""
        import httpx

        resp = httpx.get(api["url"], timeout=10, follow_redirects=True)
        if resp.status_code != 200:
            return []

        data: Any = resp.json()
        api_type = api.get("type", "")
        proxies: list[str] = []

        if api_type == "json_proxyscrape":
            # proxyscrape v4 format
            for item in data.get("proxies", []):
                ip = item.get("ip", "")
                port = item.get("port", "")
                protocol = item.get("protocol", "http")
                if ip and port:
                    proxies.append(f"{protocol}://{ip}:{port}")

        elif api_type == "json_geonode":
            # geonode format
            for item in data.get("data", []):
                ip = item.get("ip", "")
                port = item.get("port", "")
                protocols = item.get("protocols", ["http"])
                proto = protocols[0] if protocols else "http"
                if ip and port:
                    proxies.append(f"{proto}://{ip}:{port}")

        elif api_type == "json_pubproxy":
            # pubproxy format
            for item in data.get("data", []):
                ip = item.get("ip", "")
                port = item.get("port", "")
                proxy_type = item.get("type", "http").lower()
                if ip and port:
                    proxies.append(f"{proxy_type}://{ip}:{port}")

        return proxies

    def _fetch_text_list(self, url: str) -> list[str]:
        """Fetch plain-text proxy list (one ip:port per line)."""
        import httpx

        resp = httpx.get(url, timeout=15, follow_redirects=True)
        if resp.status_code != 200:
            return []

        proxies: list[str] = []
        for line in resp.text.splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                if not line.startswith(("http://", "https://", "socks")):
                    line = f"http://{line}"
                proxies.append(line)

        # Shuffle and take a subset (text lists can be huge)
        random.shuffle(proxies)
        return proxies[: self._max_proxies]

    def _validate_sample(self, count: int) -> int:
        """Validate a random sample of proxies against httpbin.org/ip."""
        import httpx

        with self._lock:
            sample = random.sample(self._proxies, min(count, len(self._proxies)))

        validated = 0
        for proxy_info in sample:
            try:
                t0 = time.monotonic()
                resp = httpx.get(
                    _VALIDATION_URL,
                    proxy=proxy_info.url,
                    timeout=_VALIDATION_TIMEOUT,
                )
                elapsed_ms = (time.monotonic() - t0) * 1000
                if resp.status_code == 200:
                    proxy_info.successes += 1
                    proxy_info.avg_latency_ms = elapsed_ms
                    validated += 1
                else:
                    proxy_info.failures += 1
            except Exception:
                proxy_info.failures += 1

        self.evict_dead()
        return validated

    def get_stats(self) -> dict[str, Any]:
        """Return pool statistics for admin UI."""
        with self._lock:
            alive = [p for p in self._proxies if p.failures < self._max_failures]
            sources = {}
            for p in self._proxies:
                sources[p.source] = sources.get(p.source, 0) + 1
            avg_score = sum(p.score for p in alive) / max(1, len(alive))

        return {
            "total": len(self._proxies),
            "alive": len(alive),
            "dead": len(self._proxies) - len(alive),
            "sources": sources,
            "avg_score": round(avg_score, 1),
            "harvested": self._harvested,
        }
