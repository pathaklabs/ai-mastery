# P4-T7: Package as Podman Compose for Open-Source Deployment

> **Goal:** Package all AIGA services into a single `podman-compose.yml` so anyone can run the full system with one command — and write a README that delivers on the "5-minute setup" promise.

**Part of:** [P4-E1: AIGA](p4-e1-aiga.md)
**Weeks:** 7–8
**Labels:** `task`, `p4-aiga`

---

## What you are doing

Right now, running AIGA means starting three things manually: ChromaDB, the FastAPI server, and the React frontend. Anyone who clones your repo would have to figure all of that out themselves.

This task wraps everything into a single `podman-compose.yml`. After this task, the entire AIGA stack starts with one command:

```bash
podman-compose up
```

That is the "5-minute setup" promise. You will also verify it works by testing it on a clean environment.

---

## Why this step matters

Open source projects live or die by their first-run experience. If someone has to spend 45 minutes debugging environment setup, they give up and never come back. If they run two commands and see the UI in their browser, they star the repo, share it, and come back.

The podman compose file is what transforms AIGA from "a project on your homelab" into "a tool anyone can use."

---

## Prerequisites

- [ ] All previous P4 tasks complete — the system works locally
- [ ] `podman-compose` installed: `pip install podman-compose`
- [ ] Sample documents exist in `source-docs/sample/` (from P4-T1) — these ship with the repo so the system works out of the box

---

## Step-by-step instructions

### Step 1 — Containerise the FastAPI backend

Create a `Dockerfile` for the API:

```dockerfile
# projects/04-aiga/api/Dockerfile

FROM python:3.11-slim

WORKDIR /app

# Install dependencies first (layer caching — only re-runs if requirements.txt changes)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# The API listens on port 8000
EXPOSE 8000

# Start the API server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Create `projects/04-aiga/api/requirements.txt`:

```
fastapi==0.111.0
uvicorn==0.29.0
pydantic==2.7.0
llama-index==0.10.40
llama-index-vector-stores-chroma==0.1.9
llama-index-embeddings-ollama==0.1.3
llama-index-llms-ollama==0.1.5
chromadb==0.5.0
pypdf==4.2.0
pdfminer.six==20221105
```

---

### Step 2 — Containerise the React frontend

```dockerfile
# projects/04-aiga/frontend/Dockerfile

FROM node:20-alpine as build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Serve the built React app with nginx
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html

# Nginx config that handles React Router
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# projects/04-aiga/frontend/nginx.conf

