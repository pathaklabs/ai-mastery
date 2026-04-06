# P6-E1: PathakLabs AI Monitoring Dashboard

> **Epic goal:** Build a single dashboard that shows the health, cost, and content status of all 5 running AI projects — then deploy it publicly as your portfolio centrepiece.

**Weeks:** 10–14
**Labels:** `epic`, `p6-dashboard`

---

## What you are building

By the time you reach Week 10, you have 5 projects running. The dashboard brings them all together in one view.

```
┌─────────────────────────────────────────────────────────────────┐
│              PathakLabs AI Dashboard                            │
├───────────┬──────────────┬────────────┬──────────┬─────────────┤
│ PromptOS  │  RAG Brain   │  Pipeline  │  AIGA    │  PR Review  │
│ ─────────│─────────────│────────────│──────────│─────────────│ │
│ 🟢 Live   │ 🟢 Live      │ 🟡 Idle   │ 🟢 Live  │ 🟢 Live     │
│           │             │            │          │             │
│ Prompts   │ Queries     │ Last run   │ Queries  │ PRs reviewed│
│ saved: 47 │ today: 23   │ 2h ago     │ today: 8 │ this week: 5│
│           │             │            │          │             │
│ ▁▂▃▄▅▆▇█  │ ▁▁▂▃▃▄▅▇   │ ▁▂▁▃▂▄▁▂  │ ▃▄▃▄▅▆▄▅ │ ▂▂▃▃▄▃▄▅   │
│ 7-day     │ 7-day       │ 7-day      │ 7-day    │ 7-day       │
├───────────┴──────────────┴────────────┴──────────┴─────────────┤
│ Total API cost today: €0.34   This month: €8.12   Budget: €15  │
│ Content: 12 build logs  6 LinkedIn posts  3 blogs  2 carousels │
└─────────────────────────────────────────────────────────────────┘
```

This is also your public portfolio. A potential employer, client, or collaborator will see this and immediately understand what you built and how it performs.

---

## Definition of done

- [ ] Unified metrics API — all 5 projects push events here
- [ ] Cost tracking per project per day
- [ ] React dashboard with project health cards
- [ ] Content publishing tracker
- [ ] Deployed publicly on shailesh-pathak.com

---

## How the data flows

```
PromptOS ──────┐
RAG Brain ─────┤
Pipeline ──────┼──► Metrics API ──► PostgreSQL ──► React Dashboard ──► shailesh-pathak.com
AIGA ──────────┤         ▲
PR Review ─────┘         │
                   Each project sends
                   events here as things happen
```

Every project sends a small event every time something notable happens:

```json
{
  "project": "promptos",
  "event_type": "prompt_run",
  "value": 1,
  "metadata": {
    "model": "claude-sonnet-4-6",
    "tokens": 312,
    "score": 4.2
  },
  "timestamp": "2026-04-06T10:23:00Z"
}
```

---

## Week 10 — Define Metrics and Build API

### Step 1 — Define the metrics schema for all 5 projects (P6-T1)

Write out exactly what each project will send. Do this before building anything.

| Project | Event type | Value | Example metadata |
|---------|-----------|-------|-----------------|
| PromptOS | `prompt_run` | 1 | `model, tokens, score` |
| PromptOS | `prompt_saved` | 1 | `title, tags` |
| RAG Brain | `query` | 1 | `retrieval_quality, hallucination_detected` |
| RAG Brain | `document_ingested` | 1 | `doc_type, chunk_count` |
| Pipeline | `pipeline_run` | 1 | `articles_found, posts_sent, run_duration_s` |
| Pipeline | `post_sent_to_telegram` | 1 | `topic` |
| AIGA | `governance_query` | 1 | `risk_level_returned, topic` |
| AIGA | `risk_assessment` | 1 | `risk_level, system_type` |
| PR Review | `pr_reviewed` | 1 | `issues_found, cost_usd, diff_lines` |
| PR Review | `pr_skipped_too_large` | 1 | `diff_lines` |

