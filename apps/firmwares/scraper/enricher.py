"""
enricher.py v6 — Structured data enrichment and validation layer.

Runs AFTER profile filtering, BEFORE writing to any output format.

New in v6 (on top of v5):
  • chipset_family       — "Snapdragon" | "Exynos" | "Dimensity" | "Helio" |
                          "Kirin" | "Apple" | "Tensor" | "Unisoc" | "Other"
  • launch_status_clean  — normalised "Available" | "Announced" | "Rumored" |
                          "Discontinued" | "Unknown"
  • has_5g               — bool (True if network_technology contains "5G/NR")
  • has_nfc              — bool (True if comms_nfc or features contain "NFC")
  • has_esim             — bool (True if body_sim contains "eSIM")
  • has_headphone_jack   — bool (True if sound_jack field is "Yes" or "3.5mm")
  • has_dual_speakers    — bool
  • has_ir_blaster       — bool
  • has_wifi6            — bool (Wi-Fi 6/6E/802.11ax/be)
  • form_factor_clean    — "Bar" | "Flip" | "Slide" | "Foldable" | "Watch" |
                          "Tablet" | "Other"
  • ip_rating            — highest IP rating found e.g. "IP68", "IP67", "MIL-STD-810H"
  • ip_water_resist_depth— parsed float e.g. "1.5m" from IP description
  • review_score         — float parsed from gsmarena_rating (e.g. "9.1" → 9.1)
  • charging_speed_w     — int parsed from battery_charging (e.g. "65W" → 65)
  • refresh_rate_hz      — int parsed from display_type (e.g. "120Hz" → 120)
  • screen_to_body_pct   — float parsed from display_size ("89.5%" → 89.5)
  • cpu_cores            — int (8 from "Octa-core")
  • bluetooth_version    — float (5.3 from "Bluetooth 5.3")
  • wifi_generation      — int (6 from "Wi-Fi 6")

Strict-mode Pylance: full annotations, no Any on public API.
"""

from __future__ import annotations

import logging
import os
import re
from dataclasses import dataclass
from dataclasses import field as dc_field
from typing import Any

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Compiled regexes
# ---------------------------------------------------------------------------

_FLOAT_RE = re.compile(r"(\d+(?:\.\d+)?)")
_INT_RE = re.compile(r"(\d+)")
_MP_RE = re.compile(r"(\d+(?:\.\d+)?)\s*MP", re.I)
_GB_RE = re.compile(r"(\d+(?:\.\d+)?)\s*GB", re.I)
_MB_RE = re.compile(r"(\d+)\s*MB", re.I)
_MAH_RE = re.compile(r"(\d+)\s*mAh", re.I)
_GRAM_RE = re.compile(r"(\d+(?:\.\d+)?)\s*g(?:rams?)?(?:\s|$)", re.I)
_INCH_RE = re.compile(r"(\d+(?:\.\d+)?)\s*inch(?:es)?", re.I)
_YEAR_RE = re.compile(r"\b(20\d{2}|19\d{2})\b")
_QUARTER_RE = re.compile(r"\bQ([1-4])\b", re.I)
_WATT_RE = re.compile(r"(\d+)\s*W(?:att)?(?:\s|$|,)", re.I)
_HZ_RE = re.compile(r"(\d+)\s*Hz", re.I)
_PCT_RE = re.compile(r"(\d+(?:\.\d+)?)\s*%")
_BT_VER_RE = re.compile(r"Bluetooth\s+(\d+\.\d+)", re.I)
_WIFI_GEN_RE = re.compile(r"Wi-?Fi\s+(\d)", re.I)
_IP_MAIN_RE = re.compile(r"IP(\d{2})", re.I)
_IP_DEPTH_RE = re.compile(r"(\d+(?:\.\d+)?)\s*m(?:eters?)?\s*deep", re.I)
_CORE_MAP = {
    "dual": 2,
    "quad": 4,
    "hexa": 6,
    "octa": 8,
    "deca": 10,
    "dodeca": 12,
    "single": 1,
}

