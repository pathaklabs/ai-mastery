# P3-T6: Build Pre-filter Agent

> **Goal:** Build the Pre-filter agent — a rule-based filter that removes junk articles before any expensive AI calls happen.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 5
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are replacing the Pre-filter placeholder node with a real Code node that removes articles that are:
- Older than 30 days
- Missing content (empty or very short snippets)
- Non-English
- Clearly below a relevance threshold

**Important:** This agent uses a **Code node**, not an AI model. This is intentional. Rule-based filtering is:
- Faster (no API call)
- Cheaper (no tokens spent)
- Predictable (same input always gives same output)

You only call AI when you need AI. Dates and length checks do not need AI.

**n8n concept:** A **Code node** runs JavaScript code against the items from the previous node. You write `$input.all()` to get all items, process them, and `return` the ones you want to keep.

---

## Why this step matters

```
[Search] → up to 30 raw articles
                  │
                  ▼
    ┌─────────────────────────┐
    │     PRE-FILTER AGENT    │  ← You are building this
    │                         │
    │  Rule 1: Too old?  ✗    │
    │  Rule 2: No content? ✗  │
    │  Rule 3: Non-English? ✗ │
    │  Rule 4: Too short? ✗   │
    │                         │
    │  Result: 15 articles ✓  │
    └─────────────────────────┘
                  │
                  ▼
            [Validator]
    (only sees quality articles)
```

Without Pre-filter, the Validator (which calls an AI model) would waste tokens scoring articles that are obviously junk.

**Rule of thumb:** Every article that Pre-filter removes saves you one AI call in Validator.

---

## Prerequisites

- [ ] [P3-T5](p3-t5-search-agent.md) complete — Search outputs normalised articles with `published_date`, `snippet`, `url`, `title`, `source_domain`

---

## Step-by-step instructions

### Step 1 — Open the Pre-filter placeholder node

1. Open your `AI Research Pipeline` workflow
2. Double-click the `Agent 3 — Pre-filter` placeholder node
3. Change the node type to **Code** (if it is currently a "Message a Model" placeholder, delete it and add a Code node)
4. Name it: `Agent 3 — Pre-filter`

---

### Step 2 — Write the filter logic

Paste this JavaScript into the Code node:

```javascript
// Get all articles from Search
const articles = $input.all().map(item => item.json);

// Define the cutoff date — 30 days ago
const cutoffDate = new Date();
cutoffDate.setDate(cutoffDate.getDate() - 30);

// Track filter stats for logging
const stats = {
  total: articles.length,
  filtered_too_old: 0,
  filtered_no_content: 0,
  filtered_non_english: 0,
  filtered_too_short: 0,
  passed: 0
};

// Run each article through the filter rules
const passed = articles.filter(article => {

  // --- Rule 1: Must have a published date and be within 30 days ---
  if (!article.published_date) {
    stats.filtered_too_old++;
    console.log(`Filtered (no date): ${article.url}`);
    return false;
  }

  const publishedDate = new Date(article.published_date);
  if (isNaN(publishedDate.getTime())) {
    // Date string could not be parsed
    stats.filtered_too_old++;
    console.log(`Filtered (unparseable date "${article.published_date}"): ${article.url}`);
    return false;
  }

  if (publishedDate < cutoffDate) {
    stats.filtered_too_old++;
    console.log(`Filtered (too old — ${article.published_date}): ${article.url}`);
    return false;
  }

  // --- Rule 2: Must have a snippet/content ---
  if (!article.snippet) {
    stats.filtered_no_content++;
    console.log(`Filtered (no content): ${article.url}`);
    return false;
  }

  // --- Rule 3: Content must be long enough to be meaningful ---
  if (article.snippet.length < 80) {
    stats.filtered_too_short++;
    console.log(`Filtered (snippet too short — ${article.snippet.length} chars): ${article.url}`);
    return false;
  }

  // --- Rule 4: Basic English detection ---
  // Simple heuristic: check for non-ASCII characters dominating the text
  const nonAsciiCount = (article.snippet.match(/[^\x00-\x7F]/g) || []).length;
  const nonAsciiRatio = nonAsciiCount / article.snippet.length;
  if (nonAsciiRatio > 0.3) {
    // More than 30% non-ASCII — likely not English
    stats.filtered_non_english++;
    console.log(`Filtered (non-English, ${Math.round(nonAsciiRatio * 100)}% non-ASCII): ${article.url}`);
    return false;
  }

  // --- Passed all rules ---
  stats.passed++;
  return true;
});

// Log summary
console.log(`Pre-filter summary: ${stats.total} in → ${stats.passed} out`);
console.log(`  Too old:      ${stats.filtered_too_old}`);
console.log(`  No content:   ${stats.filtered_no_content}`);
console.log(`  Too short:    ${stats.filtered_too_short}`);
console.log(`  Non-English:  ${stats.filtered_non_english}`);

// Alert if the filter is too aggressive
if (stats.passed === 0) {
  throw new Error(
    `Pre-filter removed ALL ${stats.total} articles. ` +
    `Check filter rules. Stats: ${JSON.stringify(stats)}`
  );
}

if (stats.passed < 3 && stats.total > 5) {
  console.log(
    `WARNING: Pre-filter is aggressive — only ${stats.passed}/${stats.total} articles passed. ` +
    `Consider loosening filter rules.`
  );
}

// Return passed articles with the filter stats attached
return passed.map(article => ({
  json: {
    ...article,
    filter_passed: true,
    filter_stats: stats
  }
}));
```

