# P2-T6: Implement Similarity Search with Score Threshold

> **Goal:** Build the search function that takes a question, converts it to a vector, finds the most similar chunks in ChromaDB, and filters out results that are not relevant enough.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 4–5
**Labels:** `task`, `p2-rag`

---

## What you are doing

You have documents embedded and stored in ChromaDB. Now you need to write the code that searches them. When a user asks a question, this search function:

1. Converts the question to a vector (using the same embedding model used during ingestion)
2. Asks ChromaDB: "find me the K vectors most similar to this one"
3. Filters out results that are below a relevance threshold
4. Returns the results with their scores — so you know how confident the retrieval is

The **score threshold** is important. ChromaDB always returns results, even if nothing in the database is actually relevant to your question. Without a threshold, you might feed the AI complete garbage as "context." With a threshold, you can say "only use results with at least 70% similarity."

---

## Why this step matters

This is the "R" in RAG — the **Retrieval** step. Everything before this was setup. The quality of retrieval determines the quality of the final answer. If retrieval finds the wrong chunks, the AI answers from wrong information, which looks like a hallucination but is actually a retrieval failure.

---

## Prerequisites

- [ ] [P2-T5](p2-t5-embedding-model.md) complete — embedding model configured and working
- [ ] Documents ingested into ChromaDB collection `rag_brain`
- [ ] `python ingest.py` completed successfully

---

## Step-by-step instructions

### Step 1 — Understand cosine distance vs. similarity score

ChromaDB returns a **distance** value, not a similarity score. The two are related:

```
similarity = 1 - distance

Distance = 0.0  → similarity = 1.0  → PERFECT match (identical text)
Distance = 0.3  → similarity = 0.7  → Good match
Distance = 0.5  → similarity = 0.5  → Mediocre match
Distance = 1.0  → similarity = 0.0  → No relationship at all
```

When you set `min_score = 0.7`, you are saying: "only keep results where similarity is at least 0.7."

---

### Step 2 — Create the search module

Create `~/projects/rag-brain/search.py`:

```python
"""
Similarity Search Module

Searches ChromaDB for chunks relevant to a given question.
Uses the same embedding model as ingestion (critical — must match).
"""
import os
import chromadb
from llama_index.core import Settings
from embeddings import get_embed_model

# ─── Configuration ────────────────────────────────────────────────────────────
CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = int(os.getenv("CHROMA_PORT", "8001"))
COLLECTION_NAME = "rag_brain"

# Tuning knobs:
# - top_k: how many candidates to retrieve before filtering
# - min_score: minimum similarity (0.0 to 1.0) to keep a result
#   Start at 0.7. If retrieval misses relevant docs: lower to 0.6
#   If retrieval returns too much garbage: raise to 0.75 or 0.8
DEFAULT_TOP_K = 10
DEFAULT_MIN_SCORE = 0.7
# ─────────────────────────────────────────────────────────────────────────────

# Initialize once (reused across calls)
_chroma_client = None
_collection = None
_embed_model = None


def _get_collection():
    """Get ChromaDB collection (lazy init, cached)."""
    global _chroma_client, _collection
    if _collection is None:
        _chroma_client = chromadb.HttpClient(host=CHROMA_HOST, port=CHROMA_PORT)
        _collection = _chroma_client.get_collection(COLLECTION_NAME)
    return _collection


def _get_embed_model():
    """Get embedding model (lazy init, cached)."""
    global _embed_model
    if _embed_model is None:
        _embed_model = get_embed_model()
    return _embed_model


def search(
    query: str,
    top_k: int = DEFAULT_TOP_K,
    min_score: float = DEFAULT_MIN_SCORE,
) -> list[dict]:
    """
    Search for chunks relevant to a query.

    Args:
        query:     The user's question in plain text.
        top_k:     How many candidates to retrieve from ChromaDB.
        min_score: Minimum similarity score (0.0 to 1.0) to include in results.
                   Results below this score are discarded.

    Returns:
        List of dicts, each containing:
            - text:     the chunk text
            - score:    similarity score (0.0 to 1.0, higher = more relevant)
            - source:   filename the chunk came from
            - metadata: all metadata from the original document
    """
    # 1. Convert the question to a vector using the SAME model as ingestion
    embed_model = _get_embed_model()
    query_vector = embed_model.get_text_embedding(query)

    # 2. Search ChromaDB
    collection = _get_collection()
    raw_results = collection.query(
        query_embeddings=[query_vector],
        n_results=top_k,
        include=["documents", "metadatas", "distances"],
    )

    # 3. Parse and filter results
    results = []
    documents = raw_results.get("documents", [[]])[0]
    metadatas = raw_results.get("metadatas", [[]])[0]
    distances = raw_results.get("distances", [[]])[0]

    for doc, meta, dist in zip(documents, metadatas, distances):
        # Convert distance to similarity score
        score = round(1.0 - dist, 4)

        # Filter out results below the threshold
        if score < min_score:
            continue

        results.append({
            "text": doc,
            "score": score,
            "source": meta.get("filename", "unknown"),
            "metadata": meta,
        })

    # Results from ChromaDB are already sorted by distance (best first)
    # After filtering, they remain sorted by score descending
    return results


def search_with_debug(query: str, top_k: int = 10) -> None:
    """
    Debug version: shows ALL results including those below threshold.
    Use this to tune your min_score value.
    """
    embed_model = _get_embed_model()
    query_vector = embed_model.get_text_embedding(query)

    collection = _get_collection()
    raw_results = collection.query(
        query_embeddings=[query_vector],
        n_results=top_k,
        include=["documents", "metadatas", "distances"],
    )

    documents = raw_results.get("documents", [[]])[0]
    metadatas = raw_results.get("metadatas", [[]])[0]
    distances = raw_results.get("distances", [[]])[0]

    print(f"\nQuery: {query}")
    print(f"Top {top_k} results (no filtering):")
    print("-" * 60)

    for i, (doc, meta, dist) in enumerate(zip(documents, metadatas, distances)):
        score = round(1.0 - dist, 4)
        source = meta.get("filename", "unknown")
        preview = doc[:120].replace("\n", " ") + ("..." if len(doc) > 120 else "")
        keep = "KEEP" if score >= DEFAULT_MIN_SCORE else "DROP"

        print(f"  #{i+1} [{keep}] score={score}  source={source}")
        print(f"       {preview}")

    print(f"\nThreshold: {DEFAULT_MIN_SCORE}")
    print(f"Results that would be kept: "
          f"{sum(1 for d in distances if (1.0 - d) >= DEFAULT_MIN_SCORE)}")
```

