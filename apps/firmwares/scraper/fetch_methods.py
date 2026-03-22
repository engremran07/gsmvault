"""
fetch_methods.py — Multi-method fallback HTTP fetcher for GSMArena scraping.

When the primary Scrapling spider gets blocked (429/403), the service layer
cascades through alternative fetch methods to retrieve GSMArena data.

Fallback chain (best → worst):
  1. Scrapling Spider (stealth sessions) — handled by run_gsmarena_scrape()
  2. Wayback Machine proxy — cached GSMArena pages, same HTML, same parser
  3. curl_cffi with rotating browser impersonation
  4. httpx with realistic headers

Also provides:
  - Rate limit detection and retry_after parsing
  - Wayback Machine URL rewriting
  - Available method probing

Strict-mode Pylance: full annotations, no assert, no bare except.
"""

from __future__ import annotations

import logging
import random
import re
import time
from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any

logger = logging.getLogger(__name__)

BASE_URL = "https://www.gsmarena.com"
WAYBACK_PREFIX = "https://web.archive.org/web/2025/"

# curl_cffi browser impersonation targets, ordered by recency / stealth
IMPERSONATION_TARGETS: list[str] = [
    "chrome137",
    "chrome136",
    "chrome131",
    "chrome124",
    "firefox137",
    "firefox135",
    "firefox133",
    "safari185",
    "safari184",
    "edge131",
    "edge101",
]

# Realistic user agents for httpx/requests fallback
USER_AGENTS: list[str] = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:137.0) Gecko/20100101 Firefox/137.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0",
]

_BAN_CODES: frozenset[int] = frozenset({403, 429, 503, 999})


# ---------------------------------------------------------------------------
# FetchResult
# ---------------------------------------------------------------------------


@dataclass
class FetchResult:
    """Result from a single fetch attempt."""

    status_code: int
    html: str
    method_name: str
    url: str
    retry_after: int = 0  # seconds, from Retry-After header
    is_banned: bool = False
    error: str = ""


# ---------------------------------------------------------------------------
# Rate limit tracker
# ---------------------------------------------------------------------------


@dataclass
class RateLimitState:
    """Tracks rate limit state across fetch attempts."""

    blocked_until: float = 0.0  # time.monotonic() when block expires
    retry_after_seconds: int = 0
    ban_count: int = 0
    last_ban_method: str = ""
    methods_exhausted: list[str] = field(default_factory=list)

    @property
    def is_blocked(self) -> bool:
        return time.monotonic() < self.blocked_until

    @property
    def remaining_seconds(self) -> int:
        return max(0, int(self.blocked_until - time.monotonic()))

    def record_ban(self, method: str, retry_after: int = 0) -> None:
        self.ban_count += 1
        self.last_ban_method = method
        if retry_after > 0:
            self.retry_after_seconds = retry_after
            self.blocked_until = time.monotonic() + retry_after
        if method not in self.methods_exhausted:
            self.methods_exhausted.append(method)

    def to_dict(self) -> dict[str, Any]:
        return {
            "blocked": self.is_blocked,
            "remaining_seconds": self.remaining_seconds,
            "retry_after_seconds": self.retry_after_seconds,
            "ban_count": self.ban_count,
            "last_ban_method": self.last_ban_method,
            "methods_exhausted": self.methods_exhausted,
        }


# ---------------------------------------------------------------------------
# Fetch methods
# ---------------------------------------------------------------------------


def _parse_retry_after(headers: Mapping[str, str | None]) -> int:
    """Extract retry-after seconds from response headers."""
    val = headers.get("retry-after") or ""
    if not val:
        return 0
    try:
        return int(val)
    except ValueError:
        return 0


def _check_ban(status_code: int, body: str) -> bool:
    """Check if the response indicates a ban/block."""
    if status_code in _BAN_CODES:
        return True
    lower = body[:3000].lower()
    ban_signals = (
        "access denied",
        "too many requests",
        "rate limit",
        "you have been blocked",
        "captcha",
        "unusual traffic",
        "cloudflare",
        "error 1020",
        "please verify you are a human",
        "bot detection",
        "challenge-platform",
        "cf-browser-verification",
        "ddos protection by",
        "enable javascript and cookies",
    )
    return any(sig in lower for sig in ban_signals)


