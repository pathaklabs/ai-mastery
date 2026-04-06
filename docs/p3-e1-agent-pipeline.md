# P3-E1: 5-Agent Research Pipeline in n8n

> **Epic goal:** Build a production-quality multi-agent pipeline that automatically researches topics, filters content, and drafts social posts — with every agent's behaviour documented before a single node is built.

**Weeks:** 4–8
**Labels:** `epic`, `p3-pipeline`
**Stack:** n8n + Tavily + Gemini + Claude + DeepSeek + MariaDB

---

## What you are building

An automated research pipeline. You give it a topic. It searches the web, filters junk, validates sources, extracts key facts, and drafts a LinkedIn post — which goes to your Telegram for approval before publishing.

```
You → [topic]
         │
         ▼
   ┌─────────────┐
   │  1. PLANNER │  Decides what to search for
   └──────┬──────┘
          │  { queries: ["query 1", "query 2", ...] }
          ▼
   ┌─────────────┐
   │  2. SEARCH  │  Searches the web via Tavily API
   └──────┬──────┘
          │  { url, title, snippet, date, domain }
          ▼
   ┌──────────────────┐
   │  3. PRE-FILTER   │  Removes junk (old, off-topic, non-English)
   └──────┬───────────┘
          │  filtered articles
          ▼
   ┌──────────────────┐
   │  4. VALIDATOR    │  Scores credibility + uniqueness (no duplicates)
   └──────┬───────────┘
          │  scored articles (only top quality pass)
          ▼
   ┌──────────────────┐
   │  5. EXTRACTOR    │  Pulls key facts, quotes, stats from each article
   └──────┬───────────┘
          │  structured article data
          ▼
   ┌──────────────────────┐
   │  6. SYNTHESIZER      │  Writes LinkedIn post + Instagram caption
   └──────┬───────────────┘
          │
          ▼
   Telegram → You approve → Post
```

---

## What is an "agent contract"?

Before you build any agent node, you must write its contract. A contract answers:

1. **What does this agent receive?** (input schema)
2. **What does this agent return?** (output schema)
3. **What can go wrong?** (failure modes)
4. **What happens if it fails?** (fallback behaviour)

Think of contracts like a job description — you would not hire someone without one.

---

## Definition of done

- [ ] All 6 agent contracts documented before building any node
- [ ] Full pipeline runs end-to-end on a test topic
- [ ] Output routes to Telegram for approval
- [ ] Per-agent quality scores logged to MariaDB

---

## Week 4 — Architecture Before Code

### Step 1 — Document all 6 agent contracts (P3-T1)

> **Do not skip this. This is the most important task in P3.**

Create `projects/03-pipeline/agent-contracts.md` and fill in this template for all 6 agents:

```markdown
## Agent: Planner

### Input
- topic: string (e.g. "AI agents in healthcare 2025")

### Output
```json
{
  "queries": [
    { "text": "AI agents healthcare diagnosis 2025", "priority": 1 },
    { "text": "hospital AI automation recent news", "priority": 2 }
  ]
}
```
Maximum 5 queries.

### Failure modes
- Produces more than 5 queries → truncate to 5
- Returns invalid JSON → retry once, then fail pipeline with error log

### Fallback
- If Planner fails: use topic as a single query directly to Search
```

Repeat this for: Search, Pre-filter, Validator, Extractor, Synthesizer.

**Architecture before code. Always.**

---

### Step 2 — Set up API keys in n8n (P3-T2)

In n8n, go to **Settings → Credentials** and add:

| Credential | Type | Where to get key |
|-----------|------|-----------------|
| Tavily | HTTP Header Auth | tavily.com |
| Gemini | Google AI API | aistudio.google.com |
| Claude | Anthropic API | console.anthropic.com |
| DeepSeek | OpenAI-compatible | platform.deepseek.com |

Store them as credentials — never paste keys directly into nodes.

---

### Step 3 — Create n8n workflow skeleton (P3-T3)

In n8n, create a new workflow called `AI Research Pipeline`.

Add all 6 agent nodes as placeholders:
1. Add a **"Message a Model"** node for each agent
2. Connect them in sequence
3. Add a **Sticky Note** to each node with the agent contract

```
[Trigger] → [Planner] → [Search] → [Pre-filter] → [Validator] → [Extractor] → [Synthesizer] → [Telegram]
```

Do not implement any logic yet. You are laying out the skeleton and making the architecture visible.

