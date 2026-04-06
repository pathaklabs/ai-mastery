# P2-T4: Implement and Compare 3 Chunking Strategies

> **Goal:** Learn what chunking is, implement three different ways to split documents, run a real experiment on your own files, and write down which strategy wins and why.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 4
**Labels:** `task`, `p2-rag`

---

## This is the most important learning task in P2

Chunking is *the* decision that most affects RAG quality. Most beginners skip it, use defaults, and then wonder why their system retrieves the wrong content. You are going to do a real experiment. The results will become part of your blog post.

---

## What is chunking?

When you load a document, it might be hundreds or thousands of words long. You cannot embed the whole thing and search it efficiently — the signal gets diluted.

Chunking = splitting a document into smaller pieces before embedding.

**Visual example:**

```
Original document (5,000 characters, too long):
───────────────────────────────────────────────
Home Assistant Automation Reference

## Motion Sensors
When motion is detected in the hallway, the light turns on.
This only triggers after sunset. The brightness is set to 50%.
The transition takes 2 seconds.

## Coffee Maker
The coffee maker automation runs on weekdays at 7am.
It requires the "morning mode" input boolean to be true.
The switch is entity switch.coffee_maker.

## Notification System
Alerts are sent via Telegram when the front door opens.
...
[continues for 4000 more characters]
───────────────────────────────────────────────

After chunking into 3 pieces:
───────────────────────────────────────────────
Chunk 1: "Home Assistant Automation Reference\n\n## Motion Sensors\n
          When motion is detected in the hallway, the light turns on.
          This only triggers after sunset..."
          [~512 tokens]

Chunk 2: "## Coffee Maker\nThe coffee maker automation runs on weekdays
          at 7am. It requires the 'morning mode' input boolean to be true.
          The switch is entity switch.coffee_maker..."
          [~512 tokens]

Chunk 3: "## Notification System\nAlerts are sent via Telegram when the
          front door opens..."
          [~512 tokens]
───────────────────────────────────────────────
```

Now when you ask "how does the motion sensor automation work?", the system can retrieve Chunk 1 specifically instead of the entire 5,000 character document.

---

## The 3 strategies you will implement

```
Strategy A: Fixed token chunks
──────────────────────────────
Split every 512 tokens. Always. With 50 token overlap between chunks.
  ✓ Simple and predictable
  ✓ Every chunk is the same size
  ✗ May cut in the middle of a sentence or idea
  ✗ The "coffee" automation might be split across two chunks

Strategy B: Sentence-based chunks
──────────────────────────────────
Split at sentence boundaries. Group sentences until ~512 tokens, then start a new chunk.
  ✓ Never cuts a sentence in half
  ✓ Each chunk contains complete thoughts
  ✗ Chunk sizes vary a lot (one long sentence = one chunk)
  ✗ No awareness of document structure (headings, sections)

Strategy C: Semantic / structural chunks
──────────────────────────────────────────
Split at headings (## or ###) or blank lines (paragraph breaks).
  ✓ Respects the document's own structure
  ✓ Each chunk is a logical section
  ✓ Best for structured docs (YAML converted to text, markdown)
  ✗ Chunk sizes are uneven and hard to predict
  ✗ A section could be very short (just a heading)
```

---

## Step-by-step instructions

### Step 1 — Pick your 10 test questions

Choose 10 questions about your own files where you know the exact answer. Write them in your build log. Examples:

```
Q1: "Which automation turns on the hallway light?"
Q2: "What entity does the coffee maker automation use?"
Q3: "Which workflow sends Telegram alerts?"
Q4: "Which workflow has a webhook trigger?"
Q5: "What happens when the front door sensor triggers?"
Q6: "Which automation only runs on weekdays?"
Q7: "What service does the hallway motion automation call?"
Q8: "Which n8n workflow handles the grocery list?"
Q9: "What is the transition time for the hallway light?"
Q10: "Which workflow has a Code node?"
```

Replace these with questions specific to YOUR files. The ground truth must be things you can look up yourself.

---

### Step 2 — Create the chunking strategies module