Create `projects/06-dashboard/metrics-schema.md` with this table before building.

---

### Step 2 — Build the unified metrics API (P6-T2)

A single FastAPI endpoint that accepts events from all 5 projects:

```python
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from datetime import datetime
import os

app = FastAPI()

class MetricEvent(BaseModel):
    project: str        # "promptos", "rag-brain", "pipeline", "aiga", "pr-review"
    event_type: str     # "prompt_run", "query", "pipeline_run", etc.
    value: float        # the metric value (usually 1 for counts)
    metadata: dict      # any extra data
    timestamp: datetime = None

API_KEY = os.environ["METRICS_API_KEY"]

@app.post("/events")
async def receive_event(
    event: MetricEvent,
    x_api_key: str = Header(None)
):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")

    # Store in PostgreSQL
    await db.execute("""
        INSERT INTO metric_events
          (project, event_type, value, metadata, timestamp)
        VALUES ($1, $2, $3, $4, $5)
    """, event.project, event.event_type, event.value,
         json.dumps(event.metadata), event.timestamp or datetime.utcnow())

    return {"status": "ok"}
```

Now add the client code to each of your 5 projects:

```python
# Add this to each project (one small function)
import requests, os

METRICS_URL = os.environ.get("METRICS_URL", "http://localhost:8006")
METRICS_KEY = os.environ.get("METRICS_API_KEY", "")

def track(event_type: str, value: float = 1, **metadata):
    """Send a metric event. Fails silently — never block the main app."""
    try:
        requests.post(
            f"{METRICS_URL}/events",
            json={
                "project": "promptos",   # change per project
                "event_type": event_type,
                "value": value,
                "metadata": metadata
            },
            headers={"x-api-key": METRICS_KEY},
            timeout=2
        )
    except Exception:
        pass   # metrics failure must never break the main app
```

---

## Week 11 — Cost Tracking and Dashboard

### Step 3 — Add API cost tracking per project per day (P6-T3)

Every time your projects call Claude or other paid APIs, log the cost:

```python
# In PromptOS, after every Claude call:
track("api_cost", value=estimated_cost_usd, model="claude-sonnet-4-6")

# In PR Review Bot:
track("api_cost", value=review_cost_usd, pr_number=pr_number)
```

The metrics API stores all cost events. A daily aggregation query gives you:

```sql
SELECT
  project,
  DATE(timestamp) as date,
  SUM(value) as total_cost_usd
FROM metric_events
WHERE event_type = 'api_cost'
GROUP BY project, DATE(timestamp)
ORDER BY date DESC;
```

Set an alert threshold: if any project exceeds €0.50/day, log a warning.

---

### Step 4 — Build React dashboard with project health cards (P6-T4)

Each project gets a card:

```
┌─────────────────────────────────┐
│ PromptOS                 🟢 Live │
│ ─────────────────────────────── │
│ Prompts saved this week: 12     │
│ Avg prompt score: 4.1 / 5       │
│ Model breakdown:                │
│   Claude: 68%  Ollama: 32%      │
│                                 │
│ ▁▂▃▄▅▆▇█▇▆▅  (7-day sparkline) │
│                                 │
│ [View on GitHub ↗]              │
└─────────────────────────────────┘
```

Status indicator logic:

| Status | Condition |
|--------|-----------|
| 🟢 Live | At least one event in the last 24 hours |
| 🟡 Idle | Last event was 24–72 hours ago |
| 🔴 Down | No events in 72+ hours |

Build 5 identical card components, one per project.

---

### Step 5 — Add cost breakdown charts (P6-T5)

Three charts on the costs page:

**Chart 1 — Daily cost per project (stacked bar chart)**

```
€0.50 │
€0.40 │         ████
€0.30 │    ████ ████ ████
€0.20 │    ████ ████ ████ ████
€0.10 │ ██ ████ ████ ████ ████
€0.00 └──────────────────────────
       Mon  Tue  Wed  Thu  Fri

■ PromptOS  ■ RAG Brain  ■ Pipeline  ■ AIGA  ■ PR Review
```

