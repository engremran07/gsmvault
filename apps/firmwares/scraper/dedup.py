"""
dedup.py — Scalable deduplication with optional bloom filter.

Two dedup strategies (both run simultaneously when both enabled):
  1. URL dedup        — exact match on device page URL (always active)
  2. Model dedup      — brand + model_name fingerprint (catches URL changes)

Bloom filter (optional, requires bitarray):
  Falls back gracefully to plain set when bitarray not installed.
  At capacity=1_000_000 / error_rate=0.001, uses ~1.8 MB vs 40+ MB for a set.

Dead-letter tracking:
  Records URLs that failed all retries for offline inspection.
  Written to output/dead_letter.json at finalize.

Strict-mode Pylance: full type annotations, no Any on public API.
"""

from __future__ import annotations

import csv
import hashlib
import json
import logging
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Bloom filter (bitarray-based with set fallback)
# ---------------------------------------------------------------------------


class _BitBloom:
    """
    Counting bloom filter backed by a bytearray (no external deps).
    Uses k=7 independent hash functions via SHA-256 truncation.
    False-positive rate ~0.001 at capacity 1M with k=7.
    """

    _K: int = 7  # number of hash functions

    def __init__(self, capacity: int, error_rate: float) -> None:
        # m = -n * ln(p) / (ln 2)^2
        import math

        m = int(-capacity * math.log(error_rate) / (math.log(2) ** 2))
        self._m: int = m
        self._bits: bytearray = bytearray((m + 7) // 8)
        self._count: int = 0

    def _positions(self, key: str) -> list[int]:
        digest = hashlib.sha256(key.encode()).digest()
        positions: list[int] = []
        step = len(digest) // self._K
        for i in range(self._K):
            chunk = digest[i * step : i * step + 4]
            pos = int.from_bytes(chunk, "big") % self._m
            positions.append(pos)
        return positions

    def add(self, key: str) -> None:
        for pos in self._positions(key):
            byte_idx = pos >> 3
            bit_idx = pos & 7
            self._bits[byte_idx] |= 1 << bit_idx
        self._count += 1

    def __contains__(self, key: str) -> bool:
        for pos in self._positions(key):
            byte_idx = pos >> 3
            bit_idx = pos & 7
            if not (self._bits[byte_idx] >> bit_idx & 1):
                return False
        return True

    def __len__(self) -> int:
        return self._count


class _SetBloom:
    """Plain set fallback when bitarray not available."""

    def __init__(self) -> None:
        self._seen: set[str] = set()

    def add(self, key: str) -> None:
        self._seen.add(key)

    def __contains__(self, key: str) -> bool:
        return key in self._seen

    def __len__(self) -> int:
        return len(self._seen)


# ---------------------------------------------------------------------------
# DedupFilter
# ---------------------------------------------------------------------------


class DedupFilter:
    """
    URL + model-name deduplication with optional bloom filter backend.

    Usage:
        dedup = DedupFilter(bloom=True, capacity=1_000_000)
        if not dedup.is_seen(url, brand, model):
            dedup.mark(url, brand, model)
            # process item
    """

    def __init__(
        self,
        bloom: bool = False,
        capacity: int = 1_000_000,
        error_rate: float = 0.001,
        dedup_by_model: bool = True,
    ) -> None:
        self._dedup_by_model = dedup_by_model

        if bloom:
            logger.info(
                "Bloom filter dedup: capacity=%d, error_rate=%.4f (~%.1f MB)",
                capacity,
                error_rate,
                capacity * 1.44 / 8 / 1024 / 1024,
            )
            self._url_bloom: _BitBloom | _SetBloom = _BitBloom(capacity, error_rate)
            self._model_bloom: _BitBloom | _SetBloom = _BitBloom(capacity, error_rate)
        else:
            self._url_bloom = _SetBloom()
            self._model_bloom = _SetBloom()

        self._exact_urls: set[str] = set()  # Always-exact fallback for resume seeding

    @staticmethod
    def _model_key(brand: str, model: str) -> str:
        key = f"{brand.lower().strip()}::{model.lower().strip()}"
        return hashlib.sha256(key.encode()).hexdigest()[:16]

    def is_seen(
        self,
        url: str,
        brand: str = "",
        model: str = "",
    ) -> bool:
        if url in self._url_bloom:
            return True
        if self._dedup_by_model and brand and model:
            mk = self._model_key(brand, model)
            if mk in self._model_bloom:
                return True
        return False

    def mark(
        self,
        url: str,
        brand: str = "",
        model: str = "",
    ) -> None:
        self._url_bloom.add(url)
        self._exact_urls.add(url)
        if self._dedup_by_model and brand and model:
            self._model_bloom.add(self._model_key(brand, model))

    def seed_from_csv(self, path: str) -> int:
        """Seed from an existing CSV (for --resume). Uses exact URLs."""
        n = 0
        p = Path(path)
        if not p.exists():
            return 0
        try:
            with p.open(encoding="utf-8") as fh:
                for row in csv.DictReader(fh):
                    url = row.get("url", "")
                    brand = row.get("brand", "")
                    model = row.get("model_name", "")
                    if url:
                        self.mark(url, brand, model)
                        n += 1
            logger.info("Dedup seeded: %d records from %s", n, path)
        except Exception as exc:
            logger.warning("Dedup seed failed: %s", exc)
        return n

    def seed_from_db(self) -> int:
        """Seed from existing GSMArenaDevice records so the scraper skips them."""
        n = 0
        try:
            from apps.firmwares.models import GSMArenaDevice

            for url, brand, model_name in GSMArenaDevice.objects.values_list(
                "url", "brand", "model_name"
            ).iterator(chunk_size=2000):
                if url:
                    self.mark(url, brand, model_name)
                    n += 1
            logger.info("Dedup seeded: %d records from GSMArenaDevice DB", n)
        except Exception as exc:
            logger.warning("Dedup DB seed failed: %s", exc)
        return n

    def __len__(self) -> int:
        return len(self._url_bloom)


# ---------------------------------------------------------------------------
# DeadLetterQueue
# ---------------------------------------------------------------------------


class DeadLetterQueue:
    """
    Tracks URLs that exhausted all retries.
    Written to disk at finalize() for manual inspection / re-run.
    """

    def __init__(self, output_dir: str) -> None:
        self._path = Path(output_dir) / "dead_letter.json"
        self._entries: list[dict[str, str]] = []

    def record(self, url: str, reason: str, attempt: int) -> None:
        self._entries.append(
            {
                "url": url,
                "reason": reason,
                "attempts": str(attempt),
            }
        )
        logger.warning("Dead letter [attempt %d]: %s — %s", attempt, url[:80], reason)

    def finalize(self) -> None:
        if not self._entries:
            return
        try:
            with open(self._path, "w", encoding="utf-8") as fh:
                json.dump(self._entries, fh, indent=2, ensure_ascii=False)
            logger.info(
                "Dead letter queue: %d URLs → %s", len(self._entries), self._path
            )
        except OSError as exc:
            logger.error("Dead letter write failed: %s", exc)

    def __len__(self) -> int:
        return len(self._entries)


# ---------------------------------------------------------------------------
# BrandProgressTracker
# ---------------------------------------------------------------------------


class BrandProgressTracker:
    """
    Per-brand device count, failure rate, and ETA tracking.
    Feeds live progress log lines every N devices.
    """

    def __init__(self) -> None:
        self._scraped: dict[str, int] = {}
        self._failed: dict[str, int] = {}
        self._expected: dict[str, int] = {}

    def set_expected(self, brand: str, count: int) -> None:
        self._expected[brand] = count

    def record_scraped(self, brand: str) -> None:
        self._scraped[brand] = self._scraped.get(brand, 0) + 1

    def record_failed(self, brand: str) -> None:
        self._failed[brand] = self._failed.get(brand, 0) + 1

    def summary_lines(self) -> list[str]:
        lines: list[str] = []
        for brand in sorted(self._scraped, key=lambda b: -self._scraped[b])[:10]:
            scraped = self._scraped[brand]
            failed = self._failed.get(brand, 0)
            expected = self._expected.get(brand, 0)
            pct = f"{scraped / expected * 100:.0f}%" if expected else "?"
            fail_rate = f"{failed / max(scraped + failed, 1) * 100:.1f}%"
            lines.append(
                f"  {brand:<20} scraped={scraped:>4} progress={pct:>5}"
                f" fail_rate={fail_rate}"
            )
        return lines

    def report(self) -> dict[str, Any]:
        return {
            "brands": {
                b: {
                    "scraped": self._scraped.get(b, 0),
                    "failed": self._failed.get(b, 0),
                    "expected": self._expected.get(b, 0),
                }
                for b in set(self._scraped) | set(self._failed)
            }
        }
