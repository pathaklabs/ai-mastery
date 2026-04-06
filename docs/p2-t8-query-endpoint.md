# P2-T8: Build FastAPI Query Endpoint with Source Citation

> **Goal:** Build the POST /query endpoint that takes a question, retrieves relevant chunks, asks Ollama for an answer, and always returns the answer together with source citations — never one without the other.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 5
**Labels:** `task`, `p2-rag`

---

## What you are doing

This is where everything connects. The query endpoint is the main interface to your RAG system. It orchestrates the full pipeline:

1. Take the user's question
2. Search ChromaDB for relevant chunks (P2-T6 + P2-T7)
3. Build a prompt: "answer this question using only these chunks"
4. Send the prompt to Ollama (local LLM)
5. Return the answer AND the source citations

The rule: **answers without sources are not allowed**. If the system cannot find relevant sources, it says "I don't know" — it does not make something up.

---

## Why this step matters

Citations are what make a RAG system trustworthy. Without them, you have a chatbot that sometimes answers correctly and sometimes hallucinates, with no way to tell the difference. With citations, you can verify every answer in seconds.

This endpoint also becomes the foundation for the chat UI (P2-T9) and hallucination detection (P2-T10).

---

## Prerequisites

- [ ] [P2-T7](p2-t7-reranking.md) complete — `search_and_rerank()` working
- [ ] Ollama running on homelab with a chat model (e.g. `llama3`, `mistral`, `phi3`)
- [ ] `podman-compose up` running

---

## Step-by-step instructions

### Step 1 — Pull a chat model in Ollama

You need a model for generating answers (separate from the embedding model):

```bash
# On your homelab — pick one:
ollama pull llama3          # 4.7 GB — best quality
ollama pull mistral         # 4.1 GB — also very good
ollama pull phi3            # 2.2 GB — smaller, faster
ollama pull llama3:8b       # 4.7 GB — same as llama3

# Verify it works:
ollama run llama3 "Say hello in one sentence."
```

---

### Step 2 — Create the Ollama client module

Create `~/projects/rag-brain/llm.py`:

```python
"""
Ollama LLM Client

Wraps Ollama's API for generating answers.
Used by the query endpoint to turn retrieved chunks into an answer.
"""
import os
import requests
import json

# ─── Configuration ────────────────────────────────────────────────────────────
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
CHAT_MODEL = os.getenv("CHAT_MODEL", "llama3")
# ─────────────────────────────────────────────────────────────────────────────


def ask_ollama(prompt: str, model: str = CHAT_MODEL) -> str:
    """
    Send a prompt to Ollama and return the response text.

    Args:
        prompt: The full prompt to send (system instructions + context + question).
        model:  The Ollama model to use.

    Returns:
        The model's response as a string.
    """
    url = f"{OLLAMA_HOST}/api/generate"
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,  # get the full response at once
        "options": {
            "temperature": 0.1,  # low temperature = more factual, less creative
            "num_ctx": 4096,     # context window size
        }
    }

    try:
        response = requests.post(url, json=payload, timeout=120)
        response.raise_for_status()
        data = response.json()
        return data.get("response", "").strip()
    except requests.exceptions.Timeout:
        return "Error: Ollama took too long to respond. Try a smaller model."
    except requests.exceptions.ConnectionError:
        return f"Error: Cannot reach Ollama at {OLLAMA_HOST}. Is it running?"
    except Exception as e:
        return f"Error: {str(e)}"


def build_rag_prompt(question: str, context_chunks: list[str]) -> str:
    """
    Build the RAG prompt that instructs the model to answer from context only.

    This prompt design is critical:
    - It tells the model to ONLY use the provided context
    - It tells the model to say "I don't know" if the answer is not in context
    - This is what prevents hallucination (along with the detection layer in P2-T10)
    """
    context = "\n\n---\n\n".join(context_chunks)

    prompt = f"""You are a helpful assistant for a homelab operator.
Answer the question using ONLY the information provided below.
If the answer is not contained in the provided information, say exactly:
"I don't know — I couldn't find this in your files."
Do not make up information. Do not use knowledge from outside the provided context.

PROVIDED INFORMATION:
{context}

QUESTION: {question}

ANSWER:"""

    return prompt


def test_ollama_connection() -> bool:
    """Test that Ollama is reachable and the chat model is available."""
    url = f"{OLLAMA_HOST}/api/tags"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        models = [m["name"] for m in response.json().get("models", [])]
        available = any(CHAT_MODEL in m for m in models)
        if not available:
            print(f"Warning: model '{CHAT_MODEL}' not found in Ollama.")
            print(f"Available models: {models}")
            print(f"Run: ollama pull {CHAT_MODEL}")
        return True
    except Exception as e:
        print(f"Cannot reach Ollama: {e}")
        return False
```