---

## Week 5 — Build Agents 1, 2, 3

### Step 4 — Build Planner Agent (P3-T4)

In the Planner node, use a **"Message a Model"** node with this system prompt:

```
You are a research planner. Given a topic, generate a JSON list of
search queries that will find the best recent articles.

Rules:
- Maximum 5 queries
- Each query should be different enough to find unique results
- Prioritise queries that will find news from the last 30 days
- Return ONLY valid JSON. No explanation text.

Output format:
{"queries": [{"text": "...", "priority": 1}, ...]}
```

After the Planner node, add a **Code node** to validate the JSON before passing to Search:

```javascript
const output = JSON.parse($input.first().json.text);
if (!output.queries || output.queries.length === 0) {
  throw new Error("Planner returned no queries");
}
if (output.queries.length > 5) {
  output.queries = output.queries.slice(0, 5);
}
return output.queries.map(q => ({ json: q }));
```

---

### Step 5 — Build Search Agent (P3-T5)

Use an **HTTP Request node** to call Tavily:

```
Method: POST
URL: https://api.tavily.com/search
Headers:
  Authorization: Bearer {{ $credentials.tavily.api_key }}
Body:
{
  "query": "{{ $json.text }}",
  "search_depth": "advanced",
  "max_results": 10,
  "days": 30,
  "include_domains": [],
  "exclude_domains": []
}
```

For each result, extract and store:

```
{ url, title, snippet, published_date, source_domain }
```

---

### Step 6 — Build Pre-filter Agent (P3-T6)

Use a **Code node** (not a model call — this is rule-based filtering):

```javascript
const articles = $input.all().map(item => item.json);
const thirtyDaysAgo = new Date();
thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

const filtered = articles.filter(article => {
  const reasons = [];

  // Rule 1: Must be recent
  const published = new Date(article.published_date);
  if (published < thirtyDaysAgo) {
    reasons.push("too old");
  }

  // Rule 2: Must have enough content
  if (!article.snippet || article.snippet.length < 50) {
    reasons.push("no content");
  }

  // Rule 3: Log everything that gets filtered out
  if (reasons.length > 0) {
    console.log(`Filtered: ${article.url} — Reasons: ${reasons.join(", ")}`);
    return false;
  }

  return true;
});

return filtered.map(a => ({ json: a }));
```

**Log filter reasons.** If 90% of articles are filtered, something is wrong upstream.

---

## Week 6 — Build Agents 4, 5

### Step 7 — Build Validator Agent with deduplication (P3-T7)

The Validator:
1. Scores each article (0–10) on: credibility, uniqueness, relevance
2. Checks if this URL was already processed in a previous run (deduplication)
3. Only passes articles that score above a threshold

```
MariaDB table: processed_urls
  id | url_hash | first_seen | run_id

Before validating: check if SHA256(url) is in processed_urls
After validating: insert new URLs into processed_urls
```

Scoring prompt (send to Gemini):

```
Rate this article on three dimensions (0-10 each):
- Credibility: Is the source trustworthy? Is it a real publication?
- Uniqueness: Does this add new information not covered by the other articles?
- Relevance: How closely does it match the research topic?

Article:
Title: {{ title }}
Source: {{ source_domain }}
Snippet: {{ snippet }}

Return JSON: {"credibility": N, "uniqueness": N, "relevance": N}
```

Pass only articles where average score ≥ 7.

---

### Step 8 — Build Extractor Agent (P3-T8)

Extract structured data from each validated article:

```
For each article, return:
{
  "key_facts": ["fact 1", "fact 2", "fact 3"],
  "notable_quote": "The most quotable sentence from the article",
  "statistics": ["stat with number", "another stat"],
  "entities": ["Company A", "Person B", "Product C"],
  "summary_one_line": "One sentence describing the article"
}
```

Use a **"Message a Model"** node with this prompt structure:

```
Extract structured information from this article.
Return ONLY valid JSON with exactly these fields:
key_facts, notable_quote, statistics, entities, summary_one_line.

Article title: {{ title }}
Article content: {{ snippet }}
```

---

## Week 7 — Build Synthesizer + Logging

### Step 9 — Build Synthesizer Agent (P3-T9)

The Synthesizer takes the top 3 validated+extracted articles and writes social content.

Use Claude here (highest quality matters for the final output):

