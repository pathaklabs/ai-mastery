# P3-T8: Build Extractor Agent

> **Goal:** Build the Extractor agent — it reads each validated article and pulls out structured facts, quotes, statistics, and entities that the Synthesizer can use.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 6
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

The Extractor takes each validated article (title + snippet) and sends it to an LLM with a structured extraction prompt. The LLM reads the article and returns:

- **key_facts:** 3–5 important facts stated in the article
- **notable_quote:** The single most quotable sentence
- **statistics:** Any facts that contain numbers or percentages
- **entities:** Company names, people, products, organisations mentioned
- **summary_one_line:** A one-sentence summary of the article

This gives the Synthesizer rich, structured material to write from — instead of just raw snippets.

**n8n concept:** The Extractor runs once per article (n8n's default item-splitting behaviour). If you have 8 articles from the Validator, the Extractor node runs 8 times.

---

## Why this step matters

```
[Validator] → 8 articles
   { url, title, snippet, scores }
                  │
                  ▼
    ┌────────────────────────────────┐
    │       EXTRACTOR AGENT          │  ← You are building this
    │                                │
    │  Article: "AI agents reduce    │
    │   diagnosis time by 40% at     │
    │   Mayo Clinic..."              │
    │                                │
    │  Extracts:                     │
    │  key_facts: ["40% reduction",  │
    │    "Mayo Clinic deployment",   │
    │    "FDA clearance received"]   │
    │  notable_quote: "This changes  │
    │   everything about triage"     │
    │  statistics: ["40% faster",    │
    │    "3,000 patients/month"]     │
    │  entities: ["Mayo Clinic",     │
    │    "FDA", "DeepMind Health"]   │
    │  summary_one_line: "AI agents  │
    │   cut diagnosis time 40% at    │
    │   Mayo Clinic pilot program"   │
    └────────────────────────────────┘
                  │
                  ▼
         [Synthesizer]
   Has rich material to write with
```

If the Synthesizer only received the raw snippet, it would write a vague post. With structured extraction, it can cite specific facts, use real quotes, and write something genuinely informative.

---

## Prerequisites

- [ ] [P3-T7](p3-t7-validator-agent.md) complete — Validator outputs articles with `scores` and `passed: true`
- [ ] A credential for an LLM (Claude, Gemini, or DeepSeek) available in n8n

**Recommended model for extraction:** DeepSeek or Gemini Flash — this task is structured and does not require the highest quality model. Save Claude for the Synthesizer.

---

## Step-by-step instructions

### Step 1 — Open the Extractor placeholder node

1. Open your `AI Research Pipeline` workflow
2. Open the `Agent 5 — Extractor` placeholder node
3. It should already be a "Message a Model" node

---

### Step 2 — Configure the extraction prompt

**Credential:** `DeepSeek API` (or Gemini if you prefer)
**Model:** `deepseek-chat` (or `gemini-1.5-flash`)

**System Prompt:**
```
You are a content extraction assistant. You read articles and extract
structured information for a content writer to use.

Your output must always be valid JSON with exactly these five fields:
- key_facts: array of 3–5 strings, each a specific factual claim from the article
- notable_quote: one string, the single most quotable sentence (or empty string if none)
- statistics: array of strings, each a fact containing a number or percentage
  (can be empty array if article has no statistics)
- entities: array of strings, each a company/person/product/organisation name
  (can be empty array)
- summary_one_line: one string, a single sentence summarising the article

Rules:
- Return ONLY the JSON object. No explanation. No markdown. No preamble.
- Do not invent facts. Only extract what is stated in the article.
- If a field has no content, use an empty array [] or empty string "".
- Each key_fact must be specific and standalone — readable without context.

Example output format:
{
  "key_facts": [
    "AI agents reduced diagnosis time by 40% in the Mayo Clinic trial",
    "The system processed 3,000 patient records per month",
    "FDA granted Class II clearance in January 2025"
  ],
  "notable_quote": "This is the most significant change to triage we have seen in 30 years",
  "statistics": ["40% reduction in diagnosis time", "3,000 patients per month"],
  "entities": ["Mayo Clinic", "FDA", "DeepMind Health"],
  "summary_one_line": "DeepMind Health's AI agents cut diagnosis time by 40% in a Mayo Clinic pilot that received FDA clearance."
}
```

**User Message:**
```
Extract structured information from this article.

Title: {{ $json.title }}
Published: {{ $json.published_date }}
Source: {{ $json.source_domain }}

Content:
{{ $json.snippet }}
```

---

### Step 3 — Add a Code node to validate and attach extraction

After the "Message a Model" node, add a **Code** node. Name it: `Parse + Attach Extraction`.

This node:
1. Parses the LLM's JSON response
2. Validates that all required fields exist
3. Attaches the extraction to the article object
4. Handles parsing failures gracefully

```javascript
const items = $input.all();

return items.map(item => {
  const article = item.json;

  // The LLM response text comes from the "Message a Model" output
  const responseText = article.text || article.output || '';

  let extracted;
  try {
    extracted = JSON.parse(responseText);
  } catch (e) {
    // JSON parsing failed — create a minimal fallback
    console.log(`Extraction parse failed for "${article.title}": ${e.message}`);
    console.log(`Raw response (first 300 chars): ${responseText.substring(0, 300)}`);

    extracted = {
      key_facts: ['Extraction failed — see raw snippet'],
      notable_quote: '',
      statistics: [],
      entities: [],
      summary_one_line: article.title || 'No summary available',
      extraction_failed: true
    };
  }

  // Ensure all required fields exist (fill in defaults if missing)
  const safeExtracted = {
    key_facts: Array.isArray(extracted.key_facts) ? extracted.key_facts : [],
    notable_quote: extracted.notable_quote || '',
    statistics: Array.isArray(extracted.statistics) ? extracted.statistics : [],
    entities: Array.isArray(extracted.entities) ? extracted.entities : [],
    summary_one_line: extracted.summary_one_line || article.title || '',
    extraction_failed: extracted.extraction_failed || false
  };

  // Log a summary
  console.log(
    `Extracted from "${article.title}": ` +
    `${safeExtracted.key_facts.length} facts, ` +
    `${safeExtracted.statistics.length} stats, ` +
    `${safeExtracted.entities.length} entities`
  );

  // Return the full article with extraction attached
  return {
    json: {
      url: article.url,
      title: article.title,
      published_date: article.published_date,
      source_domain: article.source_domain,
      snippet: article.snippet,
      scores: article.scores,
      extracted: safeExtracted
    }
  };
});
```

---

### Step 4 — Test with a real article

1. Run the pipeline up to the Extractor
2. Click on the output of `Parse + Attach Extraction`
3. Verify each article has an `extracted` object with real content

Expected output for one article:
```json
{
  "url": "https://example.com/ai-healthcare",
  "title": "AI Agents Cut Diagnosis Time by 40% at Mayo Clinic",
  "published_date": "2025-03-20",
  "source_domain": "healthcareit.com",
  "snippet": "A new AI agent system deployed at Mayo Clinic...",
  "scores": {
    "credibility": 8,
    "uniqueness": 7,
    "relevance": 9,
    "average": 8.0
  },
  "extracted": {
    "key_facts": [
      "AI agents reduced diagnosis time by 40% in a Mayo Clinic trial",
      "The FDA granted Class II clearance in January 2025",
      "3,000 patient records processed per month"
    ],
    "notable_quote": "This changes everything about how we approach triage",
    "statistics": ["40% reduction", "3,000 patients/month"],
    "entities": ["Mayo Clinic", "FDA"],
    "summary_one_line": "AI agents cut Mayo Clinic diagnosis time by 40% with FDA clearance."
  }
}
```

---

## Visual overview

```
[Validator: 8 articles]
  { url, title, snippet, scores }
        │
        │ n8n runs Extractor once per article (8 times)
        ▼
┌────────────────────────────────────────┐
│  Message a Model (DeepSeek)            │
│                                        │
│  System: "Extract structured info..."  │
│  User: "Title: {{ title }}             │
│         Content: {{ snippet }}"        │
│                                        │
│  Returns JSON with 5 fields            │
└────────────────────────────────────────┘
        │
        ▼
┌────────────────────────────────────────┐
│  Code: Parse + Attach Extraction       │
│                                        │
│  1. Parse JSON response                │
│  2. Validate 5 required fields         │
│  3. Attach to article object           │
│  4. Handle failures gracefully         │
└────────────────────────────────────────┘
        │
        │ 8 articles with extracted content
        ▼
  [Synthesizer] (next task)
  Now has rich material to write with
```

---

## Learning checkpoint

> Write in your build log:
> "Look at the extraction output for one of your articles. Is the `notable_quote` something you would actually use in a LinkedIn post? Does the `summary_one_line` accurately capture the article? If not, how would you adjust the prompt?"

This trains you to evaluate LLM output critically, not just accept it.

---

## Done when

- [ ] "Message a Model" node configured with extraction system prompt
- [ ] Extraction prompt uses `{{ $json.title }}` and `{{ $json.snippet }}` expressions
- [ ] Code node parses and validates all 5 required fields
- [ ] Extraction attached as nested `extracted` object on each article
- [ ] Parsing failures handled gracefully (fallback values, not crashes)
- [ ] Test run shows real key_facts, statistics, and entities extracted

---

## Next step

→ [P3-T9: Build Synthesizer Agent](p3-t9-synthesizer-agent.md)
