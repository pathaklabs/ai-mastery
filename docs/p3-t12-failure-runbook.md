# P3-T12: Write Agent Failure Runbook

> **Goal:** Document how to detect, recover from, and prevent failures for each of the 6 agents.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 8
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are writing a runbook — a reference document that answers the question: "Something broke. What do I do?"

A runbook is a classic DevOps tool. It documents known failure modes and their remedies so that when things break (and they will), you do not have to figure it out from scratch at 11pm.

> This is production engineering thinking applied to AI systems.

The pipeline you have built is not a demo. It runs on a schedule, processes external data, calls paid APIs, and sends content to Telegram. When it breaks silently, you need a reference to diagnose and fix it quickly.

---

## Why this step matters

```
Without a runbook:
  "Pipeline failed. Let me check every node one by one..."
  *45 minutes later*
  "Oh, Tavily rate limit. I should have known."

With a runbook:
  Check the error in pipeline_logs → agent_name = "Search"
  Open runbook → Search → "Most likely failure: Tavily rate limit (HTTP 429)"
  Fix: wait 60 seconds, re-run from Search
  *5 minutes total*
```

AI systems have more failure modes than traditional software because they depend on:
- External APIs (rate limits, outages, format changes)
- LLM outputs (non-deterministic, can return invalid JSON)
- Data quality (the internet changes, topics go cold)

A runbook makes you think about all of these in advance.

---

## Prerequisites

- [ ] [P3-T10](p3-t10-quality-logging.md) complete — you have logging in place to detect failures
- [ ] Full pipeline has run at least 3 times (gives you real failure data to draw from)

---

## Step-by-step instructions

### Step 1 — Create the runbook file

Create `projects/03-pipeline/RUNBOOK.md` in your project folder.

Start with this header:

```markdown
# Agent Failure Runbook — AI Research Pipeline

Last updated: [date]
Pipeline version: P3

## How to use this runbook
1. Check pipeline_logs: `SELECT * FROM pipeline_logs WHERE failed = 1 ORDER BY timestamp DESC`
2. Find the agent_name that failed
3. Go to that agent's section below
4. Follow the steps in order
```

---

### Step 2 — Write the Planner runbook entry

Copy this into your runbook:

```markdown
## Agent 1: Planner

### Most likely failure
**Invalid JSON output** — The LLM returns text that is not valid JSON.
This happens when the model adds explanation text around the JSON output,
or when it "helpfully" wraps the JSON in markdown code fences.

### How to detect
- pipeline_logs: `failed = 1` AND `agent_name = 'Planner'`
- Error message contains: "invalid JSON" or "SyntaxError"
- n8n execution log: the Validate Planner Output Code node threw an error

### How to recover
1. Check the raw LLM response in n8n execution history
2. If response contains JSON wrapped in ```json ... ``` — update the Code node
   to strip markdown fences before parsing:
   ```javascript
   const cleaned = responseText.replace(/```json\n?/g, '').replace(/```/g, '').trim();
   const parsed = JSON.parse(cleaned);
   ```
3. Re-run the workflow from the Manual Trigger

### How to prevent
- Add explicit "Return ONLY raw JSON, no markdown, no code fences" to the system prompt
- Add a pre-parse cleanup step in the Code node (always strip fences)
- Use structured output mode if your LLM provider supports it (e.g. Anthropic's JSON mode)
```

---

### Step 3 — Write the Search runbook entry

