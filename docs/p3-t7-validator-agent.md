# P3-T7: Build Validator Agent with Deduplication

> **Goal:** Build the Validator agent — it scores each article on credibility, uniqueness, and relevance, and prevents the same articles from appearing across multiple pipeline runs.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 6
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

The Validator has two jobs:

**Job 1 — Deduplication:** Before scoring any article, check if its URL was already processed in a previous run. If yes, skip it. This prevents you from writing about the same article twice.

**Job 2 — Scoring:** Send each article to Gemini and ask it to rate the article on three dimensions:
- Credibility (0–10): Is the source trustworthy?
- Uniqueness (0–10): Does this article add something new compared to others?
- Relevance (0–10): How closely does it match the research topic?

Only articles with an average score of 7 or higher pass through to the Extractor.

**n8n concepts:**
- **MariaDB node:** Runs SQL queries against your homelab MariaDB database
- Deduplication uses a `processed_urls` table — a simple record of every URL you have ever processed
- URL hashing: Instead of storing the full URL, you store a short hash of it (SHA-256). This keeps the table small and fast.

---

## Why this step matters

```
[Pre-filter] → 18 filtered articles
                      │
                      ▼
     ┌──────────────────────────────────┐
     │         VALIDATOR AGENT          │  ← You are building this
     │                                  │
     │  Step 1: Check MariaDB           │
     │   → 3 URLs already seen → skip   │
     │                                  │
     │  Step 2: Score remaining 15      │
     │   (Gemini rates each article)    │
     │                                  │
     │  Step 3: Keep score >= 7         │
     │   → 7 articles pass              │
     └──────────────────────────────────┘
                      │
                      ▼
              [Extractor] (7 articles)
```

Without deduplication, every time you run the pipeline on a similar topic, you might surface the same viral article from last week. Your posts would repeat.

Without scoring, the Extractor and Synthesizer would process low-quality articles and produce bad content.

---

## Prerequisites

- [ ] [P3-T6](p3-t6-prefilter-agent.md) complete — Pre-filter outputs articles with `filter_passed: true`
- [ ] Gemini API credential added to n8n
- [ ] MariaDB running on your homelab and accessible from n8n
- [ ] n8n can connect to MariaDB (add MariaDB credential in n8n Settings → Credentials)

---

## Step-by-step instructions

### Step 1 — Create the MariaDB table

Run this SQL on your MariaDB database to create the deduplication table:

```sql
CREATE TABLE IF NOT EXISTS processed_urls (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  url_hash      VARCHAR(64) NOT NULL UNIQUE,
  url           TEXT NOT NULL,
  first_seen    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  run_id        VARCHAR(128),
  topic         VARCHAR(512)
);

-- Index for fast lookups
CREATE INDEX idx_url_hash ON processed_urls (url_hash);
```

You can run this via:
- Your MariaDB admin interface (Adminer, phpMyAdmin, DBeaver)
- Or by adding a one-time Code node in n8n that runs the SQL

---

### Step 2 — Add a Code node for URL hashing and dedup check

After the Pre-filter, add a **Code** node. Name it: `Dedup Check — Hash URLs`.

This node:
1. Computes a hash for each article URL
2. Queries MariaDB to check which hashes already exist
3. Marks duplicates so you can filter them

```javascript
// n8n has the crypto module available
const crypto = require('crypto');

// Get all filtered articles
const articles = $input.all().map(item => item.json);

// Hash each URL
const articlesWithHashes = articles.map(article => {
  const hash = crypto
    .createHash('sha256')
    .update(article.url || '')
    .digest('hex');

  return {
    ...article,
    url_hash: hash
  };
});

// Return articles with their hashes attached
// The next node (MariaDB) will check which hashes exist
return articlesWithHashes.map(a => ({ json: a }));
```

---

### Step 3 — Add a MariaDB node to check for duplicates

After the hash node, add a **MariaDB** node. Name it: `Check Existing URLs`.

Set it up:
- **Credential:** Your MariaDB credential
- **Operation:** `Execute Query`
- **Query:**
```sql
SELECT url_hash
FROM processed_urls
WHERE url_hash IN ({{ $json.url_hash }})
```

Wait — this approach queries one article at a time. For a better approach, use a Code node to build the IN clause:

**Better approach:** Use a single Code node that queries all hashes at once.

Replace the single-article query with this Code node named `Filter Duplicates`:

```javascript
// This node receives articles WITH url_hash from the previous Code node
// It then runs a batch query to check which are already in the DB

const articles = $input.all().map(item => item.json);
const hashes = articles.map(a => a.url_hash);

// Build the SQL IN clause safely
const placeholders = hashes.map((_, i) => `?`).join(', ');
const sql = `SELECT url_hash FROM processed_urls WHERE url_hash IN (${placeholders})`;

// Run the query via n8n's built-in $db helper
// Note: if using MariaDB node, you may need to chain this differently
// Here we return the articles with a flag — the MariaDB node will handle the query

// For now, return articles — you will use a MariaDB node for the actual query
return articles.map(a => ({ json: a }));
```

**Practical approach for n8n:** Use the following flow:

```
[Pre-filter articles]
        │
        ▼
[Code: Hash URLs]  → adds url_hash to each article
        │
        ▼
[MariaDB: Select existing hashes]
  Query: SELECT url_hash FROM processed_urls
         WHERE url_hash = {{ $json.url_hash }}
  (runs once per article — n8n splits automatically)
        │
        ▼
[Code: Mark duplicates]  → if MariaDB returned a row, it's a duplicate
```