Create `~/projects/rag-brain/chunking.py`:

```python
"""
Chunking Strategies for RAG

Three strategies for splitting documents before embedding.
Each returns a list of LlamaIndex Document objects.
"""
from llama_index.core import Document
from llama_index.core.node_parser import (
    SentenceSplitter,
    SimpleNodeParser,
)
from llama_index.core.node_parser import SentenceSplitter
import re


# ─────────────────────────────────────────────────────────────────────────────
# Strategy A: Fixed token chunks (512 tokens, 50 overlap)
# ─────────────────────────────────────────────────────────────────────────────

def chunk_fixed(documents: list[Document]) -> list[Document]:
    """
    Strategy A: Split at fixed token intervals.
    chunk_size=512, chunk_overlap=50

    The overlap means the last 50 tokens of chunk N are repeated
    at the start of chunk N+1. This helps avoid losing context
    at chunk boundaries.
    """
    splitter = SentenceSplitter(
        chunk_size=512,
        chunk_overlap=50,
        paragraph_separator="\n\n",
    )

    nodes = splitter.get_nodes_from_documents(documents)

    # Convert nodes back to Documents (preserving metadata)
    chunks = []
    for i, node in enumerate(nodes):
        chunks.append(Document(
            text=node.text,
            metadata={
                **node.metadata,
                "chunk_strategy": "fixed_512",
                "chunk_index": i,
            }
        ))

    return chunks


# ─────────────────────────────────────────────────────────────────────────────
# Strategy B: Sentence-based chunks
# ─────────────────────────────────────────────────────────────────────────────

def chunk_sentences(documents: list[Document]) -> list[Document]:
    """
    Strategy B: Group sentences into chunks, not exceeding ~300 tokens each.
    Each chunk contains complete sentences — never cuts mid-sentence.
    """
    splitter = SentenceSplitter(
        chunk_size=300,
        chunk_overlap=30,
        # Use a small separator so it splits on sentences, not paragraphs
        paragraph_separator="\n",
    )

    nodes = splitter.get_nodes_from_documents(documents)

    chunks = []
    for i, node in enumerate(nodes):
        chunks.append(Document(
            text=node.text,
            metadata={
                **node.metadata,
                "chunk_strategy": "sentence_based",
                "chunk_index": i,
            }
        ))

    return chunks


# ─────────────────────────────────────────────────────────────────────────────
# Strategy C: Semantic / structural chunks (split on headings + blank lines)
# ─────────────────────────────────────────────────────────────────────────────

def _split_on_structure(text: str) -> list[str]:
    """
    Split text at markdown headings (##, ###) or double newlines (paragraph breaks).
    This preserves the document's own logical structure.
    """
    # Split on: heading lines (## something) or double blank lines
    pattern = r'(?=^#{1,3}\s+.+$)|(?:\n\n+)'

    raw_parts = re.split(pattern, text, flags=re.MULTILINE)

    # Clean up and filter empty parts
    parts = []
    for part in raw_parts:
        stripped = part.strip()
        if len(stripped) > 20:  # skip tiny fragments
            parts.append(stripped)

    return parts


def chunk_semantic(documents: list[Document]) -> list[Document]:
    """
    Strategy C: Split at headings and paragraph boundaries.
    Each chunk = one logical section of the document.

    Best for structured documents like:
    - YAML converted to readable text (has clear labels)
    - Markdown notes (has headings)
    - n8n workflow text (has "Workflow:", "Nodes:", "Flow:" sections)
    """
    chunks = []
    chunk_index = 0

    for doc in documents:
        parts = _split_on_structure(doc.text)

        if not parts:
            # Fallback: keep whole document as one chunk
            chunks.append(Document(
                text=doc.text,
                metadata={
                    **doc.metadata,
                    "chunk_strategy": "semantic",
                    "chunk_index": chunk_index,
                }
            ))
            chunk_index += 1
            continue

        for part in parts:
            chunks.append(Document(
                text=part,
                metadata={
                    **doc.metadata,
                    "chunk_strategy": "semantic",
                    "chunk_index": chunk_index,
                }
            ))
            chunk_index += 1

    return chunks


# ─────────────────────────────────────────────────────────────────────────────
# Utility: print chunk stats
# ─────────────────────────────────────────────────────────────────────────────

def print_chunk_stats(chunks: list[Document], strategy_name: str):
    """Print statistics about a set of chunks."""
    lengths = [len(c.text) for c in chunks]
    avg = sum(lengths) / len(lengths) if lengths else 0
    print(f"\n{strategy_name}:")
    print(f"  Total chunks:   {len(chunks)}")
    print(f"  Avg length:     {avg:.0f} chars")
    print(f"  Min length:     {min(lengths)} chars")
    print(f"  Max length:     {max(lengths)} chars")

    # Show first chunk as sample
    if chunks:
        print(f"  Sample chunk 1: {chunks[0].text[:150].replace(chr(10), ' ')}...")
```