---

### Step 3 — Build the FastAPI query endpoint

Update `~/projects/rag-brain/main.py` with the full query endpoint:

```python
"""
RAG Brain — FastAPI Application

Endpoints:
  GET  /health          — health check
  POST /query           — main RAG query endpoint
  POST /ingest/trigger  — trigger re-ingestion (optional)
"""
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import chromadb

from search import search_and_rerank
from llm import ask_ollama, build_rag_prompt, test_ollama_connection

app = FastAPI(
    title="RAG Brain",
    description="Personal RAG system over homelab files. All local, no cloud.",
    version="1.0.0",
)

# ─── Request / Response models ────────────────────────────────────────────────

class QueryRequest(BaseModel):
    question: str
    top_k: int = 5          # how many sources to return
    min_score: float = 0.5  # minimum vector similarity at retrieval stage


class SourceCitation(BaseModel):
    file: str        # filename (e.g. automations.yaml)
    score: float     # relevance score (0-1)
    excerpt: str     # first 300 characters of the chunk


class QueryResponse(BaseModel):
    question: str
    answer: str
    sources: list[SourceCitation]
    source_count: int
    model_used: str

# ─────────────────────────────────────────────────────────────────────────────


@app.get("/health")
def health():
    """Check API, ChromaDB, and Ollama are all reachable."""
    chroma_host = os.getenv("CHROMA_HOST", "localhost")
    chroma_port = int(os.getenv("CHROMA_PORT", "8001"))

    status = {"api": "ok"}

    # Check ChromaDB
    try:
        client = chromadb.HttpClient(host=chroma_host, port=chroma_port)
        client.heartbeat()
        status["chromadb"] = "ok"
    except Exception as e:
        status["chromadb"] = f"error: {e}"

    # Check Ollama
    ollama_ok = test_ollama_connection()
    status["ollama"] = "ok" if ollama_ok else "error"

    all_ok = all(v == "ok" for v in status.values())
    return {**status, "overall": "ok" if all_ok else "degraded"}


@app.post("/query", response_model=QueryResponse)
async def query(request: QueryRequest):
    """
    Main RAG query endpoint.

    Steps:
    1. Validate question is not empty
    2. Search ChromaDB (vector search + reranking)
    3. If no results found — return "I don't know" with empty sources
    4. Build context from results
    5. Ask Ollama to answer from context only
    6. Return answer + source citations

    Rule: NEVER return an answer without sources.
    """
    question = request.question.strip()

    if not question:
        raise HTTPException(status_code=400, detail="Question cannot be empty.")

    # Step 2: Retrieve relevant chunks
    results = search_and_rerank(
        query=question,
        retrieve_k=request.top_k * 4,   # retrieve more, reranker filters down
        return_top_n=request.top_k,
        min_score=request.min_score,
    )

    # Step 3: Handle no results
    if not results:
        return QueryResponse(
            question=question,
            answer="I don't know — I couldn't find relevant information in your files.",
            sources=[],
            source_count=0,
            model_used=os.getenv("CHAT_MODEL", "llama3"),
        )

    # Step 4: Build context from retrieved chunks
    context_chunks = [r["text"] for r in results]
    prompt = build_rag_prompt(question, context_chunks)

    # Step 5: Get answer from Ollama
    answer = ask_ollama(prompt)

    # Step 6: Build source citations
    sources = []
    for r in results:
        sources.append(SourceCitation(
            file=r["metadata"].get("filename", r["source"]),
            score=r.get("rerank_score", r["score"]),
            excerpt=r["text"][:300],   # first 300 chars as preview
        ))

    return QueryResponse(
        question=question,
        answer=answer,
        sources=sources,
        source_count=len(sources),
        model_used=os.getenv("CHAT_MODEL", "llama3"),
    )


@app.get("/collections")
def list_collections():
    """List all ChromaDB collections and their document counts."""
    chroma_host = os.getenv("CHROMA_HOST", "localhost")
    chroma_port = int(os.getenv("CHROMA_PORT", "8001"))
    client = chromadb.HttpClient(host=chroma_host, port=chroma_port)
    collections = client.list_collections()
    return {
        "collections": [
            {"name": c.name, "count": c.count()}
            for c in collections
        ]
    }
```

