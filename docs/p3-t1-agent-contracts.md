# P3-T1: Document All 6 Agent Contracts

> **Goal:** Write a complete contract for every agent in the pipeline before building any node in n8n.

**Part of:** [P3-US1: Document and Design the Full Pipeline](p3-us1-pipeline-architecture.md)
**Week:** 4
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are writing a contract document for each of the 6 agents in the research pipeline.

A contract is a plain text document that answers four questions about an agent:
1. What does it receive? (input)
2. What does it return? (output)
3. What can go wrong? (failure modes)
4. What happens if it fails? (fallback)

You are doing this **before opening n8n**. You are not building anything yet.

---

## Why this step matters

> **Architecture before code. Always.**

If you skip this step:
- You will build a Planner agent that returns data in a format the Search agent does not understand
- You will spend hours debugging a mismatch that 20 minutes of planning would have prevented
- When something breaks at 2am, you will have no reference for what each agent was supposed to do

Agent contracts are your blueprint. Build the blueprint first.

---

## Prerequisites

- [ ] You have read the [P3-E1 epic overview](p3-e1-agent-pipeline.md)
- [ ] You have a text editor or your `projects/03-pipeline/` folder set up
- [ ] Nothing else — this task has no technical prerequisites

---

## What an agent contract looks like

Here is the template. Copy this for each agent.

```markdown
## Agent: [Name]

### What this agent does
One sentence description.

### Input schema
What data arrives at this agent. List field names, types, and examples.

### Output schema
What data this agent returns. Include JSON format.

### Failure modes
List every way this agent can fail. Be specific.

### Fallback behavior
What the pipeline does when this agent fails.
```

---

## Step-by-step instructions

### Step 1 — Create the contracts file

Create a file at `projects/03-pipeline/agent-contracts.md`.

You will fill in all 6 contracts in this file.

---

### Step 2 — Write the Planner Agent contract

```markdown
## Agent 1: Planner

### What this agent does
Takes a research topic and generates a list of search queries
that will find the best recent articles about that topic.

### Input schema
{
  "topic": "string"
}
Example: { "topic": "AI agents in healthcare 2025" }

### Output schema
{
  "queries": [
    { "text": "string", "priority": number }
  ]
}

Rules:
- Maximum 5 queries
- Priority is 1 (highest) to 5 (lowest)
- Each query must be meaningfully different

Example output:
{
  "queries": [
    { "text": "AI agents healthcare diagnosis 2025", "priority": 1 },
    { "text": "hospital AI automation latest news", "priority": 2 },
    { "text": "clinical AI agents FDA approval 2025", "priority": 3 }
  ]
}

### Failure modes
1. Returns more than 5 queries → truncate to first 5
2. Returns invalid JSON → retry once, then fail with error
3. Returns queries that are too similar → pipeline still runs, but
   Search results will overlap (acceptable, Validator will deduplicate)
4. LLM timeout → fail with error, log to MariaDB

### Fallback behavior
If Planner fails after one retry:
- Use the raw topic string as a single query
- Log: "Planner failed — using raw topic as query"
- Continue pipeline with 1 query instead of 5
```

---

### Step 3 — Write the Search Agent contract

```markdown
## Agent 2: Search

### What this agent does
Takes each search query and finds recent web articles using
the Tavily search API.

### Input schema
One item per query from the Planner:
{
  "text": "string",     // the search query
  "priority": number    // 1–5
}

### Output schema
Array of articles. For each article:
{
  "url": "string",
  "title": "string",
  "snippet": "string",      // short excerpt from the article
  "published_date": "string", // ISO 8601 format: "2025-03-15"
  "source_domain": "string"   // e.g. "techcrunch.com"
}

### Failure modes
1. Tavily API returns HTTP 429 (rate limit) → wait 60 seconds, retry once
2. Tavily returns 0 results → log warning, continue with 0 articles from
   this query
3. Article missing published_date → set to null, Pre-filter will remove it
4. Network timeout → log error, skip this query

### Fallback behavior
If Search returns 0 total articles across all queries:
- Fail pipeline with error: "Search returned no results"
- Log query list and timestamp to MariaDB
```

---

### Step 4 — Write the Pre-filter Agent contract

```markdown
## Agent 3: Pre-filter

### What this agent does
Removes articles that are too old, in a non-English language,
too short to contain useful content, or obviously off-topic.
This agent uses rules, not AI.

### Input schema
Array of articles (raw output from Search):
{
  "url": "string",
  "title": "string",
  "snippet": "string",
  "published_date": "string | null",
  "source_domain": "string"
}

### Output schema
Same schema as input — only the articles that passed all filters:
{
  "url": "string",
  "title": "string",
  "snippet": "string",
  "published_date": "string",
  "source_domain": "string",
  "filter_passed": true
}

### Failure modes
1. All articles filtered out → log warning with counts, fail pipeline
2. published_date in unrecognised format → treat as too old (filtered out)
3. Snippet is null or empty → filtered out (no content to process)

### Fallback behavior
If fewer than 3 articles pass:
- Log warning: "Pre-filter too aggressive — only N articles passed"
- Continue anyway (Validator may still find enough quality articles)
- If 0 articles pass: fail pipeline, log all filter reasons
```

---

### Step 5 — Write the Validator Agent contract