---

### Step 3 — Create three separate ChromaDB collections (one per strategy)

Create `~/projects/rag-brain/ingest_chunking_experiment.py`:

```python
"""
Ingestion script for the chunking experiment.

Creates 3 separate ChromaDB collections — one per chunking strategy.
Run: python ingest_chunking_experiment.py
"""
import chromadb
from llama_index.core import VectorStoreIndex, StorageContext
from llama_index.vector_stores.chroma import ChromaVectorStore

from loaders.ha_loader import load_ha_yaml_folder
from loaders.n8n_loader import load_n8n_workflows_folder
from chunking import chunk_fixed, chunk_sentences, chunk_semantic, print_chunk_stats

# --- Load base documents ---
print("Loading documents...")
ha_docs = load_ha_yaml_folder("data/ha-yaml")
n8n_docs = load_n8n_workflows_folder("data/n8n-exports")
all_docs = ha_docs + n8n_docs
print(f"Loaded {len(all_docs)} documents total")

# --- Apply 3 chunking strategies ---
print("\nApplying chunking strategies...")
chunks_a = chunk_fixed(all_docs)
chunks_b = chunk_sentences(all_docs)
chunks_c = chunk_semantic(all_docs)

print_chunk_stats(chunks_a, "Strategy A: Fixed 512 tokens")
print_chunk_stats(chunks_b, "Strategy B: Sentence-based")
print_chunk_stats(chunks_c, "Strategy C: Semantic/structural")

# --- Connect to ChromaDB ---
chroma_client = chromadb.HttpClient(host="localhost", port=8001)

# --- Create one collection per strategy ---
strategies = [
    ("strategy_a_fixed", chunks_a),
    ("strategy_b_sentence", chunks_b),
    ("strategy_c_semantic", chunks_c),
]

for collection_name, chunks in strategies:
    print(f"\nIndexing into collection: {collection_name} ({len(chunks)} chunks)...")

    # Delete existing collection to start fresh
    try:
        chroma_client.delete_collection(collection_name)
        print(f"  Deleted existing collection: {collection_name}")
    except Exception:
        pass

    collection = chroma_client.get_or_create_collection(collection_name)
    vector_store = ChromaVectorStore(chroma_collection=collection)
    storage_context = StorageContext.from_defaults(vector_store=vector_store)

    VectorStoreIndex.from_documents(
        chunks,
        storage_context=storage_context,
        show_progress=True,
    )

    print(f"  Done. {collection.count()} vectors stored.")

print("\nChunking experiment ingestion complete.")
print("Collections created:")
print("  - strategy_a_fixed")
print("  - strategy_b_sentence")
print("  - strategy_c_semantic")
```

```bash
python ingest_chunking_experiment.py
```

---

### Step 4 — Create the experiment query runner

Create `~/projects/rag-brain/chunking_experiment.py`:

```python
"""
Chunking Experiment — Query Runner

Runs your 10 test questions against all 3 chunking strategies.
Prints results so you can score retrieval manually.

Run: python chunking_experiment.py
"""
import chromadb
from llama_index.core import VectorStoreIndex
from llama_index.vector_stores.chroma import ChromaVectorStore

# ─── Your 10 test questions ───────────────────────────────────────────────
# REPLACE THESE WITH YOUR OWN QUESTIONS AND EXPECTED ANSWERS
TEST_QUESTIONS = [
    {
        "q": "Which automation turns on the hallway light?",
        "expected_source": "automations.yaml",  # filename you expect to be cited
        "expected_keywords": ["hallway", "motion", "light"],  # words you expect in result
    },
    {
        "q": "What entity does the coffee maker automation use?",
        "expected_source": "automations.yaml",
        "expected_keywords": ["coffee_maker", "switch"],
    },
    {
        "q": "Which n8n workflow sends Telegram messages?",
        "expected_source": "grocery-tracker.json",
        "expected_keywords": ["telegram", "GroceryTracker"],
    },
    # Add your remaining 7 questions here...
    # {
    #     "q": "YOUR QUESTION",
    #     "expected_source": "EXPECTED_FILE",
    #     "expected_keywords": ["word1", "word2"],
    # },
]
# ─────────────────────────────────────────────────────────────────────────────


def query_collection(collection_name: str, question: str, top_k: int = 3) -> list[dict]:
    """Query a specific ChromaDB collection and return top results."""
    chroma_client = chromadb.HttpClient(host="localhost", port=8001)
    collection = chroma_client.get_collection(collection_name)

    results = collection.query(
        query_texts=[question],
        n_results=top_k,
        include=["documents", "metadatas", "distances"],
    )

    output = []
    for doc, meta, dist in zip(
        results["documents"][0],
        results["metadatas"][0],
        results["distances"][0],
    ):
        output.append({
            "text": doc,
            "source": meta.get("filename", "unknown"),
            "score": round(1 - dist, 3),  # convert distance to similarity
        })
    return output


def score_result(result: dict, expected_source: str, expected_keywords: list[str]) -> bool:
    """
    Simple scoring: did the top result come from the right file
    AND contain at least one expected keyword?
    """
    right_source = result["source"] == expected_source
    has_keyword = any(kw.lower() in result["text"].lower() for kw in expected_keywords)
    return right_source and has_keyword


def run_experiment():
    collections = [
        "strategy_a_fixed",
        "strategy_b_sentence",
        "strategy_c_semantic",
    ]

    print("=" * 70)
    print("CHUNKING EXPERIMENT RESULTS")
    print("=" * 70)

    # Results table
    results_table = []

    for test in TEST_QUESTIONS:
        question = test["q"]
        print(f"\nQuestion: {question}")
        print("-" * 50)

        row = {"question": question, "scores": {}}

        for collection_name in collections:
            try:
                results = query_collection(collection_name, question, top_k=1)
                if not results:
                    print(f"  {collection_name}: NO RESULTS")
                    row["scores"][collection_name] = False
                    continue

                top_result = results[0]
                passed = score_result(
                    top_result,
                    test["expected_source"],
                    test["expected_keywords"]
                )
                status = "PASS" if passed else "FAIL"
                row["scores"][collection_name] = passed

                print(f"  {collection_name}: {status} (score={top_result['score']})")
                print(f"    Source: {top_result['source']}")
                print(f"    Text:   {top_result['text'][:100].replace(chr(10), ' ')}...")

            except Exception as e:
                print(f"  {collection_name}: ERROR — {e}")
                row["scores"][collection_name] = False

        results_table.append(row)

    # Summary table
    print("\n" + "=" * 70)
    print("SUMMARY TABLE")
    print("=" * 70)
    print(f"{'Question':<45} {'A':^6} {'B':^6} {'C':^6}")
    print("-" * 70)

    totals = {"strategy_a_fixed": 0, "strategy_b_sentence": 0, "strategy_c_semantic": 0}
    for row in results_table:
        q_short = row["question"][:43] + ".." if len(row["question"]) > 43 else row["question"]
        a = "✓" if row["scores"].get("strategy_a_fixed") else "✗"
        b = "✓" if row["scores"].get("strategy_b_sentence") else "✗"
        c = "✓" if row["scores"].get("strategy_c_semantic") else "✗"
        print(f"{q_short:<45} {a:^6} {b:^6} {c:^6}")
        for k in totals:
            if row["scores"].get(k):
                totals[k] += 1

    total_questions = len(TEST_QUESTIONS)
    print("-" * 70)
    print(f"{'SCORE':<45} "
          f"{totals['strategy_a_fixed']}/{total_questions}  "
          f"{totals['strategy_b_sentence']}/{total_questions}  "
          f"{totals['strategy_c_semantic']}/{total_questions}")

    print("\nRecord these results in your build log.")
    print("Which strategy won? Write WHY you think that is.")


if __name__ == "__main__":
    run_experiment()
```