---

### Step 3 — Test the search function

Create `~/projects/rag-brain/test_search.py`:

```python
"""
Test the similarity search.
Run: python test_search.py
"""
from search import search, search_with_debug, DEFAULT_MIN_SCORE

# ─── Test 1: Basic search ─────────────────────────────────────────────────────
print("=" * 60)
print("TEST 1: Basic search")
print("=" * 60)

results = search("which automation controls the hallway light?")

if not results:
    print("No results above threshold. Try lowering min_score in search.py.")
else:
    print(f"Found {len(results)} results above score={DEFAULT_MIN_SCORE}:\n")
    for r in results:
        print(f"Score: {r['score']}  |  Source: {r['source']}")
        print(f"  {r['text'][:200].replace(chr(10), ' ')}")
        print()

# ─── Test 2: Debug view (see all results before filtering) ───────────────────
print("=" * 60)
print("TEST 2: Debug view (tune your threshold)")
print("=" * 60)

search_with_debug("which workflow sends telegram messages?", top_k=5)

# ─── Test 3: No-match query (should return empty list) ───────────────────────
print("\n" + "=" * 60)
print("TEST 3: Query with no match (should return empty or low-score results)")
print("=" * 60)

results_nomatch = search("what is the weather forecast for tomorrow?")
print(f"Results for unrelated query: {len(results_nomatch)}")
if not results_nomatch:
    print("Correctly returned no results for an unrelated question.")
```

```bash
python test_search.py
```

---

### Step 4 — Tune the score threshold

Run the debug view on several of your 10 test questions from P2-T4 and look at the score distribution:

```bash
python -c "
from search import search_with_debug
search_with_debug('which automation controls the hallway light?')
search_with_debug('which workflow handles telegram notifications?')
search_with_debug('what is the coffee maker automation condition?')
"
```

Use this guide to tune `DEFAULT_MIN_SCORE` in `search.py`:

```
You see:                              → Action:
─────────────────────────────────────────────────────────
Top result: 0.95, rest: 0.3-0.4      → Threshold is good. Keep 0.7.
All results: 0.5-0.6 (never 0.7+)    → Your docs might not match well.
                                         Try min_score=0.55 or check embedding.
Top 5 all: 0.9+                       → Threshold could go higher (0.8)
                                         to be more precise.
Getting empty results on good queries → Lower threshold: try 0.6
Getting irrelevant results returned   → Raise threshold: try 0.75 or 0.8
```

---

### Step 5 — Add a "no results" handler

You need the system to handle the case where nothing relevant is found. Update `search.py` at the bottom:

```python
def search_or_fallback(query: str, top_k: int = DEFAULT_TOP_K) -> tuple[list[dict], bool]:
    """
    Search and return a flag indicating if the results are usable.

    Returns:
        (results, has_results)
        - results: list of search results
        - has_results: False if nothing above threshold was found
    """
    results = search(query, top_k=top_k)
    return results, len(results) > 0
```

---

## Visual overview

```
User question: "which automation turns on the hallway light?"
         │
         ▼ embed_model.get_text_embedding(question)
Question vector: [0.24, -0.86, 0.39, ...]
         │
         ▼ collection.query(query_embeddings=[...], n_results=10)
ChromaDB returns 10 nearest vectors:
┌──────────────────────────────────────────────────────┐
│  #1  distance=0.08  score=0.92  ← KEEP  (above 0.7) │
│      source: automations.yaml                         │
│      text: "Automation: Hallway Motion Light..."     │
│                                                      │
│  #2  distance=0.21  score=0.79  ← KEEP               │
│      source: automations.yaml                         │
│      text: "...light.turn_on on light.hallway..."    │
│                                                      │
│  #3  distance=0.35  score=0.65  ← DROP  (below 0.7) │
│      source: morning-briefing.json                   │
│      text: "Workflow: MorningBriefing..."            │
│                                                      │
│  #4 ... more results ...                             │
└──────────────────────────────────────────────────────┘
         │
         │ filter: keep only score >= 0.7
         ▼
Filtered results: [result #1, result #2]
         │
         ▼ (passed to P2-T7 for reranking, then P2-T8 for answer generation)
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"You ran 3 test queries and tuned your threshold. What min_score value did you settle on? Show the before/after: what scores did your good results get vs. your garbage results? How did you decide where to draw the line?"**

---

## Done when

- [ ] `search.py` created with `search()`, `search_with_debug()`, and `search_or_fallback()` functions
- [ ] `python test_search.py` runs without errors
- [ ] Test 1 returns relevant results for a question about your documents
- [ ] Test 3 returns zero or very low-score results for an unrelated question
- [ ] `min_score` threshold tuned and documented in build log
- [ ] Learning checkpoint answered

---

## Next step

→ [P2-T7: Add reranking layer and compare results](p2-t7-reranking.md)