```markdown
## Agent 2: Search

### Most likely failure
**Tavily API rate limit (HTTP 429)** — Too many requests in a short window.
The free Tavily tier allows 1,000 requests/month but has per-minute limits.

### How to detect
- pipeline_logs: `failed = 1` AND `agent_name = 'Search'`
- Error message contains: "429" or "rate limit"
- output_count = 0 despite no error thrown (silent failure)

### How to recover
1. Wait 60 seconds
2. Re-run from the Search node only (do not re-run Planner — it wastes credits)
3. If persistent: reduce parallel queries from 5 to 3 by editing the Planner prompt

### How to prevent
- Add a delay between search calls:
  Add a Wait node (1–2 seconds) between the Planner output and Search
- Monitor monthly usage at tavily.com/dashboard before running high-volume tests

### Secondary failure
**Zero results returned** — Tavily finds no articles for a query.
This is not an API error — the response is 200 OK with an empty results array.
- Detect: output_count = 0 in logs
- Recovery: widen the search query (edit the Planner prompt)
- Prevention: log a warning when any query returns 0 results
```

---

### Step 4 — Write the Pre-filter runbook entry

```markdown
## Agent 3: Pre-filter

### Most likely failure
**Over-filtering** — Pre-filter removes all or nearly all articles.
This is not a crash — it is a logic error that silently empties the pipeline.

### How to detect
- pipeline_logs: `agent_name = 'Pre-filter'` AND `output_count = 0`
- Error message: "Pre-filter removed ALL articles"
- Funnel shows: Search output_count >> Pre-filter output_count (e.g. 30 → 0)

### How to recover
1. Check filter logs in n8n console: what reason was most common?
2. Most likely cause: `published_date` format mismatch (Tavily changed their date format)
3. Log one raw article's published_date and check what it looks like
4. Fix the date parsing in the Code node
5. Re-run from Pre-filter (or from the start if articles were not saved)

### How to prevent
- Add a log line showing date format of the first article on every run
- Add a filter stats Code node that alerts you if output_count/input_count < 0.2
- Test Pre-filter with a seed set of known articles when updating rules

### Common false trigger
Dates like "2025-04-06T14:30:00Z" vs "April 6, 2025" vs "6 Apr 25" all parse differently.
Always log the raw published_date before filtering.
```

---

### Step 5 — Write the Validator runbook entry

```markdown
## Agent 4: Validator

### Most likely failure
**All articles score below threshold** — Gemini rates everything low.
This can happen if:
- The topic is very niche (real articles score low on uniqueness)
- Gemini's output format changed (it returns different JSON structure)
- The topic has mostly low-credibility sources

### How to detect
- pipeline_logs: `agent_name = 'Validator'` AND `output_count = 0`
- Check quality_score in logs — if average < 5.0, topic is the likely cause
- Check error message for JSON parse failures from Gemini

### How to recover
1. Check the average score in logs
2. If average is 4–6: lower threshold to 5 for the next run (edit the Code node)
3. If average is 0–3: the topic may not have enough quality content —
   try a different topic or wait a week for more articles
4. If Gemini returned malformed JSON: fix JSON parsing as in Planner runbook

### How to prevent
- Log the distribution of scores on every run (min, max, average)
- Alert if average score drops below 5.0 across a run
- Use the threshold-lowering fallback (already in your code) but log it prominently

### Secondary failure
**MariaDB connection error** — Dedup check fails.
- Detect: error message contains "ECONNREFUSED" or "Access denied"
- Recovery: skip dedup for this run (already handled by fallback logic)
- Prevention: monitor MariaDB health on homelab
```

---

### Step 6 — Write the Extractor runbook entry

```markdown
## Agent 5: Extractor

### Most likely failure
**Invalid JSON from LLM** — Same as Planner failure.
The extraction prompt is strict, but LLMs still occasionally add preamble text.

### How to detect
- pipeline_logs: `agent_name = 'Extractor'` AND `failed = 1`
- Or: output has `extraction_failed: true` on some articles

### How to recover
1. Check n8n execution log for the raw LLM response
2. The Code node has a fallback — it returns minimal extraction data instead of crashing
3. If most articles have `extraction_failed: true`:
   - Add JSON cleanup (strip markdown fences) before parsing
   - Try a different model for extraction (switch DeepSeek to Gemini or vice versa)

### How to prevent
- Same JSON output hardening as Planner: tell the LLM to return raw JSON only
- The fallback extraction (using article title as summary) ensures the pipeline
  can continue even if extraction is poor
- Monitor extraction_failed count in logs
```

