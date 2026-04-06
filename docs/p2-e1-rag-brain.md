# P2-E1: RAG Brain — Personal Knowledge System

> **Epic goal:** Build a system that lets you ask questions in plain English and get answers from YOUR OWN files — with citations and hallucination detection.

**Weeks:** 3–6
**Labels:** `epic`, `p2-rag`
**Stack:** Python + LlamaIndex + ChromaDB + Ollama + FastAPI

---

## What is RAG?

RAG stands for **Retrieval-Augmented Generation**.

Without RAG:
```
You: "Which n8n workflow handles my grocery automation?"
AI:  "I don't know — I don't have access to your files."
```

With RAG:
```
You: "Which n8n workflow handles my grocery automation?"
AI:  "The 'GroceryTracker_v2' workflow does this. It uses a webhook
      trigger and posts to your Telegram channel. [Source: n8n-exports/
      grocery-tracker.json, section: trigger nodes]"
```

---

## How RAG works (simple version)

```
Step 1: INGEST (done once)
──────────────────────────
Your files → Split into chunks → Convert to numbers (embeddings) → Store in vector DB

Step 2: QUERY (done every time you ask a question)
───────────────────────────────────────────────────
Your question → Convert to numbers → Find similar chunks → Feed to AI → Get answer
```

Visual:

```
Your files                         Vector DB (ChromaDB)
┌──────────────┐                   ┌─────────────────────┐
│ HA YAML      │  → chunk →        │ [0.2, 0.8, 0.1...] │
│ n8n JSONs    │  → embed →  ────► │ [0.5, 0.1, 0.9...] │
│ README docs  │                   │ [0.3, 0.7, 0.2...] │
│ Markdown notes│                  └─────────────────────┘
└──────────────┘                            │
                                            │ (at query time)
                                     "Which n8n workflow...?"
                                            │
                                   Find similar vectors
                                            │
                                   Return top 3 matching chunks
                                            │
                                   Feed chunks + question to Ollama
                                            │
                                   Get answer with citations
```

---

## Definition of done

- [ ] Ingest 3+ document types (YAML, JSON, Markdown)
- [ ] Test 3 chunking strategies and pick the best one
- [ ] Query returns answer + cited source file and chunk
- [ ] Hallucination detection layer: AI checks its own answer

---

## What files to use

Use YOUR OWN files — you know the ground truth, which makes it the best learning environment:

| File type | Where to get them |
|-----------|------------------|
| Home Assistant YAML configs | `/config/automations.yaml` on your HA instance |
| n8n workflow JSON exports | n8n → Settings → Export all workflows |
| GroceryTracker README + docs | Your repo |
| Personal markdown notes | Obsidian vault or any notes folder |

---

## Week 3 — Setup and First Ingestion

### Step 1 — Set up LlamaIndex + ChromaDB via podman compose (P2-T1)

> **⚡ Learning checkpoint first:** Before you write any code, answer this in your build log:
> "What does a vector database store, compared to a regular database like PostgreSQL?"
> Write your best guess. After the week, verify it.

Create `podman-compose.yml`:

```yaml
version: "3.9"
services:
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8001:8000"
    volumes:
      - chromadata:/chroma/chroma

  api:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - chromadb

volumes:
  chromadata:
```

Install Python dependencies:

```bash
pip install llama-index chromadb ollama fastapi
```

---

### Step 2 — Build document loader for Home Assistant YAML (P2-T2)

```python
import yaml
from pathlib import Path

def load_ha_yaml(folder_path: str) -> list[dict]:
    """Load Home Assistant YAML files and extract useful text."""
    documents = []
    for yaml_file in Path(folder_path).glob("*.yaml"):
        with open(yaml_file) as f:
            content = yaml.safe_load(f)
        # Turn the YAML into readable text for embedding
        text = yaml.dump(content, default_flow_style=False)
        documents.append({
            "text": text,
            "metadata": {
                "source": str(yaml_file),   # keeps track of where it came from
                "type": "home_assistant_yaml",
                "filename": yaml_file.name
            }
        })
    return documents
```

Key rule: **always keep the source filename in metadata** — this is what you cite later.

---

### Step 3 — Build document loader for n8n JSON exports (P2-T3)

