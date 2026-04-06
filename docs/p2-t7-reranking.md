# P2-T7: Add Reranking Layer and Compare Results

> **Goal:** Add a second pass over your search results that re-orders them by actual relevance to the question — not just vector similarity — and verify with your test questions whether it improves retrieval.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 5
**Labels:** `task`, `p2-rag`

---

## What you are doing

Vector similarity search (P2-T6) finds chunks that are *topically near* your question. But "near in vector space" does not always mean "actually answers the question." Reranking is a second pass that asks the question again, more carefully.

**Two-stage retrieval:**

```
Stage 1 — Vector search (fast, approximate):
  "Give me the 20 most similar chunks to this question"
  → Fast. Good at broad recall.
  → Can return chunks that share topics but miss the specific answer.

Stage 2 — Reranker (slower, precise):
  "Of these 20 chunks, which ones ACTUALLY answer the question?"
  → Slower. Good at precision.
  → Re-scores and re-ranks by true relevance.
  → You keep only the top 5.
```

---

## Why retrieval does not equal relevance

Here is a concrete example:

```
Question: "What transition time is set for the hallway light?"

Vector search results (ranked by similarity):
  #1 score=0.91 — "Automation: Hallway Motion Light. Triggers when
                   binary_sensor.hallway_motion changes to 'on'..."
  #2 score=0.88 — "Action: light.turn_on on light.hallway.
                   Transition: 2 seconds. Brightness: 128."
  #3 score=0.85 — "Automation: Morning Coffee. Weekdays at 7am..."

The TOP result (0.91) is about the hallway automation but does NOT contain
the transition time. Result #2 has the actual answer.

After reranking (by "does this chunk answer the question?"):
  #1 score=0.96 — "Transition: 2 seconds. Brightness: 128."  ← MOVED UP
  #2 score=0.71 — "Automation: Hallway Motion Light..."
  #3 score=0.12 — "Morning Coffee..."                         ← DROPPED
```

The reranker catches this because it reads the question and each chunk together, not independently.

---

## Prerequisites

- [ ] [P2-T6](p2-t6-similarity-search.md) complete — similarity search working
- [ ] `search.py` working and tuned

---

## Step-by-step instructions

### Step 1 — Understand how reranking works

A **cross-encoder reranker** reads (question + chunk) together and outputs a single relevance score. This is different from an embedding model, which encodes question and chunk independently.

```
Embedding model (bi-encoder):
  embed("my question")    → vector A
  embed("the chunk text") → vector B
  similarity(A, B)        → score

  ✓ Fast (embeddings are precomputed)
  ✗ Question and chunk never interact directly

Cross-encoder reranker:
  score("my question", "the chunk text")  → relevance score

  ✓ Question and chunk interact directly → much more accurate
  ✗ Slower (cannot precompute; must run for every (question, chunk) pair)
```

This is why reranking is a second pass — you use the fast bi-encoder to get candidates, then the slower cross-encoder to pick the best ones.

---

### Step 2 — Install the reranking library

```bash
pip install sentence-transformers
```

Add to `requirements.txt`:

```
sentence-transformers==2.7.0
```

Note: `sentence-transformers` downloads a cross-encoder model from HuggingFace. For a fully offline setup, download the model first:

```bash
# Download the model once (while you have internet access)
python -c "
from sentence_transformers import CrossEncoder
CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
print('Model downloaded and cached.')
"
```

The model will be cached in `~/.cache/huggingface/` and can be used offline after that.

---

### Step 3 — Create the reranker module

Create `~/projects/rag-brain/reranker.py`:

```python
"""
Reranking Module

Takes the output of similarity search and re-scores each chunk
by how well it actually answers the question.

Uses a cross-encoder model that reads (question + chunk) together.
"""
from sentence_transformers import CrossEncoder

# ─── Configuration ────────────────────────────────────────────────────────────
# This model is small and fast — good for homelab use.
# It is the standard model for passage reranking.
RERANKER_MODEL = "cross-encoder/ms-marco-MiniLM-L-6-v2"

# How many results to keep after reranking
DEFAULT_TOP_N = 5
# ─────────────────────────────────────────────────────────────────────────────

_reranker = None


def _get_reranker() -> CrossEncoder:
    """Get reranker model (lazy init, cached)."""
    global _reranker
    if _reranker is None:
        print("Loading reranker model (first time only)...")
        _reranker = CrossEncoder(RERANKER_MODEL)
        print("Reranker model loaded.")
    return _reranker


def rerank(query: str, results: list[dict], top_n: int = DEFAULT_TOP_N) -> list[dict]:
    """
    Rerank search results by cross-encoder relevance score.

    Args:
        query:   The user's original question.
        results: Output from search.search() — list of result dicts.
        top_n:   How many results to return after reranking.

    Returns:
        Top N results sorted by reranker score (highest first).
        Each dict gains a 'rerank_score' key.
    """
    if not results:
        return []

    reranker = _get_reranker()

    # Create (question, chunk) pairs for the cross-encoder
    pairs = [(query, r["text"]) for r in results]

    # Get relevance scores for each pair
    scores = reranker.predict(pairs)

    # Attach rerank scores to results
    for result, score in zip(results, scores):
        result["rerank_score"] = float(score)
        # Normalize to 0-1 range for readability
        # Cross-encoder scores are logits (can be any value)
        # We will keep the raw score and also add it to the result

    # Sort by rerank score, highest first
    reranked = sorted(results, key=lambda r: r["rerank_score"], reverse=True)

    # Return top N
    return reranked[:top_n]


def rerank_with_comparison(query: str, results: list[dict], top_n: int = DEFAULT_TOP_N) -> dict:
    """
    Rerank and return a comparison showing before/after order.
    Useful for understanding what reranking changed.
    """
    if not results:
        return {"before": [], "after": [], "changed": False}

    reranker = _get_reranker()
    pairs = [(query, r["text"]) for r in results]
    scores = reranker.predict(pairs)

    # Record original order
    before = [
        {"rank": i + 1, "source": r["source"], "score": r["score"]}
        for i, r in enumerate(results)
    ]

    # Apply rerank
    for result, score in zip(results, scores):
        result["rerank_score"] = float(score)

    reranked = sorted(results, key=lambda r: r["rerank_score"], reverse=True)[:top_n]

    # Record new order
    after = [
        {"rank": i + 1, "source": r["source"], "rerank_score": round(r["rerank_score"], 3)}
        for i, r in enumerate(reranked)
    ]

    # Did the order change?
    changed = [b["source"] for b in before[:top_n]] != [a["source"] for a in after]

    return {"before": before, "after": after, "changed": changed, "results": reranked}
```

---

### Step 4 — Test reranking

Create `~/projects/rag-brain/test_reranker.py`:

```python
"""
Test the reranker.
Run: python test_reranker.py
"""
from search import search
from reranker import rerank, rerank_with_comparison

# Test with one of your known questions
query = "what transition time is set for the hallway light?"

print(f"Query: {query}")
print("=" * 60)

# Get initial search results (retrieve more than needed so reranker has candidates)
initial_results = search(query, top_k=10, min_score=0.5)

if not initial_results:
    print("No results from vector search. Check your documents are ingested.")
    print("Try lowering min_score to 0.5 for this test.")
else:
    print(f"Vector search returned {len(initial_results)} results")

    # Show before
    print("\nBEFORE reranking (vector similarity order):")
    for i, r in enumerate(initial_results[:5]):
        print(f"  #{i+1} score={r['score']}  {r['source']}")
        print(f"       {r['text'][:100].replace(chr(10), ' ')}...")

    # Rerank
    comparison = rerank_with_comparison(query, initial_results, top_n=5)

    # Show after
    print("\nAFTER reranking (cross-encoder relevance order):")
    for r in comparison["after"]:
        print(f"  #{r['rank']} rerank_score={r['rerank_score']}  {r['source']}")

    if comparison["changed"]:
        print("\n*** ORDER CHANGED — reranking made a difference ***")
    else:
        print("\n(Order did not change for this query)")

    print("\nTop result text after reranking:")
    if comparison["results"]:
        print(comparison["results"][0]["text"][:300])
```

```bash
python test_reranker.py
```

---

### Step 5 — Run the comparison experiment

Re-run your 10 test questions from P2-T4, this time comparing vector search alone vs. vector search + reranking. Create `~/projects/rag-brain/reranking_experiment.py`:

```python
"""
Reranking experiment: compare retrieval with and without reranking.
Run: python reranking_experiment.py
"""
from search import search
from reranker import rerank

# Use the same 10 questions from P2-T4
TEST_QUESTIONS = [
    {
        "q": "Which automation turns on the hallway light?",
        "expected_keywords": ["hallway", "motion", "light"],
    },
    {
        "q": "What entity does the coffee maker automation use?",
        "expected_keywords": ["coffee_maker", "switch"],
    },
    {
        "q": "Which n8n workflow sends Telegram messages?",
        "expected_keywords": ["telegram", "GroceryTracker"],
    },
    # Add your remaining 7 questions here
]


def top_result_passes(results: list[dict], expected_keywords: list[str]) -> bool:
    """Check if the top result contains any expected keyword."""
    if not results:
        return False
    top_text = results[0]["text"].lower()
    return any(kw.lower() in top_text for kw in expected_keywords)


print("RERANKING EXPERIMENT")
print("=" * 70)
print(f"{'Question':<45} {'Vector':^10} {'Reranked':^10}")
print("-" * 70)

vector_total = 0
rerank_total = 0

for test in TEST_QUESTIONS:
    q = test["q"]
    keywords = test["expected_keywords"]

    # Vector search only
    vector_results = search(q, top_k=10, min_score=0.5)
    vector_pass = top_result_passes(vector_results, keywords)

    # Vector search + reranking
    reranked_results = rerank(q, vector_results, top_n=5)
    rerank_pass = top_result_passes(reranked_results, keywords)

    vector_total += vector_pass
    rerank_total += rerank_pass

    q_short = q[:43] + ".." if len(q) > 43 else q
    v_mark = "PASS" if vector_pass else "FAIL"
    r_mark = "PASS" if rerank_pass else "FAIL"
    print(f"{q_short:<45} {v_mark:^10} {r_mark:^10}")

total = len(TEST_QUESTIONS)
print("-" * 70)
print(f"{'SCORE':<45} {vector_total}/{total}     {rerank_total}/{total}")
print(f"\nReranking improvement: {rerank_total - vector_total} additional passes")
```

```bash
python reranking_experiment.py
```

---

### Step 6 — Wire reranking into the search pipeline

Update `search.py` to export a combined function:

```python
# Add to search.py

from reranker import rerank as _rerank


def search_and_rerank(
    query: str,
    retrieve_k: int = 20,
    return_top_n: int = 5,
    min_score: float = 0.5,  # lower threshold at retrieval stage, reranker filters
) -> list[dict]:
    """
    Full retrieval pipeline: vector search → reranking → top N results.

    Args:
        query:       The user's question.
        retrieve_k:  How many candidates to retrieve (before reranking).
        return_top_n: How many results to return (after reranking).
        min_score:   Minimum vector similarity to even send to reranker.
                     Use a lower value here (0.5) since reranker will filter.

    Returns:
        Top N results sorted by reranker score.
    """
    # Stage 1: broad vector search
    candidates = search(query, top_k=retrieve_k, min_score=min_score)

    if not candidates:
        return []

    # Stage 2: precise reranking
    return _rerank(query, candidates, top_n=return_top_n)
```

---

## Visual overview

```
User question: "What transition time is set for the hallway light?"
         │
         ▼ Stage 1: Vector search (fast)
     top 20 candidates by vector similarity
┌────────────────────────────────────────────────────┐
│  #1  0.91  automations.yaml  "Hallway Motion..."   │
│  #2  0.88  automations.yaml  "Transition: 2 sec..."│
│  #3  0.85  automations.yaml  "Morning Coffee..."   │
│  ...17 more candidates...                          │
└────────────────────────────────────────────────────┘
         │
         ▼ Stage 2: Cross-encoder reranking (slower, more precise)
     reads (question + each chunk) together
┌────────────────────────────────────────────────────┐
│  #1  0.96  automations.yaml  "Transition: 2 sec..."│ ← moved up!
│  #2  0.71  automations.yaml  "Hallway Motion..."   │ ← moved down
│  #3  0.12  automations.yaml  "Morning Coffee..."   │ ← very low relevance
│  (rest dropped)                                    │
└────────────────────────────────────────────────────┘
         │
         ▼ Top 5 results passed to answer generation (P2-T8)
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"Why does retrieval by vector similarity not equal retrieval by relevance? Give a concrete example from YOUR OWN experiment results where the order changed after reranking. What did you learn about when reranking helps most?"**
>
> Also record: did reranking improve your 10-question score? By how many questions?

---

## Done when

- [ ] `sentence-transformers` installed and `cross-encoder/ms-marco-MiniLM-L-6-v2` downloaded
- [ ] `reranker.py` created with `rerank()` and `rerank_with_comparison()`
- [ ] `python test_reranker.py` runs and shows before/after comparison
- [ ] `python reranking_experiment.py` runs and prints score table
- [ ] Reranking comparison experiment results recorded in build log
- [ ] `search_and_rerank()` added to `search.py`
- [ ] Learning checkpoint answered with a concrete example from your results

---

## Next step

→ [P2-T8: Build FastAPI query endpoint with source citation](p2-t8-query-endpoint.md)