_MONTH_TO_Q: dict[str, str] = {
    "january": "Q1",
    "february": "Q1",
    "march": "Q1",
    "april": "Q2",
    "may": "Q2",
    "june": "Q2",
    "july": "Q3",
    "august": "Q3",
    "september": "Q3",
    "october": "Q4",
    "november": "Q4",
    "december": "Q4",
}

_FX_TO_USD: dict[str, float] = {
    "eur": float(os.getenv("GSMA_FX_EUR", "1.09")),
    "gbp": float(os.getenv("GSMA_FX_GBP", "1.27")),
    "inr": float(os.getenv("GSMA_FX_INR", "0.012")),
    "cny": float(os.getenv("GSMA_FX_CNY", "0.138")),
    "usd": 1.0,
}

_CURRENCY_RE = re.compile(
    r"([€£₹¥\$])\s*(\d[\d,\.]*)"
    r"|(\d[\d,\.]*)\s*(EUR|GBP|INR|CNY|USD)",
    re.I,
)
_SYMBOL_MAP: dict[str, str] = {
    "€": "eur",
    "£": "gbp",
    "₹": "inr",
    "¥": "cny",
    "$": "usd",
}

_NET_GEN_MAP: list[tuple[str, str]] = [
    ("5G", "5G"),
    ("NR", "5G"),
    ("LTE", "4G"),
    ("4G", "4G"),
    ("HSPA", "3G"),
    ("HSDPA", "3G"),
    ("UMTS", "3G"),
    ("3G", "3G"),
    ("EDGE", "2G"),
    ("GPRS", "2G"),
    ("GSM", "2G"),
]

# Chipset family keyword detection — order matters (most specific first)
_CHIPSET_FAMILIES: list[tuple[str, str]] = [
    ("snapdragon", "Snapdragon"),
    ("exynos", "Exynos"),
    ("dimensity", "Dimensity"),
    ("helio", "Helio"),
    ("kirin", "Kirin"),
    ("apple a", "Apple"),
    ("apple m", "Apple"),
    ("tensor", "Tensor"),
    ("unisoc", "Unisoc"),
    ("spreadtrum", "Unisoc"),
    ("mediatek", "Helio"),
    ("intel", "Intel"),
    ("nvidia", "Nvidia"),
]

# Canonical launch status
_STATUS_MAP: list[tuple[str, str]] = [
    ("rumored", "Rumored"),
    ("rumour", "Rumored"),
    ("cancelled", "Cancelled"),
    ("discontinued", "Discontinued"),
    ("coming soon", "Announced"),
    ("announced", "Announced"),
    ("expected", "Announced"),
    ("available", "Available"),
]

_MANDATORY_ANY: frozenset[str] = frozenset({"brand", "model_name", "url"})


# ---------------------------------------------------------------------------
# ValidationResult
# ---------------------------------------------------------------------------


@dataclass
class ValidationResult:
    is_valid: bool = True
    warnings: list[str] = dc_field(default_factory=list)
    errors: list[str] = dc_field(default_factory=list)

    def add_warning(self, msg: str) -> None:
        self.warnings.append(msg)

    def add_error(self, msg: str) -> None:
        self.errors.append(msg)
        self.is_valid = False


# ---------------------------------------------------------------------------
# Pure extraction helpers
# ---------------------------------------------------------------------------


def _first_float(text: str, pat: re.Pattern[str] = _FLOAT_RE) -> float | None:
    m = pat.search(text)
    return float(m.group(1)) if m else None


def _first_int(text: str, pat: re.Pattern[str] = _INT_RE) -> int | None:
    m = pat.search(text)
    return int(m.group(1)) if m else None


def _extract_display_size(raw: str) -> float | None:
    m = _INCH_RE.search(raw)
    if m:
        return float(m.group(1))
    m2 = _FLOAT_RE.search(raw)
    if m2:
        val = float(m2.group(1))
        if 1.0 <= val <= 9.9:
            return val
    return None


