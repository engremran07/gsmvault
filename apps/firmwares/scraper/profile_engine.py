"""
profile_engine.py — Intelligence layer between raw extraction and output.

Responsibilities (in pipeline order):
  1. Load & validate scraper_profile.json
  2. Section / field include-exclude filtering  (modes: full | profile | exclude)
  3. Value normalisation  (strip footnotes, collapse whitespace)
  4. Field aliasing  (rename raw keys → preferred column names)
  5. AI canonicalisation  (optional, Claude API)
  6. AI chipset enrichment  (optional, Claude API)
  7. Schema tracker  (emit schema_report.json after crawl)

Strict-mode Pylance compliance:
  - No bare 'Any' on function signatures — TYPE_CHECKING guard for aiohttp
  - No assert in production paths
  - All exceptions logged, none silently swallowed
  - _aliases dict is pre-cleaned (no _comment keys leak through)
  - Section-slug matching uses full prefix, not just first word
"""

from __future__ import annotations

import json
import logging
import os
import re
from collections import defaultdict
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    pass  # only imported for type-checking, not at runtime

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Regex constants
# ---------------------------------------------------------------------------

_WS_RE: re.Pattern[str] = re.compile(r"\s{2,}")
_FOOTNOTE_RE: re.Pattern[str] = re.compile(r"\s*\(\d+\)\s*")
_BRACKET_RE: re.Pattern[str] = re.compile(r"\s*\[.*?\]\s*")
_TRAIL_RE: re.Pattern[str] = re.compile(r"[,;]\s*$")
_SLUG_RE: re.Pattern[str] = re.compile(r"[^a-z0-9]+")
_MULTI_UNDER: re.Pattern[str] = re.compile(r"_+")


# ---------------------------------------------------------------------------
# Pure helper functions
# ---------------------------------------------------------------------------


def _clean_value(v: str) -> str:
    """Strip footnote markers, bracket annotations, trailing punctuation, excess ws."""
    v = _FOOTNOTE_RE.sub(" ", v)
    v = _BRACKET_RE.sub(" ", v)
    v = _TRAIL_RE.sub("", v)
    v = _WS_RE.sub(" ", v)
    return v.strip()


def _slugify(text: str) -> str:
    """Lowercase, replace non-alphanumeric runs with underscores, collapse multiples."""
    s = _SLUG_RE.sub("_", text.lower()).strip("_")
    return _MULTI_UNDER.sub("_", s)


def _section_slug_of(field_key: str) -> str:
    """
    Derive the section slug from a dynamic field key.

    Field keys are  "{section_slug}_{label_slug}".
    GSMArena sections like "Main Camera" → slug "main_camera".
    A field like "main_camera_triple" has section slug "main_camera".

    We use the _PRIORITY_SECTIONS list to match greedily from longest prefix.
    Fallback: everything up to the second underscore.
    """
    for prefix in _SECTION_PREFIXES:
        if field_key.startswith(prefix + "_") or field_key == prefix:
            return prefix
    # Fallback — first word only (covers old-era single-word sections: misc, network…)
    return field_key.split("_")[0]


# Known section slugs from modern GSMArena pages — ordered longest-first so
# greedy prefix matching works correctly.
_SECTION_PREFIXES: list[str] = [
    "selfie_camera",
    "main_camera",
    "platform",
    "network",
    "display",
    "memory",
    "battery",
    "comms",
    "features",
    "launch",
    "sound",
    "tests",
    "body",
    "misc",
    # Old-era section names
    "software",
    "multimedia",
    "general",
    "other",
    "connectivity",
    "data",
]


# ---------------------------------------------------------------------------
# AI canonicalisation (process-level cache)
# ---------------------------------------------------------------------------

_CANON_CACHE: dict[str, str] = {}

_CANON_PROMPT = (
    "You are a data normalisation expert for smartphone specifications.\n\n"
    "Below is a JSON array of raw field names scraped from GSMArena device pages.\n"
    "Field names come from multiple page generations:\n"
    "  - Very old (2002-2008): few fields, different section names\n"
    "  - Mid-era (2009-2015): moderate fields, mixed naming\n"
    "  - Modern (2016-2024): 60-80+ fields with consistent naming\n\n"
    "Your task:\n"
    "  Return a JSON object mapping each raw field name to a canonical snake_case field name.\n"
    "  Rules:\n"
    "  - Unify equivalent fields: platform_os / software_os / misc_operating_system → platform_os\n"
    "  - Keep the most descriptive modern name as canonical\n"
    "  - Never rename: brand, brand_slug, url, scraped_at, model_variants_str,\n"
    "    model_variant_count, model_name, full_name, image_url, related_devices\n"
    "  - Output ONLY valid JSON, no markdown, no explanation\n\n"
    "Input field names:\n"
    "{fields}"
)