def fetch_via_curl_cffi(
    url: str,
    *,
    impersonate: str | None = None,
    timeout: int = 20,
    proxy: str | None = None,
) -> FetchResult:
    """Fetch using curl_cffi with browser TLS impersonation."""
    method_name = f"curl_cffi/{impersonate or 'auto'}"
    try:
        from curl_cffi import requests  # type: ignore[import-untyped]

        target: Any = impersonate or random.choice(IMPERSONATION_TARGETS)  # noqa: S311
        kwargs: dict[str, Any] = {
            "impersonate": target,
            "timeout": timeout,
            "allow_redirects": True,
        }
        if proxy:
            kwargs["proxies"] = {"http": proxy, "https": proxy}
        resp = requests.get(url, **kwargs)
        headers = {k.lower(): v for k, v in resp.headers.items()}
        retry_after = _parse_retry_after(headers)
        is_banned = _check_ban(resp.status_code, resp.text)

        return FetchResult(
            status_code=resp.status_code,
            html=resp.text,
            method_name=method_name,
            url=url,
            retry_after=retry_after,
            is_banned=is_banned,
        )
    except Exception as exc:
        return FetchResult(
            status_code=0,
            html="",
            method_name=method_name,
            url=url,
            is_banned=False,
            error=str(exc),
        )


def fetch_via_httpx(
    url: str, *, timeout: int = 20, proxy: str | None = None
) -> FetchResult:
    """Fetch using httpx with realistic browser headers."""
    method_name = "httpx"
    try:
        import httpx

        ua = random.choice(USER_AGENTS)  # noqa: S311
        headers = {
            "User-Agent": ua,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
        }
        kwargs: dict[str, Any] = {
            "headers": headers,
            "timeout": timeout,
            "follow_redirects": True,
        }
        if proxy:
            kwargs["proxy"] = proxy
        resp = httpx.get(url, **kwargs)
        resp_headers = {k.lower(): v for k, v in resp.headers.items()}
        retry_after = _parse_retry_after(resp_headers)
        is_banned = _check_ban(resp.status_code, resp.text)

        return FetchResult(
            status_code=resp.status_code,
            html=resp.text,
            method_name=method_name,
            url=url,
            retry_after=retry_after,
            is_banned=is_banned,
        )
    except Exception as exc:
        return FetchResult(
            status_code=0,
            html="",
            method_name=method_name,
            url=url,
            error=str(exc),
        )


def fetch_via_wayback(url: str, *, timeout: int = 25) -> FetchResult:
    """Fetch a cached version of the URL from Wayback Machine."""
    method_name = "wayback"
    try:
        import httpx

        wayback_url = f"{WAYBACK_PREFIX}{url}"
        resp = httpx.get(
            wayback_url,
            timeout=timeout,
            follow_redirects=True,
            headers={"User-Agent": random.choice(USER_AGENTS)},  # noqa: S311
        )

        if resp.status_code != 200:
            return FetchResult(
                status_code=resp.status_code,
                html="",
                method_name=method_name,
                url=url,
                is_banned=False,
                error=f"Wayback returned {resp.status_code}",
            )

        # Strip Wayback Machine's injected toolbar/banner from HTML
        html = _strip_wayback_toolbar(resp.text)

        return FetchResult(
            status_code=200,
            html=html,
            method_name=method_name,
            url=url,
            is_banned=False,
        )
    except Exception as exc:
        return FetchResult(
            status_code=0,
            html="",
            method_name=method_name,
            url=url,
            error=str(exc),
        )