def _extract_weight_g(raw: str) -> int | None:
    m = _GRAM_RE.search(raw)
    if m:
        return int(float(m.group(1)))
    m2 = _INT_RE.search(raw)
    if m2:
        val = int(m2.group(1))
        if 50 <= val <= 600:
            return val
    return None


def _extract_battery_mah(raw: str) -> int | None:
    m = _MAH_RE.search(raw)
    if m:
        return int(m.group(1))
    m2 = _INT_RE.search(raw)
    if m2:
        val = int(m2.group(1))
        if 500 <= val <= 20000:
            return val
    return None


def _extract_camera_mp(raw: str) -> float | None:
    m = _MP_RE.search(raw)
    return float(m.group(1)) if m else None


def _extract_ram_gb(raw: str) -> float | None:
    vals = [float(m.group(1)) for m in _GB_RE.finditer(raw)]
    if not vals:
        m = _MB_RE.search(raw)
        if m:
            return round(int(m.group(1)) / 1024, 2)
        return None
    return min(vals)


def _extract_storage_gb(raw: str) -> float | None:
    vals = [float(m.group(1)) for m in _GB_RE.finditer(raw)]
    return max(vals) if vals else None


def _parse_launch_date(raw: str) -> tuple[int | None, str | None]:
    year: int | None = None
    quarter: str | None = None
    ym = _YEAR_RE.search(raw)
    if ym:
        year = int(ym.group(1))
    qm = _QUARTER_RE.search(raw)
    if qm:
        quarter = f"Q{qm.group(1)}"
    else:
        lower = raw.lower()
        for month_name, q in _MONTH_TO_Q.items():
            if month_name in lower:
                quarter = q
                break
    return year, quarter


def _parse_price_usd(raw: str) -> float | None:
    for m in _CURRENCY_RE.finditer(raw):
        symbol = m.group(1) or ""
        amount_s = m.group(2) or m.group(3) or ""
        code = (m.group(4) or "").lower()
        currency = _SYMBOL_MAP.get(symbol, code or "usd")
        try:
            amount = float(amount_s.replace(",", ""))
            rate = _FX_TO_USD.get(currency, 1.0)
            return round(amount * rate, 2)
        except ValueError:
            continue
    return None


def _derive_network_gen(raw: str) -> str | None:
    upper = raw.upper()
    for token, gen in _NET_GEN_MAP:
        if token in upper:
            return gen
    return None


def _derive_chipset_family(raw: str) -> str | None:
    lower = raw.lower()
    for keyword, family in _CHIPSET_FAMILIES:
        if keyword in lower:
            return family
    return "Other" if raw.strip() else None


def _derive_launch_status(raw: str) -> str:
    lower = raw.lower()
    for token, status in _STATUS_MAP:
        if token in lower:
            return status
    return "Unknown"


def _derive_ip_rating(raw: str) -> str | None:
    """Extract highest IP rating or MIL-STD cert from body_build / body string."""
    lower = raw.lower()
    # MIL-STD takes priority for rugged devices
    if "mil-std-810h" in lower:
        return "MIL-STD-810H"
    if "mil-std-810g" in lower:
        return "MIL-STD-810G"
    # IP ratings — highest number wins
    matches = _IP_MAIN_RE.findall(raw)
    if matches:
        best = max(matches, key=lambda s: int(s))
        return f"IP{best}"
    return None


def _derive_form_factor(raw: str) -> str | None:
    lower = raw.lower()
    if "foldable" in lower or "fold" in lower:
        return "Foldable"
    if "flip" in lower:
        return "Flip"
    if "slide" in lower:
        return "Slide"
    if "watch" in lower or "wearable" in lower:
        return "Watch"
    if "tablet" in lower:
        return "Tablet"
    if "bar" in lower:
        return "Bar"
    return None


def _parse_charging_watts(raw: str) -> int | None:
    m = _WATT_RE.search(raw)
    if m:
        w = int(m.group(1))
        if 5 <= w <= 300:
            return w
    return None