---

### Step 4 — Test the endpoint

Start the API server:

```bash
# Start the server locally
uvicorn main:app --reload --port 8000
```

In a second terminal, test it:

```bash
# Test 1: Health check
curl http://localhost:8000/health | python3 -m json.tool

# Test 2: Query
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Which automation controls the hallway light?",
    "top_k": 3
  }' | python3 -m json.tool
```

Expected response format:

```json
{
  "question": "Which automation controls the hallway light?",
  "answer": "The 'Hallway Motion Light' automation controls the hallway light. It triggers when the hallway motion sensor (binary_sensor.hallway_motion) changes to 'on', but only after sunset. It calls light.turn_on on light.hallway with a 2 second transition.",
  "sources": [
    {
      "file": "automations.yaml",
      "score": 0.94,
      "excerpt": "Automation: Hallway Motion Light\nDescription: Turn on hallway light when motion detected after sunset..."
    },
    {
      "file": "automations.yaml",
      "score": 0.87,
      "excerpt": "Actions:\n  - Call service: light.turn_on on light.hallway\n  Brightness: 128\n  Transition: 2 seconds..."
    }
  ],
  "source_count": 2,
  "model_used": "llama3"
}
```

---

### Step 5 — Explore the auto-generated API docs

FastAPI generates interactive documentation automatically:

```
http://localhost:8000/docs
```

Open this in your browser. You can try the `/query` endpoint directly from the browser — it shows you all the fields and lets you send requests.

---

### Step 6 — Deploy via podman compose

Make sure your updated `main.py` is used in the container. Rebuild:

```bash
podman-compose down
podman-compose up -d --build
podman-compose logs -f api
```

Test against the containerized version:

```bash
curl http://localhost:8000/health
```

---

## Visual overview

```
POST /query
{ "question": "Which automation controls hallway light?" }
         │
         ▼
main.py → query()
         │
         ├─── search_and_rerank()
         │         │
         │         ├── embed question (Ollama: nomic-embed-text)
         │         ├── ChromaDB query (top 20 candidates)
         │         ├── rerank (cross-encoder: top 5)
         │         └── return 5 most relevant chunks
         │
         ├─── build_rag_prompt(question, chunks)
         │         │
         │         └── "Answer ONLY from this context: ..."
         │
         ├─── ask_ollama(prompt)
         │         │
         │         └── HTTP POST to Ollama → answer text
         │
         └─── return QueryResponse
                   {
                     "answer": "The Hallway Motion Light automation...",
                     "sources": [
                       { "file": "automations.yaml", "score": 0.94,
                         "excerpt": "Automation: Hallway Motion..." }
                     ]
                   }
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"What happens in your system when the user asks a question that is NOT in any of your files (e.g., 'What is the capital of France?')? Walk through what each step of the pipeline does. What does the final response look like?"**

---

## Done when

- [ ] `llm.py` created with `ask_ollama()` and `build_rag_prompt()`
- [ ] `main.py` has `POST /query` endpoint returning `QueryResponse` with sources
- [ ] `curl` test returns correct JSON with `answer` and `sources` fields
- [ ] Response for a known question includes correct source filename
- [ ] Response for an unknown question returns "I don't know" with empty sources
- [ ] `/docs` page loads and shows the interactive API documentation
- [ ] `podman-compose` version works with the updated `main.py`
- [ ] Learning checkpoint answered in build log

---

## Next step

→ [P2-T9: Build simple chat UI](p2-t9-chat-ui.md)