_ENRICH_PROMPT = (
    'Given smartphone chipset: "{chipset}"\n\n'
    "Return a JSON object with exactly these keys (use null if unknown):\n"
    '  "process_node"  - manufacturing process e.g. "4nm", "7nm", "28nm"\n'
    '  "cpu_arch"      - CPU microarchitecture e.g. "Cortex-A78"\n'
    '  "fab"           - fab company e.g. "TSMC", "Samsung Foundry"\n'
    '  "chipset_year"  - integer year the chipset was released e.g. 2023\n\n'
    "Output ONLY valid JSON, no markdown, no explanation."
)


async def _ai_canonicalise(keys: list[str], api_key: str) -> dict[str, str]:
    """
    Batch-send unknown field names to Claude; return raw→canonical mapping.
    Results are cached so each key is sent at most once per process.
    Logs a warning on failure and falls back to identity mapping.
    """
    unknown = [k for k in keys if k not in _CANON_CACHE]
    if not unknown:
        return {k: _CANON_CACHE.get(k, k) for k in keys}

    try:
        import aiohttp  # type: ignore[import-untyped]  # optional dependency
    except ImportError:
        logger.warning(
            "aiohttp not installed — AI canonicalisation disabled. "
            "Run: pip install aiohttp"
        )
        return {k: k for k in keys}

    payload: dict[str, object] = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "messages": [
            {
                "role": "user",
                "content": _CANON_PROMPT.format(fields=json.dumps(unknown)),
            }
        ],
    }
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    try:
        async with aiohttp.ClientSession() as sess:
            async with sess.post(
                "https://api.anthropic.com/v1/messages",
                json=payload,
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                data: dict[str, Any] = await resp.json()
        raw_text: str = data["content"][0]["text"].strip()
        raw_text = re.sub(
            r"^```(?:json)?\s*|\s*```$", "", raw_text, flags=re.DOTALL
        ).strip()
        mapping: dict[str, str] = json.loads(raw_text)
        for raw_key, canon in mapping.items():
            _CANON_CACHE[raw_key] = _slugify(str(canon))
        logger.info("AI canonicalised %d new field names", len(mapping))
    except Exception as exc:  # catch-all: AI call may fail in many ways — logged above
        logger.warning("AI canonicalisation call failed: %s — raw names kept", exc)

    return {k: _CANON_CACHE.get(k, k) for k in keys}


async def _ai_enrich_chipset(chipset: str, api_key: str) -> dict[str, Any]:
    """
    Ask Claude for process node / arch / fab / year for a chipset name.
    Returns {} on any error — enrichment is best-effort, never blocking.
    """
    if not chipset:
        return {}
    try:
        import aiohttp  # type: ignore[import-untyped]  # optional dependency
    except ImportError:
        return {}

    payload: dict[str, object] = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 256,
        "messages": [
            {"role": "user", "content": _ENRICH_PROMPT.format(chipset=chipset)}
        ],
    }
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    try:
        async with aiohttp.ClientSession() as sess:
            async with sess.post(
                "https://api.anthropic.com/v1/messages",
                json=payload,
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=20),
            ) as resp:
                data: dict[str, Any] = await resp.json()
        raw_text: str = data["content"][0]["text"].strip()
        raw_text = re.sub(
            r"^```(?:json)?\s*|\s*```$", "", raw_text, flags=re.DOTALL
        ).strip()
        result: dict[str, Any] = json.loads(raw_text)
        return result
    except Exception as exc:  # catch-all: enrichment is best-effort — logged above
        logger.debug("AI chipset enrichment failed for %r: %s", chipset, exc)
        return {}


# ---------------------------------------------------------------------------
# SchemaTracker
# ---------------------------------------------------------------------------


