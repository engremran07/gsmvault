---
name: seo-interlinking-tfidf
description: "TF-IDF based internal link suggestion. Use when: computing content similarity for link suggestions, building LinkSuggestion records, text-based relatedness scoring."
---

# TF-IDF Internal Link Suggestion

## When to Use

- Computing content similarity between pages for link suggestions
- Building `LinkSuggestion` records based on text analysis
- Finding related content without manual curation

## Rules

### TF-IDF Similarity Service

```python
# apps/seo/services.py
import math
from collections import Counter

def compute_tfidf_similarity(
    source_text: str,
    candidates: list[dict[str, str]],
    top_n: int = 5,
) -> list[dict[str, float]]:
    """Compute TF-IDF cosine similarity between source and candidates.
    candidates: [{'id': '1', 'text': '...'}]
    Returns sorted list of {'id': ..., 'score': 0.0-1.0}.
    """
    all_docs = [source_text] + [c["text"] for c in candidates]
    # Tokenize
    tokenized = [_tokenize(doc) for doc in all_docs]
    # Build IDF
    idf = _compute_idf(tokenized)
    # Compute TF-IDF vectors
    source_vec = _tfidf_vector(tokenized[0], idf)
    results = []
    for i, candidate in enumerate(candidates):
        cand_vec = _tfidf_vector(tokenized[i + 1], idf)
        score = _cosine_similarity(source_vec, cand_vec)
        results.append({"id": candidate["id"], "score": round(score, 4)})
    results.sort(key=lambda x: x["score"], reverse=True)
    return results[:top_n]

def _tokenize(text: str) -> list[str]:
    import re
    return re.findall(r"\b[a-z]{3,}\b", text.lower())

def _compute_idf(docs: list[list[str]]) -> dict[str, float]:
    n = len(docs)
    df: dict[str, int] = {}
    for doc in docs:
        for word in set(doc):
            df[word] = df.get(word, 0) + 1
    return {word: math.log(n / count) for word, count in df.items()}

def _tfidf_vector(tokens: list[str], idf: dict[str, float]) -> dict[str, float]:
    tf = Counter(tokens)
    total = len(tokens) or 1
    return {word: (count / total) * idf.get(word, 0) for word, count in tf.items()}

def _cosine_similarity(a: dict[str, float], b: dict[str, float]) -> float:
    keys = set(a) & set(b)
    if not keys:
        return 0.0
    dot = sum(a[k] * b[k] for k in keys)
    mag_a = math.sqrt(sum(v**2 for v in a.values()))
    mag_b = math.sqrt(sum(v**2 for v in b.values()))
    if mag_a == 0 or mag_b == 0:
        return 0.0
    return dot / (mag_a * mag_b)
```

### Creating LinkSuggestions

```python
def generate_link_suggestions(page_id: int, threshold: float = 0.15) -> int:
    """Generate LinkSuggestion records for a page using TF-IDF."""
    from apps.seo.models import LinkableEntity, LinkSuggestion
    source = LinkableEntity.objects.get(pk=page_id)
    candidates = LinkableEntity.objects.exclude(pk=page_id).values("pk", "content_preview")
    cand_list = [{"id": str(c["pk"]), "text": c["content_preview"] or ""} for c in candidates]
    results = compute_tfidf_similarity(source.content_preview or "", cand_list)
    created = 0
    for r in results:
        if r["score"] >= threshold:
            LinkSuggestion.objects.get_or_create(
                source_id=page_id, target_id=int(r["id"]),
                defaults={"score": r["score"], "method": "tfidf"},
            )
            created += 1
    return created
```

## Anti-Patterns

- Running TF-IDF on every request — use Celery task or batch
- No minimum token length — filter words < 3 chars
- Missing stopword removal — filter common words

## Red Flags

- Similarity score always 0 (empty content or bad tokenization)
- Suggesting links to the same page (self-link)
- No threshold — always filter scores below 0.1

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
