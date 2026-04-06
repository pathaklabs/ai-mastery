# P2-T5: Set Up Local Embedding Model via Ollama

> **Goal:** Replace the default embedding with a local model running on your homelab via Ollama, so your entire RAG system works without any internet connection or cloud API.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 4
**Labels:** `task`, `p2-rag`

---

## What you are doing

An **embedding model** converts text into a list of numbers (a vector). These numbers capture the *meaning* of the text — not just the words, but the concepts behind them.

Example:
```
"turn on the hallway light"   → [0.23, -0.87, 0.41, 0.09, ...]  (384 numbers)
"activate hallway illumination" → [0.25, -0.84, 0.39, 0.11, ...]  (similar numbers!)
"grocery shopping list"        → [-0.61, 0.33, -0.52, 0.78, ...]  (very different)
```

The embedding model is what makes semantic search possible — finding documents that are *about* the same thing, not just documents that contain the same words.

Until now, LlamaIndex has been using a default embedding. In this task, you will switch to a proper model running locally on Ollama.

---

## Why this step matters

The choice of embedding model affects:
- **Retrieval quality** — a better model understands more nuance
- **Embedding dimension** — how many numbers per vector (affects ChromaDB storage and search speed)
- **Local vs. cloud** — this system is designed to run entirely on your homelab

You will use `nomic-embed-text` (the most widely used local embedding model, 768 dimensions) or optionally `mxbai-embed-large` (1024 dimensions, slightly higher quality).

---

## Prerequisites