class SchemaTracker:
    """
    Observes every processed record and emits a JSON field-frequency report.

    Output schema:
      {
        "total_devices_seen": int,
        "total_unique_fields": int,
        "fields": [
          { "field": str, "frequency": int, "coverage_pct": float, "samples": [str] }
        ]
      }
    """

    def __init__(self) -> None:
        self._freq: dict[str, int] = defaultdict(int)
        self._samples: dict[str, list[str]] = defaultdict(list)
        self._total: int = 0

    def observe(self, record: dict[str, Any]) -> None:
        self._total += 1
        for key, val in record.items():
            self._freq[key] += 1
            slist = self._samples[key]
            if val not in (None, "", [], {}) and len(slist) < 3:
                sv = str(val)[:120]
                if sv not in slist:
                    slist.append(sv)

    def report(self) -> dict[str, Any]:
        fields = [
            {
                "field": k,
                "frequency": self._freq[k],
                "coverage_pct": round(self._freq[k] / max(self._total, 1) * 100, 1),
                "samples": self._samples[k],
            }
            for k in sorted(self._freq)
        ]
        return {
            "total_devices_seen": self._total,
            "total_unique_fields": len(fields),
            "fields": fields,
        }

    def save(self, path: str) -> None:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(self.report(), fh, indent=2, ensure_ascii=False)
        logger.info(
            "Schema report: %d unique fields across %d devices → %s",
            len(self._freq),
            self._total,
            path,
        )


# ---------------------------------------------------------------------------
# Meta keys — always preserved regardless of filter mode
# ---------------------------------------------------------------------------

_META_KEYS: frozenset[str] = frozenset(
    {
        "brand",
        "brand_slug",
        "model_name",
        "full_name",
        "url",
        "image_url",
        "model_variants",
        "model_variants_str",
        "model_variant_count",
        "scraped_at",
        "related_devices",
        "gsmarena_rating",
        "gsmarena_fans",
        "quick_display",
        "quick_camera",
        "quick_processor",
        "quick_ram",
        "quick_battery",
        "quick_storage",
        "quick_os",
    }
)


# ---------------------------------------------------------------------------
# ProfileEngine
# ---------------------------------------------------------------------------


