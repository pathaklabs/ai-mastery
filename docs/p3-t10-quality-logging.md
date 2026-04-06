# P3-T10: Add Per-Agent Quality Scoring and Logging

> **Goal:** Add a logging Code node after each agent so every pipeline run is recorded in MariaDB — what went in, what came out, and how well it performed.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 7
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are adding one Code node after each of the 6 agents. Each node logs a structured record to MariaDB documenting that agent's performance for this run.

This is **observability** — the practice of making a system's internal behaviour visible from the outside.

Without logging, if the pipeline runs and produces a bad LinkedIn post, you have no idea:
- Which agent produced bad output?
- Did Pre-filter let too many junk articles through?
- Did Validator score badly that day?
- Did Claude misfire, or was the input data just poor?

Logging gives you the evidence to answer these questions.

---

## Why this step matters

> This is production AI observability. If an agent silently returns bad output — wrong format, low quality, hallucinated data — your pipeline runs, posts bad content, and you never know. Logging catches it.

```
Without logging:
  Pipeline runs → bad post appears → you have no idea why

With logging:
  Pipeline runs → bad post appears
  → You check MariaDB
  → "Pre-filter only passed 2 articles — it was too aggressive"
  → You fix the threshold
  → Problem solved in 10 minutes instead of 2 hours of guessing
```

This is not extra work. This is how real systems are built.

---

## Prerequisites

- [ ] [P3-T9](p3-t9-synthesizer-agent.md) complete — full pipeline runs end-to-end
- [ ] MariaDB running and accessible from n8n
- [ ] `processed_urls` table already exists (from P3-T7)

---

## Step-by-step instructions

### Step 1 — Create the logging table in MariaDB

Run this SQL on your MariaDB database:

```sql
CREATE TABLE IF NOT EXISTS pipeline_logs (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  run_id        VARCHAR(128) NOT NULL,
  agent_name    VARCHAR(64) NOT NULL,
  timestamp     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  input_count   INT NOT NULL DEFAULT 0,
  output_count  INT NOT NULL DEFAULT 0,
  quality_score DECIMAL(4,2),
  failed        BOOLEAN NOT NULL DEFAULT FALSE,
  error_message TEXT,
  metadata      JSON,
  topic         VARCHAR(512),
  INDEX idx_run_id (run_id),
  INDEX idx_agent_name (agent_name),
  INDEX idx_timestamp (timestamp)
);
```

Column meanings:
- `run_id`: Unique ID for this pipeline run (all agents in one run share this ID)
- `agent_name`: Which agent this row represents
- `input_count`: How many items entered this agent
- `output_count`: How many items passed through (output_count < input_count means filtering happened)
- `quality_score`: Optional — average score, word count, or other quality measure
- `failed`: TRUE if this agent threw an error
- `error_message`: The error text if it failed
- `metadata`: JSON blob for any extra data you want to store
- `topic`: The research topic for this run

---

### Step 2 — Generate a run ID at the start of the pipeline

At the very beginning of your workflow (after the Input — Set Topic node), add a **Code** node. Name it: `Generate Run ID`.

```javascript
// Create a unique run ID for this pipeline execution
// All log entries for this run will share this ID
const runId = `run_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

console.log(`Starting pipeline run: ${runId}`);

return [{
  json: {
    ...$input.first().json,
    run_id: runId,
    pipeline_started_at: new Date().toISOString()
  }
}];
```

All subsequent nodes can access `{{ $('Generate Run ID').item.json.run_id }}` to include the run ID in their logs.

---

### Step 3 — Create the log function Code node template

This is the template you will reuse (with slight changes) after each agent. Create a Code node and paste this, then customise the `AGENT_NAME` and `quality_score` calculation.

```javascript
// ============================================================
// LOGGING NODE — runs after each agent
// Change: AGENT_NAME, quality_score calculation
// ============================================================

const AGENT_NAME = 'Planner'; // <-- CHANGE THIS per agent

// Count input and output
const inputItems = $input.all();
const outputCount = inputItems.length; // how many items this agent produced

// Get the run ID from the start of the pipeline
const runId = $('Generate Run ID').item?.json?.run_id || 'unknown';
const topic = $('Input — Set Topic').item?.json?.topic || 'unknown';

// Calculate quality score (customise per agent)
let qualityScore = null;
if (AGENT_NAME === 'Validator') {
  // Average of all article scores
  const scores = inputItems.map(i => i.json.scores?.average || 0);
  qualityScore = scores.length > 0
    ? Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 10) / 10
    : null;
}

// Build the log entry
const logEntry = {
  run_id: runId,
  agent_name: AGENT_NAME,
  timestamp: new Date().toISOString(),
  input_count: outputCount,   // This node runs AFTER the agent, so input = agent output
  output_count: outputCount,
  quality_score: qualityScore,
  failed: false,
  error_message: null,
  topic: topic,
  metadata: JSON.stringify({
    sample_item: inputItems[0]?.json ? {
      // Include a non-sensitive sample for debugging
      url: inputItems[0].json.url,
      title: inputItems[0].json.title
    } : null
  })
};

console.log(`Log: ${AGENT_NAME} → in: ${logEntry.input_count}, out: ${logEntry.output_count}`);

