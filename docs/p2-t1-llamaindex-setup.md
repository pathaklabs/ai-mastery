# P2-T1: Set Up LlamaIndex + ChromaDB

> **Goal:** Get your RAG infrastructure running locally — ChromaDB as a vector database and LlamaIndex as the Python framework that connects everything together.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 3
**Labels:** `task`, `p2-rag`

---

## What you are doing

You are setting up two pieces of infrastructure before writing any AI code:

1. **ChromaDB** — a database that stores text as vectors (numbers). Think of it like a regular database but instead of querying by ID or text match, you query by "similarity." A sentence about your Telegram alert workflow will be "near" other sentences about Telegram, even if they don't share the same words.

2. **LlamaIndex** — a Python library that handles the boring parts of RAG: loading documents, splitting them into chunks, sending them to an embedding model, storing them, and running queries. You write the high-level logic; LlamaIndex handles the plumbing.

Both will run in containers on your homelab using podman compose.

---

## Why this step matters

You cannot build any part of the RAG system without this foundation. ChromaDB is where your embedded documents will live. LlamaIndex is the framework you'll use in every subsequent task. Getting this working first means every future task can focus on the interesting learning rather than setup troubleshooting.

---

## Prerequisites

- [ ] Podman and podman-compose installed on your homelab
- [ ] Python 3.10+ available (on the machine you'll run code from)
- [ ] Ollama already running on your homelab (you'll add embedding models in P2-T5)
- [ ] Port 8001 free on your homelab (for ChromaDB)
- [ ] Port 8000 free on your homelab (for the FastAPI app you'll build later)

---

## Step-by-step instructions

### Step 1 — Answer the learning question in your build log

Before writing any code, open your build log and write your answer to:

> **"What does a vector database store compared to a relational database like PostgreSQL?"**

Write your best guess. You do not need to be right — you need to have a concrete answer in your own words before you verify it. You will revisit this at the end of the week.

---

### Step 2 — Create your project folder

On the machine you will develop from (or directly on the homelab):

```bash
mkdir -p ~/projects/rag-brain
cd ~/projects/rag-brain
mkdir -p data/ha-yaml data/n8n-exports data/markdown
```

Your folder structure will look like this:

```
rag-brain/
├── podman-compose.yml
├── Dockerfile
├── requirements.txt
├── main.py
├── loaders/
│   ├── __init__.py
│   ├── ha_loader.py
│   └── n8n_loader.py
├── data/
│   ├── ha-yaml/        ← put your HA YAML files here
│   ├── n8n-exports/    ← put your n8n JSON exports here
│   └── markdown/       ← put your markdown notes here
└── chroma_store/       ← ChromaDB will create this automatically
```

---

### Step 3 — Create the podman-compose file

Create `~/projects/rag-brain/podman-compose.yml`:

```yaml
version: "3.9"

services:
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8001:8000"
    volumes:
      - chromadata:/chroma/chroma
    environment:
      - ALLOW_RESET=TRUE
    restart: unless-stopped

  api:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./data:/app/data
    depends_on:
      - chromadb
    environment:
      - CHROMA_HOST=chromadb
      - CHROMA_PORT=8000
      - OLLAMA_HOST=http://YOUR_HOMELAB_IP:11434
    restart: unless-stopped

volumes:
  chromadata:
```

Replace `YOUR_HOMELAB_IP` with the actual IP of your homelab (e.g. `192.168.1.100`).

Note: The ChromaDB container runs on port 8000 internally but is exposed as 8001 on your host. This avoids a conflict with the API container.

---

### Step 4 — Create the Dockerfile

Create `~/projects/rag-brain/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

### Step 5 — Create requirements.txt

Create `~/projects/rag-brain/requirements.txt`:

```
llama-index==0.10.30
llama-index-vector-stores-chroma==0.1.7
llama-index-embeddings-ollama==0.1.3
llama-index-llms-ollama==0.1.3
chromadb==0.4.24
fastapi==0.111.0
uvicorn==0.29.0
pyyaml==6.0.1
python-multipart==0.0.9
```

---

### Step 6 — Create a minimal main.py to verify the setup

Create `~/projects/rag-brain/main.py`:

```python
from fastapi import FastAPI
import chromadb
import os

app = FastAPI(title="RAG Brain")

# Connect to ChromaDB
CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = int(os.getenv("CHROMA_PORT", "8001"))

chroma_client = chromadb.HttpClient(host=CHROMA_HOST, port=CHROMA_PORT)


@app.get("/health")
def health():
    """Check that the API and ChromaDB are both reachable."""
    try:
        # This will throw an error if ChromaDB is unreachable
        chroma_client.heartbeat()
        return {"status": "ok", "chromadb": "connected"}
    except Exception as e:
        return {"status": "error", "chromadb": str(e)}


@app.get("/")
def root():
    return {"message": "RAG Brain is running"}
```

---

### Step 7 — Start the services

From your project folder:

```bash
# Build and start everything
podman-compose up -d --build

# Check the logs to confirm both services started
podman-compose logs

# Test the health endpoint
curl http://localhost:8000/health
```

Expected response:

```json
{"status": "ok", "chromadb": "connected"}
```

If you see `"chromadb": "connected"`, both services are talking to each other correctly.

---

### Step 8 — Verify ChromaDB directly

```bash
# ChromaDB exposes its own API on port 8001
curl http://localhost:8001/api/v1/heartbeat
```

Expected response:

```json
{"nanosecond heartbeat": 1234567890}
```

---

### Step 9 — Install Python dependencies locally for development

You will want to run scripts directly (not just inside Docker) during development:

```bash
# Create a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

### Step 10 — Create a quick connection test script

Create `~/projects/rag-brain/test_connection.py`:

```python
"""
Run this script to verify your local Python can reach ChromaDB.
Usage: python test_connection.py
"""
import chromadb

# If running outside Docker, ChromaDB is on port 8001
client = chromadb.HttpClient(host="localhost", port=8001)

# Try creating a test collection
test_collection = client.get_or_create_collection("test")
print(f"Connected! Test collection: {test_collection.name}")

# Add a test document
test_collection.add(
    documents=["This is a test document about my homelab."],
    metadatas=[{"source": "test"}],
    ids=["test-1"]
)
print("Added test document.")

# Query it back
results = test_collection.query(
    query_texts=["homelab"],
    n_results=1
)
print(f"Query result: {results['documents']}")

# Clean up
client.delete_collection("test")
print("Connection test passed. ChromaDB is working.")
```

```bash
python test_connection.py
```

---

## Visual overview

```
Your machine (dev)
┌──────────────────────────────────────────────────────┐
│  Python scripts / FastAPI                            │
│  LlamaIndex (orchestration framework)               │
│       │                                              │
│       │  HTTP                                        │
└───────┼──────────────────────────────────────────────┘
        │
        ▼
Your homelab (containers via podman-compose)
┌──────────────────────────────────────────────────────┐
│                                                      │
│  ┌─────────────────────┐  ┌────────────────────────┐ │
│  │  api container      │  │  chromadb container    │ │
│  │  :8000              │  │  :8001 (host)          │ │
│  │  FastAPI app        │  │  :8000 (internal)      │ │
│  │  LlamaIndex code    │◄─┤  Stores vectors        │ │
│  └─────────────────────┘  │  Persistent volume     │ │
│                           └────────────────────────┘ │
│                                                      │
│  ┌─────────────────────┐                             │
│  │  Ollama             │                             │
│  │  :11434             │                             │
│  │  LLM inference      │                             │
│  │  (already running)  │                             │
│  └─────────────────────┘                             │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Troubleshooting

**ChromaDB container keeps restarting:**
Check logs with `podman-compose logs chromadb`. Often a permissions issue with the volume.

```bash
# Fix volume permissions
podman volume inspect chromadata
# If needed, recreate the volume
podman-compose down -v
podman-compose up -d
```

**`Connection refused` when running test_connection.py:**
Make sure ChromaDB is exposed on port 8001 (not 8000) and your compose file uses `8001:8000`.

**`pip install` fails on `chromadb`:**
ChromaDB requires `sqlite3` and some build tools. On Linux:
```bash
sudo apt-get install -y libsqlite3-dev build-essential
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"What does a vector database store, compared to a relational database like PostgreSQL? How would you query each one to find documents related to 'Telegram notifications'?"**
>
> Write your answer now (your original guess from Step 1), then after getting ChromaDB running, write whether your mental model was correct and what you learned.

---

## Done when

- [ ] `podman-compose up` starts both containers without errors
- [ ] `curl http://localhost:8000/health` returns `{"status": "ok", "chromadb": "connected"}`
- [ ] `curl http://localhost:8001/api/v1/heartbeat` responds
- [ ] `python test_connection.py` passes without errors
- [ ] Learning checkpoint answered in your build log

---

## Next step

→ [P2-T2: Build document loader for Home Assistant YAML](p2-t2-ha-yaml-loader.md)