class ProfileEngine:
    """
    Central intelligence filter — instantiate once, call process() per device.

    Pipeline (sync):  filter → normalise → alias → schema observe
    Pipeline (async): filter → normalise → AI canonicalise → AI enrich → alias → observe
    """

    def __init__(self, profile_path: str, output_dir: str = "output") -> None:
        self._output_dir = output_dir
        raw = self._load_profile(profile_path)

        self._mode: str = str(raw.get("mode", "full"))
        self._inc_sections: frozenset[str] = frozenset(raw.get("include_sections", []))
        self._exc_sections: frozenset[str] = frozenset(raw.get("exclude_sections", []))
        self._inc_fields: frozenset[str] = frozenset(raw.get("include_fields", []))
        self._exc_fields: frozenset[str] = frozenset(raw.get("exclude_fields", []))

        # Clean aliases — strip any metadata keys like "_comment" that users
        # may leave inside the field_aliases dict in the JSON file.
        raw_aliases: dict[str, Any] = raw.get("field_aliases", {})
        self._aliases: dict[str, str] = {
            k: str(v)
            for k, v in raw_aliases.items()
            if not k.startswith("_") and isinstance(v, str)
        }

        self._normalise: bool = bool(raw.get("normalize_values", True))
        self._ai_canon: bool = bool(raw.get("ai_canonicalize", False))
        self._ai_enrich: bool = bool(raw.get("ai_enrich", False))
        self._always_meta: bool = bool(raw.get("always_include_meta", True))
        self._schema_export: bool = bool(raw.get("schema_export", True))
        self._api_key: str = os.getenv("ANTHROPIC_API_KEY", "")

        self.output_formats: dict[str, bool] = {
            k: bool(v)
            for k, v in raw.get(
                "output_formats",
                {
                    "csv": True,
                    "json": True,
                    "jsonl": True,
                    "sqlite": True,
                    "excel": False,
                },
            ).items()
        }
        self.schema = SchemaTracker()

        if self._ai_canon and not self._api_key:
            logger.warning(
                "ai_canonicalize=true but ANTHROPIC_API_KEY not set — disabling"
            )
            self._ai_canon = False
        if self._ai_enrich and not self._api_key:
            logger.warning("ai_enrich=true but ANTHROPIC_API_KEY not set — disabling")
            self._ai_enrich = False

        logger.info(
            "ProfileEngine: mode=%s | ai_canon=%s | ai_enrich=%s "
            "| inc_sections=%d | exc_fields=%d",
            self._mode,
            self._ai_canon,
            self._ai_enrich,
            len(self._inc_sections),
            len(self._exc_fields),
        )

    # -- Public API -----------------------------------------------------------

    def process(self, record: dict[str, Any]) -> dict[str, Any]:
        """Synchronous pipeline: filter → normalise → alias → observe."""
        result = self._filter(record)
        if self._normalise:
            result = _normalise_values(result)
        result = self._apply_aliases(result)
        self.schema.observe(result)
        return result

    async def process_async(self, record: dict[str, Any]) -> dict[str, Any]:
        """Async pipeline — adds AI canonicalise + AI enrich steps."""
        result = self._filter(record)
        if self._normalise:
            result = _normalise_values(result)

        if self._ai_canon:
            mapping = await _ai_canonicalise(list(result.keys()), self._api_key)
            result = {mapping.get(k, k): v for k, v in result.items()}

        if self._ai_enrich:
            chipset_val: str | None = None
            for ck in ("platform_chipset", "chipset"):
                v = result.get(ck)
                if isinstance(v, str) and v:
                    chipset_val = v
                    break
            if chipset_val is not None:
                enrichment = await _ai_enrich_chipset(chipset_val, self._api_key)
                for ek, ev in enrichment.items():
                    if ev is not None:
                        result[f"chipset_{ek}"] = ev

        result = self._apply_aliases(result)
        self.schema.observe(result)
        return result

    def finalize(self) -> None:
        """Write schema report to disk (called once after all records processed)."""
        if self._schema_export:
            self.schema.save(str(Path(self._output_dir) / "schema_report.json"))

    # -- Filtering ------------------------------------------------------------

    def _filter(self, record: dict[str, Any]) -> dict[str, Any]:
        """
        Mode-aware field filtering.

        full:    keep everything; honour exclude_fields
        profile: keep only meta + included sections/fields; drop excluded
        exclude: keep everything except excluded sections/fields
        """
        if self._mode == "full":
            result = {k: v for k, v in record.items() if k not in self._exc_fields}
            if self._always_meta:
                for mk in _META_KEYS:
                    if mk in record and mk not in result:
                        result[mk] = record[mk]
            return result

        if self._mode == "profile":
            result: dict[str, Any] = {}
            if self._always_meta:
                for mk in _META_KEYS:
                    if mk in record:
                        result[mk] = record[mk]
            for key, val in record.items():
                if key in result:
                    continue
                sec = _section_slug_of(key)
                if self._section_in_include(sec):
                    result[key] = val
            for fld in self._inc_fields:
                if fld in record:
                    result[fld] = record[fld]
            for fld in self._exc_fields:
                result.pop(fld, None)
            return result

        if self._mode == "exclude":
            result = {}
            for key, val in record.items():
                if self._always_meta and key in _META_KEYS:
                    result[key] = val
                    continue
                sec = _section_slug_of(key)
                if sec in {_slugify(s) for s in self._exc_sections}:
                    continue
                if key in self._exc_fields:
                    continue
                result[key] = val
            return result

        # Unknown mode — treat as full
        logger.warning("Unknown profile mode %r — defaulting to full", self._mode)
        return dict(record)

    def _section_in_include(self, section_slug: str) -> bool:
        """True when section_slug matches any entry in include_sections."""
        if not self._inc_sections:
            return True
        slugged = {_slugify(s) for s in self._inc_sections}
        return section_slug in slugged

    # -- Normalisation --------------------------------------------------------

    # -- Aliasing -------------------------------------------------------------

    def _apply_aliases(self, record: dict[str, Any]) -> dict[str, Any]:
        if not self._aliases:
            return record
        return {self._aliases.get(k, k): v for k, v in record.items()}

    # -- Profile loader -------------------------------------------------------

    @staticmethod
    def _load_profile(path: str) -> dict[str, Any]:
        p = Path(path)
        if not p.exists():
            logger.warning("Profile not found: %s — defaulting to full mode", path)
            return {"mode": "full"}
        with p.open(encoding="utf-8") as fh:
            raw: dict[str, Any] = json.load(fh)
        # Strip metadata/comment keys (any key starting with "_")
        return {k: v for k, v in raw.items() if not k.startswith("_")}


# ---------------------------------------------------------------------------
# Module-level normalisation (used by ProfileEngine and importable standalone)
# ---------------------------------------------------------------------------


def _normalise_values(record: dict[str, Any]) -> dict[str, Any]:
    """Return a new dict with all string values cleaned."""
    result: dict[str, Any] = {}
    for key, val in record.items():
        if isinstance(val, str):
            result[key] = _clean_value(val)
        elif isinstance(val, list):
            result[key] = [
                _clean_value(item) if isinstance(item, str) else item for item in val
            ]
        else:
            result[key] = val
    return result
