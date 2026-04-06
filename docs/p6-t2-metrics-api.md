# P6-T2: Build the Unified Metrics API

> **Goal:** Build a FastAPI service that accepts metric events from all 5 projects and stores them in PostgreSQL.

**Part of:** [P6-US1: Unified Metrics](p6-us1-unified-metrics.md)
**Week:** 10–11
**Labels:** `task`, `p6-dashboard`

---

## What you are doing

You are building the backbone of the entire dashboard. This is a small FastAPI service with one main job: accept a POST request with a metric event and save it to a database.

Once this is running, all 5 projects can send their events here, and the dashboard can read everything from one place.

This step also includes the `track()` client function that you will paste into each of your 5 projects.

---

## Why this step matters

Without a central metrics store, every project lives in isolation. You have logs, but they are scattered across your homelab. The metrics API turns all those scattered signals into a single queryable table.

This is the same architecture that production monitoring tools use — tools like Datadog, PostHog, and Segment all work this way: events come in from many sources, get stored centrally, and get queried for dashboards.

---

## Prerequisites

- [ ] [P6-T1: Metrics Schema](p6-t1-metrics-schema.md) is complete — you know exactly what each project will send
- [ ] Python 3.11+ installed
- [ ] PostgreSQL running (local or via Docker/Podman)
- [ ] Familiarity with FastAPI from Project 1

---

## Step-by-step instructions

### Step 1 — Set up the project folder

```
projects/06-dashboard/
  api/
    main.py          ← FastAPI app (you will write this)
    database.py      ← database connection
    models.py        ← Pydantic models
    requirements.txt
    .env.example
  dashboard/         ← React app (P6-T4)
  metrics-schema.md
```

Create the folder structure:

```bash
mkdir -p projects/06-dashboard/api
cd projects/06-dashboard/api
```

### Step 2 — Install dependencies

Create `requirements.txt`:

```
fastapi==0.111.0
uvicorn==0.29.0
asyncpg==0.29.0
pydantic==2.7.0
python-dotenv==1.0.1
```

Install:

```bash
pip install -r requirements.txt
```

### Step 3 — Create the PostgreSQL schema

Connect to your PostgreSQL instance and run this SQL. This creates the table that stores every event:

```sql
-- Create the metrics database
CREATE DATABASE pathaklabs_metrics;

\c pathaklabs_metrics;

-- Main events table
CREATE TABLE metric_events (
    id          BIGSERIAL PRIMARY KEY,
    project     TEXT        NOT NULL,
    event_type  TEXT        NOT NULL,
    value       NUMERIC     NOT NULL,
    metadata    JSONB       NOT NULL DEFAULT '{}',
    timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for the queries the dashboard will use
CREATE INDEX idx_events_project     ON metric_events (project);
CREATE INDEX idx_events_event_type  ON metric_events (event_type);
CREATE INDEX idx_events_timestamp   ON metric_events (timestamp DESC);
CREATE INDEX idx_events_project_ts  ON metric_events (project, timestamp DESC);

-- Daily cost view (used by cost charts)
CREATE VIEW daily_costs AS
SELECT
    project,
    DATE(timestamp) AS date,
    SUM(value)      AS total_cost_usd
FROM metric_events
WHERE event_type = 'api_cost'
GROUP BY project, DATE(timestamp)
ORDER BY date DESC;
```

To run this:

```bash
# If PostgreSQL is local:
psql -U postgres -f schema.sql

# If using Docker/Podman:
podman exec -i your-postgres-container psql -U postgres < schema.sql
```

### Step 4 — Write the database connection

Create `database.py`:

```python
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

# Module-level connection pool (created on startup)
_pool = None

async def get_pool():
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(
            dsn=os.environ["DATABASE_URL"],
            min_size=2,
            max_size=10
        )
    return _pool

async def close_pool():
    global _pool
    if _pool:
        await _pool.close()
        _pool = None
```

### Step 5 — Write the Pydantic models

Create `models.py`:

```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Any

class MetricEvent(BaseModel):
    project: str = Field(
        ...,
        description="One of: promptos, rag-brain, pipeline, aiga, pr-review"
    )
    event_type: str = Field(
        ...,
        description="What happened: prompt_run, query, pipeline_run, etc."
    )
    value: float = Field(
        ...,
        description="The metric value. Usually 1 for counts, or a cost/score."
    )
    metadata: dict[str, Any] = Field(
        default_factory=dict,
        description="Extra detail. Different per event type."
    )
    timestamp: Optional[datetime] = Field(
        default=None,
        description="When it happened. Defaults to now if omitted."
    )

# Valid project names — reject anything else
VALID_PROJECTS = {"promptos", "rag-brain", "pipeline", "aiga", "pr-review"}
```

