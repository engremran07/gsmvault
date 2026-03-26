"""
SEO Audit Service — On-site SEO health checks for all content types.

Provides real-time SEO analysis for: Blog Posts, Brands, Device Models,
Firmware Files, and Forum Topics.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any

from django.db.models import Count, Q, QuerySet

logger = logging.getLogger(__name__)

# ── SEO Rule Thresholds ──────────────────────────────────────────
TITLE_MIN = 30
TITLE_MAX = 60
TITLE_WARN_MAX = 70
DESC_MIN = 120
DESC_MAX = 160
DESC_WARN_MAX = 200
SLUG_MAX = 75
CONTENT_MIN_WORDS = 300


@dataclass
class SEOIssue:
    """Single SEO issue found on a content item."""

    severity: str  # "error" | "warning" | "info"
    code: str  # machine-readable code e.g. "title_missing"
    message: str  # human-readable description
    field: str = ""  # which field the issue is about


@dataclass
class SEOAuditResult:
    """Audit result for a single content item."""

    content_type: str  # "post", "brand", "model", "firmware", "topic"
    item_id: int | str
    item_title: str
    item_url: str = ""
    score: int = 100  # 0-100
    issues: list[SEOIssue] = field(default_factory=list)

    def add_issue(
        self, severity: str, code: str, message: str, field_name: str = ""
    ) -> None:
        self.issues.append(
            SEOIssue(severity=severity, code=code, message=message, field=field_name)
        )
        # Deduct score
        if severity == "error":
            self.score = max(0, self.score - 15)
        elif severity == "warning":
            self.score = max(0, self.score - 5)
        else:
            self.score = max(0, self.score - 2)

    @property
    def error_count(self) -> int:
        return sum(1 for i in self.issues if i.severity == "error")

    @property
    def warning_count(self) -> int:
        return sum(1 for i in self.issues if i.severity == "warning")

    @property
    def score_color(self) -> str:
        if self.score >= 80:
            return "emerald"
        if self.score >= 60:
            return "amber"
        return "red"

    def to_dict(self) -> dict[str, Any]:
        return {
            "content_type": self.content_type,
            "item_id": self.item_id,
            "item_title": self.item_title,
            "item_url": self.item_url,
            "score": self.score,
            "score_color": self.score_color,
            "error_count": self.error_count,
            "warning_count": self.warning_count,
            "issues": [
                {
                    "severity": i.severity,
                    "code": i.code,
                    "message": i.message,
                    "field": i.field,
                }
                for i in self.issues
            ],
        }


# ── Audit Functions ──────────────────────────────────────────────


def _check_title(result: SEOAuditResult, title: str, field_name: str = "title") -> None:
    if not title or not title.strip():
        result.add_issue("error", "title_missing", "Title is empty.", field_name)
        return
    length = len(title.strip())
    if length < TITLE_MIN:
        result.add_issue(
            "warning",
            "title_short",
            f"Title is {length} chars — recommended {TITLE_MIN}–{TITLE_MAX}.",
            field_name,
        )
    elif length > TITLE_WARN_MAX:
        result.add_issue(
            "error",
            "title_too_long",
            f"Title is {length} chars — max {TITLE_MAX} for SERP display.",
            field_name,
        )
    elif length > TITLE_MAX:
        result.add_issue(
            "warning",
            "title_long",
            f"Title is {length} chars — may be truncated in SERP.",
            field_name,
        )


def _check_description(
    result: SEOAuditResult, desc: str, field_name: str = "description"
) -> None:
    if not desc or not desc.strip():
        result.add_issue(
            "error", "desc_missing", "Meta description is empty.", field_name
        )
        return
    length = len(desc.strip())
    if length < DESC_MIN:
        result.add_issue(
            "warning",
            "desc_short",
            f"Description is {length} chars — recommended {DESC_MIN}–{DESC_MAX}.",
            field_name,
        )
    elif length > DESC_WARN_MAX:
        result.add_issue(
            "error",
            "desc_too_long",
            f"Description is {length} chars — max {DESC_MAX} for SERP.",
            field_name,
        )
    elif length > DESC_MAX:
        result.add_issue(
            "warning",
            "desc_long",
            f"Description is {length} chars — may be truncated.",
            field_name,
        )


def _check_slug(result: SEOAuditResult, slug: str) -> None:
    if not slug:
        result.add_issue("error", "slug_missing", "URL slug is empty.", "slug")
        return
    if len(slug) > SLUG_MAX:
        result.add_issue(
            "warning",
            "slug_long",
            f"Slug is {len(slug)} chars — keep under {SLUG_MAX}.",
            "slug",
        )
    if "_" in slug:
        result.add_issue(
            "info",
            "slug_underscores",
            "Slug uses underscores — hyphens are preferred for SEO.",
            "slug",
        )


def _check_content_length(
    result: SEOAuditResult, content: str, field_name: str = "body"
) -> None:
    if not content or not content.strip():
        result.add_issue("error", "content_empty", "Content body is empty.", field_name)
        return
    word_count = len(content.split())
    if word_count < CONTENT_MIN_WORDS:
        result.add_issue(
            "warning",
            "content_thin",
            f"Content has {word_count} words — recommend {CONTENT_MIN_WORDS}+ for SEO.",
            field_name,
        )


def _check_image(result: SEOAuditResult, image_url: str, field_name: str) -> None:
    if not image_url:
        result.add_issue(
            "warning",
            "image_missing",
            f"No {field_name} — images improve CTR and social sharing.",
            field_name,
        )


# ── Per-Content-Type Auditors ────────────────────────────────────


def audit_post(post: Any) -> SEOAuditResult:
    """Audit a blog Post for SEO health."""
    result = SEOAuditResult(
        content_type="post",
        item_id=post.pk,
        item_title=str(post.title or f"Post #{post.pk}"),
    )

    # SEO title
    seo_title = getattr(post, "seo_title", "") or ""
    if seo_title:
        _check_title(result, seo_title, "seo_title")
    else:
        # Fall back to regular title
        _check_title(result, post.title or "", "title")
        result.add_issue(
            "warning",
            "seo_title_missing",
            "No dedicated SEO title — using post title.",
            "seo_title",
        )

    # Meta description
    seo_desc = getattr(post, "seo_description", "") or ""
    if seo_desc:
        _check_description(result, seo_desc, "seo_description")
    else:
        summary = getattr(post, "summary", "") or ""
        if summary:
            _check_description(result, summary, "summary")
            result.add_issue(
                "warning",
                "seo_desc_missing",
                "No SEO description — using summary as fallback.",
                "seo_description",
            )
        else:
            result.add_issue(
                "error",
                "desc_missing",
                "No meta description or summary.",
                "seo_description",
            )

    _check_slug(result, post.slug or "")
    _check_content_length(result, post.body or "")
    _check_image(result, getattr(post, "hero_image", "") or "", "hero_image")

    # Canonical URL
    canonical = getattr(post, "canonical_url", "") or ""
    if not canonical:
        result.add_issue(
            "info",
            "canonical_missing",
            "No canonical URL set — auto-canonical will be used.",
            "canonical_url",
        )

    # Noindex flag
    if getattr(post, "noindex", False):
        result.add_issue(
            "info",
            "noindex_set",
            "Post is marked noindex — excluded from search engines.",
            "noindex",
        )

    return result


def audit_brand(brand: Any) -> SEOAuditResult:
    """Audit a firmware Brand for SEO health."""
    result = SEOAuditResult(
        content_type="brand",
        item_id=brand.pk,
        item_title=str(brand.name or f"Brand #{brand.pk}"),
    )

    _check_title(result, brand.name or "", "name")
    _check_slug(result, brand.slug or "")

    desc = getattr(brand, "description", "") or ""
    if not desc.strip():
        result.add_issue(
            "error",
            "desc_missing",
            "Brand has no description — pages need meta descriptions.",
            "description",
        )
    else:
        _check_description(result, desc, "description")

    _check_image(result, getattr(brand, "logo_url", "") or "", "logo_url")

    return result


def audit_model(model: Any) -> SEOAuditResult:
    """Audit a device Model for SEO health."""
    result = SEOAuditResult(
        content_type="model",
        item_id=model.pk,
        item_title=f"{getattr(model, 'brand', '')} {model.name or ''}".strip()
        or f"Model #{model.pk}",
    )

    _check_title(result, model.name or "", "name")
    _check_slug(result, model.slug or "")

    desc = getattr(model, "description", "") or ""
    if not desc.strip():
        result.add_issue(
            "error",
            "desc_missing",
            "Device model has no description — provide SEO text.",
            "description",
        )
    else:
        _check_description(result, desc, "description")

    _check_image(result, getattr(model, "image_url", "") or "", "image_url")

    # Check for missing specs that help SEO
    if not getattr(model, "chipset", ""):
        result.add_issue(
            "info",
            "chipset_missing",
            "Chipset info missing — enriches schema markup.",
            "chipset",
        )

    return result


def audit_firmware(fw: Any) -> SEOAuditResult:
    """Audit a Firmware file for SEO health."""
    result = SEOAuditResult(
        content_type="firmware",
        item_id=str(fw.pk),
        item_title=str(getattr(fw, "original_file_name", "") or f"Firmware #{fw.pk}"),
    )

    # Firmware files lack SEO fields — audit what's available
    fname = getattr(fw, "original_file_name", "") or ""
    if not fname:
        result.add_issue(
            "error",
            "filename_missing",
            "Firmware has no filename.",
            "original_file_name",
        )

    brand = getattr(fw, "brand", None)
    if not brand:
        result.add_issue(
            "warning",
            "brand_missing",
            "Firmware has no brand assigned — hurts category SEO.",
            "brand",
        )

    model = getattr(fw, "model", None)
    if not model:
        result.add_issue(
            "warning",
            "model_missing",
            "Firmware has no device model assigned.",
            "model",
        )

    if not getattr(fw, "android_version", ""):
        result.add_issue(
            "info",
            "android_version_missing",
            "Android version not specified — helps search visibility.",
            "android_version",
        )

    if not getattr(fw, "build_number", ""):
        result.add_issue(
            "info",
            "build_number_missing",
            "Build number not specified.",
            "build_number",
        )

    return result


def audit_topic(topic: Any) -> SEOAuditResult:
    """Audit a ForumTopic for SEO health."""
    result = SEOAuditResult(
        content_type="topic",
        item_id=topic.pk,
        item_title=str(topic.title or f"Topic #{topic.pk}"),
    )

    _check_title(result, topic.title or "", "title")
    _check_slug(result, topic.slug or "")
    _check_content_length(result, topic.content or "", "content")

    # Forum topics lack seo_description — check if first content is useful
    content = (topic.content or "").strip()
    if content:
        first_line = content.split("\n")[0][:160]
        if len(first_line) < DESC_MIN:
            result.add_issue(
                "warning",
                "opening_short",
                "First paragraph is short — search engines use it as snippet.",
                "content",
            )

    return result


# ── Batch Audit & Statistics ─────────────────────────────────────


def audit_posts_batch(queryset: QuerySet[Any] | None = None) -> list[SEOAuditResult]:
    """Audit all published blog posts."""
    from apps.blog.models import Post

    if queryset is None:
        queryset = Post.objects.filter(is_published=True)
    return [audit_post(p) for p in queryset.select_related("category")]


def audit_brands_batch(queryset: QuerySet[Any] | None = None) -> list[SEOAuditResult]:
    """Audit all brands."""
    from apps.firmwares.models import Brand

    if queryset is None:
        queryset = Brand.objects.all()
    return [audit_brand(b) for b in queryset]


def audit_models_batch(queryset: QuerySet[Any] | None = None) -> list[SEOAuditResult]:
    """Audit all active device models."""
    from apps.firmwares.models import Model

    if queryset is None:
        queryset = Model.objects.filter(is_active=True)
    return [audit_model(m) for m in queryset.select_related("brand")]


def audit_firmwares_batch(
    queryset: QuerySet[Any] | None = None,
) -> list[SEOAuditResult]:
    """Audit active firmware files (sample from OfficialFirmware)."""
    from apps.firmwares.models import OfficialFirmware

    if queryset is None:
        queryset = OfficialFirmware.objects.filter(is_active=True)
    return [
        audit_firmware(fw) for fw in queryset.select_related("brand", "model")[:200]
    ]


def audit_topics_batch(queryset: QuerySet[Any] | None = None) -> list[SEOAuditResult]:
    """Audit all visible forum topics."""
    from apps.forum.models import ForumTopic

    if queryset is None:
        queryset = ForumTopic.objects.filter(is_removed=False)
    return [audit_topic(t) for t in queryset.select_related("category")]


def get_seo_overview() -> dict[str, Any]:
    """Aggregate SEO health stats across all content types."""
    from apps.blog.models import Post
    from apps.firmwares.models import Brand, Model, OfficialFirmware
    from apps.forum.models import ForumTopic

    overview: dict[str, Any] = {
        "total_content": 0,
        "avg_score": 0,
        "total_errors": 0,
        "total_warnings": 0,
        "by_type": {},
    }

    type_configs = [
        ("posts", Post.objects.filter(is_published=True), audit_post),
        ("brands", Brand.objects.all(), audit_brand),
        ("models", Model.objects.filter(is_active=True), audit_model),
        (
            "firmwares",
            OfficialFirmware.objects.filter(is_active=True)[:100],
            audit_firmware,
        ),
        ("topics", ForumTopic.objects.filter(is_removed=False), audit_topic),
    ]

    all_scores: list[int] = []

    for type_key, qs, audit_fn in type_configs:
        results = [audit_fn(item) for item in qs]
        scores = [r.score for r in results]
        errors = sum(r.error_count for r in results)
        warnings = sum(r.warning_count for r in results)
        avg = round(sum(scores) / len(scores)) if scores else 100

        overview["by_type"][type_key] = {
            "count": len(results),
            "avg_score": avg,
            "errors": errors,
            "warnings": warnings,
            "score_color": (
                "emerald" if avg >= 80 else "amber" if avg >= 60 else "red"
            ),
        }

        overview["total_content"] += len(results)
        overview["total_errors"] += errors
        overview["total_warnings"] += warnings
        all_scores.extend(scores)

    overview["avg_score"] = (
        round(sum(all_scores) / len(all_scores)) if all_scores else 100
    )
    overview["score_color"] = (
        "emerald"
        if overview["avg_score"] >= 80
        else "amber"
        if overview["avg_score"] >= 60
        else "red"
    )

    return overview


def get_content_type_audit(
    content_type: str,
    search: str = "",
    sort_by: str = "score",
    sort_dir: str = "asc",
) -> list[dict[str, Any]]:
    """Get audit results for a specific content type with search/sort."""
    audit_map: dict[str, tuple[Any, Any]] = {}

    try:
        from apps.blog.models import Post

        audit_map["posts"] = (
            Post.objects.filter(is_published=True),
            audit_post,
        )
    except Exception:
        logger.debug("Could not load blog Post model for SEO audit")

    try:
        from apps.firmwares.models import Brand

        audit_map["brands"] = (Brand.objects.all(), audit_brand)
    except Exception:
        logger.debug("Could not load Brand model for SEO audit")

    try:
        from apps.firmwares.models import Model

        audit_map["models"] = (
            Model.objects.filter(is_active=True),
            audit_model,
        )
    except Exception:
        logger.debug("Could not load Model model for SEO audit")

    try:
        from apps.firmwares.models import OfficialFirmware

        audit_map["firmwares"] = (
            OfficialFirmware.objects.filter(is_active=True)[:200],
            audit_firmware,
        )
    except Exception:
        logger.debug("Could not load OfficialFirmware model for SEO audit")

    try:
        from apps.forum.models import ForumTopic

        audit_map["topics"] = (
            ForumTopic.objects.filter(is_removed=False),
            audit_topic,
        )
    except Exception:
        logger.debug("Could not load ForumTopic model for SEO audit")

    if content_type not in audit_map:
        return []

    qs, audit_fn = audit_map[content_type]

    # Apply search filter at ORM level where possible
    if search:
        if content_type == "posts":
            qs = qs.filter(Q(title__icontains=search) | Q(slug__icontains=search))
        elif content_type in ("brands", "models"):
            qs = qs.filter(Q(name__icontains=search) | Q(slug__icontains=search))
        elif content_type == "firmwares":
            qs = qs.filter(
                Q(original_file_name__icontains=search)
                | Q(build_number__icontains=search)
            )
        elif content_type == "topics":
            qs = qs.filter(Q(title__icontains=search) | Q(slug__icontains=search))

    results = [audit_fn(item).to_dict() for item in qs]

    # Sort
    reverse = sort_dir == "desc"
    if sort_by == "score":
        results.sort(key=lambda r: r["score"], reverse=reverse)
    elif sort_by == "errors":
        results.sort(key=lambda r: r["error_count"], reverse=reverse)
    elif sort_by == "title":
        results.sort(key=lambda r: r["item_title"].lower(), reverse=reverse)
    else:
        results.sort(key=lambda r: r["score"], reverse=reverse)

    return results


def get_duplicate_titles() -> dict[str, list[dict[str, Any]]]:
    """Find duplicate titles/names across content types."""
    from apps.blog.models import Post
    from apps.firmwares.models import Brand, Model
    from apps.forum.models import ForumTopic

    duplicates: dict[str, list[dict[str, Any]]] = {}

    # Blog post title duplicates
    dup_titles = (
        Post.objects.filter(is_published=True)
        .values("title")
        .annotate(cnt=Count("id"))
        .filter(cnt__gt=1)
    )
    if dup_titles.exists():
        duplicates["posts"] = [
            {"title": d["title"], "count": d["cnt"]} for d in dup_titles
        ]

    # Brand name duplicates — unlikely but check
    dup_brands = (
        Brand.objects.values("name").annotate(cnt=Count("id")).filter(cnt__gt=1)
    )
    if dup_brands.exists():
        duplicates["brands"] = [
            {"title": d["name"], "count": d["cnt"]} for d in dup_brands
        ]

    # Model name duplicates (within same brand)
    dup_models = (
        Model.objects.filter(is_active=True)
        .values("brand__name", "name")
        .annotate(cnt=Count("id"))
        .filter(cnt__gt=1)
    )
    if dup_models.exists():
        duplicates["models"] = [
            {"title": f"{d['brand__name']} {d['name']}", "count": d["cnt"]}
            for d in dup_models
        ]

    # Forum topic title duplicates
    dup_topics = (
        ForumTopic.objects.filter(is_removed=False)
        .values("title")
        .annotate(cnt=Count("id"))
        .filter(cnt__gt=1)
    )
    if dup_topics.exists():
        duplicates["topics"] = [
            {"title": d["title"], "count": d["cnt"]} for d in dup_topics
        ]

    return duplicates