def _strip_wayback_toolbar(html: str) -> str:
    """Remove Wayback Machine's injected toolbar and fix relative URLs."""
    # Remove the Wayback toolbar div
    html = re.sub(
        r"<!-- BEGIN WAYBACK TOOLBAR INSERT -->.*?<!-- END WAYBACK TOOLBAR INSERT -->",
        "",
        html,
        flags=re.DOTALL,
    )
    # Fix rewritten URLs: /web/2025xxxx/https://... → https://...
    html = re.sub(
        r"/web/\d{14}(?:im_|js_|cs_|id_|fw_|if_)?/(https?://)",
        r"\1",
        html,
    )
    return html


# ---------------------------------------------------------------------------
# Web search fallback — find GSMArena pages via DuckDuckGo HTML search
# ---------------------------------------------------------------------------

_DDG_URL = "https://html.duckduckgo.com/html/"


def fetch_via_websearch(url: str, *, timeout: int = 20) -> FetchResult:
    """
    Fetch a GSMArena page by searching DuckDuckGo for its URL.

    When direct access is blocked, we search DuckDuckGo for the page URL
    and follow the first matching result link. DuckDuckGo HTML endpoint
    does not require JavaScript or API keys.
    """
    method_name = "websearch"
    try:
        import httpx

        # Build search query from the URL — e.g. "site:gsmarena.com samsung_galaxy_s24"
        query = f"site:gsmarena.com {url.split('/')[-1].replace('.php', '').replace('_', ' ')}"
        ua = random.choice(USER_AGENTS)  # noqa: S311
        headers = {
            "User-Agent": ua,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
        }

        search_resp = httpx.post(
            _DDG_URL,
            data={"q": query},
            headers=headers,
            timeout=timeout,
            follow_redirects=True,
        )
        if search_resp.status_code != 200:
            return FetchResult(
                status_code=search_resp.status_code,
                html="",
                method_name=method_name,
                url=url,
                error=f"DuckDuckGo returned {search_resp.status_code}",
            )

        # Extract first GSMArena result link from DDG HTML
        link_match = re.search(
            r'href="(https?://www\.gsmarena\.com/[^"]+)"',
            search_resp.text,
        )
        if not link_match:
            return FetchResult(
                status_code=200,
                html="",
                method_name=method_name,
                url=url,
                error="No GSMArena result found in search",
            )

        found_url = link_match.group(1)
        # Fetch the actual page via httpx
        page_resp = httpx.get(
            found_url,
            headers=headers,
            timeout=timeout,
            follow_redirects=True,
        )
        resp_headers = {k.lower(): v for k, v in page_resp.headers.items()}
        retry_after = _parse_retry_after(resp_headers)
        is_banned = _check_ban(page_resp.status_code, page_resp.text)

        return FetchResult(
            status_code=page_resp.status_code,
            html=page_resp.text,
            method_name=method_name,
            url=found_url,
            retry_after=retry_after,
            is_banned=is_banned,
        )
    except Exception as exc:
        return FetchResult(
            status_code=0,
            html="",
            method_name=method_name,
            url=url,
            error=str(exc),
        )


# ---------------------------------------------------------------------------
# FetchChain — cascading fallback
# ---------------------------------------------------------------------------


@dataclass
class _MethodConfig:
    name: str
    fetch_fn: str  # function name in this module
    priority: int  # lower = tried first
    kwargs: dict[str, Any] = field(default_factory=dict)


# Default method chain, ordered by effectiveness
_DEFAULT_CHAIN: list[_MethodConfig] = [
    _MethodConfig(
        "curl_cffi/chrome136", "fetch_via_curl_cffi", 10, {"impersonate": "chrome136"}
    ),
    _MethodConfig(
        "curl_cffi/firefox135", "fetch_via_curl_cffi", 20, {"impersonate": "firefox135"}
    ),
    _MethodConfig(
        "curl_cffi/safari184", "fetch_via_curl_cffi", 30, {"impersonate": "safari184"}
    ),
    _MethodConfig(
        "curl_cffi/chrome124", "fetch_via_curl_cffi", 40, {"impersonate": "chrome124"}
    ),
    _MethodConfig(
        "curl_cffi/edge101", "fetch_via_curl_cffi", 50, {"impersonate": "edge101"}
    ),
    _MethodConfig("wayback", "fetch_via_wayback", 60, {}),
    _MethodConfig("websearch", "fetch_via_websearch", 65, {}),
    _MethodConfig("httpx", "fetch_via_httpx", 70, {}),
]

