from __future__ import annotations

import math
import re
from collections import Counter
from collections.abc import Iterable

from django.contrib.contenttypes.models import ContentType

from apps.core import ai
from apps.core.utils import feature_flags
from apps.seo.models import InterlinkExclusion, LinkableEntity, LinkSuggestion


def refresh_linkable_entity(obj, title: str, url: str, keywords: str = ""):
    if not feature_flags.seo_enabled():
        return None
    ct = ContentType.objects.get_for_model(obj.__class__)
    defaults = {
        "title": title,
        "url": url,
        "keywords": keywords.split(",")
        if isinstance(keywords, str)
        else (keywords or []),
        "is_active": True,
    }
    # Optional embedding if enabled
    try:
        if feature_flags.auto_linking_enabled():
            vec = ai.embed_text(f"{title}\n{keywords}")
            defaults["embedding"] = vec
            defaults["vector"] = vec
    except Exception:  # noqa: S110
        pass
    entity, _ = LinkableEntity.objects.update_or_create(
        content_type=ct,
        object_id=obj.pk,
        defaults=defaults,
    )
    return entity


def _eligible_candidates(
    source: LinkableEntity, candidates: Iterable[LinkableEntity]
) -> list[LinkableEntity]:
    seen = {source.pk}
    out: list[LinkableEntity] = []
    for c in candidates:
        if not c or c.pk in seen:
            continue
        seen.add(c.pk)
        out.append(c)
    return out


def _score_candidate(source: LinkableEntity, target: LinkableEntity) -> float:
    """
    Lightweight semantic-ish score:
    - keyword overlap (bag-of-words)
    - title overlap
    """
    src_terms = Counter(" ".join(source.keywords or []).lower().split())
    tgt_terms = Counter(" ".join(target.keywords or []).lower().split())
    overlap = sum((src_terms & tgt_terms).values())

    title_overlap = 0
    if source.title and target.title:
        src_title = set(source.title.lower().split())
        tgt_title = set(target.title.lower().split())
        title_overlap = len(src_title & tgt_title)

    return float(overlap + title_overlap * 0.5)


def tokenize(text: str) -> list[str]:
    return re.findall(r"\b[a-zA-Z]{3,}\b", text.lower())


def classify_intent(text: str) -> str:
    lowered = text.lower()
    transactional_terms = {"buy", "price", "order", "download", "deal", "coupon"}
    navigational_terms = {"login", "homepage", "official", "site", "forum"}
    commercial_terms = {"best", "top", "compare", "review", "vs"}

    if any(term in lowered for term in transactional_terms):
        return "transactional"
    if any(term in lowered for term in navigational_terms):
        return "navigational"
    if any(term in lowered for term in commercial_terms):
        return "commercial"
    return "informational"


def tfidf_similarity(source_text: str, candidate_texts: list[str]) -> list[float]:
    source_tokens = tokenize(source_text)
    documents = [source_tokens] + [tokenize(text) for text in candidate_texts]
    total_docs = len(documents)

    df: dict[str, int] = {}
    for doc in documents:
        for token in set(doc):
            df[token] = df.get(token, 0) + 1

    idf = {
        token: math.log((total_docs + 1) / (freq + 1)) + 1.0
        for token, freq in df.items()
    }

    def to_vector(tokens: list[str]) -> dict[str, float]:
        counts = Counter(tokens)
        size = len(tokens) or 1
        return {
            token: (count / size) * idf.get(token, 0.0)
            for token, count in counts.items()
        }

    def cosine(a: dict[str, float], b: dict[str, float]) -> float:
        common = set(a).intersection(b)
        if not common:
            return 0.0
        dot = sum(a[token] * b[token] for token in common)
        mag_a = math.sqrt(sum(v * v for v in a.values()))
        mag_b = math.sqrt(sum(v * v for v in b.values()))
        if mag_a == 0.0 or mag_b == 0.0:
            return 0.0
        return dot / (mag_a * mag_b)

    source_vector = to_vector(source_tokens)
    return [
        round(cosine(source_vector, to_vector(tokens)), 4) for tokens in documents[1:]
    ]


def _is_excluded(source_url: str, target_url: str, keyword: str) -> bool:
    exclusions = InterlinkExclusion.objects.filter(is_active=True)
    for exclusion in exclusions:
        phrase_match = exclusion.phrase.lower() in keyword.lower()
        source_match = (
            not exclusion.source_pattern or exclusion.source_pattern in source_url
        )
        target_match = (
            not exclusion.target_pattern or exclusion.target_pattern in target_url
        )
        if phrase_match and source_match and target_match:
            return True
    return False


def suggest_links(
    source: LinkableEntity, candidates: list[LinkableEntity], limit: int = 5
):
    """
    Keyword-first suggestions with stability: we do not churn locked suggestions,
    cap updates to the provided limit, and order by simple similarity scoring.
    """
    if not feature_flags.seo_enabled() or not feature_flags.auto_linking_enabled():
        return

    allowed = _eligible_candidates(source, candidates)
    LinkSuggestion.objects.filter(source=source, locked=False).delete()

    ranked = sorted(allowed, key=lambda t: _score_candidate(source, t), reverse=True)
    added = 0
    for target in ranked:
        if added >= limit:
            break
        score = _score_candidate(source, target)
        LinkSuggestion.objects.update_or_create(
            source=source,
            target=target,
            defaults={"score": score, "is_applied": False, "locked": False},
        )
        added += 1


def generate_interlink_suggestions(source: LinkableEntity, limit: int = 10) -> int:
    candidates = list(
        LinkableEntity.objects.filter(is_active=True).exclude(pk=source.pk)
    )
    if not candidates:
        return 0

    source_text = f"{source.title} {' '.join(source.keywords or [])}"
    candidate_texts = [
        f"{item.title} {' '.join(item.keywords or [])}" for item in candidates
    ]
    scores = tfidf_similarity(source_text, candidate_texts)

    LinkSuggestion.objects.filter(source=source, locked=False).delete()

    created = 0
    ranked = sorted(
        zip(candidates, scores, strict=True), key=lambda row: row[1], reverse=True
    )
    for target, score in ranked:
        if created >= limit:
            break
        if _is_excluded(source.url, target.url, source.title):
            continue
        if score < 0.12:
            continue
        LinkSuggestion.objects.update_or_create(
            source=source,
            target=target,
            defaults={
                "score": score,
                "is_applied": False,
                "locked": False,
                "is_active": True,
            },
        )
        created += 1

    return created
