---
name: seo-interlinking-jaccard
description: "Jaccard similarity for related content. Use when: finding related pages by tag/keyword overlap, lightweight similarity without full text analysis."
---

# Jaccard Similarity for Related Content

## When to Use

- Finding related content by tag or keyword overlap
- Lightweight link suggestion without heavy TF-IDF computation
- Quick relatedness scoring for category/tag-based pages

## Rules

### Jaccard Similarity Function

```python
# apps/seo/services.py
def jaccard_similarity(set_a: set[str], set_b: set[str]) -> float:
    """Compute Jaccard index: |A ∩ B| / |A ∪ B|. Returns 0.0–1.0."""
    if not set_a and not set_b:
        return 0.0
    intersection = set_a & set_b
    union = set_a | set_b
    return len(intersection) / len(union) if union else 0.0
```

### Tag-Based Similarity

```python
def find_related_by_tags(
    page_tags: set[str],
    candidates: list[dict],
    top_n: int = 5,
    threshold: float = 0.2,
) -> list[dict]:
    """Find related pages by Jaccard similarity on tags.
    candidates: [{'id': 1, 'tags': {'python', 'django'}}]
    """
    results = []
    for candidate in candidates:
        score = jaccard_similarity(page_tags, candidate["tags"])
        if score >= threshold:
            results.append({"id": candidate["id"], "score": round(score, 4)})
    results.sort(key=lambda x: x["score"], reverse=True)
    return results[:top_n]
```

### Keyword-Based Similarity

```python
def find_related_by_keywords(page_id: int, top_n: int = 5) -> list[dict]:
    """Find related pages using keyword set overlap."""
    from apps.seo.models import Metadata
    source = Metadata.objects.filter(pk=page_id).first()
    if not source or not source.keywords:
        return []
    source_kw = {k.strip().lower() for k in source.keywords.split(",")}
    candidates = Metadata.objects.exclude(pk=page_id).exclude(keywords="")
    results = []
    for meta in candidates:
        cand_kw = {k.strip().lower() for k in meta.keywords.split(",")}
        score = jaccard_similarity(source_kw, cand_kw)
        if score > 0.1:
            results.append({"id": meta.pk, "path": meta.path, "score": round(score, 4)})
    results.sort(key=lambda x: x["score"], reverse=True)
    return results[:top_n]
```

### When Jaccard vs TF-IDF

| Method | Best For | Complexity |
|--------|---------|------------|
| Jaccard | Tag/keyword overlap, categorical match | O(n) per comparison |
| TF-IDF | Full text content similarity | O(n × m) tokens |
| Hybrid | Use Jaccard first to filter, then TF-IDF on top candidates | O(n) + O(k × m) |

### Hybrid Approach

```python
def find_related_hybrid(page_id: int, top_n: int = 5) -> list[dict]:
    """Pre-filter with Jaccard, refine with TF-IDF."""
    jaccard_results = find_related_by_keywords(page_id, top_n=20)
    if not jaccard_results:
        return []
    # Refine top 20 with TF-IDF
    from apps.seo.services import compute_tfidf_similarity
    # ... load content for top candidates, run TF-IDF
    return jaccard_results[:top_n]
```

## Anti-Patterns

- Comparing pages with no tags/keywords — Jaccard returns 0, use TF-IDF instead
- No threshold — always filter scores below 0.1
- Running Jaccard on full text instead of discrete sets

## Red Flags

- All scores are 0 (empty keyword fields)
- Self-comparison not excluded
- Unlimited candidate list (no `.only()` or limit)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
