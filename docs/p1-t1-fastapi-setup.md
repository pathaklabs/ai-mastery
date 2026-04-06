# P1-T1: Set Up FastAPI Project with Podman Compose

> **Goal:** Create the project folder structure, get PostgreSQL running in a container, and verify FastAPI responds on port 8000.

**Part of:** [P1-US1: Prompt Storage](p1-us1-prompt-storage.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 1
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are creating the skeleton of the PromptOS application. This means making a folder structure, writing a `podman-compose.yml` that starts a PostgreSQL database, writing a minimal FastAPI app, and confirming that both the database and the API are running before writing any real logic.

This is also where you write your `CLAUDE.md` — the file that tells Claude Code everything about your project. You write this BEFORE opening Claude Code.

---

## Why this step matters

A clean project structure makes every task after this easier. If the database is not running before you try to write models, you will hit confusing errors. The `CLAUDE.md` file is equally important: it is the context document that makes Claude Code give you useful, accurate output instead of generic boilerplate.

---

## Prerequisites

- [ ] Podman and podman-compose installed (`podman --version` and `podman-compose --version` work)
- [ ] Python 3.11 installed (`python3 --version`)
- [ ] Node.js 18+ installed (for React in P1-T4, but good to confirm now)
- [ ] You have a GitHub repository for this project (or will create one)

---

## Step-by-step instructions

### Step 1 — Create the CLAUDE.md first

This is the most important step. Do not skip it.

Create the file at `projects/01-promptos/CLAUDE.md`:

```bash
mkdir -p projects/01-promptos
```

Now create the file with this exact content (fill in the `## Current Task` section before every Claude Code session):

```markdown
# Project: PromptOS

## Project Context
Personal prompt management system. Stores prompts with version history,
runs them across multiple models (Claude + local Ollama), and scores
outputs to build intuition for prompt quality.

This project is part of the AI Mastery program — PathakLabs.
It is for my own learning and daily AI development use.

## Tech Stack
- Language: Python 3.11
- Framework: FastAPI (async)
- Database: PostgreSQL 15 (via SQLAlchemy ORM + Alembic migrations)
- AI layer: Claude API (Anthropic SDK), Ollama REST API
- Containerisation: podman compose (NOT Docker)
- Frontend: React 18 with Vite

## Current Task
[UPDATE THIS BEFORE EVERY SESSION — be specific]
Example: "I am adding the POST /prompts endpoint. The Prompt and
PromptVersion SQLAlchemy models already exist. I need a Pydantic
schema and a route handler. Return 201 on success."

## Architecture Decisions Already Made
- PostgreSQL only — no SQLite
- SQLAlchemy ORM — no raw SQL
- Alembic for all schema changes — never ALTER TABLE manually
- All FastAPI routes are async
- Pydantic v2 for all request/response schemas

## Constraints
- API keys in .env only — never hardcoded in source files
- Track token count and latency on every Claude API call
- Podman, not Docker — use `podman compose` not `docker compose`

## What NOT To Do
- Do not mix sync and async code in FastAPI route handlers
- Do not use SQLite
- Do not hardcode credentials
- Do not use Docker commands — this machine uses Podman
```

> **Why this matters:** Claude Code reads `CLAUDE.md` at the start of every session. The more specific your context, the less you have to explain in every prompt, and the less generic garbage you get back.

---

### Step 2 — Create the folder structure

```bash
cd projects/01-promptos
mkdir -p api models schemas db tests
```

Your structure should look like this:

```
projects/01-promptos/
├── CLAUDE.md
├── api/
│   └── __init__.py
├── models/
│   └── __init__.py
├── schemas/
│   └── __init__.py
├── db/
│   └── __init__.py
├── tests/
│   └── __init__.py
├── main.py
├── podman-compose.yml
├── Dockerfile
├── requirements.txt
└── .env
```

Create the `__init__.py` files:

```bash
touch api/__init__.py models/__init__.py schemas/__init__.py db/__init__.py tests/__init__.py
```

---

### Step 3 — Write the podman-compose.yml

Create `podman-compose.yml` in `projects/01-promptos/`:

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
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U promptos"]
      interval: 5s
      timeout: 5s
      retries: 5

  api:
    build: .
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - .:/app
    command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload

volumes:
  pgdata:
```

Key points:
- `depends_on` with `condition: service_healthy` means the API container only starts after PostgreSQL is accepting connections.
- `volumes: - .:/app` mounts your code into the container so `--reload` works during development.

---

### Step 4 — Write the Dockerfile

Create `Dockerfile` in `projects/01-promptos/`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

### Step 5 — Write requirements.txt

Create `requirements.txt`:

```
fastapi==0.111.0
uvicorn[standard]==0.29.0
sqlalchemy==2.0.30
alembic==1.13.1
psycopg2-binary==2.9.9
pydantic==2.7.1
pydantic-settings==2.2.1
python-dotenv==1.0.1
anthropic==0.26.0
httpx==0.27.0
```

---

### Step 6 — Write the .env file

Create `.env` (this file must NEVER be committed to git):

```
DATABASE_URL=postgresql://promptos:promptos@db:5432/promptos
ANTHROPIC_API_KEY=sk-ant-your-key-here
OLLAMA_URL=http://YOUR_HOMELAB_IP:11434
```

Add `.env` to `.gitignore` immediately:

```bash
echo ".env" >> .gitignore
echo "__pycache__/" >> .gitignore
echo "*.pyc" >> .gitignore
```

---

### Step 7 — Write the minimal FastAPI main.py

Create `main.py`:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="PromptOS API",
    description="Personal prompt management system",
    version="0.1.0",
)

# Allow React dev server to call the API during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # Vite default port
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "promptos-api"}
```

---

### Step 8 — Write the database connection module

Create `db/session.py`:

```python
import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

# Convert the sync postgres:// URL to the async asyncpg driver URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://promptos:promptos@localhost:5432/promptos")
# SQLAlchemy async needs the +asyncpg driver
ASYNC_DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

engine = create_async_engine(ASYNC_DATABASE_URL, echo=True)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    """FastAPI dependency that provides a database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

Add `asyncpg` to your requirements.txt:

```
asyncpg==0.29.0
```

---

### Step 9 — Start the database and verify everything works

Start just the database first:

```bash
podman compose up db -d
```

Check it is running:

```bash
podman ps
```

You should see a container named something like `01-promptos_db_1` with status `Up`.

Connect to it to confirm:

```bash
podman exec -it 01-promptos_db_1 psql -U promptos -d promptos -c "\dt"
```

(It will say "Did not find any relations." — that is correct, no tables yet.)

Now start the full stack:

```bash
podman compose up --build
```

Open your browser at `http://localhost:8000/health`. You should see:

```json
{"status": "ok", "service": "promptos-api"}
```

Open `http://localhost:8000/docs` — you should see the FastAPI auto-generated docs page.

---

## Visual overview

```
Your machine
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   podman compose                                         │
│                                                          │
│   ┌────────────────┐         ┌───────────────────────┐  │
│   │  api container │         │  db container         │  │
│   │  FastAPI       │────────►│  PostgreSQL 15        │  │
│   │  port 8000     │         │  port 5432            │  │
│   │                │         │  pgdata volume        │  │
│   └────────────────┘         └───────────────────────┘  │
│           ▲                                              │
│           │ HTTP                                         │
│   Your browser / curl                                    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> You wrote `CLAUDE.md` before writing any code. When you open a new Claude Code session for P1-T2, how will you update the "Current Task" section? Write the exact text you would put in it for the next task (designing the data model).
>
> Bonus: Compare the output quality of Claude Code with a detailed `CLAUDE.md` vs. just asking "build me a FastAPI app". Document the difference.

---

## Done when

- [ ] `CLAUDE.md` is written and committed to the repo
- [ ] Folder structure (`api/`, `models/`, `schemas/`, `db/`, `tests/`) exists
- [ ] `podman compose up` starts without errors
- [ ] `GET /health` returns `{"status": "ok"}`
- [ ] `http://localhost:8000/docs` loads the FastAPI Swagger UI
- [ ] `.env` is listed in `.gitignore` and NOT committed

---

## Next step

→ After this, do [P1-T2: Design Prompt Data Model](p1-t2-data-model.md)