For the `Mark Duplicates` Code node:

```javascript
const articles = $input.all().map(item => item.json);

return articles
  .filter(article => {
    // If the MariaDB query returned rows, this URL already exists
    // The MariaDB node output includes the query results
    const isDuplicate = article.existing_hash !== undefined && article.existing_hash !== null;

    if (isDuplicate) {
      console.log(`Duplicate skipped: ${article.url}`);
    }

    return !isDuplicate;
  })
  .map(article => ({ json: article }));
```

---

### Step 4 — Add a "Message a Model" node for scoring

After duplicate filtering, add a **"Message a Model"** node. Name it: `Agent 4 — Validator (Score)`.

**Credential:** Gemini API
**Model:** `gemini-1.5-flash` (fast and cheap for scoring tasks)

**System Prompt:**
```
You are an article quality evaluator. Rate the given article on three dimensions.

Scoring rules:
- Credibility (0–10): Is this from a known, trustworthy source? Is the domain reputable?
  10 = major publication (Reuters, NYT, TechCrunch)
  5  = blog or unknown site with okay content
  0  = spam, clickbait, or unknown domain
- Uniqueness (0–10): Does this article contain something genuinely new?
  10 = exclusive data, original research, breaking news
  5  = standard coverage of a known topic
  0  = listicle or rephrasing of existing content
- Relevance (0–10): How closely does this match the research topic?
  10 = exactly on topic, highly specific
  5  = loosely related
  0  = unrelated

Research topic: {{ $('Input — Set Topic').item.json.topic }}

Return ONLY valid JSON. No explanation. No markdown.
Format: {"credibility": N, "uniqueness": N, "relevance": N}
```

**User Message:**
```
Article to evaluate:
Title: {{ $json.title }}
Source domain: {{ $json.source_domain }}
Published: {{ $json.published_date }}
Content: {{ $json.snippet }}
```

---

### Step 5 — Add a Code node to parse scores and apply threshold

After the scoring node, add a **Code** node. Name it: `Apply Score Threshold`.

```javascript
const items = $input.all();

const scored = items.map(item => {
  const article = item.json;

  // Parse the Gemini score response
  let scores;
  try {
    scores = JSON.parse(article.text || article.output || '{}');
  } catch (e) {
    console.log(`Score parsing failed for ${article.url}: ${e.message}`);
    scores = { credibility: 0, uniqueness: 0, relevance: 0 };
  }

  const average = (
    (scores.credibility || 0) +
    (scores.uniqueness || 0) +
    (scores.relevance || 0)
  ) / 3;

  return {
    json: {
      ...article,
      scores: {
        credibility: scores.credibility || 0,
        uniqueness: scores.uniqueness || 0,
        relevance: scores.relevance || 0,
        average: Math.round(average * 10) / 10
      },
      passed: average >= 7
    }
  };
});

// Filter to only passing articles
const passing = scored.filter(item => item.json.passed);

console.log(`Validator: ${items.length} scored → ${passing.length} passed (threshold: 7/10)`);

if (passing.length === 0) {
  // Lower threshold for this run and log it
  console.log('WARNING: No articles passed threshold 7. Lowering to 5 for this run.');
  const fallback = scored.filter(item => item.json.scores.average >= 5);

  if (fallback.length === 0) {
    throw new Error('Validator: no articles met even the fallback threshold of 5/10. Pipeline stopped.');
  }

  return fallback.map(item => ({ json: { ...item.json, threshold_lowered: true } }));
}

return passing;
```

---

### Step 6 — Add a MariaDB node to save processed URLs

After the threshold filter, add a **MariaDB** node to record the validated URLs so future runs skip them.

Name it: `Save Processed URLs`

```sql
INSERT IGNORE INTO processed_urls (url_hash, url, run_id, topic)
VALUES (
  '{{ $json.url_hash }}',
  '{{ $json.url }}',
  '{{ $workflow.id }}-{{ Date.now() }}',
  '{{ $('Input — Set Topic').item.json.topic }}'
)
```

`INSERT IGNORE` means: if the hash already exists, skip (no error).

---

## Visual overview

```
[Pre-filter: 18 articles]
        │
        ▼
[Code: Hash URLs]
  Adds url_hash to each article
        │
        ▼
[MariaDB: Check existing hashes]
  → 3 duplicates found
        │
        ▼
[Code: Filter duplicates]
  15 articles remain
        │
        ▼
[Message a Model: Gemini scores each article]
  → {"credibility": 8, "uniqueness": 6, "relevance": 9}
        │
        ▼
[Code: Apply threshold]
  Average >= 7 → 8 articles pass
        │
        ▼
[MariaDB: Save processed URLs]
  Record 8 new URLs for future deduplication
        │
        ▼
[Extractor: 8 articles]
```

---

## Learning checkpoint

> Write in your build log:
> "Why is it important to check for duplicates BEFORE scoring? What would happen if you scored first and then checked duplicates?"
>
> Hint: think about API costs and the order of operations.

---

## Done when

- [ ] `processed_urls` table created in MariaDB
- [ ] URL hashing Code node adds `url_hash` to each article
- [ ] Duplicate check skips already-processed URLs
- [ ] Gemini scores each article on credibility, uniqueness, relevance
- [ ] Score threshold Code node keeps only average >= 7 articles
- [ ] Fallback to threshold 5 if no articles pass at 7
- [ ] Processed URLs saved to MariaDB after validation
- [ ] Test run shows scores attached to each passing article

---

## Next step

→ [P3-T8: Build Extractor Agent](p3-t8-extractor-agent.md)
