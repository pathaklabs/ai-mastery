# P1-E1: PromptOS — Personal Prompt Management System

> **Epic goal:** Build a tool to store, version, test, and score your AI prompts — and understand why prompt quality matters.

**Weeks:** 1–3
**Labels:** `epic`, `p1-promptos`
**Stack:** FastAPI + PostgreSQL + React + Claude API + Ollama

---

## What you are building

A personal "prompt library" — like GitHub for your prompts. You can:
- Save prompts with version history (like git commits for text)
- Run the same prompt on Claude AND your local Ollama models side by side
- Score each output so you learn what makes a good prompt

```
┌─────────────────────────────────────────────────────────┐
│                      PromptOS UI                        │
│                                                         │
│  Prompt List          Editor            Comparison      │
│  ┌──────────┐         ┌────────────┐    ┌───────────┐  │
│  │ prompt 1 │         │ Write your │    │ Claude    │  │
│  │ prompt 2 │ ──────► │ prompt     │───►│ output    │  │
│  │ prompt 3 │         │ here       │    ├───────────┤  │
│  └──────────┘         └────────────┘    │ Ollama    │  │
│                                         │ output    │  │
│                                         └───────────┘  │
└─────────────────────────────────────────────────────────┘
         │                                      │
         ▼                                      ▼
   PostgreSQL DB                          Score each output
   (prompts + versions)                   1–5 stars per dimension
```

---

## Definition of done

- [ ] Store and version prompts with metadata (title, tags, model target)
- [ ] Run one prompt across Claude AND a local Ollama model — see both outputs side by side
- [ ] Score outputs with ratings and free-text notes
- [ ] View a dashboard showing which prompts perform best

---

## Week 1 — Prompt Storage & Versioning

### What you are building this week

The back end: database + API. Think of it as building the filing cabinet before the front end.

```
Week 1 target
─────────────
[FastAPI app]
      │
      ├── POST /prompts          ← save a new prompt
      ├── GET  /prompts          ← list all prompts
      ├── GET  /prompts/{id}     ← get one prompt
      ├── POST /prompts/{id}/versions       ← save new version
      └── GET  /prompts/{id}/versions/diff  ← compare versions
      │
[PostgreSQL]
      │
      ├── Table: prompts         (id, title, tags, model_target, created_at)
      ├── Table: prompt_versions (id, prompt_id, body, version_num, created_at)
      └── Table: tags
```

---

### Step 1 — Create your project CLAUDE.md (P1-T1, part 1)

Before writing any code, fill in `projects/01-promptos/CLAUDE.md` with these sections:

```markdown
# Project: PromptOS

## Project Context
Personal prompt management system. Stores prompts with version history,
runs them across multiple models, and scores outputs to build intuition
for prompt quality. For my own learning and daily AI development use.

## Tech Stack
- Language: Python 3.11
- Framework: FastAPI
- Database: PostgreSQL (via SQLAlchemy + Alembic)
- AI layer: Claude API (Anthropic SDK), Ollama REST API
- Deployment: podman compose

## Current Task
[Update this before every session]

## Architecture Decisions Already Made
- PostgreSQL only (no SQLite — I want real DB experience)
- SQLAlchemy ORM — no raw SQL
- Alembic for all schema changes — no manual ALTER TABLE

## Constraints
- API keys in .env only — never in code
- Track token count on every Claude API call

## What NOT To Do
- Do not mix sync and async code — use async throughout FastAPI
```

---

### Step 2 — Set up the project with podman compose (P1-T1)

Create the folder structure:

```bash
mkdir -p projects/01-promptos/{api,models,schemas,db,tests}
cd projects/01-promptos
```

Create `podman-compose.yml`:

```yaml
version: "3.9"
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: promptos
      POSTGRES_PASSWORD: promptos
      POSTGRES_DB: promptos
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  api:
    build: .
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      - db

volumes:
  pgdata:
```

Start the database:

```bash
podman compose up db -d
```

---

### Step 3 — Design the data model (P1-T2)

Create `models/prompt.py`:

```python
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from db.base import Base
import datetime

class Prompt(Base):
    __tablename__ = "prompts"
    id         = Column(Integer, primary_key=True)
    title      = Column(String(200), nullable=False)
    model_target = Column(String(100))          # e.g. "claude-3-5-sonnet"
    tags       = Column(String(500))            # comma-separated
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    versions   = relationship("PromptVersion", back_populates="prompt")

class PromptVersion(Base):
    __tablename__ = "prompt_versions"
    id          = Column(Integer, primary_key=True)
    prompt_id   = Column(Integer, ForeignKey("prompts.id"))
    body        = Column(Text, nullable=False)  # the actual prompt text
    version_num = Column(Integer, nullable=False)
    created_at  = Column(DateTime, default=datetime.datetime.utcnow)
    prompt      = relationship("Prompt", back_populates="versions")
```