def _parse_refresh_rate(raw: str) -> int | None:
    """Find highest Hz value in display_type string."""
    vals = [int(m.group(1)) for m in _HZ_RE.finditer(raw)]
    valid = [v for v in vals if 30 <= v <= 165]
    return max(valid) if valid else None


def _parse_screen_to_body(raw: str) -> float | None:
    """'89.5% screen-to-body ratio' → 89.5"""
    m = _PCT_RE.search(raw)
    if m:
        val = float(m.group(1))
        if 30.0 <= val <= 100.0:
            return val
    return None


def _parse_cpu_cores(raw: str) -> int | None:
    lower = raw.lower()
    for word, count in _CORE_MAP.items():
        if word + "-core" in lower or word + "core" in lower:
            return count
    # Explicit number
    m = re.search(r"(\d+)[- ]?core", lower)
    if m:
        return int(m.group(1))
    return None


def _parse_bluetooth_version(raw: str) -> float | None:
    m = _BT_VER_RE.search(raw)
    if m:
        return float(m.group(1))
    return None


def _parse_wifi_gen(raw: str) -> int | None:
    # Wi-Fi 7 / Wi-Fi 6E / Wi-Fi 6 — check named generations first
    if "802.11be" in raw or "Wi-Fi 7" in raw or "WiFi 7" in raw:
        return 7
    if "802.11ax" in raw or "Wi-Fi 6" in raw or "WiFi 6" in raw or "6e" in raw.lower():
        return 6
    if "802.11ac" in raw or "Wi-Fi 5" in raw or "WiFi 5" in raw:
        return 5
    if "802.11n" in raw or "Wi-Fi 4" in raw or "WiFi 4" in raw:
        return 4
    # Fallback: explicit "Wi-Fi N" where N is 4-7
    m = _WIFI_GEN_RE.search(raw)
    if m:
        gen = int(m.group(1))
        if 4 <= gen <= 7:
            return gen
    return None


def _bool_field(raw: str, *keywords: str) -> bool | None:
    """Return True if any keyword appears in raw (case-insensitive)."""
    if not raw:
        return None
    lower = raw.lower()
    if any(kw in lower for kw in keywords):
        return True
    # Explicit "no" / "n/a" returns False
    if lower.strip() in ("no", "n/a", "none", "-"):
        return False
    return None


# ---------------------------------------------------------------------------
# DataEnricher
# ---------------------------------------------------------------------------