# Map function name → callable
_FETCH_FNS: dict[str, Any] = {
    "fetch_via_curl_cffi": fetch_via_curl_cffi,
    "fetch_via_httpx": fetch_via_httpx,
    "fetch_via_wayback": fetch_via_wayback,
    "fetch_via_websearch": fetch_via_websearch,
}


class FetchChain:
    """
    Cascading fallback fetcher. Tries methods in priority order,
    moving to the next when the current one gets banned/errors.

    Supports proxy rotation: when a ProxyPool is provided, each request
    is routed through a different proxy. Failed proxies are reported back
    to the pool for automatic eviction.

    Usage:
        chain = FetchChain()
        result = chain.fetch("https://www.gsmarena.com/makers.php3")
        if result.is_banned:
            # All methods exhausted
            print(f"Blocked — retry after {chain.rate_state.retry_after_seconds}s")
    """

    def __init__(
        self,
        *,
        methods: list[_MethodConfig] | None = None,
        delay_between_methods: float = 2.0,
        preferred_method: str = "",
        proxy_pool: Any | None = None,
    ) -> None:
        # Deep-copy default chain to avoid mutating the module-level list
        chain = [
            _MethodConfig(m.name, m.fetch_fn, m.priority, dict(m.kwargs))
            for m in (methods or _DEFAULT_CHAIN)
        ]
        # Boost the preferred method (last successful) to top priority
        if preferred_method:
            for m in chain:
                if m.name == preferred_method:
                    m.priority = -1  # Will sort first
                    logger.info(
                        "FetchChain: boosting preferred method '%s' to top priority",
                        preferred_method,
                    )
                    break
        self._methods = sorted(chain, key=lambda m: m.priority)
        self._delay = delay_between_methods
        self.rate_state = RateLimitState()
        self._last_successful_method: str = ""
        self._proxy_pool = proxy_pool

    @property
    def last_successful_method(self) -> str:
        return self._last_successful_method

    def fetch(self, url: str) -> FetchResult:
        """
        Try all methods in priority order. Returns the first successful result,
        or the last failed result with ban info.

        When a proxy pool is available, each attempt gets a fresh proxy.
        If the proxy fails, it's reported back to the pool.
        """
        last_result: FetchResult | None = None

        for method in self._methods:
            fn = _FETCH_FNS.get(method.fetch_fn)
            if fn is None:
                continue

            # Get a proxy from the pool if available
            proxy: str | None = None
            if self._proxy_pool is not None:
                proxy = self._proxy_pool.next()

            logger.info(
                "FetchChain: trying %s for %s%s",
                method.name,
                url[:80],
                f" via proxy {proxy[:30]}…" if proxy else "",
            )

            kwargs = dict(method.kwargs)
            if proxy and method.fetch_fn in ("fetch_via_curl_cffi", "fetch_via_httpx"):
                kwargs["proxy"] = proxy

            result: FetchResult = fn(url, **kwargs)

            if result.error:
                logger.warning("FetchChain: %s error: %s", method.name, result.error)
                if proxy and self._proxy_pool is not None:
                    self._proxy_pool.report_failure(proxy)
                last_result = result
                continue

            if result.is_banned:
                logger.warning(
                    "FetchChain: %s banned (status=%d, retry_after=%d)",
                    method.name,
                    result.status_code,
                    result.retry_after,
                )
                self.rate_state.record_ban(method.name, result.retry_after)
                if proxy and self._proxy_pool is not None:
                    self._proxy_pool.report_failure(proxy)
                last_result = result

                # Small delay before trying next method
                if self._delay > 0:
                    time.sleep(self._delay)
                continue

            # Success — report proxy latency
            if proxy and self._proxy_pool is not None:
                self._proxy_pool.report_success(proxy)
            logger.info(
                "FetchChain: %s succeeded (status=%d, len=%d)",
                method.name,
                result.status_code,
                len(result.html),
            )
            self._last_successful_method = method.name
            return result

        # All methods exhausted
        return last_result or FetchResult(
            status_code=0,
            html="",
            method_name="all_exhausted",
            url=url,
            is_banned=True,
            error="All fetch methods exhausted",
        )

    def fetch_multiple(
        self,
        urls: list[str],
        *,
        delay: float = 3.0,
    ) -> list[FetchResult]:
        """Fetch multiple URLs with delay. Stops if all methods are exhausted."""
        results: list[FetchResult] = []
        all_banned_count = 0

        for url in urls:
            result = self.fetch(url)
            results.append(result)

            if result.is_banned and not result.html:
                all_banned_count += 1
                if all_banned_count >= 3:
                    logger.error("FetchChain: 3 consecutive bans — stopping batch")
                    break
            else:
                all_banned_count = 0

            if delay > 0:
                time.sleep(delay)

        return results

    def probe_all(
        self,
        url: str,
        *,
        delay: float = 2.0,
    ) -> list[dict[str, Any]]:
        """
        Probe ALL methods against a test URL instead of stopping at first success.

        Returns a list of dicts, one per method, with:
            name, status_code, success, is_banned, error, html_length, elapsed_ms
        """
        results: list[dict[str, Any]] = []

        for method in self._methods:
            fn = _FETCH_FNS.get(method.fetch_fn)
            if fn is None:
                results.append(
                    {
                        "name": method.name,
                        "status_code": 0,
                        "success": False,
                        "is_banned": False,
                        "error": "fetch function not found",
                        "html_length": 0,
                        "elapsed_ms": 0,
                    }
                )
                continue

            logger.info("ProbeAll: testing %s against %s", method.name, url[:80])
            t0 = time.monotonic()
            result: FetchResult = fn(url, **method.kwargs)
            elapsed = int((time.monotonic() - t0) * 1000)

            success = bool(
                result.html
                and not result.is_banned
                and not result.error
                and result.status_code in range(200, 400)
            )
            results.append(
                {
                    "name": method.name,
                    "status_code": result.status_code,
                    "success": success,
                    "is_banned": result.is_banned,
                    "error": result.error,
                    "html_length": len(result.html),
                    "elapsed_ms": elapsed,
                }
            )

            if delay > 0:
                time.sleep(delay)

        return results