- [ ] [P2-T4](p2-t4-chunking-strategies.md) complete — chunking strategy decided
- [ ] Ollama running on your homelab
- [ ] Port 11434 accessible (Ollama's default port)

---

## Step-by-step instructions

### Step 1 — Answer the learning question in your build log

Before pulling any models, write your answer to:

> **"What is an embedding? Why does the choice of embedding model affect what your RAG system can retrieve?"**
>
> Specifically: if you embed documents with Model A and then query with Model B, what happens?

Write your answer now. You will verify it at the end of this task.

---

### Step 2 — Pull the embedding model on your homelab

SSH into your homelab (or run this locally if Ollama is on your dev machine):

```bash
# Pull nomic-embed-text (recommended starting point)
ollama pull nomic-embed-text

# Optional: also pull mxbai-embed-large for comparison
ollama pull mxbai-embed-large
```

Verify the models are available:

```bash
ollama list
```

Expected output (you should see both models listed):

```
NAME                       ID              SIZE    MODIFIED
nomic-embed-text:latest    0a109f422b47    274 MB  2 minutes ago
mxbai-embed-large:latest   819c2adf5ce6    669 MB  1 minute ago
llama3:latest              365c0bd3c000    4.7 GB  5 days ago
```

---

### Step 3 — Test the embedding model directly

Before wiring it into LlamaIndex, verify Ollama can embed text:

```bash
# Test embedding via Ollama's HTTP API
curl http://YOUR_HOMELAB_IP:11434/api/embeddings \
  -d '{
    "model": "nomic-embed-text",
    "prompt": "turn on the hallway light"
  }'
```

You should get back a JSON response with an `embedding` array of 768 numbers:

```json
{
  "embedding": [0.23, -0.87, 0.41, ..., 0.09]
}
```

If that works, Ollama is ready.

---

### Step 4 — Create the embedding configuration module

Create `~/projects/rag-brain/embeddings.py`:

```python
"""
Embedding model configuration.

All RAG components (ingest + query) must use the SAME embedding model.
If you change the model, you must re-ingest all documents.
"""
import os
from llama_index.embeddings.ollama import OllamaEmbedding

# ─── Configuration ────────────────────────────────────────────────────────────
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

# IMPORTANT: Use the same model for ingestion AND querying.
# If you change this, delete your ChromaDB collections and re-ingest.
EMBEDDING_MODEL = "nomic-embed-text"

# Model info (for reference)
EMBEDDING_DIMENSIONS = {
    "nomic-embed-text": 768,
    "mxbai-embed-large": 1024,
    "all-minilm": 384,
}
# ─────────────────────────────────────────────────────────────────────────────


def get_embed_model() -> OllamaEmbedding:
    """
    Return the configured embedding model.
    Call this once and reuse the instance.
    """
    return OllamaEmbedding(
        model_name=EMBEDDING_MODEL,
        base_url=OLLAMA_HOST,
        # embed_batch_size: how many texts to embed in one API call
        # Increase if ingestion is slow; decrease if you get timeouts
        embed_batch_size=10,
    )


def test_embedding(text: str = "test sentence for homelab RAG system") -> list[float]:
    """
    Quick test: embed a string and return the vector.
    Useful for verifying the model is working before full ingestion.
    """
    embed_model = get_embed_model()
    embedding = embed_model.get_text_embedding(text)
    return embedding
```

---

### Step 5 — Test the embedding module

Create `~/projects/rag-brain/test_embeddings.py`:

```python
"""
Test the embedding model connection.
Run: python test_embeddings.py
"""
from embeddings import get_embed_model, EMBEDDING_MODEL

print(f"Testing embedding model: {EMBEDDING_MODEL}")
print("Connecting to Ollama...")

embed_model = get_embed_model()

# Test 1: basic embedding
print("\nTest 1: Basic embedding")
vec = embed_model.get_text_embedding("turn on the hallway light")
print(f"  Input: 'turn on the hallway light'")
print(f"  Output: {len(vec)}-dimensional vector")
print(f"  First 5 values: {[round(v, 4) for v in vec[:5]]}")

# Test 2: semantic similarity check
print("\nTest 2: Semantic similarity check")
vec_a = embed_model.get_text_embedding("turn on the hallway light")
vec_b = embed_model.get_text_embedding("activate hallway illumination")
vec_c = embed_model.get_text_embedding("grocery shopping list")

# Compute cosine similarity manually
def cosine_similarity(a, b):
    dot = sum(x * y for x, y in zip(a, b))
    mag_a = sum(x**2 for x in a) ** 0.5
    mag_b = sum(x**2 for x in b) ** 0.5
    return dot / (mag_a * mag_b) if mag_a and mag_b else 0.0

sim_ab = cosine_similarity(vec_a, vec_b)
sim_ac = cosine_similarity(vec_a, vec_c)

print(f"  'hallway light' vs 'hallway illumination': {sim_ab:.3f}  (should be HIGH, ~0.8+)")
print(f"  'hallway light' vs 'grocery shopping':     {sim_ac:.3f}  (should be LOW, ~0.3)")

# Test 3: batch embedding
print("\nTest 3: Batch embedding")
texts = ["first sentence", "second sentence", "third sentence"]
vecs = embed_model.get_text_embedding_batch(texts)
print(f"  Embedded {len(vecs)} texts in one call")
print(f"  Each vector: {len(vecs[0])} dimensions")

print("\nAll tests passed. Embedding model is working.")
```

```bash
python test_embeddings.py
```

Expected output:

```
Testing embedding model: nomic-embed-text
Connecting to Ollama...

Test 1: Basic embedding
  Input: 'turn on the hallway light'
  Output: 768-dimensional vector
  First 5 values: [0.0231, -0.8741, 0.4103, 0.0921, -0.3341]

Test 2: Semantic similarity check
  'hallway light' vs 'hallway illumination': 0.847  (should be HIGH, ~0.8+)
  'hallway light' vs 'grocery shopping':     0.312  (should be LOW, ~0.3)

Test 3: Batch embedding
  Embedded 3 texts in one call
  Each vector: 768 dimensions

All tests passed. Embedding model is working.
```

The key check is Test 2 — similar sentences should score much higher than unrelated ones.

---

### Step 6 — Wire the embedding model into the ingestion pipeline

Update `~/projects/rag-brain/ingest.py` to use the local embedding model:

```python
"""
Ingestion script with local embedding model.
Run: python ingest.py
"""
import chromadb
from llama_index.core import VectorStoreIndex, StorageContext, Settings
from llama_index.vector_stores.chroma import ChromaVectorStore

from loaders.ha_loader import load_ha_yaml_folder
from loaders.n8n_loader import load_n8n_workflows_folder
from embeddings import get_embed_model
from chunking import chunk_semantic  # or your winning strategy from P2-T4

# ─── IMPORTANT: Set the embedding model globally ──────────────────────────────
# LlamaIndex uses Settings.embed_model everywhere.
# This MUST match what you use at query time.
embed_model = get_embed_model()
Settings.embed_model = embed_model
# ─────────────────────────────────────────────────────────────────────────────

# --- Connect to ChromaDB ---
chroma_client = chromadb.HttpClient(host="localhost", port=8001)

# --- Load documents ---
print("Loading documents...")
ha_docs = load_ha_yaml_folder("data/ha-yaml")
n8n_docs = load_n8n_workflows_folder("data/n8n-exports")
all_docs = ha_docs + n8n_docs
print(f"Loaded {len(all_docs)} documents")

# --- Apply chunking strategy ---
print("Chunking documents...")
chunks = chunk_semantic(all_docs)  # use your winning strategy
print(f"Created {len(chunks)} chunks")

# --- Store in ChromaDB ---
# Delete and recreate to ensure consistency with new embedding model
try:
    chroma_client.delete_collection("rag_brain")
    print("Deleted existing 'rag_brain' collection")
except Exception:
    pass

collection = chroma_client.get_or_create_collection("rag_brain")
vector_store = ChromaVectorStore(chroma_collection=collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

print(f"\nEmbedding and indexing {len(chunks)} chunks...")
print("This may take a few minutes the first time...")

index = VectorStoreIndex.from_documents(
    chunks,
    storage_context=storage_context,
    show_progress=True,
)

count = collection.count()
print(f"\nIngestion complete.")
print(f"  Chunks indexed: {count}")
print(f"  Embedding model: nomic-embed-text")
print(f"  Collection: rag_brain")
```

```bash
# This will take longer than before — it's now actually embedding with nomic-embed-text
python ingest.py
```

---

## Visual overview

```
Text → Embedding model → Vector

"turn on hallway light"
         │
         ▼  OllamaEmbedding(nomic-embed-text)
         │  HTTP call to http://homelab:11434/api/embeddings
         ▼
[0.231, -0.874, 0.410, 0.092, ..., 0.341]   ← 768 numbers
         │
         ▼  stored in ChromaDB
Vector database can now find similar vectors for any query

─────────────────────────────────────────────────────────

IMPORTANT: Same model must be used for BOTH ingest and query

  Ingest time:              Query time:
  "hallway light" ──────► [0.23, -0.87, ...]  stored
  "your question" ──────► [0.24, -0.85, ...]  ← finds the stored vector!

  If you used different models:
  Ingest: model-A("hallway light") ─► [0.23, -0.87, ...]  stored
  Query:  model-B("hallway light") ─► [0.91,  0.44, ...]  COMPLETELY DIFFERENT
  Result: retrieval completely fails
```

---

## Which model to choose?

| Model | Dimensions | Size | Speed | Quality |
|-------|-----------|------|-------|---------|
| `nomic-embed-text` | 768 | 274 MB | Fast | Good |
| `mxbai-embed-large` | 1024 | 669 MB | Medium | Better |
| `all-minilm` | 384 | 46 MB | Very fast | OK for simple use |

For this project: **start with `nomic-embed-text`**. It is the best balance of quality and speed on a homelab.

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"Before this task, you wrote a guess about what an embedding is and why model choice matters. Now that you have run the similarity test (Test 2), was your guess correct? What surprised you about the similarity scores?"**
>
> Also write: what would happen to your existing ChromaDB vectors if you switched from `nomic-embed-text` to `mxbai-embed-large` without re-ingesting?

---

## Done when

- [ ] `ollama pull nomic-embed-text` completes on homelab
- [ ] `ollama list` shows `nomic-embed-text`
- [ ] `curl` to Ollama embeddings endpoint returns a vector
- [ ] `python test_embeddings.py` passes all 3 tests
- [ ] Similar sentences score noticeably higher than unrelated sentences
- [ ] `ingest.py` updated to use `get_embed_model()` and `Settings.embed_model`
- [ ] `python ingest.py` completes and ChromaDB shows correct chunk count
- [ ] Learning checkpoint answered in build log

---

## Next step

→ [P2-T6: Implement similarity search with score threshold](p2-t6-similarity-search.md)
