# P3-T4: Build Planner Agent

> **Goal:** Build the first agent — it takes a topic and returns a prioritised list of search queries.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 5
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are replacing the Planner placeholder node with a real implementation. This agent:
1. Receives a topic string
2. Sends it to an LLM with a structured prompt
3. Gets back a JSON list of search queries
4. Validates the output format before passing to the next agent

**n8n concepts:**
- **"Message a Model" node:** Sends a prompt to an LLM and returns the response
- **Code node:** Runs JavaScript — used here to validate and parse the LLM output
- **Expression syntax:** In n8n, `{{ $json.fieldName }}` pulls data from the previous node's output

---

## Why this step matters

```
[You: "AI in healthcare"]
        │
        ▼
┌──────────────────┐
│  PLANNER AGENT   │  ← You are building this
│                  │
│  "What searches  │
│   should I run   │
│   to find the    │
│   best articles?"│
└──────────────────┘
        │
        ▼
[Search queries]
→ "AI agents healthcare diagnosis 2025"
→ "hospital AI automation latest news"
→ "clinical AI FDA 2025"
```

A dumb Planner produces vague queries → Search returns irrelevant articles → everything downstream fails.

A good Planner produces specific, varied queries → Search returns high-quality articles → the whole pipeline works.

---

## Prerequisites

- [ ] [P3-T3](p3-t3-workflow-skeleton.md) complete — skeleton workflow exists with placeholder Planner node
- [ ] Claude or Gemini credential added to n8n (P3-T2)

---

## Step-by-step instructions

### Step 1 — Open the Planner placeholder node

1. Open your `AI Research Pipeline` workflow in n8n
2. Double-click the `Agent 1 — Planner` node to open its settings

---

### Step 2 — Configure the "Message a Model" node

Set these properties in the node:

**Model settings:**
- **Credential:** Select `Claude API` (or Gemini — either works for planning)
- **Model:** `claude-3-5-haiku-20241022` (fast and cheap — good for planning tasks)

**Prompt settings:**

Set **System Prompt** to:
```
You are a research planner. Your job is to generate search queries
that will find the best, most recent articles about a given topic.

Rules you must follow:
1. Generate between 3 and 5 queries — no more, no fewer
2. Each query must be different enough to find unique results
3. Prioritise queries that find news from the last 30 days
4. Return ONLY valid JSON — no explanation, no markdown, just JSON
5. Do not include quotes inside the JSON strings

Output format (copy this exactly):
{
  "queries": [
    { "text": "your search query here", "priority": 1 },
    { "text": "another query here", "priority": 2 }
  ]
}

Priority 1 = most important query. Higher numbers = less important.
```

Set **User Message** to:
```
Research topic: {{ $json.topic }}

Generate 3–5 search queries for this topic.
```

The `{{ $json.topic }}` expression pulls the topic value from the previous node (the Input — Set Topic node).

---

### Step 3 — Add a Code node to validate and parse output

After the "Message a Model" node, add a **Code** node. Name it `Validate Planner Output`.

This node does three things:
1. Parses the LLM's text response as JSON
2. Checks that queries exist and the list is not empty
3. Trims to 5 queries maximum
4. Returns one item per query (so the next node runs once per query)

Paste this JavaScript into the Code node:

```javascript
// Get the LLM's response text
const responseText = $input.first().json.text;

// Parse the JSON response
let parsed;
try {
  parsed = JSON.parse(responseText);
} catch (e) {
  // If JSON parsing fails, log and throw a clear error
  throw new Error(
    `Planner returned invalid JSON. Raw response: ${responseText.substring(0, 200)}`
  );
}

// Check that queries exist and is an array
if (!parsed.queries || !Array.isArray(parsed.queries)) {
  throw new Error(
    `Planner output missing 'queries' array. Got: ${JSON.stringify(parsed)}`
  );
}

// Check that we have at least one query
if (parsed.queries.length === 0) {
  throw new Error('Planner returned an empty queries array');
}

// Truncate to maximum 5 queries (contract rule)
if (parsed.queries.length > 5) {
  console.log(`Planner returned ${parsed.queries.length} queries — truncating to 5`);
  parsed.queries = parsed.queries.slice(0, 5);
}

// Return one item per query so the next node processes each one
return parsed.queries.map(query => ({
  json: {
    text: query.text,
    priority: query.priority,
    original_topic: $input.first().json.topic || 'unknown'
  }
}));
```

---

### Step 4 — Connect the nodes

Make sure the connections in your workflow are:

```
[Input — Set Topic]
        │
        ▼
[Agent 1 — Planner]   ← "Message a Model" node
        │
        ▼
[Validate Planner Output]  ← Code node
        │
        ▼
[Agent 2 — Search]    ← placeholder (you build this next)
```

The Code node outputs one item per query. This means the Search agent will run once per query — this is called "splitting" in n8n.

---

### Step 5 — Test the Planner

1. Make sure the Input node has a topic set (e.g. `AI agents in healthcare 2025`)
2. Right-click the `Validate Planner Output` node → **Execute from here**
3. Check the output panel — you should see 3–5 items, one per query

Expected output (one item example):
```json
{
  "text": "AI agents healthcare diagnosis 2025",
  "priority": 1,
  "original_topic": "AI agents in healthcare 2025"
}
```

If you get an error, check:
- Is the LLM credential selected correctly?
- Copy the raw LLM response text from the "Message a Model" node output and paste it into a JSON validator

---

## Visual overview

```
[Input node]
  topic: "AI agents in healthcare"
        │
        ▼
┌────────────────────────────────┐
│  Message a Model (Claude)       │
│                                 │
│  System: "You are a research   │
│   planner. Return JSON only."   │
│                                 │
│  User: "Research topic:        │
│   {{ $json.topic }}"           │
└────────────────────────────────┘
        │
        │ Raw text: '{"queries": [...]}'
        ▼
┌────────────────────────────────┐
│  Code: Validate Planner Output │
│                                 │
│  1. Parse JSON                  │
│  2. Check queries[] exists      │
│  3. Truncate to max 5           │
│  4. Return one item per query   │
└────────────────────────────────┘
        │
        │ 3–5 items, one per query
        ▼
[Agent 2 — Search] (next task)
```

---

## Learning checkpoint

> Write in your build log:
> "What would happen to the whole pipeline if the Planner returned queries in plain text instead of JSON? Walk through each downstream agent and describe the failure."

This exercise teaches you to think about contract enforcement.

---

## Done when

- [ ] "Message a Model" node configured with system prompt and user message
- [ ] Code node validates and parses Planner output
- [ ] Validation node throws a clear error on bad JSON (not a silent failure)
- [ ] Output is one item per query (not one item with an array)
- [ ] Test run with topic `AI agents in healthcare 2025` produces 3–5 queries

---

## Next step

→ [P3-T5: Build Search Agent](p3-t5-search-agent.md)