```markdown
## Agent 4: Validator

### What this agent does
Scores each article on credibility, uniqueness, and relevance.
Also checks a MariaDB table to make sure this URL has not been
processed in a previous pipeline run (deduplication).

### Input schema
Array of filtered articles from Pre-filter (same schema as above).

### Output schema
Articles that scored high enough, with scores added:
{
  "url": "string",
  "title": "string",
  "snippet": "string",
  "published_date": "string",
  "source_domain": "string",
  "scores": {
    "credibility": number,   // 0–10
    "uniqueness": number,    // 0–10
    "relevance": number,     // 0–10
    "average": number        // calculated: (c + u + r) / 3
  },
  "is_duplicate": boolean,
  "passed": boolean          // true if average >= 7 AND not duplicate
}

Only articles where passed = true continue to Extractor.

### Failure modes
1. MariaDB connection fails → skip deduplication, log warning, continue scoring
2. LLM returns invalid score format → set scores to null, exclude article
3. All articles score below 7 → log warning, lower threshold to 5 for
   this run only, log that threshold was lowered
4. Gemini API timeout → retry once, then exclude article

### Fallback behavior
If 0 articles pass validation:
- Fail pipeline with error: "Validator: no articles met quality threshold"
- Log all scores to MariaDB for debugging
```

---

### Step 6 — Write the Extractor Agent contract

```markdown
## Agent 5: Extractor

### What this agent does
Reads each validated article and extracts structured information
from it: key facts, notable quotes, statistics, and entities.

### Input schema
Validated articles from Validator (where passed = true):
{
  "url": "string",
  "title": "string",
  "snippet": "string",
  "published_date": "string",
  "source_domain": "string",
  "scores": { ... }
}

### Output schema
Same article fields, plus extracted content:
{
  "url": "string",
  "title": "string",
  "snippet": "string",
  "published_date": "string",
  "source_domain": "string",
  "scores": { ... },
  "extracted": {
    "key_facts": ["string"],         // 3–5 key facts
    "notable_quote": "string",       // best quotable sentence
    "statistics": ["string"],        // facts that include numbers
    "entities": ["string"],          // company/person/product names
    "summary_one_line": "string"     // one-sentence summary
  }
}

### Failure modes
1. LLM returns invalid JSON → retry once, then exclude article
2. Extracted fields are empty arrays → keep article but flag it
3. notable_quote is null → acceptable, set to empty string
4. LLM API timeout → exclude article, log error

### Fallback behavior
If Extractor fails on all articles:
- Fail pipeline with error
- Log: which articles failed and with what error
```

---

### Step 7 — Write the Synthesizer Agent contract

```markdown
## Agent 6: Synthesizer

### What this agent does
Takes the top 3 articles (by score) with their extracted content
and writes a LinkedIn post draft and an Instagram caption.
Uses Claude for highest output quality.

### Input schema
Top 3 articles from Extractor, sorted by scores.average descending:
[
  {
    "url": "string",
    "title": "string",
    "source_domain": "string",
    "scores": { "average": number },
    "extracted": {
      "key_facts": ["string"],
      "notable_quote": "string",
      "statistics": ["string"],
      "summary_one_line": "string"
    }
  }
  // ... up to 3 articles
]
Also receives: { "topic": "string" } — the original topic

### Output schema
{
  "linkedin_post": "string",        // 150–250 words
  "instagram_caption": "string",    // 50–80 words with hashtags
  "sources": ["url1", "url2", ...], // articles used
  "generated_at": "ISO timestamp"
}

### Failure modes
1. Claude API timeout → retry once with exponential backoff
2. Output does not include both fields → retry with stricter prompt
3. Output exceeds word limits → truncate with note in log
4. Claude API rate limit → wait 30 seconds, retry

### Fallback behavior
If Synthesizer fails after 2 retries:
- Send Telegram message: "Pipeline ran but Synthesizer failed. Check logs."
- Save raw articles to MariaDB for manual review
- Do not attempt to post anything
```

---

## Visual overview

```
BEFORE YOU BUILD ANYTHING:

  ┌──────────────────────────────────────────────────────┐
  │  agent-contracts.md                                   │
  │                                                       │
  │  Agent 1: Planner     ← contract written              │
  │  Agent 2: Search      ← contract written              │
  │  Agent 3: Pre-filter  ← contract written              │
  │  Agent 4: Validator   ← contract written              │
  │  Agent 5: Extractor   ← contract written              │
  │  Agent 6: Synthesizer ← contract written              │
  └──────────────────────────────────────────────────────┘
                          │
                          │  Only when all 6 are done
                          ▼
                  Open n8n and start building
```

---

## Learning checkpoint

> Before moving on, write in your build log:
> "For each agent, what is the one failure mode that worries me most, and why?"

This forces you to think about your system's weakest points before you build them.

---

## Done when

- [ ] `projects/03-pipeline/agent-contracts.md` exists
- [ ] All 6 agents have input schema documented
- [ ] All 6 agents have output schema documented with example JSON
- [ ] All 6 agents have at least 3 failure modes listed
- [ ] All 6 agents have a fallback behavior defined
- [ ] You have re-read all 6 contracts and they are consistent (Planner's output matches Search's expected input, etc.)

---

## Next step

→ [P3-T2: Set Up API Keys in n8n](p3-t2-api-keys-n8n.md)