```python
import json
from pathlib import Path

def load_n8n_workflows(folder_path: str) -> list[dict]:
    documents = []
    for json_file in Path(folder_path).glob("*.json"):
        with open(json_file) as f:
            workflow = json.load(f)
        # Extract the meaningful parts of each workflow
        name = workflow.get("name", "Unknown workflow")
        nodes = workflow.get("nodes", [])
        node_summary = "\n".join([
            f"Node: {n.get('name')} | Type: {n.get('type')} | Notes: {n.get('notes', '')}"
            for n in nodes
        ])
        text = f"Workflow: {name}\n\nNodes:\n{node_summary}"
        documents.append({
            "text": text,
            "metadata": {
                "source": str(json_file),
                "type": "n8n_workflow",
                "workflow_name": name
            }
        })
    return documents
```

Goal: after ingestion, you should be able to ask "which workflow handles X?" and get a real answer.

---

## Week 4 — Chunking Experiments

### Step 4 — Implement and compare 3 chunking strategies (P2-T4)

> **This is the most important learning task in P2.** Chunking = how you split documents before storing them. The strategy dramatically affects retrieval quality.

**What is chunking?**

```
Original document (too long for the AI's context window):
────────────────────────────────────────────────────────
"Home Assistant automation: when motion detected in hallway,
turn on hallway light. Condition: only after sunset. Action:
call service light.turn_on. Entity: light.hallway. Transition: 2s..."
[continues for 3000 tokens]

After chunking (each chunk fits neatly, keeps context):
────────────────────────────────────────────────────────
Chunk 1: "Home Assistant automation: when motion detected..."  [512 tokens]
Chunk 2: "...Condition: only after sunset. Action..."          [512 tokens]
Chunk 3: "Entity: light.hallway. Transition: 2s..."           [512 tokens]
```

**The 3 strategies to test:**

| Strategy | How it works | When it works well |
|----------|-------------|-------------------|
| A: Fixed 512 tokens | Cut every 512 tokens, 50 token overlap | Simple, predictable |
| B: Sentence-based | Split at sentence boundaries | Better for prose |
| C: Semantic (heading/paragraph) | Split at `##` headings or blank lines | Best for structured docs |

**Your experiment:**

1. Pick 10 questions you know the exact answer to (from your own files)
2. Ingest the same files 3 times — once per strategy
3. Ask all 10 questions against all 3 strategies
4. Score retrieval: did it find the right chunk? (Yes/No)
5. Record results in a table:

```
Question                    | Strategy A | Strategy B | Strategy C
"Which workflow uses Telegram?" |    ✓    |     ✓      |     ✓
"HA automation for motion?"     |    ✗    |     ✓      |     ✓
"Grocery tracker webhook?"      |    ✗    |     ✗      |     ✓
Score                           |   4/10  |    7/10    |    9/10
```

Write in your build log: **which strategy won? Why do you think that is?**

---

### Step 5 — Set up local embedding model via Ollama (P2-T5)

```bash
# On your homelab, pull an embedding model
ollama pull nomic-embed-text
```

```python
from llama_index.embeddings.ollama import OllamaEmbedding

embed_model = OllamaEmbedding(
    model_name="nomic-embed-text",
    base_url="http://YOUR_HOMELAB_IP:11434"
)
```

> **⚡ Learning checkpoint:** What is an embedding? Why does the choice of embedding model affect what your RAG system can retrieve? Write your answer before verifying online.

---

## Week 4–5 — Search and Reranking

### Step 6 — Implement similarity search with score threshold (P2-T6)

```python
def search(query: str, top_k: int = 5, min_score: float = 0.7):
    """Search ChromaDB and return relevant chunks above a score threshold."""
    query_embedding = embed_model.get_text_embedding(query)
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        include=["documents", "metadatas", "distances"]
    )
    # Filter out low-relevance results
    filtered = [
        {"text": doc, "metadata": meta, "score": 1 - dist}
        for doc, meta, dist in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0]
        )
        if (1 - dist) >= min_score
    ]
    return filtered
```

Start with `min_score=0.7`. If you get too many bad results, increase it. If too few results, lower it.

---

### Step 7 — Add reranking layer (P2-T7)

Reranking is a second pass that re-orders your results by actual relevance.

```
First pass (vector search):
  Returns top 20 results by "nearness" in vector space

Second pass (reranker):
  Re-scores all 20 by "how well does this actually answer the question?"
  Returns top 5 truly relevant results
```

