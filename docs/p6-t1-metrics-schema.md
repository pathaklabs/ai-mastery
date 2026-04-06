# P6-T1: Define Metrics Schema for All 5 Projects

> **Goal:** Write down exactly what each project will send to the metrics API before building anything.

**Part of:** [P6-US1: Unified Metrics](p6-us1-unified-metrics.md)
**Week:** 10
**Labels:** `task`, `p6-dashboard`

---

## What you are doing

Before writing a single line of API code, you are going to decide exactly what data each project will send. This is called defining your schema — the shape of the data.

Think of it like designing a form before you build a database. If you skip this step, you will end up with inconsistent data that is hard to query and visualise.

This step produces one file: `projects/06-dashboard/metrics-schema.md`. It takes about an hour to write, and it saves you days of confusion later.

---

## Why this step matters

Every project sends events to the same API endpoint. If each project uses different field names, different value types, or different timestamp formats, your dashboard queries become impossible.

Agree on the schema first. Build to that agreement second.

---

## Prerequisites

- [ ] You have read the [P6-E1 Epic Overview](p6-e1-ai-dashboard.md) and understand how the data flows
- [ ] All 5 projects (P1–P5) are at least partially running — you need to know what they actually do before you can define what to track

---

## Step-by-step instructions

### Step 1 — Understand the event structure

Every event sent to the metrics API has this shape:

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

| Field | Type | Description |
|-------|------|-------------|
| `project` | string | One of: `promptos`, `rag-brain`, `pipeline`, `aiga`, `pr-review` |
| `event_type` | string | What happened (e.g. `prompt_run`, `query`, `pr_reviewed`) |
| `value` | float | The number (usually `1` for counts, or a real cost/score) |
| `metadata` | object | Extra detail — different per event type |
| `timestamp` | ISO datetime | When it happened. If omitted, the API uses the current time. |

### Step 2 — Define events for each project

Copy this schema into `projects/06-dashboard/metrics-schema.md` and use it as your reference for the rest of Project 6.

---

#### PromptOS (P1)

| event_type | value | metadata fields |
|-----------|-------|----------------|
| `prompt_run` | 1 | `model`, `tokens`, `score` (1–5), `tags` |
| `prompt_saved` | 1 | `title`, `tags` |
| `api_cost` | cost in USD | `model`, `tokens` |

**Example events:**

```json
{ "project": "promptos", "event_type": "prompt_run", "value": 1,
  "metadata": { "model": "claude-sonnet-4-6", "tokens": 312, "score": 4.2 } }

{ "project": "promptos", "event_type": "api_cost", "value": 0.004,
  "metadata": { "model": "claude-sonnet-4-6", "tokens": 312 } }
```

---

#### RAG Brain (P2)

| event_type | value | metadata fields |
|-----------|-------|----------------|
| `query` | 1 | `retrieval_quality` (0–1), `hallucination_detected` (bool), `source_count` |
| `document_ingested` | 1 | `doc_type`, `chunk_count` |
| `api_cost` | cost in USD | `model`, `tokens` |

**Example events:**

```json
{ "project": "rag-brain", "event_type": "query", "value": 1,
  "metadata": { "retrieval_quality": 0.87, "hallucination_detected": false, "source_count": 4 } }

{ "project": "rag-brain", "event_type": "document_ingested", "value": 1,
  "metadata": { "doc_type": "ha_yaml", "chunk_count": 14 } }
```

---

#### Content Pipeline (P3)

| event_type | value | metadata fields |
|-----------|-------|----------------|
| `pipeline_run` | 1 | `articles_found`, `posts_sent`, `run_duration_s` |
| `post_sent_to_approval` | 1 | `topic`, `source_url` |
| `api_cost` | cost in USD | `model`, `tokens` |

**Example events:**

```json
{ "project": "pipeline", "event_type": "pipeline_run", "value": 1,
  "metadata": { "articles_found": 8, "posts_sent": 3, "run_duration_s": 47 } }

{ "project": "pipeline", "event_type": "post_sent_to_approval", "value": 1,
  "metadata": { "topic": "AI regulation", "source_url": "https://..." } }
```

---

#### AIGA — AI Governance Assistant (P4)

| event_type | value | metadata fields |
|-----------|-------|----------------|
| `governance_query` | 1 | `risk_level_returned`, `topic`, `framework_used` |
| `risk_assessment` | 1 | `risk_level`, `system_type` |
| `api_cost` | cost in USD | `model`, `tokens` |

**Example events:**

```json
{ "project": "aiga", "event_type": "governance_query", "value": 1,
  "metadata": { "risk_level_returned": "medium", "topic": "facial recognition", "framework_used": "EU AI Act" } }

{ "project": "aiga", "event_type": "risk_assessment", "value": 1,
  "metadata": { "risk_level": "high", "system_type": "biometric" } }
```

---

#### PR Review Bot (P5)

| event_type | value | metadata fields |
|-----------|-------|----------------|
| `pr_reviewed` | 1 | `issues_found`, `false_positives`, `cost_usd`, `diff_lines`, `repo` |
| `pr_skipped_too_large` | 1 | `diff_lines`, `repo` |
| `api_cost` | cost in USD | `model`, `tokens`, `pr_number` |

**Example events:**

```json
{ "project": "pr-review", "event_type": "pr_reviewed", "value": 1,
  "metadata": { "issues_found": 3, "false_positives": 0, "cost_usd": 0.008, "diff_lines": 142, "repo": "ai-mastery" } }

{ "project": "pr-review", "event_type": "pr_skipped_too_large", "value": 1,
  "metadata": { "diff_lines": 3201, "repo": "big-monorepo" } }
```

### Step 3 — Agree on the project name strings

Write these down. They must match exactly across all 5 projects:

```
promptos
rag-brain
pipeline
aiga
pr-review
```

If one project sends `"promptOS"` and another sends `"promptos"`, your dashboard queries will break. Consistency matters.

### Step 4 — Create the schema file

Create `projects/06-dashboard/metrics-schema.md` containing the full table above. Commit it before you write any API code.

```
projects/
  06-dashboard/
    metrics-schema.md    ← create this now
    api/                 ← will create in P6-T2
    dashboard/           ← will create in P6-T4
```

---

## Visual overview

```
                     ONE EVENT SHAPE
                     ──────────────
                   ┌──────────────────┐
                   │ project          │  ← which system sent it
                   │ event_type       │  ← what happened
                   │ value            │  ← the number
                   │ metadata { }     │  ← extra detail
                   │ timestamp        │  ← when
                   └──────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
          PromptOS      Pipeline     PR Review
         (uses same    (uses same   (uses same
          shape)        shape)       shape)
```

Every project sends the same outer structure. Only `metadata` changes per event type. This makes the API trivial to build and the queries easy to write.

---

## Learning checkpoint

**Why define schema before code?**

In software, it is much easier to agree on a data structure first and build to it, rather than building five independent systems and trying to merge them later. This is the same reason APIs have documentation before implementation, and databases have designs before rows.

The 30 minutes you spend writing this schema file will save you 3 hours of fixing mismatched data later.

---

## Done when

- [ ] `projects/06-dashboard/metrics-schema.md` exists and is committed
- [ ] All 5 projects' event types are listed with their value and metadata fields
- [ ] The exact project name strings are documented and agreed
- [ ] You have reviewed the schema against the actual code in each project to confirm the events make sense

---

## Next step

→ [P6-T2: Build the Metrics API](p6-t2-metrics-api.md) — now that you know what data to accept, build the endpoint that receives it.