---

### Step 7 — Write the Synthesizer runbook entry

```markdown
## Agent 6: Synthesizer

### Most likely failure
**Claude API rate limit or timeout** — Claude is slower than other models
and has strict rate limits on lower-tier plans.

### How to detect
- pipeline_logs: `agent_name = 'Synthesizer'` AND `failed = 1`
- Error contains: "rate limit", "529", or "timeout"
- Telegram receives no message

### How to recover
1. Wait 30–60 seconds
2. In n8n, right-click the Synthesizer node → Execute from here
3. If persistent: switch to Claude Sonnet (faster, cheaper) instead of Opus

### How to prevent
- Add a retry mechanism to the Code node (retry once after 30 seconds on failure)
- For development runs, use Sonnet instead of Opus to stay within rate limits

### Secondary failure
**Missing articles[1] or articles[2]** — Synthesizer received fewer than 3 articles.
- The prompt references `$json.articles[1]` and `$json.articles[2]` which may be undefined
- Detect: error contains "Cannot read property" or "undefined"
- Recovery: update the Select Top 3 Code node to pad with placeholders:
  ```javascript
  while (top3.length < 3) {
    top3.push({ title: 'No article', source_domain: 'n/a',
      extracted: { summary_one_line: '', key_facts: [], statistics: [], notable_quote: '' }});
  }
  ```
- Prevention: always pad to 3 articles in the selection node

### Telegram failure
If Telegram does not receive the message:
- Check the bot token has not expired
- Verify your chat ID is correct (send /start to the bot and check getUpdates)
- Check n8n's Telegram node output for the HTTP response code
```

---

### Step 8 — Add a "Common patterns" section

At the end of your runbook, add:

```markdown
## Common failure patterns

### "Silent zero" — the most dangerous failure
An agent returns 0 items without throwing an error.
The pipeline continues but with no data.
Result: Synthesizer receives empty input → produces nonsense or crashes.

Detection: `SELECT * FROM pipeline_logs WHERE output_count = 0 AND failed = 0`
Prevention: Add explicit checks in each Code node — throw an error if output is empty.

### JSON format drift
LLMs are updated regularly. After a model update, the JSON format may change slightly.
Example: The model starts wrapping JSON in ```json ... ``` blocks.
Affects: Planner, Validator (scoring), Extractor, Synthesizer.
Prevention: Log raw LLM responses for the first run after any model update.

### Cascading failures
If Search returns 0 articles, every downstream agent gets 0 input.
They may not fail — they may just silently process nothing.
Prevention: Each agent must throw if it receives 0 items (except on first run).
```

---

## Visual overview

```
Something is wrong. Now what?

1. Check Telegram — did a post arrive?
   NO → Something failed
        │
        ▼
2. Check pipeline_logs
   SELECT * FROM pipeline_logs
   WHERE run_id = 'latest_run_id'
   ORDER BY timestamp ASC;
        │
        ▼
3. Find the first agent where:
   failed = 1  → go to that agent's runbook section
   output_count = 0 (but failed = 0) → "silent zero" — check upstream

4. Follow the runbook steps for that agent

5. Fix and re-run from that agent (do not re-run the whole pipeline
   unless agents before it also need to re-run)
```

---

## Done when

- [ ] `projects/03-pipeline/RUNBOOK.md` exists
- [ ] All 6 agents have: most likely failure / how to detect / how to recover / how to prevent
- [ ] "Common patterns" section covers silent zero, JSON drift, and cascading failures
- [ ] Runbook was written based on real failures you encountered during P3 (not just copied from this doc)

---

## Next step

→ [P3-C2: LinkedIn Post — Architecture Diagram](p3-c2-linkedin-architecture.md)
