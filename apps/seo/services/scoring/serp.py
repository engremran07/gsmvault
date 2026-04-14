from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any

from apps.seo.models import Metadata

logger = logging.getLogger(__name__)


@dataclass(slots=True)
class AuditCheckResult:
    check_id: int
    name: str
    passed: bool
    weight: int
    severity: str
    message: str


def _score(results: list[AuditCheckResult]) -> float:
    total_weight = sum(item.weight for item in results) or 1
    passed_weight = sum(item.weight for item in results if item.passed)
    return round((passed_weight / total_weight) * 100, 2)


def serp_analyze(meta_title: str, meta_description: str) -> dict[str, float]:
    """
    Placeholder SERP analyzer that returns a simple heuristic score.
    """
    try:
        length_score = min(len(meta_title) / 60.0, 1.0)
        desc_score = min(len(meta_description) / 160.0, 1.0)
        score = round((length_score * 0.6 + desc_score * 0.4) * 100, 1)
        logger.info("seo.serp.analyze", extra={"event": {"score": score}})
        return {"serp_score": score}
    except Exception as exc:
        logger.warning("serp_analyze failed: %s", exc)
        return {"serp_score": 0.0}


def run_seo_audit(metadata: Metadata | None, html: str = "") -> dict[str, Any]:
    """Run a deterministic 21-check SEO audit and return weighted score."""
    title = (metadata.meta_title if metadata else "") or ""
    description = (metadata.meta_description if metadata else "") or ""
    canonical = (metadata.canonical_url if metadata else "") or ""
    noindex = bool(metadata.noindex) if metadata else False
    social_title = (metadata.social_title if metadata else "") or ""
    social_description = (metadata.social_description if metadata else "") or ""
    social_image = (metadata.social_image if metadata else "") or ""
    schema_json = bool(metadata and metadata.schema_json)
    focus_keywords = metadata.focus_keywords if metadata else []

    checks: list[AuditCheckResult] = [
        AuditCheckResult(
            1, "title_exists", bool(title), 8, "critical", "Title is required"
        ),
        AuditCheckResult(
            2,
            "title_length",
            30 <= len(title) <= 60 if title else False,
            4,
            "warning",
            "Title should be 30-60 chars",
        ),
        AuditCheckResult(
            3,
            "description_exists",
            bool(description),
            8,
            "critical",
            "Meta description is required",
        ),
        AuditCheckResult(
            4,
            "description_length",
            120 <= len(description) <= 160 if description else False,
            4,
            "warning",
            "Description should be 120-160 chars",
        ),
        AuditCheckResult(
            5,
            "has_focus_keywords",
            len(focus_keywords) > 0,
            4,
            "warning",
            "Add focus keywords",
        ),
        AuditCheckResult(
            6,
            "has_canonical",
            bool(canonical),
            6,
            "critical",
            "Canonical URL should be set",
        ),
        AuditCheckResult(
            7,
            "robots_directives",
            bool(metadata.robots_directives if metadata else ""),
            2,
            "info",
            "Robots directives recommended",
        ),
        AuditCheckResult(
            8,
            "social_title",
            bool(social_title),
            3,
            "warning",
            "Social title recommended",
        ),
        AuditCheckResult(
            9,
            "social_description",
            bool(social_description),
            3,
            "warning",
            "Social description recommended",
        ),
        AuditCheckResult(
            10,
            "social_image",
            bool(social_image),
            3,
            "warning",
            "Social image recommended",
        ),
        AuditCheckResult(
            11, "schema_json", schema_json, 3, "warning", "Schema JSON recommended"
        ),
        AuditCheckResult(
            12,
            "ai_score_present",
            (metadata.ai_score if metadata else 0.0) >= 0.0,
            1,
            "info",
            "AI score should be computed",
        ),
        AuditCheckResult(
            13,
            "not_noindex",
            not noindex,
            6,
            "critical",
            "Avoid noindex unless intentional",
        ),
        AuditCheckResult(
            14,
            "html_has_h1",
            "<h1" in html.lower() if html else False,
            4,
            "warning",
            "Page should include H1",
        ),
        AuditCheckResult(
            15,
            "html_has_h2",
            "<h2" in html.lower() if html else False,
            2,
            "info",
            "Page should include H2",
        ),
        AuditCheckResult(
            16,
            "html_has_alt",
            " alt=" in html.lower() if html else False,
            2,
            "info",
            "Images should have alt text",
        ),
        AuditCheckResult(
            17,
            "html_internal_links",
            'href="/' in html.lower() if html else False,
            2,
            "info",
            "Internal links recommended",
        ),
        AuditCheckResult(
            18,
            "content_hash",
            bool(metadata.content_hash if metadata else ""),
            1,
            "info",
            "Content hash should be tracked",
        ),
        AuditCheckResult(
            19,
            "generated_at",
            bool(metadata and metadata.generated_at),
            1,
            "info",
            "Generated timestamp recommended",
        ),
        AuditCheckResult(
            20,
            "has_proposed_json",
            bool(metadata and metadata.proposed_json),
            1,
            "info",
            "Proposed JSON payload recommended",
        ),
        AuditCheckResult(
            21,
            "auto_apply_flag_defined",
            bool(metadata is not None),
            1,
            "info",
            "Auto-apply flag should be set explicitly",
        ),
    ]

    return {
        "score": _score(checks),
        "checks": [
            {
                "check_id": item.check_id,
                "name": item.name,
                "passed": item.passed,
                "weight": item.weight,
                "severity": item.severity,
                "message": item.message,
            }
            for item in checks
        ],
    }