// Pass through all input items unchanged (logging should not block the pipeline)
return inputItems;
```

---

### Step 4 — Add a MariaDB Insert node after each log Code node

After the log Code node for each agent, add a **MariaDB** node. Name it: `Log — [Agent Name]`.

**Operation:** Execute Query
**Query:**

```sql
INSERT INTO pipeline_logs
  (run_id, agent_name, input_count, output_count, quality_score, failed, error_message, topic, metadata)
VALUES (
  '{{ $json.run_id }}',
  '{{ $json.agent_name }}',
  {{ $json.input_count }},
  {{ $json.output_count }},
  {{ $json.quality_score !== null ? $json.quality_score : 'NULL' }},
  {{ $json.failed ? 1 : 0 }},
  {{ $json.error_message ? `'${$json.error_message}'` : 'NULL' }},
  '{{ $json.topic }}',
  '{{ $json.metadata }}'
)
```

**Better approach:** Use a Code node that makes an HTTP request to your homelab API, or directly use n8n's MariaDB node with parameter binding to avoid SQL injection.

---

### Step 5 — Add logging after each agent

Go through your workflow and add a log Code node + MariaDB node after each of the 6 agents:

```
[Planner] → [Log: Planner] → [MariaDB: Insert Log]
         ↓
[Search] → [Log: Search] → [MariaDB: Insert Log]
         ↓
[Pre-filter] → [Log: Pre-filter] → [MariaDB: Insert Log]
         ↓
[Validator] → [Log: Validator] → [MariaDB: Insert Log]
         ↓
[Extractor] → [Log: Extractor] → [MariaDB: Insert Log]
         ↓
[Synthesizer] → [Log: Synthesizer] → [MariaDB: Insert Log]
         ↓
[Telegram]
```

For each logging node, change `AGENT_NAME` and the `quality_score` calculation:

| Agent | AGENT_NAME value | quality_score |
|-------|-----------------|---------------|
| Planner | `'Planner'` | number of queries generated |
| Search | `'Search'` | number of articles returned |
| Pre-filter | `'Pre-filter'` | pass rate: output/input * 100 |
| Validator | `'Validator'` | average score of passing articles |
| Extractor | `'Extractor'` | number of facts extracted |
| Synthesizer | `'Synthesizer'` | word count of LinkedIn post |

---

### Step 6 — Add error logging with n8n error handling

n8n has a built-in **Error Trigger** node — it fires if any node in the workflow fails.

1. Add a new node: `Error Trigger`
2. Connect it to a **Code + MariaDB** chain that logs the failure

Error logging Code node:
```javascript
const error = $input.first().json;

return [{
  json: {
    run_id: error.execution?.workflowData?.id || 'unknown',
    agent_name: error.node?.name || 'unknown',
    failed: true,
    error_message: error.error?.message || 'Unknown error',
    input_count: 0,
    output_count: 0,
    quality_score: null,
    topic: 'unknown',
    metadata: JSON.stringify({ raw_error: error })
  }
}];
```

---

## Visual overview

```
┌────────────────────────────────────────────────────────────────┐
│  Pipeline with Logging                                          │
│                                                                 │
│  [Run ID] → [Planner] → [LOG] → [Search] → [LOG] →            │
│                          ↓                   ↓                 │
│                    MariaDB Insert       MariaDB Insert          │
│                                                                 │
│  [Pre-filter] → [LOG] → [Validator] → [LOG] → ...             │
│                   ↓                     ↓                      │
│             MariaDB Insert         MariaDB Insert               │
│                                                                 │
│  Result: Every run creates 6 rows in pipeline_logs             │
└────────────────────────────────────────────────────────────────┘

pipeline_logs table after 3 runs:
┌────────┬──────────────┬─────────────┬──────────────┬──────────────┬────────┐
│ run_id │  agent_name  │ input_count │ output_count │ quality_score│ failed │
├────────┼──────────────┼─────────────┼──────────────┼──────────────┼────────┤
│ run_1  │ Planner      │ 1           │ 4            │ null         │ false  │
│ run_1  │ Search       │ 4           │ 31           │ null         │ false  │
│ run_1  │ Pre-filter   │ 31          │ 19           │ 61.3         │ false  │
│ run_1  │ Validator    │ 19          │ 8            │ 7.4          │ false  │
│ run_1  │ Extractor    │ 8           │ 8            │ 4.1          │ false  │
│ run_1  │ Synthesizer  │ 8           │ 1            │ 218          │ false  │
└────────┴──────────────┴─────────────┴──────────────┴──────────────┴────────┘
```

---

## Learning checkpoint

> Before moving on, write in your build log:
> "Looking at what I would monitor in production — if I came in on a Monday morning and the pipeline had been running all weekend, what three numbers would I check first in `pipeline_logs` to know if everything was working? Why those three?"

This is the difference between someone who builds features and someone who operates systems.

---

## Done when

- [ ] `pipeline_logs` table created in MariaDB
- [ ] `run_id` generated at pipeline start and passed through
- [ ] Log Code node exists after each of the 6 agents
- [ ] MariaDB Insert node saves log after each agent
- [ ] Error Trigger node logs failures to `pipeline_logs` with `failed = true`
- [ ] Test run creates 6 rows in `pipeline_logs` (one per agent)
- [ ] Quality scores are populated where defined

---

## Next step

→ [P3-T11: Build Pipeline Run Summary Dashboard](p3-t11-run-dashboard.md)