Then run the Alembic migration:

```bash
alembic init alembic
alembic revision --autogenerate -m "create prompts and versions"
alembic upgrade head
```

> **⚡ Learning checkpoint:** Before running `alembic upgrade head`, write down in your build log: what SQL tables do you expect to be created? Check after running — was your prediction right?

---

### Step 4 — Build the CRUD API endpoints (P1-T3)

Create `api/prompts.py` with these endpoints:

| Method | Path | What it does |
|--------|------|--------------|
| `POST` | `/prompts` | Create a new prompt |
| `GET` | `/prompts` | List all prompts (with search + tag filter) |
| `GET` | `/prompts/{id}` | Get one prompt with its versions |
| `POST` | `/prompts/{id}/versions` | Save a new version of a prompt |
| `GET` | `/prompts/{id}/versions/{v1}/diff/{v2}` | Show what changed between two versions |

Test each endpoint using FastAPI's built-in docs at `http://localhost:8000/docs`.

---

### Step 5 — Build the React frontend for Week 1 (P1-T4)

Two screens:

```
Screen 1: Prompt List          Screen 2: Prompt Editor
┌──────────────────┐           ┌─────────────────────────┐
│ Search: [______] │           │ Title: [______________] │
│ Tag: [all ▼]    │           │                         │
│                  │           │ Body:                   │
│ • My prompt v3   │ ────────► │ ┌─────────────────────┐ │
│ • Test prompt v1 │           │ │ You are a...        │ │
│ • Draft v2       │           │ └─────────────────────┘ │
└──────────────────┘           │                         │
                               │ Version history:        │
                               │  v3 (today)             │
                               │  v2 (yesterday)         │
                               │  v1 (last week)         │
                               └─────────────────────────┘
```

> **AI tool tip:** Try using v0.dev to generate the initial React components. Paste your design description. Document in your build log: what did it get right? What did you have to fix?

---

## Week 2 — Multi-Model Testing

### What you are building this week

Connect Claude and Ollama. Show both outputs side by side.

```
User submits prompt
        │
        ├──────────────────────┐
        ▼                      ▼
  Claude API              Ollama API
  (cloud)                 (your homelab)
        │                      │
        ▼                      ▼
  Output + tokens         Output + latency
        │                      │
        └──────────┬───────────┘
                   ▼
         Side-by-side UI
```

---

### Step 6 — Integrate Claude API with streaming (P1-T5)

Install the SDK:

```bash
pip install anthropic
```

Add to `.env`:

```
ANTHROPIC_API_KEY=sk-ant-...
```

Basic call with token logging:

```python
import anthropic
import time

client = anthropic.Anthropic()

def run_claude(prompt_text: str, model: str = "claude-sonnet-4-6"):
    start = time.time()
    response = client.messages.create(
        model=model,
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt_text}]
    )
    latency_ms = int((time.time() - start) * 1000)
    return {
        "output": response.content[0].text,
        "input_tokens": response.usage.input_tokens,
        "output_tokens": response.usage.output_tokens,
        "latency_ms": latency_ms,
        "model": model,
    }
```

> **⚡ Learning checkpoint:** After your first real API call, look at the token counts. Calculate the cost (check Anthropic pricing page). Write the exact number in your build log. Cost awareness is a real engineering skill.

---

### Step 7 — Integrate Ollama (P1-T6)

Ollama runs on your homelab. Call it via HTTP:

```python
import requests
import time

OLLAMA_URL = "http://YOUR_HOMELAB_IP:11434"

def run_ollama(prompt_text: str, model: str = "llama3"):
    start = time.time()
    response = requests.post(f"{OLLAMA_URL}/api/generate", json={
        "model": model,
        "prompt": prompt_text,
        "stream": False
    }, timeout=120)  # local models can be slow
    latency_ms = int((time.time() - start) * 1000)
    data = response.json()
    return {
        "output": data["response"],
        "latency_ms": latency_ms,
        "model": model,
    }
```

> **⚡ Learning checkpoint:** Run the same prompt through Claude and Ollama (Qwen3 14B or Llama 3). Measure the latency difference. When would you choose a local model over Claude? Write your answer in the build log.