class DataEnricher:
    """
    Stateless enricher — safe to share across all pipeline invocations.
    Call enrich(record) to add structured derived fields.
    Call validate(record) for per-record quality checks.
    """

    def enrich(self, record: dict[str, Any]) -> dict[str, Any]:
        """
        Return a new dict with all enriched fields added.
        Never removes existing fields.
        """
        out = dict(record)
        self._add_display_size(out)
        self._add_weight(out)
        self._add_battery(out)
        self._add_camera_mp(out)
        self._add_ram_storage(out)
        self._add_launch_date(out)
        self._add_price_usd(out)
        self._add_network_gen(out)
        self._add_chipset_family(out)
        self._add_launch_status_clean(out)
        self._add_bool_flags(out)
        self._add_form_factor(out)
        self._add_ip_rating(out)
        self._add_review_score(out)
        self._add_charging_speed(out)
        self._add_refresh_rate(out)
        self._add_screen_to_body(out)
        self._add_cpu_cores(out)
        self._add_bluetooth_version(out)
        self._add_wifi_gen(out)
        return out

    def validate(self, record: dict[str, Any]) -> ValidationResult:
        result = ValidationResult()
        url = str(record.get("url", ""))
        model = str(record.get("model_name", ""))
        brand = str(record.get("brand", ""))

        for f in _MANDATORY_ANY:
            if not record.get(f):
                result.add_error(f"Missing mandatory field: {f}")

        if not any(
            record.get(k)
            for k in ("display_size", "screen_size_inches", "display_size_in")
        ):
            result.add_warning(f"No display size: {brand} {model}")

        if url and "gsmarena.com" not in url:
            result.add_warning(f"Unexpected URL domain: {url}")

        size = record.get("display_size_in")
        if size is not None:
            try:
                if not (0.5 <= float(size) <= 15.0):
                    result.add_warning(f"display_size_in out of range: {size}")
            except (ValueError, TypeError):
                result.add_warning(f"display_size_in non-numeric: {size}")

        weight = record.get("weight_g_num")
        if weight is not None:
            try:
                if not (20 <= int(weight) <= 1000):
                    result.add_warning(f"weight_g_num out of range: {weight}")
            except (ValueError, TypeError):
                result.add_warning(f"weight_g_num non-numeric: {weight}")

        battery = record.get("battery_mah_num")
        if battery is not None:
            try:
                if not (100 <= int(battery) <= 30000):
                    result.add_warning(f"battery_mah_num out of range: {battery}")
            except (ValueError, TypeError):
                result.add_warning(f"battery_mah_num non-numeric: {battery}")

        return result

    # -- Internal enrichment steps ------------------------------------------

    @staticmethod
    def _get(record: dict[str, Any], *keys: str) -> str | None:
        for k in keys:
            v = record.get(k)
            if isinstance(v, str) and v.strip():
                return v.strip()
        return None

    def _add_display_size(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "display_size", "screen_size_inches", "quick_display")
        if raw:
            val = _extract_display_size(raw)
            if val is not None:
                out["display_size_in"] = val

    def _add_weight(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "body_weight", "weight_g")
        if raw:
            val = _extract_weight_g(raw)
            if val is not None:
                out["weight_g_num"] = val

    def _add_battery(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "battery_capacity", "battery_mah", "battery_type")
        if raw:
            val = _extract_battery_mah(raw)
            if val is not None:
                out["battery_mah_num"] = val

    def _add_camera_mp(self, out: dict[str, Any]) -> None:
        for key in (
            "main_camera_single",
            "main_camera_dual",
            "main_camera_triple",
            "main_camera_quad",
        ):
            raw = out.get(key)
            if isinstance(raw, str) and raw:
                val = _extract_camera_mp(raw)
                if val is not None:
                    out["main_camera_mp_num"] = val
                    break

    def _add_ram_storage(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "memory_internal", "storage_ram")
        if raw:
            ram = _extract_ram_gb(raw)
            if ram is not None:
                out["ram_gb_num"] = ram
            storage = _extract_storage_gb(raw)
            if storage is not None:
                out["storage_gb_num"] = storage

    def _add_launch_date(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "launch_announced")
        if raw:
            year, quarter = _parse_launch_date(raw)
            if year is not None:
                out["launch_year"] = year
            if quarter is not None:
                out["launch_quarter"] = quarter

    def _add_price_usd(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "misc_price", "price_eur")
        if raw:
            val = _parse_price_usd(raw)
            if val is not None:
                out["price_usd_approx"] = val

    def _add_network_gen(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "network_technology", "network_gen")
        if raw:
            gen = _derive_network_gen(raw)
            if gen is not None and "network_gen_derived" not in out:
                out["network_gen_derived"] = gen

    def _add_chipset_family(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "platform_chipset", "chipset", "quick_processor")
        if raw:
            family = _derive_chipset_family(raw)
            if family:
                out["chipset_family"] = family

    def _add_launch_status_clean(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "launch_status", "launch_announced")
        if raw:
            out["launch_status_clean"] = _derive_launch_status(raw)

    def _add_bool_flags(self, out: dict[str, Any]) -> None:
        # 5G
        net_raw = self._get(out, "network_technology", "network_gen_derived") or ""
        out["has_5g"] = bool("5G" in net_raw.upper() or "NR" in net_raw.upper())

        # NFC
        nfc_raw = self._get(out, "comms_nfc", "features_sensors") or ""
        lower_nfc = nfc_raw.lower().strip()
        out["has_nfc"] = (
            "nfc" in lower_nfc
            or lower_nfc in ("yes", "yes (nfc)", "1")
            or lower_nfc.startswith("yes")
        )

        # eSIM
        sim_raw = self._get(out, "body_sim") or ""
        out["has_esim"] = "esim" in sim_raw.lower()

        # Headphone jack
        jack_raw = self._get(out, "sound_jack_35mm", "sound_35mm_jack") or ""
        out["has_headphone_jack"] = bool(
            jack_raw
            and jack_raw.strip().lower() not in ("no", "n/a", "")
            and any(t in jack_raw.lower() for t in ("yes", "3.5mm", "3.5 mm"))
        )

        # Dual speakers
        spk_raw = self._get(out, "sound_loudspeaker") or ""
        out["has_dual_speakers"] = (
            "stereo" in spk_raw.lower() or "dual" in spk_raw.lower()
        )

        # IR blaster
        ir_raw = self._get(out, "comms_infrared_port", "comms_ir") or ""
        feat_raw = self._get(out, "features_sensors") or ""
        out["has_ir_blaster"] = (
            bool(ir_raw and ir_raw.strip().lower() not in ("no", ""))
            or "infrared" in feat_raw.lower()
        )

        # Wi-Fi 6+
        wifi_raw = self._get(out, "comms_wlan") or ""
        gen = _parse_wifi_gen(wifi_raw)
        out["has_wifi6"] = bool(gen and gen >= 6)

    def _add_form_factor(self, out: dict[str, Any]) -> None:
        # Try form factor field first, then derive from model name and body build
        raw = self._get(out, "body_form_factor", "misc_form_factor")
        if not raw:
            # Derive from model name (e.g. "Galaxy Z Fold", "Moto Razr")
            model = self._get(out, "model_name", "full_name") or ""
            body = self._get(out, "body_build") or ""
            raw = f"{model} {body}"
        ff = _derive_form_factor(raw)
        if ff:
            out["form_factor_clean"] = ff

    def _add_ip_rating(self, out: dict[str, Any]) -> None:
        # Try dedicated field first, then body_build, then body
        for key in ("body_protection", "body_build", "body_dimensions", "body_weight"):
            raw = out.get(key)
            if isinstance(raw, str):
                rating = _derive_ip_rating(raw)
                if rating:
                    out["ip_rating"] = rating
                    # Try to extract water resistance depth
                    m = _IP_DEPTH_RE.search(raw)
                    if m:
                        out["ip_water_depth_m"] = float(m.group(1))
                    return

    def _add_review_score(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "gsmarena_rating")
        if raw:
            m = _FLOAT_RE.search(raw)
            if m:
                val = float(m.group(1))
                if 0.0 <= val <= 10.0:
                    out["review_score"] = val

    def _add_charging_speed(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "battery_charging")
        if raw:
            val = _parse_charging_watts(raw)
            if val is not None:
                out["charging_speed_w"] = val

    def _add_refresh_rate(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "display_type", "screen_type")
        if raw:
            val = _parse_refresh_rate(raw)
            if val is not None:
                out["refresh_rate_hz"] = val

    def _add_screen_to_body(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "display_size", "screen_size_inches")
        if raw:
            val = _parse_screen_to_body(raw)
            if val is not None:
                out["screen_to_body_pct"] = val

    def _add_cpu_cores(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "platform_cpu", "cpu", "quick_processor")
        if raw:
            val = _parse_cpu_cores(raw)
            if val is not None:
                out["cpu_cores"] = val

    def _add_bluetooth_version(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "comms_bluetooth")
        if raw:
            val = _parse_bluetooth_version(raw)
            if val is not None:
                out["bluetooth_version"] = val

    def _add_wifi_gen(self, out: dict[str, Any]) -> None:
        raw = self._get(out, "comms_wlan")
        if raw:
            val = _parse_wifi_gen(raw)
            if val is not None:
                out["wifi_generation"] = val