server {
    listen 3000;

    location / {
        root   /usr/share/nginx/html;
        index  index.html;
        try_files $uri $uri/ /index.html;  # Handle React Router paths
    }

    # Proxy API calls to the FastAPI backend
    location /api/ {
        proxy_pass http://api:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

With this nginx proxy config, the frontend can call `/api/query` and nginx will forward it to the API container — no CORS issues, no hardcoded `localhost:8000` in the frontend code.

Update the frontend API URL to use relative paths:

```typescript
// In ChatInterface.tsx and RiskAssessmentForm.tsx, change:
const API_URL = 'http://localhost:8000/api/query';
// to:
const API_URL = '/api/query';
```

---

### Step 3 — Write the podman-compose.yml

This is the core of this task. Every service is defined here.

```yaml
# projects/04-aiga/podman-compose.yml

version: "3.9"

services:

  # ── ChromaDB ──────────────────────────────────────────────────────
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8001:8000"      # ChromaDB listens on 8000 inside, exposed on 8001 outside
    volumes:
      - chromadata:/chroma/chroma    # persistent vector store
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/v1/heartbeat"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ── Ingestion job ─────────────────────────────────────────────────
  # Runs once at startup to load documents into ChromaDB.
  # Exits after ingestion is complete — that is normal behaviour.
  ingest:
    build: ./api
    command: python -m rag.ingest
    depends_on:
      chromadb:
        condition: service_healthy
    environment:
      - CHROMA_URL=http://chromadb:8000
      - DOCS_DIR=/app/source-docs/sample    # use the sample docs that ship with the repo
    volumes:
      - ./source-docs:/app/source-docs:ro   # read-only — ingest reads, does not write docs

  # ── FastAPI backend ───────────────────────────────────────────────
  api:
    build: ./api
    ports:
      - "8000:8000"
    depends_on:
      chromadb:
        condition: service_healthy
      ingest:
        condition: service_completed_successfully
    environment:
      - CHROMA_URL=http://chromadb:8000
      - OLLAMA_URL=${OLLAMA_URL:-http://host-gateway:11434}
      - EMBED_MODEL=${EMBED_MODEL:-nomic-embed-text}
      - LLM_MODEL=${LLM_MODEL:-llama3}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 15s
      timeout: 5s
      retries: 5

  # ── React frontend ────────────────────────────────────────────────
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      api:
        condition: service_healthy

volumes:
  chromadata:     # ChromaDB vector data persists between restarts
```

---

### Step 4 — Create the environment file

```bash
# projects/04-aiga/.env.example
# Copy this to .env and fill in your values

# URL for your local Ollama instance
# If Ollama runs on the host machine (not in a container), use:
OLLAMA_URL=http://host-gateway:11434

# Or if Ollama runs at a specific IP (e.g. homelab server):
# OLLAMA_URL=http://192.168.1.50:11434

# Models to use (must be already pulled in Ollama)
LLM_MODEL=llama3
EMBED_MODEL=nomic-embed-text
```

Add `.env` to `.gitignore` (never commit secrets). Commit `.env.example`.

```bash
echo ".env" >> .gitignore
```

---

### Step 5 — Write the startup script

A simple script that handles the complete setup:

```bash
#!/bin/bash
# projects/04-aiga/start.sh

set -e  # Exit immediately if any command fails

echo "=== AIGA — AI Governance Assistant ==="
echo ""

# Check prerequisites
if ! command -v podman-compose &> /dev/null; then
    echo "ERROR: podman-compose not found. Install it: pip install podman-compose"
    exit 1
fi

if ! command -v ollama &> /dev/null; then
    echo "ERROR: Ollama not found. Install from https://ollama.ai"
    exit 1
fi

# Check .env file
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env from .env.example"
    echo "Edit .env if your Ollama URL differs from the default."
    echo ""
fi

# Pull required Ollama models if not already present
echo "Checking Ollama models..."
ollama pull llama3 2>/dev/null || true
ollama pull nomic-embed-text 2>/dev/null || true

echo ""
echo "Starting AIGA services..."
podman-compose up --build

echo ""
echo "AIGA is running:"
echo "  Frontend:  http://localhost:3000"
echo "  API docs:  http://localhost:8000/docs"
echo "  ChromaDB:  http://localhost:8001"
```

```bash
chmod +x start.sh
```

---

### Step 6 — Verify the 5-minute setup

Test this yourself as if you are a new user. Open a fresh terminal, go to an empty directory, and try:

```bash
git clone https://github.com/PathakLabs/aiga.git
cd aiga
./start.sh
# Wait for services to start (first run takes 2-3 minutes — subsequent runs are faster)
```

Then open `http://localhost:3000` and ask: "What is the EU AI Act?"

If you get a cited answer in under 5 minutes from `git clone`, your README is honest. If not, find and fix the friction.

---

### Step 7 — Write the production-quality README

This README is the AIGA marketing page. It must be sharp.

```markdown
# AIGA — AI Governance Assistant

Ask questions about the EU AI Act, NIST AI RMF, and ISO 42001 in plain English.
Get cited answers with exact article references. Classify your AI system's risk level
in under a minute.

[screenshot goes here]

## What it does

AIGA is an open-source RAG assistant over AI governance documents. You ask,
it retrieves the relevant legal text and explains what it means — citing the
exact article or section every time.

## 5-minute quickstart

**Prerequisites:**
- [Ollama](https://ollama.ai) running locally
- [podman-compose](https://github.com/containers/podman-compose) installed

```bash
git clone https://github.com/PathakLabs/aiga.git
cd aiga
./start.sh
```

Open http://localhost:3000

That is it. The ingestion step runs automatically.

## Example

**Question:** What does the EU AI Act require for a hiring algorithm?

**AIGA:** Hiring algorithms are classified as HIGH RISK under Article 6 and Annex III,
paragraph 4. Before deployment you must: (1) conduct a conformity assessment,
(2) register in the EU AI database, (3) implement human oversight, (4) maintain
technical documentation for 10 years.

**Sources:**
- EU AI Act, Article 6: "AI systems referred to in Annex III shall be considered high-risk..."
- EU AI Act, Annex III, paragraph 4: "AI systems intended for recruitment or selection..."

## Architecture

[architecture diagram]

API: FastAPI + LlamaIndex + Ollama
Vector store: ChromaDB
Frontend: React + TypeScript
Deployment: podman compose

## Documents included

- EU AI Act (2024) — full text
- NIST AI Risk Management Framework 1.0
- ISO 42001 overview
- Anthropic and OpenAI model cards
- Sample AI policy templates

## Read more

[Blog post: How I Built an Open-Source AI Governance Assistant]

## Licence

MIT
```

---

## Visual overview

```
One command: podman-compose up

  ┌──────────────────────────────────────────────────────────┐
  │  podman-compose.yml                                      │
  │                                                          │
  │  chromadb ──────────────────────────────────────────┐   │
  │    image: chromadb/chroma                           │   │
  │    port: 8001                                       │   │
  │    volume: chromadata (persistent)                  │   │
  │                                                     │   │
  │  ingest (runs once then exits)                      │   │
  │    build: ./api                                     │   │
  │    cmd: python -m rag.ingest                        ├──►│
  │    depends_on: chromadb (healthy)                   │   │
  │                                                     │   │
  │  api ────────────────────────────────────────────┐  │   │
  │    build: ./api                                  │  │   │
  │    port: 8000                                    │  ├──►│
  │    depends_on: chromadb + ingest complete        │  │   │
  │    env: OLLAMA_URL, LLM_MODEL, EMBED_MODEL       │  │   │
  │                                                  │  │   │
  │  frontend                                        │  │   │
  │    build: ./frontend                             ├──┘   │
  │    port: 3000                                    │      │
  │    depends_on: api (healthy)                     │      │
  │    nginx proxies /api/* → api:8000               │      │
  └──────────────────────────────────────────────────┘      │
                                                            │
  User opens http://localhost:3000 ◄──────────────────────┘
```

---

## Learning checkpoint

After this task, think about:

1. Why is there a separate `ingest` service instead of ingesting inside the `api` service?
   - Ingestion is a one-time job. The API is a long-running server. Separating them is cleaner.
   - `service_completed_successfully` lets the API wait for ingestion to finish before starting.

2. Why do sample documents ship with the repo?
   - So anyone can run AIGA immediately without downloading 144-page PDFs.
   - The sample documents are big enough for demo queries, small enough to include in the repo.

3. Why does nginx proxy `/api/*` to the API container?
   - The frontend and API run on different ports. Without a proxy, the browser would make cross-origin requests.
   - The proxy makes it transparent: from the browser's perspective, everything is on `localhost:3000`.

---

## Done when

- [ ] `podman-compose up` starts all services without errors
- [ ] `http://localhost:3000` loads the AIGA UI
- [ ] `http://localhost:8000/health` returns `{"status": "ok"}`
- [ ] Asking "What is the EU AI Act?" returns a cited answer
- [ ] ChromaDB data persists after `podman-compose restart` (no need to re-ingest)
- [ ] README 5-minute quickstart tested on a clean terminal from `git clone`
- [ ] `.env.example` committed, `.env` in `.gitignore`

---

## Next step

→ [P4-C4: Publish GitHub repo with strong README](p4-c4-publish-repo.md)