---

### Step 8 — Build the side-by-side comparison UI (P1-T7)

```
┌─────────────────────────────────────────────────────────┐
│  Prompt: "Explain async/await in Python in 3 sentences" │
│  [Run on all models]                                    │
├─────────────────────┬───────────────────────────────────┤
│  Claude Sonnet      │  Llama 3 (Ollama)                 │
│  ─────────────────  │  ──────────────────────────────── │
│  Async/await lets   │  In Python, async/await...        │
│  you write code...  │                                   │
│                     │                                   │
│  Tokens: 312        │  Latency: 4.2s                   │
│  Latency: 820ms     │  Model: llama3:8b                │
│  Cost: $0.0009      │                                   │
└─────────────────────┴───────────────────────────────────┘
```

---

## Week 3 — Output Scoring & Evaluation

### What you are building this week

A rating system for AI outputs. This teaches you the hardest skill in AI: evaluating quality.

```
Prompt output
     │
     ▼
Rate 1–5 on each dimension:
  ├── Accuracy    (is it factually correct?)
  ├── Format      (is the structure right?)
  ├── Tone        (does it match the intended voice?)
  └── Completeness (did it answer the full question?)
     │
     ▼
Write annotation (free text notes)
     │
     ▼
Database stores all scores
     │
     ▼
Dashboard shows: best prompts, best models, score trends
```

---

### Step 9 — Build the scoring data model and API (P1-T8)

Add to your models:

```python
class OutputScore(Base):
    __tablename__ = "output_scores"
    id                = Column(Integer, primary_key=True)
    prompt_version_id = Column(Integer, ForeignKey("prompt_versions.id"))
    model             = Column(String(100))     # e.g. "claude-sonnet-4-6"
    accuracy          = Column(Integer)          # 1–5
    format            = Column(Integer)          # 1–5
    tone              = Column(Integer)          # 1–5
    completeness      = Column(Integer)          # 1–5
    annotation        = Column(Text)             # your notes
    created_at        = Column(DateTime, default=datetime.datetime.utcnow)
```

---

### Step 10 — Add scoring UI (P1-T9)

Below each model output column, add:

```
┌─────────────────────┐
│  Claude Sonnet      │
│  [output text...]   │
│                     │
│  Rate this output:  │
│  Accuracy:    ★★★★☆ │
│  Format:      ★★★☆☆ │
│  Tone:        ★★★★★ │
│  Completeness:★★★☆☆ │
│  Notes: [_________] │
│  [Save score]       │
└─────────────────────┘
```

---

### Step 11 — Build the performance dashboard (P1-T10)

Three charts:

| Chart | What it shows |
|-------|--------------|
| Top prompts | Which prompt versions have the highest average score |
| Model win rate | Which model wins most head-to-head comparisons |
| Score over time | Is your prompt quality improving across the program? |

> **⚡ Learning checkpoint:** After scoring 10+ outputs, look at your data. Write in your build log: how do you know if an AI output is actually good? This is the hardest open problem in AI engineering. There is no clean answer — write your current thinking.

---

## Week 3 — Content tasks

| Task | What to do |
|------|-----------|
| P1-C1 | Fill 3 build logs during weeks 1–3 using `BUILD_LOG_TEMPLATE.md` |
| P1-C2 | Write a LinkedIn post: "I built prompt version control" |
| P1-C3 | Write a blog post (800–1200 words) with architecture diagram + one failure story + GitHub link |
| P1-C4 | Create an Instagram carousel: 7 slides on what makes a great prompt |

---

## Full task checklist

### Week 1
- [ ] P1-T1: Set up FastAPI project with podman compose
- [ ] P1-T2: Design prompt data model (SQLAlchemy + Alembic migration)
- [ ] P1-T3: Build CRUD API endpoints for prompts
- [ ] P1-T4: Build React frontend — prompt list and editor

### Week 2
- [ ] P1-T5: Integrate Claude API with streaming and token logging
- [ ] P1-T6: Integrate local Ollama models
- [ ] P1-T7: Build side-by-side model comparison UI

### Week 3
- [ ] P1-T8: Build scoring data model and API
- [ ] P1-T9: Add scoring UI to comparison view
- [ ] P1-T10: Build prompt performance dashboard
- [ ] P1-C1: Write 3 build logs
- [ ] P1-C2: LinkedIn post
- [ ] P1-C3: Blog post
- [ ] P1-C4: Instagram carousel