### Step 6 — Write the main FastAPI app

Create `main.py`. This is the complete, working API:

```python
import json
import os
from datetime import datetime, timezone

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

from database import get_pool, close_pool
from models import MetricEvent, VALID_PROJECTS

load_dotenv()

app = FastAPI(
    title="PathakLabs Metrics API",
    description="Unified metrics collector for all 5 AI projects",
    version="1.0.0"
)

# Allow the React dashboard to call this API from a browser
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten this in production to your domain
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

API_KEY = os.environ["METRICS_API_KEY"]


# ── Startup / Shutdown ────────────────────────────────────────────

@app.on_event("startup")
async def startup():
    await get_pool()
    print("Database pool ready.")

@app.on_event("shutdown")
async def shutdown():
    await close_pool()


# ── Authentication helper ─────────────────────────────────────────

def require_api_key(x_api_key: str = Header(None)):
    """All write endpoints require a valid API key in the header."""
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


# ── Write endpoints ───────────────────────────────────────────────

@app.post("/events", status_code=201)
async def receive_event(event: MetricEvent, x_api_key: str = Header(None)):
    """
    Accept a metric event from any project.

    Required header: x-api-key: <your key>

    Example body:
    {
      "project": "promptos",
      "event_type": "prompt_run",
      "value": 1,
      "metadata": { "model": "claude-sonnet-4-6", "score": 4.2 }
    }
    """
    require_api_key(x_api_key)

    # Validate project name
    if event.project not in VALID_PROJECTS:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown project '{event.project}'. Valid: {VALID_PROJECTS}"
        )

    # Default timestamp to now
    ts = event.timestamp or datetime.now(timezone.utc)

    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            """
            INSERT INTO metric_events
              (project, event_type, value, metadata, timestamp)
            VALUES ($1, $2, $3, $4, $5)
            """,
            event.project,
            event.event_type,
            event.value,
            json.dumps(event.metadata),
            ts
        )

    return {"status": "ok", "project": event.project, "event_type": event.event_type}


# ── Read endpoints (public — no auth needed) ──────────────────────

@app.get("/projects")
async def list_projects():
    """Return a health summary for all 5 projects."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT
                project,
                COUNT(*)                         AS total_events,
                MAX(timestamp)                   AS last_seen,
                NOW() - MAX(timestamp)           AS time_since_last_event
            FROM metric_events
            GROUP BY project
            ORDER BY project
            """
        )
    return [dict(r) for r in rows]


@app.get("/projects/{project}/events")
async def get_project_events(project: str, limit: int = 100):
    """Return recent events for one project."""
    if project not in VALID_PROJECTS:
        raise HTTPException(status_code=404, detail="Project not found")

    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT project, event_type, value, metadata, timestamp
            FROM metric_events
            WHERE project = $1
            ORDER BY timestamp DESC
            LIMIT $2
            """,
            project, limit
        )
    return [dict(r) for r in rows]


@app.get("/projects/{project}/sparkline")
async def get_sparkline(project: str, days: int = 7):
    """Return daily event counts for the past N days — used by the sparkline chart."""
    if project not in VALID_PROJECTS:
        raise HTTPException(status_code=404, detail="Project not found")

    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT
                DATE(timestamp) AS date,
                COUNT(*)        AS event_count
            FROM metric_events
            WHERE project = $1
              AND event_type != 'api_cost'
              AND timestamp >= NOW() - INTERVAL '1 day' * $2
            GROUP BY DATE(timestamp)
            ORDER BY date ASC
            """,
            project, days
        )
    return [dict(r) for r in rows]


@app.get("/costs/daily")
async def get_daily_costs(days: int = 30):
    """Return daily API cost per project for the past N days."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT
                project,
                DATE(timestamp)  AS date,
                SUM(value)       AS total_cost_usd
            FROM metric_events
            WHERE event_type = 'api_cost'
              AND timestamp >= NOW() - INTERVAL '1 day' * $1
            GROUP BY project, DATE(timestamp)
            ORDER BY date DESC, project
            """,
            days
        )
    return [dict(r) for r in rows]


@app.get("/health")
async def health():
    """Simple health check endpoint."""
    return {"status": "ok", "service": "pathaklabs-metrics-api"}
```