```
You are a social media content writer for a tech professional.

You have researched the topic: {{ topic }}

Here are the top 3 most relevant, credible articles and their key facts:

[Article 1]
Summary: {{ article1.summary_one_line }}
Key facts: {{ article1.key_facts }}
Notable quote: {{ article1.notable_quote }}

[Article 2]
...

[Article 3]
...

Write:
1. A LinkedIn post (150-250 words). Professional tone. Start with a hook.
   End with a question for comments.
2. An Instagram caption (50-80 words). More casual. Use 3-5 relevant hashtags.

Return as JSON: {"linkedin_post": "...", "instagram_caption": "..."}
```

After the Synthesizer node, route to a **Telegram node** for human approval before any publishing.

---

### Step 10 — Add per-agent quality scoring and logging (P3-T10)

After each agent, add a **Code node** that logs to MariaDB:

```javascript
// Log this agent's run
const logEntry = {
  agent_name: "Planner",          // change per agent
  run_id: $workflow.id + "_" + Date.now(),
  timestamp: new Date().toISOString(),
  input_count: $input.all().length,
  output_count: $output.all().length,
  quality_score: null,            // calculate where possible
  failed: false
};

// Insert to MariaDB via HTTP request to your API
await $http.post("http://your-api/pipeline-logs", logEntry);
```

> **⚡ Learning checkpoint:** This is production AI observability. If an agent silently returns bad output — wrong format, low quality, hallucinated data — your pipeline runs, posts bad content, and you never know. Logging catches it. Write in your build log: what would you monitor in production?

---

## Week 8 — Dashboard and Runbook

### Step 11 — Build pipeline run summary dashboard (P3-T11)

A simple table view showing:

| Run | Articles found | Passed filter | Validated | Posts sent | Status |
|-----|----------------|---------------|-----------|------------|--------|
| Run 1 | 50 | 32 | 8 | 1 | ✓ |
| Run 2 | 47 | 28 | 6 | 1 | ✓ |
| Run 3 | 51 | 30 | 0 | 0 | ✗ (Validator timeout) |

Funnel view (what's normal):

```
Articles found:    50
After Pre-filter:  30  (60%)  ← if below 40%, Pre-filter may be too strict
After Validator:    8  (27%)  ← if below 10%, topic may be too niche
Posts drafted:      1
```

---

### Step 12 — Write agent failure runbook (P3-T12)

Create `projects/03-pipeline/RUNBOOK.md`:

For each agent, document:

```markdown
## Agent: Search

### Most likely failure
Tavily API rate limit exceeded. Returns HTTP 429.

### How to detect
Check pipeline logs: output_count = 0 AND no error thrown.

### How to recover
1. Wait 60 seconds
2. Re-run from Search step only (do not re-run Planner)
3. If persistent: reduce number of parallel queries from 5 to 3

### How to prevent
Add a rate limiter Code node before Search: max 1 request per 2 seconds.
```

---

## Week 8 — Content tasks

| Task | What to do |
|------|-----------|
| P3-C1 | Write 5 build logs during weeks 4–8 |
| P3-C2 | LinkedIn post with actual architecture diagram of all 6 agents. Walk through each agent + one mistake made. |
| P3-C3 | Blog: multi-agent orchestration — patterns, failures, lessons |
| P3-C4 | Instagram carousel: "What is an AI agent?" |

---

## Full task checklist

### Week 4
- [ ] P3-T1: Document all 6 agent contracts (DO NOT skip)
- [ ] P3-T2: Set up Tavily, Gemini, DeepSeek API keys in n8n
- [ ] P3-T3: Create n8n workflow skeleton with all 6 agent nodes

### Week 5
- [ ] P3-T4: Build Planner Agent
- [ ] P3-T5: Build Search Agent
- [ ] P3-T6: Build Pre-filter Agent

### Week 6
- [ ] P3-T7: Build Validator Agent with deduplication
- [ ] P3-T8: Build Extractor Agent

### Week 7
- [ ] P3-T9: Build Synthesizer Agent (routes to Telegram)
- [ ] P3-T10: Add per-agent quality scoring and logging

### Week 8
- [ ] P3-T11: Build pipeline run summary dashboard
- [ ] P3-T12: Write agent failure runbook
- [ ] P3-C1: Write 5 build logs
- [ ] P3-C2: LinkedIn post with architecture diagram
- [ ] P3-C3: Blog post
- [ ] P3-C4: Instagram carousel
