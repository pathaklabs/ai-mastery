# P3-T5: Build Search Agent

> **Goal:** Build the Search agent — it takes each query from the Planner and finds real web articles using the Tavily API.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 5
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are replacing the Search placeholder node with a real HTTP Request node that calls the Tavily search API. For each query the Planner produced, Search will return up to 10 recent web articles.

**n8n concepts:**
- **HTTP Request node:** Makes API calls to any web service. Think of it as a built-in Postman or curl.
- **Input items:** Because the Planner outputs one item per query, this node will run once per query automatically — n8n's default behaviour.
- **Body (JSON):** The data you send in a POST request — in this case, the search parameters.

---

## Why this step matters

```
[Planner] → 3 queries
               │
               ▼
     ┌──────────────────┐
     │   SEARCH AGENT   │  ← You are building this
     │                  │
     │  Query 1 → Tavily → 10 articles
     │  Query 2 → Tavily → 10 articles
     │  Query 3 → Tavily → 10 articles
     │                  │
     │  Total: up to 30 raw articles
     └──────────────────┘
               │
               ▼
         [Pre-filter]
```

Without the Search agent, the pipeline has no data. Everything downstream depends on the quality of what Search returns.

The 30-day date filter is critical — without it, Tavily may return articles from 2021 that are still indexed.

---

## Prerequisites

- [ ] [P3-T4](p3-t4-planner-agent.md) complete — Planner outputs `{ text, priority, original_topic }` per item
- [ ] Tavily API credential (`Tavily API`) added to n8n

---

## Step-by-step instructions

### Step 1 — Replace the Search placeholder node

1. Open your `AI Research Pipeline` workflow
2. Delete (or open and reconfigure) the `Agent 2 — Search` placeholder node
3. Add an **HTTP Request** node in its place
4. Name it: `Agent 2 — Search (Tavily)`

---

### Step 2 — Configure the HTTP Request node

Set these fields in the node:

**Method:** `POST`

**URL:** `https://api.tavily.com/search`

**Authentication:**
- Select: `Predefined Credential Type`
- Credential Type: `Header Auth`
- Credential: `Tavily API`

**Body Content Type:** `JSON`

**Body (JSON):**
```json
{
  "query": "{{ $json.text }}",
  "search_depth": "advanced",
  "max_results": 10,
  "days": 30,
  "include_answer": false,
  "include_raw_content": false,
  "include_images": false
}
```

What each field does:
- `query`: The search query text from the Planner output
- `search_depth`: `"advanced"` gives better results (slower but worth it)
- `max_results`: Up to 10 articles per query
- `days`: Only return articles from the last 30 days — this is your recency filter
- The three `false` fields: turn off features we do not need (saves API credits)

---

### Step 3 — Add a Code node to normalise Search output

After the HTTP Request node, add a **Code** node. Name it `Normalise Search Results`.

This node reshapes Tavily's response into the standard article format defined in your agent contract.

```javascript
// Tavily returns: { results: [ { url, title, content, published_date, ... } ] }
const tavilyResponse = $input.first().json;

// Get the results array (Tavily might return 'results' or 'data')
const rawResults = tavilyResponse.results || tavilyResponse.data || [];

// Check if we got any results
if (rawResults.length === 0) {
  console.log(`Search returned 0 results for this query`);
  return []; // Return empty — pipeline continues, Pre-filter handles 0 articles
}

// Normalise each result to our standard schema
const articles = rawResults.map(result => ({
  json: {
    url: result.url || null,
    title: result.title || 'No title',
    snippet: result.content || result.snippet || null,
    published_date: result.published_date || null,
    source_domain: extractDomain(result.url),
    query_that_found_this: $input.first().json.query || 'unknown'
  }
}));

// Helper function to extract domain from URL
function extractDomain(url) {
  if (!url) return 'unknown';
  try {
    return new URL(url).hostname.replace('www.', '');
  } catch (e) {
    return 'unknown';
  }
}

return articles;
```

---

### Step 4 — Add a Merge node to combine all query results

Because the Planner outputs 3 queries, n8n runs the Search node 3 times — once per query. You need to merge all the results back into one list before passing to Pre-filter.

1. Add a **Merge** node after the Normalise node
2. Name it: `Merge All Search Results`
3. Set Mode: `Append` (combines all items into one list)
4. Connect all branches into this Merge node

The Merge node waits for all query branches to finish, then outputs everything together.

```
[Planner]
    │
    ├── Query 1 → [Search] → [Normalise] ─┐
    ├── Query 2 → [Search] → [Normalise] ─┤→ [Merge] → [Pre-filter]
    └── Query 3 → [Search] → [Normalise] ─┘
```

Note: In n8n, when one node outputs multiple items, the next node runs once per item by default. You may need to use a **Loop Over Items** or check the "Execute Once Per Item" setting depending on your n8n version. Test and adjust.

---

### Step 5 — Test the Search agent

1. Set your Input topic to `AI agents in healthcare 2025`
2. Run the workflow up to the Merge node
3. Check the output — you should see 10–30 article items

Expected output (one item example):
```json
{
  "url": "https://techcrunch.com/2025/03/15/ai-agents-healthcare",
  "title": "AI Agents Are Transforming Hospital Diagnosis",
  "snippet": "New AI agents deployed in Mayo Clinic have reduced...",
  "published_date": "2025-03-15",
  "source_domain": "techcrunch.com",
  "query_that_found_this": "AI agents healthcare diagnosis 2025"
}
```

If you get 0 results:
- Check your Tavily credential is correct
- Try a broader query manually in Tavily's web interface
- Check if `days: 30` is too restrictive for your topic

---

## Visual overview

```
[Planner Output]
  { text: "AI agents healthcare 2025", priority: 1, ... }
  { text: "hospital AI automation news", priority: 2, ... }
  { text: "clinical AI FDA 2025", priority: 3, ... }
        │
        │ n8n runs Search once per item
        ▼
┌───────────────────────────────────┐
│  HTTP Request: POST tavily.com/search │
│                                   │
│  query: "{{ $json.text }}"        │
│  days: 30                         │
│  max_results: 10                  │
└───────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────┐
│  Code: Normalise Search Results   │
│                                   │
│  { url, title, snippet,           │
│    published_date, source_domain, │
│    query_that_found_this }        │
└───────────────────────────────────┘
        │
        ▼ (3 branches merge here)
┌───────────────────┐
│  Merge (Append)   │  All articles from all queries
└───────────────────┘
        │
        ▼
 Up to 30 raw articles
 → [Pre-filter] (next task)
```

---

## Learning checkpoint

> Write in your build log:
> "I searched for `{{ topic }}` and got `{{ N }}` total articles. If I had not set `days: 30`, what would I expect to be different? Why does recency matter for this pipeline?"

---

## Done when

- [ ] HTTP Request node configured with Tavily endpoint and `days: 30`
- [ ] Tavily API credential used (not raw key in URL)
- [ ] Normalise Code node reshapes results to standard article schema
- [ ] Merge node combines results from all queries
- [ ] Test run returns at least 5 articles
- [ ] Each article item has: url, title, snippet, published_date, source_domain

---

## Next step

→ [P3-T6: Build Pre-filter Agent](p3-t6-prefilter-agent.md)