### Step 7 — Create the environment file

Create `.env` (and add it to `.gitignore`):

```bash
# .env
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/pathaklabs_metrics
METRICS_API_KEY=change-this-to-a-long-random-string
```

Generate a strong API key:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Step 8 — Run the API locally

```bash
uvicorn main:app --reload --port 8006
```

Visit `http://localhost:8006/docs` — you will see the interactive API docs (Swagger UI). Try the `/health` endpoint to confirm it is working.

### Step 9 — Add the `track()` function to each project

This is the client function. It is the same for all 5 projects — only the `"project"` value changes. Add it to each project's codebase.

```python
# metrics_client.py  ← add this file to each project

import os
import requests
from datetime import datetime, timezone

METRICS_URL = os.environ.get("METRICS_URL", "http://localhost:8006")
METRICS_KEY = os.environ.get("METRICS_API_KEY", "")

# Change this constant in each project file:
PROJECT_NAME = "promptos"   # or "rag-brain" / "pipeline" / "aiga" / "pr-review"

def track(event_type: str, value: float = 1.0, **metadata) -> None:
    """
    Send a metric event to the central metrics API.

    Fails silently — a metrics failure must never break the main app.

    Usage:
        track("prompt_run", model="claude-sonnet-4-6", score=4.2)
        track("api_cost", 0.004, model="claude-sonnet-4-6", tokens=312)
    """
    try:
        requests.post(
            f"{METRICS_URL}/events",
            json={
                "project": PROJECT_NAME,
                "event_type": event_type,
                "value": value,
                "metadata": metadata,
                "timestamp": datetime.now(timezone.utc).isoformat()
            },
            headers={"x-api-key": METRICS_KEY},
            timeout=2   # never wait more than 2 seconds
        )
    except Exception:
        pass  # metrics must never crash the main app
```

Then use it anywhere in the project:

```python
# In PromptOS, after a successful prompt run:
from metrics_client import track

track("prompt_run", model="claude-sonnet-4-6", tokens=312, score=4.2)
track("api_cost", 0.004, model="claude-sonnet-4-6", tokens=312)

# In PR Review Bot, after reviewing a PR:
track("pr_reviewed", issues_found=3, cost_usd=0.008, diff_lines=142, repo="my-repo")
```

### Step 10 — Add environment variables to each project

Add to each project's `.env`:

```bash
METRICS_URL=http://your-homelab-ip:8006
METRICS_API_KEY=the-same-key-from-the-api
```

### Step 11 — Test end-to-end

Send a test event using curl:

```bash
curl -X POST http://localhost:8006/events \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-api-key-here" \
  -d '{
    "project": "promptos",
    "event_type": "prompt_run",
    "value": 1,
    "metadata": {"model": "claude-sonnet-4-6", "score": 4.2}
  }'

# Expected response:
# {"status": "ok", "project": "promptos", "event_type": "prompt_run"}
```

Then check it was saved:

```bash
curl http://localhost:8006/projects/promptos/events
```

---

## Visual overview

```
                    THE METRICS API
                    ───────────────

  Each project                    PostgreSQL
  ───────────                     ──────────
  track(...)  ──► POST /events ──► metric_events table
                      │
                      │ (validates API key + project name)
                      │
              GET /projects       ◄── React Dashboard
              GET /projects/{p}/sparkline
              GET /costs/daily


  Security model:
  ┌──────────────────────────────────────┐
  │  Write: requires x-api-key header   │
  │  Read:  public, no auth needed      │
  └──────────────────────────────────────┘
```

---

## Learning checkpoint

**Why does `track()` fail silently?**

The metrics system is support infrastructure — it exists to help you, not to affect your users. If the metrics API is down for some reason, you do not want PromptOS to crash because of it. The `try/except pass` pattern ensures the main application always keeps running even if the side-channel metric call fails.

This is called "fire and forget" telemetry, and it is standard practice in production systems.

---

## Done when

- [ ] FastAPI service runs on port 8006
- [ ] `POST /events` accepts and stores valid events, rejects invalid API keys
- [ ] `GET /projects` returns data after events are sent
- [ ] `GET /health` returns 200
- [ ] `track()` function is installed in all 5 projects
- [ ] Test event successfully stored in PostgreSQL

---

## Next step

→ [P6-T3: Cost Tracking](p6-t3-cost-tracking.md) — now that the API is running, add daily cost aggregation and alerts.
