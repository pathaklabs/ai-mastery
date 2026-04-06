# P6-T3: Add API Cost Tracking Per Project Per Day

> **Goal:** See exactly how much each project is spending on AI APIs, day by day, with an alert if any project goes over budget.

**Part of:** [P6-US1: Unified Metrics](p6-us1-unified-metrics.md)
**Week:** 11
**Labels:** `task`, `p6-dashboard`

---

## What you are doing

You already built the metrics API in P6-T2. Every project can now send events. This task focuses on one specific event type — `api_cost` — and makes it easy to see exactly what you are spending.

You will:
1. Make sure every project is sending cost events correctly
2. Add a daily alert that warns you if any project exceeds €0.50/day
3. Verify the `daily_costs` SQL view works

This is also your source of truth for the "real numbers" content you will publish. Blog posts and LinkedIn posts are much more credible with actual cost data.

---

## Why this step matters

AI API costs can surprise you. A project that processes 50 documents overnight might cost €2.00 and you would not know unless you are tracking it. Without cost visibility, you are flying blind.

More importantly: the numbers become content. "I ran 5 AI projects for 14 weeks and spent a total of €47" is a concrete, credible claim. It shows you did the work and you measured it.

---

## Prerequisites

- [ ] [P6-T2: Metrics API](p6-t2-metrics-api.md) is complete — the API is running and accepting events
- [ ] The `track()` function is installed in all 5 projects
- [ ] The `daily_costs` view was created in the PostgreSQL schema (from P6-T2)

---

## Step-by-step instructions

### Step 1 — Verify cost events are being sent

Check that each project is calling `track("api_cost", ...)` after every paid API call.

Here is the correct pattern for each project:

**PromptOS** — after every Claude call:

```python
import anthropic
from metrics_client import track

client = anthropic.Anthropic()

def run_prompt(prompt: str, model: str = "claude-sonnet-4-6") -> str:
    response = client.messages.create(
        model=model,
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}]
    )

    # Calculate cost (approximate — update prices as they change)
    input_tokens  = response.usage.input_tokens
    output_tokens = response.usage.output_tokens

    # Claude Sonnet 4.6 pricing (April 2026)
    cost_usd = (input_tokens / 1_000_000 * 3.00) + (output_tokens / 1_000_000 * 15.00)

    # Track both the run and the cost
    track("prompt_run",
          model=model,
          tokens=input_tokens + output_tokens,
          score=None)   # score gets filled in after human rating
    track("api_cost",
          cost_usd,
          model=model,
          input_tokens=input_tokens,
          output_tokens=output_tokens)

    return response.content[0].text
```

**RAG Brain** — after every retrieval + generation:

```python
from metrics_client import track

def answer_query(question: str) -> str:
    # ... your retrieval logic ...
    response = llm.complete(question)

    cost_usd = estimate_cost(response.usage)  # your existing cost calc

    track("query",
          retrieval_quality=0.85,
          hallucination_detected=False,
          source_count=len(source_nodes))
    track("api_cost", cost_usd, model="claude-sonnet-4-6")

    return response.text
```

**PR Review Bot** — after reviewing each PR:

```python
from metrics_client import track

def review_pr(pr_number: int, diff: str) -> dict:
    # ... your review logic ...
    result = call_claude(diff)

    cost_usd = result["cost"]

    track("pr_reviewed",
          issues_found=len(result["issues"]),
          false_positives=0,
          cost_usd=cost_usd,
          diff_lines=len(diff.splitlines()),
          repo=repo_name)
    track("api_cost",
          cost_usd,
          model="claude-sonnet-4-6",
          pr_number=pr_number)

    return result
```

### Step 2 — Query the daily costs

After your projects have been running for a day or two, query the database directly to verify:

```sql
-- How much did each project spend today?
SELECT project, SUM(value) AS cost_usd
FROM metric_events
WHERE event_type = 'api_cost'
  AND DATE(timestamp) = CURRENT_DATE
GROUP BY project
ORDER BY cost_usd DESC;

-- How much did each project spend this week?
SELECT
    project,
    DATE(timestamp) AS date,
    ROUND(SUM(value)::numeric, 4) AS cost_usd
FROM metric_events
WHERE event_type = 'api_cost'
  AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY project, DATE(timestamp)
ORDER BY date DESC, cost_usd DESC;

-- What is the total spend so far this month?
SELECT
    SUM(value) AS total_usd,
    SUM(value) * 0.93 AS total_eur   -- approximate USD to EUR
FROM metric_events
WHERE event_type = 'api_cost'
  AND DATE_TRUNC('month', timestamp) = DATE_TRUNC('month', NOW());
```

### Step 3 — Add the daily alert check

Add this function to your metrics API (`main.py`). It runs as a background check and logs a warning if any project exceeds €0.50/day.

First, add a background scheduler. Add to `requirements.txt`:

```
apscheduler==3.10.4
```

Then add to `main.py`:

```python
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler

logger = logging.getLogger(__name__)

DAILY_ALERT_THRESHOLD_USD = 0.54   # approx €0.50 at current exchange rate

async def check_daily_costs():
    """Run once per hour. Alert if any project exceeds daily threshold."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT project, SUM(value) AS cost_usd
            FROM metric_events
            WHERE event_type = 'api_cost'
              AND DATE(timestamp) = CURRENT_DATE
            GROUP BY project
            HAVING SUM(value) > $1
            """,
            DAILY_ALERT_THRESHOLD_USD
        )

    for row in rows:
        logger.warning(
            "COST ALERT: %s has spent $%.4f today (threshold: $%.2f)",
            row["project"], row["cost_usd"], DAILY_ALERT_THRESHOLD_USD
        )


# Start the scheduler when the app starts
@app.on_event("startup")
async def startup():
    await get_pool()

    scheduler = AsyncIOScheduler()
    scheduler.add_job(check_daily_costs, "interval", hours=1)
    scheduler.start()

    print("Database pool ready. Cost alert scheduler started.")
```

### Step 4 — Add a cost summary API endpoint

Add this read endpoint to `main.py` so the dashboard can fetch cost data:

```python
@app.get("/costs/summary")
async def get_cost_summary():
    """
    Return today's spend, this month's spend, and a projection.
    Used by the dashboard cost panel.
    """
    pool = await get_pool()
    async with pool.acquire() as conn:
        today_rows = await conn.fetch(
            """
            SELECT project, COALESCE(SUM(value), 0) AS cost_usd
            FROM metric_events
            WHERE event_type = 'api_cost'
              AND DATE(timestamp) = CURRENT_DATE
            GROUP BY project
            """
        )

        month_total = await conn.fetchval(
            """
            SELECT COALESCE(SUM(value), 0)
            FROM metric_events
            WHERE event_type = 'api_cost'
              AND DATE_TRUNC('month', timestamp) = DATE_TRUNC('month', NOW())
            """
        )

        days_in_month = await conn.fetchval("SELECT EXTRACT(DAY FROM NOW())")

    total_today = sum(r["cost_usd"] for r in today_rows)
    days_elapsed = float(days_in_month)
    projected = (float(month_total) / days_elapsed * 30) if days_elapsed > 0 else 0

    return {
        "today": {p["project"]: float(p["cost_usd"]) for p in today_rows},
        "today_total_usd": float(total_today),
        "month_total_usd": float(month_total),
        "projected_month_usd": round(projected, 2),
        "budget_usd": 16.20,      # approx €15
        "alert_threshold_usd": DAILY_ALERT_THRESHOLD_USD
    }
```

### Step 5 — Test the cost tracking

Send a few test cost events:

```bash
# Simulate a PromptOS cost event
curl -X POST http://localhost:8006/events \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-key" \
  -d '{
    "project": "promptos",
    "event_type": "api_cost",
    "value": 0.0034,
    "metadata": {"model": "claude-sonnet-4-6", "tokens": 312}
  }'

# Simulate a PR Review cost event
curl -X POST http://localhost:8006/events \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-key" \
  -d '{
    "project": "pr-review",
    "event_type": "api_cost",
    "value": 0.0089,
    "metadata": {"model": "claude-sonnet-4-6", "pr_number": 42}
  }'

# Check the summary
curl http://localhost:8006/costs/summary
```

---

## Visual overview

```
Each project                 metrics_events table          Dashboard
─────────────                ────────────────────          ─────────
After every API call         project │ event_type │ value
                             ────────┼────────────┼───────
track("api_cost", 0.004) ──► promptos│ api_cost   │ 0.004
track("api_cost", 0.009) ──► pr-review│ api_cost  │ 0.009
track("api_cost", 0.001) ──► pipeline│ api_cost   │ 0.001


          Daily aggregation query
          ──────────────────────
          project   │ date       │ total_usd
          ──────────┼────────────┼──────────
          promptos  │ 2026-04-06 │ 0.23
          pr-review │ 2026-04-06 │ 0.41
          pipeline  │ 2026-04-06 │ 0.08


          Alert fires if any project > $0.54/day
                         │
                         ▼
                  logger.warning(...)
                  (extend to send Telegram/email later)
```

---

## Learning checkpoint

**Token-based cost calculation**

Most AI APIs charge per token. To calculate cost yourself:

```
cost = (input_tokens / 1,000,000 * input_price) + (output_tokens / 1,000,000 * output_price)
```

For Claude Sonnet (approximate April 2026 pricing):
- Input: $3.00 per million tokens
- Output: $15.00 per million tokens

Always track `input_tokens` and `output_tokens` separately in metadata — it lets you understand your usage patterns later.

---

## Done when

- [ ] All 5 projects are sending `api_cost` events after every paid API call
- [ ] `GET /costs/summary` returns non-zero values after a day of use
- [ ] `GET /costs/daily` shows per-project breakdown
- [ ] Daily alert check runs every hour and logs a warning for any project over threshold
- [ ] You have seen real cost data in the database (not just test events)

---

## Next step

→ [P6-T4: React Dashboard](p6-t4-react-dashboard.md) — now that the API has data, build the UI that shows it.