---

### Step 3 — Test the Pre-filter

1. Run the workflow through Pre-filter
2. Check the n8n execution log (the panel below the canvas when running)
3. You should see console.log output showing which articles were filtered and why

Look for the summary line:
```
Pre-filter summary: 28 in → 19 out
  Too old:      5
  No content:   2
  Too short:    1
  Non-English:  1
```

If you see `Pre-filter removed ALL articles`:
- Check that Search is returning articles with `published_date` set
- Check that your date parsing is correct (log one raw article to see what `published_date` looks like)

---

### Step 4 — Adjust thresholds if needed

Every topic behaves differently. If Pre-filter is too aggressive:
- Increase snippet minimum length from 80 to 50
- Relax the non-ASCII ratio from 0.3 to 0.5
- Check if `published_date` is coming through in the right format from Tavily

If Pre-filter is too lenient (junk articles are passing):
- Add domain blocklist: exclude known low-quality domains
- Increase minimum snippet length

---

## Visual overview

```
[Search Output]
  30 articles: { url, title, snippet, published_date, source_domain }
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  Code: Pre-filter Agent                              │
│                                                      │
│  For each article:                                   │
│                                                      │
│  published_date exists?  NO  → filtered_too_old++   │
│  published_date < 30d?   YES → filtered_too_old++   │
│  snippet exists?         NO  → filtered_no_content++│
│  snippet.length >= 80?   NO  → filtered_too_short++ │
│  non-ASCII ratio < 30%?  NO  → filtered_non_english+│
│                                                      │
│  Passed all rules?       YES → include in output    │
│                                                      │
│  Log summary to console                              │
│  Throw error if 0 articles pass                      │
└─────────────────────────────────────────────────────┘
        │
        │ ~15–20 filtered articles
        ▼
  [Validator] (next task)
```

---

## Learning checkpoint

> Write in your build log:
> "My Pre-filter passed `{{ N }}` out of `{{ total }}` articles. The most common reason for rejection was `{{ reason }}`. Does this make sense given my topic? If the filter were too strict and I had 0 passing, what would be my first debugging step?"

---

## Done when

- [ ] Code node replaces the Pre-filter placeholder
- [ ] Rule 1: Articles older than 30 days are filtered
- [ ] Rule 2: Articles with no snippet are filtered
- [ ] Rule 3: Articles with snippet shorter than 80 chars are filtered
- [ ] Rule 4: Non-English articles are filtered (non-ASCII heuristic)
- [ ] Filter reasons are logged for each rejected article
- [ ] Pipeline throws a clear error if 0 articles pass
- [ ] Test run shows at least 5 articles passing through

---

## Next step

→ [P3-T7: Build Validator Agent](p3-t7-validator-agent.md)