After adding reranking, re-run your 10 test questions. Did the score improve?

> **⚡ Learning checkpoint:** Why is retrieval by vector similarity not the same as retrieval by relevance? Give a concrete example from your test results where they disagreed.

---

## Week 5 — API and Chat UI

### Step 8 — Build FastAPI query endpoint with source citation (P2-T8)

Every response MUST include sources. No exceptions.

```python
@app.post("/query")
async def query(request: QueryRequest):
    # 1. Search for relevant chunks
    chunks = search(request.question, top_k=5, min_score=0.7)

    # 2. Build context from chunks
    context = "\n\n".join([c["text"] for c in chunks])

    # 3. Ask Ollama with the context
    prompt = f"""Answer the question using ONLY the information below.
If the answer is not in the information, say "I don't know."

Information:
{context}

Question: {request.question}"""

    answer = run_ollama(prompt)

    # 4. Return answer WITH sources
    return {
        "answer": answer,
        "sources": [
            {
                "file": c["metadata"]["source"],
                "score": c["score"],
                "excerpt": c["text"][:200]   # first 200 chars as preview
            }
            for c in chunks
        ]
    }
```

---

### Step 9 — Build the chat UI (P2-T9)

```
┌────────────────────────────────────────────────────────┐
│  RAG Brain                                             │
├────────────────────────────────────────────────────────┤
│  Chat history                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │ You: Which n8n workflow handles groceries?       │  │
│  │                                                  │  │
│  │ AI: The GroceryTracker_v2 workflow handles this. │  │
│  │     It uses a webhook trigger...                 │  │
│  │                                                  │  │
│  │     Sources (click to expand):                  │  │
│  │     ▶ n8n-exports/grocery-tracker.json (0.94)   │  │
│  │     ▶ README.md (0.81)                          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  [ Ask a question...                          ] [Ask]  │
└────────────────────────────────────────────────────────┘
```

---

## Week 6 — Hallucination Detection

### Step 10 — Add hallucination detection eval loop (P2-T10)

After every answer, make a second AI call to verify the answer:

```python
def detect_hallucination(question: str, answer: str, sources: list[str]) -> dict:
    source_text = "\n\n".join(sources)
    verification_prompt = f"""You are a fact-checker.

Source documents:
{source_text}

Claim to verify: {answer}

Is this claim FULLY supported by the source documents above?
Reply with: YES or NO, then one sentence of reasoning."""

    result = run_ollama(verification_prompt)
    hallucination_detected = result.strip().upper().startswith("NO")
    return {
        "hallucination_detected": hallucination_detected,
        "verification_response": result
    }
```

Log every result:
```
question | answer | sources | hallucination_detected | verification_response
```

> **⚡ Learning checkpoint:** After running on 20+ questions, what percentage triggered hallucination detection? That rate is your RAG quality baseline. Write it in your build log. This is the number you will reference in every future blog post about RAG.

---

## Week 6 — Content tasks

| Task | What to do |
|------|-----------|
| P2-C1 | Write 3 build logs using `BUILD_LOG_TEMPLATE.md` |
| P2-C2 | LinkedIn: "RAG explained from someone who broke it 5 times" |
| P2-C3 | Blog post: architecture diagram + chunking experiment results table + hallucination rate before/after detection |
| P2-C4 | Instagram carousel: "What is RAG? (real example)" |

---

## Full task checklist

### Week 3
- [ ] P2-T1: Set up LlamaIndex + ChromaDB via podman compose
- [ ] P2-T2: Build document loader for Home Assistant YAML configs
- [ ] P2-T3: Build document loader for n8n JSON workflow exports

### Week 4
- [ ] P2-T4: Implement and compare 3 chunking strategies
- [ ] P2-T5: Set up local embedding model via Ollama

### Week 4–5
- [ ] P2-T6: Implement similarity search with score threshold
- [ ] P2-T7: Add reranking layer and compare results

### Week 5
- [ ] P2-T8: Build FastAPI query endpoint with source citation
- [ ] P2-T9: Build simple chat UI

### Week 6
- [ ] P2-T10: Add hallucination detection eval loop
- [ ] P2-C1: Write 3 build logs
- [ ] P2-C2: LinkedIn post
- [ ] P2-C3: Blog post (must include chunking experiment table)
- [ ] P2-C4: Instagram carousel