```bash
python chunking_experiment.py
```

---

### Step 5 — Fill in the results table in your build log

Copy this template into your build log and fill it in:

```
CHUNKING EXPERIMENT RESULTS
Date: ____________
Documents ingested: HA YAML (___ files), n8n workflows (___ files)

| Question                              | Strategy A | Strategy B | Strategy C |
|---------------------------------------|:----------:|:----------:|:----------:|
| Q1: _________________________________ |            |            |            |
| Q2: _________________________________ |            |            |            |
| Q3: _________________________________ |            |            |            |
| Q4: _________________________________ |            |            |            |
| Q5: _________________________________ |            |            |            |
| Q6: _________________________________ |            |            |            |
| Q7: _________________________________ |            |            |            |
| Q8: _________________________________ |            |            |            |
| Q9: _________________________________ |            |            |            |
| Q10: ________________________________ |            |            |            |
| **SCORE**                             |  __/10     |  __/10     |  __/10     |

Winner: Strategy ___ with ___/10

Why it won: _______________________________________________
```

---

### Step 6 — Apply the winning strategy to your main collection

Once you have your results, update `ingest.py` to use the winning chunking strategy:

```python
# In ingest.py, import and apply your winner
from chunking import chunk_semantic  # or chunk_fixed / chunk_sentences

# After loading documents:
all_chunks = chunk_semantic(all_docs)  # use your winning strategy

# Index the chunks instead of the raw docs:
index = VectorStoreIndex.from_documents(
    all_chunks,
    storage_context=storage_context,
    show_progress=True,
)
```

---

## Visual overview

```
Same documents, 3 different chunking approaches:

STRATEGY A (Fixed 512 tokens)
──────────────────────────────
"Automation: Hallway Motion Light\nDescription: Turn on hallway...
 ...condition: only after sunset\nAction: light.turn_on on light.hallway\n
 ---\nAutomation: Morning Coffee Routine\nDescription: Start coffee..."
[might split in the middle of an automation]

STRATEGY B (Sentence-based)
────────────────────────────
"Automation: Hallway Motion Light. Description: Turn on hallway light when motion detected."
"This only triggers after sunset. Brightness is set to 50%."
"The transition takes 2 seconds. Action calls service light.turn_on."
[each chunk = complete sentences]

STRATEGY C (Semantic / structural)
────────────────────────────────────
Chunk 1: "Automation: Hallway Motion Light
          Description: Turn on hallway light when motion detected
          Triggers: binary_sensor.hallway_motion → on
          Conditions: Sun after sunset
          Actions: light.turn_on on light.hallway"
[each chunk = one complete automation block]

For structured docs like HA YAML and n8n workflows, Strategy C
tends to win because each chunk = one meaningful unit.
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"Which strategy scored highest on YOUR data? Why do you think that strategy worked better for your specific document types? What would be different if your documents were long prose articles instead of structured configs?"**

---

## Done when

- [ ] 10 test questions written in build log with expected answers
- [ ] `ingest_chunking_experiment.py` runs and creates 3 ChromaDB collections
- [ ] `chunking_experiment.py` runs and prints a scores table
- [ ] Results table filled in (all 10 questions × 3 strategies)
- [ ] Winner identified and reasoning written in build log
- [ ] Winning strategy applied in `ingest.py`
- [ ] Experiment results saved — you will use them in the P2-C3 blog post

---

## Next step

→ [P2-T5: Set up local embedding model via Ollama](p2-t5-embedding-model.md)