**Chart 2 — Model usage breakdown (pie chart)**

```
Claude Sonnet 4.6: 45%
Gemini: 28%
Ollama (free): 22%
DeepSeek: 5%
```

**Chart 3 — Monthly total with projection**

```
April spend so far: €12.40
Projected month total: €21.80
Budget: €30.00
Budget remaining: €8.20
```

---

## Week 12 — Content Tracker

### Step 6 — Add content publishing tracker (P6-T6)

A simple table showing your publishing progress:

```
┌──────────┬────────────┬────────────┬─────────┬───────────┐
│ Project  │ Build Logs │ LinkedIn   │ Blog    │ Instagram │
├──────────┼────────────┼────────────┼─────────┼───────────┤
│ P1       │ ✓ ✓ ✓      │ ✓          │ ✓       │ ✓         │
│ P2       │ ✓ ✓ ○      │ ✓          │ ○       │ ○         │
│ P3       │ ✓ ✓ ✓ ○ ○  │ ○          │ ○       │ ○         │
│ P4       │ —          │ ○          │ ○       │ ○         │
│ P5       │ —          │ ○          │ ○       │ —         │
│ P6       │ —          │ ○          │ ○       │ ○         │
└──────────┴────────────┴────────────┴─────────┴───────────┘
✓ = published  ○ = not yet  — = not applicable
```

Update this manually each time you publish something. It holds you accountable to the content system you set up in Week 1.

---

## Week 13 — Deploy Publicly

### Step 7 — Deploy dashboard to shailesh-pathak.com (P6-T7)

The public dashboard is the most powerful portfolio item you can show. It proves you built 5 working systems, not just 5 repositories.

Deployment steps:

1. Build the React app: `npm run build`
2. Set up a subdomain: `dashboard.shailesh-pathak.com` or `labs.shailesh-pathak.com`
3. Deploy the FastAPI metrics API on your homelab with a public port (or a VPS)
4. Deploy the React build to your hosting (Netlify, Vercel, or your own server)
5. Add a link from your main portfolio to the dashboard

Make the public view read-only — no login needed to view, but metrics API requires an API key to write.

---

## Week 14 — Capstone Content

These are the most important pieces of content you will publish in the entire program:

### P6-C1: 14-week capstone blog post

**Your most important piece of content. Write it carefully.**

Structure (2000 words):
1. Why you started (what gap were you trying to fill?)
2. One key lesson per project (6 paragraphs, each with one concrete insight)
3. What you would do differently (honest reflection)
4. What you can build now that you could not 14 weeks ago
5. What is next for PathakLabs

### P6-C2: LinkedIn retrospective series

6 posts, one per project. Each under 300 words. Each must include one concrete number or result:
- "PromptOS: I scored 200 AI outputs. Here is what separates a 5-star prompt from a 2-star one."
- "RAG Brain: My hallucination detection caught 23% of answers. That number surprised me."

### P6-C3: Instagram reel

A screen recording walkthrough of the live dashboard. Show all 5 project cards, cost charts, and content tracker. Raw and real builds more trust than polished and staged.

---

## Full task checklist

### Week 10
- [ ] P6-T1: Define metrics schema for all 5 projects
- [ ] P6-T2: Build unified metrics API (FastAPI + PostgreSQL)
- [ ] Add `track()` client function to all 5 projects

### Week 11
- [ ] P6-T3: Add API cost tracking per project per day
- [ ] P6-T4: Build React dashboard with project health cards

### Week 12
- [ ] P6-T5: Add cost breakdown charts
- [ ] P6-T6: Add content publishing tracker

### Week 13
- [ ] P6-T7: Deploy dashboard to shailesh-pathak.com (public)
- [ ] P6-C2: LinkedIn retrospective series (6 posts, weeks 13–14)

### Week 14
- [ ] P6-C1: Blog — 14-week capstone retrospective (write this carefully)
- [ ] P6-C3: Instagram reel — screen recording of live dashboard