# ---------------------------------------------------------------------------
# Probe available methods
# ---------------------------------------------------------------------------


def probe_available_methods() -> dict[str, bool]:
    """Check which fetch methods are available based on installed packages."""
    available: dict[str, bool] = {}

    try:
        import curl_cffi  # type: ignore[import-untyped]  # noqa: F401

        available["curl_cffi"] = True
    except ImportError:
        available["curl_cffi"] = False

    try:
        import httpx  # noqa: F401

        available["httpx"] = True
    except ImportError:
        available["httpx"] = False

    try:
        from scrapling.fetchers import (
            AsyncStealthySession,  # type: ignore[import-untyped]  # noqa: F401
        )

        available["scrapling_stealth"] = True
    except ImportError:
        available["scrapling_stealth"] = False

    try:
        from scrapling.fetchers import (
            DynamicSession,  # type: ignore[import-untyped]  # noqa: F401
        )

        available["scrapling_dynamic"] = True
    except ImportError:
        available["scrapling_dynamic"] = False

    try:
        from scrapling.fetchers import (
            FetcherSession,  # type: ignore[import-untyped]  # noqa: F401
        )

        available["scrapling_fetcher"] = True
    except ImportError:
        available["scrapling_fetcher"] = False

    available["wayback"] = available.get("httpx", False)
    available["websearch"] = available.get("httpx", False)

    return available
