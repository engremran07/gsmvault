"""Firmware AI analysis client.

Provides AI-powered firmware file analysis for auto-classification
of brand, model, chipset, and category during the ingestion pipeline.
"""

from __future__ import annotations

import logging
from typing import Any

from apps.core.ai import CoreAiService

logger = logging.getLogger(__name__)

_ai = CoreAiService()


class AIClient:
    """Thin facade that delegates firmware analysis to :class:`CoreAiService`."""

    def analyze_firmware(
        self,
        file_path: str,
        *,
        password: str | None = None,
    ) -> dict[str, Any]:
        """Analyse a firmware file and return classification hints.

        Returns a dict with keys:
        ``brand``, ``model``, ``variant``, ``category``, ``subtype``,
        ``chipset``, ``partitions``, ``metadata``.
        """
        prompt = (
            f"Analyze the firmware file at '{file_path}'. "
            "Extract brand, model, variant, category (official/engineering/"
            "readback/modified/other), subtype, chipset, and partition list."
        )
        if password:
            prompt += " The archive is password-protected."

        try:
            result = _ai.generate_text(prompt)
            # CoreAiService.generate_text returns a string — parse as needed.
            # For now return an empty classification; real implementation would
            # parse the AI response into structured fields.
            logger.info("AI analysis completed for %s", file_path)
            return _parse_ai_response(result)
        except Exception:
            logger.exception("AI firmware analysis failed for %s", file_path)
            return {}


def _parse_ai_response(text: str) -> dict[str, Any]:
    """Best-effort parse of the AI text response into structured fields."""
    import json

    # If the AI returns JSON, use it directly
    try:
        data = json.loads(text)
        if isinstance(data, dict):
            return data
    except (json.JSONDecodeError, TypeError):
        pass

    # Fallback: return empty dict — manual classification via admin
    return {
        "brand": "",
        "model": "",
        "variant": "",
        "category": None,
        "subtype": None,
        "chipset": "",
        "partitions": [],
        "metadata": {},
    }
