# P3-T9: Build Synthesizer Agent

> **Goal:** Build the final agent — it takes the top 3 articles and writes a LinkedIn post draft and an Instagram caption, then sends them to Telegram for your approval.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 7
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

The Synthesizer is the creative engine of the pipeline. It takes the structured facts the Extractor produced and turns them into social media content.

You will use **Claude** here. This is intentional — Claude is the best model for long-form writing tasks. The Synthesizer is where quality matters most. The output will go to your Telegram, where you read it, approve or edit it, and then publish.

**n8n concepts:**
- **Aggregate node** (or Code node): Collects all articles into a single item so the Synthesizer sees all 3 at once
- **Telegram node:** Sends a message to a Telegram chat or channel
- **Webhook node** (optional, advanced): Can receive Telegram button presses for approve/reject

---

## Why this step matters

```
[Extractor] → 8 articles with structured facts
                        │
                        │ Pick top 3 by score
                        ▼
        ┌───────────────────────────────────┐
        │        SYNTHESIZER AGENT          │  ← You are building this
        │                                   │
        │  Uses: Claude (best quality)      │
        │                                   │
        │  Receives:                        │
        │   Article 1: facts, quote, stats  │
        │   Article 2: facts, quote, stats  │
        │   Article 3: facts, quote, stats  │
        │   Topic: "AI in healthcare"       │
        │                                   │
        │  Produces:                        │
        │   LinkedIn post (200 words)       │
        │   Instagram caption (70 words)    │
        └───────────────────────────────────┘
                        │
                        ▼
              [Telegram → You]
              Review and approve before posting
```

This is the last step in the automation. Human review happens in Telegram before anything is published.

---

## Prerequisites

- [ ] [P3-T8](p3-t8-extractor-agent.md) complete — Extractor outputs articles with nested `extracted` objects
- [ ] Claude API credential added to n8n
- [ ] Telegram bot set up (see Step 1 below)

---

## Step-by-step instructions

### Step 1 — Set up a Telegram bot

You need a Telegram bot to receive the draft posts.

1. Open Telegram and search for `@BotFather`
2. Send `/newbot`
3. Give your bot a name (e.g. `PathakLabs Pipeline Bot`)
4. Give it a username (e.g. `pathaklabs_pipeline_bot`)
5. BotFather will give you a token like: `7123456789:AAH...`
6. Save this token
7. Start a chat with your new bot (search for it, press Start)
8. Find your chat ID: go to `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates` in your browser after sending the bot a message

In n8n, add a **Telegram** credential:
- Settings → Credentials → Add → Telegram
- Paste the bot token

---

### Step 2 — Add a Code node to select the top 3 articles

Before the Synthesizer, add a **Code** node. Name it: `Select Top 3 Articles`.

This node collects all articles, sorts by score, and picks the top 3.

```javascript
// Collect all articles from Extractor
const articles = $input.all().map(item => item.json);

// Sort by average score (highest first)
const sorted = articles.sort((a, b) => {
  const scoreA = a.scores?.average || 0;
  const scoreB = b.scores?.average || 0;
  return scoreB - scoreA;
});

// Take top 3
const top3 = sorted.slice(0, 3);

console.log(`Selecting top ${top3.length} articles from ${articles.length} validated articles`);
top3.forEach((a, i) => {
  console.log(`  ${i + 1}. "${a.title}" — score: ${a.scores?.average}`);
});

// Return as a single item containing all 3 articles
// (Synthesizer needs to see all 3 at once, not one at a time)
return [{
  json: {
    articles: top3,
    topic: $input.first().json.original_topic || 'general AI topic',
    selected_count: top3.length,
    selected_at: new Date().toISOString()
  }
}];
```

---

### Step 3 — Configure the Synthesizer "Message a Model" node

Add or open a **"Message a Model"** node. Name it: `Agent 6 — Synthesizer (Claude)`.

**Credential:** `Claude API`
**Model:** `claude-opus-4-5` or `claude-sonnet-4-5` (use Sonnet for cost savings, Opus for best quality)

**System Prompt:**
```
You are a content writer for a senior AI engineer and builder who shares
learnings publicly on LinkedIn and Instagram.

Your writing style:
- LinkedIn: professional but not corporate. Direct. Data-backed. Ends with a question.
  No buzzwords like "game-changer", "groundbreaking", or "revolutionary".
  Start with a hook — a surprising fact or bold statement.
  Length: 150–250 words.
- Instagram: casual, personal, uses 3–5 hashtags. Length: 50–80 words.

You will receive the top 3 articles about a topic, with extracted facts,
quotes, and statistics. Use them to write original content — do not just
summarise the articles.

Return ONLY valid JSON with two fields:
{
  "linkedin_post": "your post text here",
  "instagram_caption": "your caption text here"
}

No markdown. No explanation. No preamble.
```

**User Message:**

```
Research topic: {{ $json.topic }}

Here are the 3 most relevant and credible articles I found:

---
ARTICLE 1
Title: {{ $json.articles[0].title }}
Source: {{ $json.articles[0].source_domain }}
Summary: {{ $json.articles[0].extracted.summary_one_line }}
Key facts:
{{ $json.articles[0].extracted.key_facts.join('\n') }}
Statistics: {{ $json.articles[0].extracted.statistics.join(', ') }}
Notable quote: "{{ $json.articles[0].extracted.notable_quote }}"

---
ARTICLE 2
Title: {{ $json.articles[1].title }}
Source: {{ $json.articles[1].source_domain }}
Summary: {{ $json.articles[1].extracted.summary_one_line }}
Key facts:
{{ $json.articles[1].extracted.key_facts.join('\n') }}
Statistics: {{ $json.articles[1].extracted.statistics.join(', ') }}
Notable quote: "{{ $json.articles[1].extracted.notable_quote }}"

---
ARTICLE 3
Title: {{ $json.articles[2].title }}
Source: {{ $json.articles[2].source_domain }}
Summary: {{ $json.articles[2].extracted.summary_one_line }}
Key facts:
{{ $json.articles[2].extracted.key_facts.join('\n') }}
Statistics: {{ $json.articles[2].extracted.statistics.join(', ') }}
Notable quote: "{{ $json.articles[2].extracted.notable_quote }}"

---
Write a LinkedIn post and Instagram caption about this topic using these facts.
```

**Note:** If fewer than 3 articles passed validation, the `$json.articles[1]` and `$json.articles[2]` expressions may be undefined. Add a check in the top 3 selection node to handle this — replace missing article slots with a placeholder.

---

### Step 4 — Add a Code node to parse Synthesizer output

After the "Message a Model" node, add a **Code** node. Name it: `Parse Synthesizer Output`.

```javascript
const item = $input.first().json;
const responseText = item.text || item.output || '';

let parsed;
try {
  parsed = JSON.parse(responseText);
} catch (e) {
  throw new Error(
    `Synthesizer returned invalid JSON. ` +
    `Raw response: ${responseText.substring(0, 400)}`
  );
}

if (!parsed.linkedin_post || !parsed.instagram_caption) {
  throw new Error(
    `Synthesizer output missing required fields. Got: ${Object.keys(parsed).join(', ')}`
  );
}

// Attach metadata
return [{
  json: {
    linkedin_post: parsed.linkedin_post,
    instagram_caption: parsed.instagram_caption,
    sources: (item.articles || []).map(a => a.url),
    topic: item.topic || '',
    generated_at: new Date().toISOString(),
    word_count_linkedin: parsed.linkedin_post.split(' ').length,
    word_count_instagram: parsed.instagram_caption.split(' ').length
  }
}];
```

---

### Step 5 — Configure the Telegram node

Add a **Telegram** node after the parse node. Name it: `Telegram — Send for Approval`.

**Credential:** Your Telegram credential
**Resource:** `Message`
**Operation:** `Send Message`
**Chat ID:** Your chat ID (the one you found in Step 1)

**Message Text:**
```
🔬 *New AI Research Pipeline Draft*

*Topic:* {{ $json.topic }}
*Generated:* {{ $json.generated_at }}

---

📌 *LINKEDIN POST* ({{ $json.word_count_linkedin }} words)

{{ $json.linkedin_post }}

---

📱 *INSTAGRAM CAPTION* ({{ $json.word_count_instagram }} words)

{{ $json.instagram_caption }}

---

📚 *Sources used:*
{{ $json.sources.join('\n') }}

---
Review above and publish manually if approved.
```

**Parse Mode:** `Markdown`

---

### Step 6 — Test the full pipeline end-to-end

1. Set your input topic to something you genuinely want to research
2. Click **Execute Workflow**
3. Watch each agent run in sequence
4. After 2–3 minutes, check your Telegram — the draft should arrive

If Telegram does not receive the message:
- Check the chat ID is correct
- Check the bot token credential
- Look at the Telegram node output in n8n for any error

---

## Visual overview

```
[Extractor: 8 articles with extracted facts]
        │
        ▼
┌───────────────────────────────┐
│  Code: Select Top 3           │
│  Sort by score → pick top 3   │
│  Bundle into single item      │
└───────────────────────────────┘
        │
        │ { articles: [3], topic: "..." }
        ▼
┌───────────────────────────────┐
│  Message a Model (Claude)     │
│                               │
│  Receives all 3 articles      │
│  with facts, quotes, stats    │
│                               │
│  Returns:                     │
│  { linkedin_post, instagram } │
└───────────────────────────────┘
        │
        ▼
┌───────────────────────────────┐
│  Code: Parse output           │
│  Validate fields              │
│  Attach metadata              │
└───────────────────────────────┘
        │
        ▼
┌───────────────────────────────┐
│  Telegram: Send for Approval  │
│                               │
│  → Your Telegram chat         │
│  → You review the draft       │
│  → You publish manually       │
└───────────────────────────────┘
```

---

## Learning checkpoint

> Write in your build log:
> "Read the LinkedIn post Claude produced. Would you post this? What would you change? Is the hook strong? Does it have a specific fact or is it vague? What does this tell you about your prompt quality?"

This is the core skill: evaluating AI output and iterating on prompts.

---

## Done when

- [ ] Telegram bot created and bot token saved as credential
- [ ] Code node selects top 3 articles by score
- [ ] Claude "Message a Model" node configured with synthesis prompt
- [ ] Output parsing Code node validates linkedin_post and instagram_caption
- [ ] Telegram node sends the draft to your chat
- [ ] Full end-to-end test completes: topic → Telegram draft

---

## Next step

→ [P3-T10: Add Quality Logging](p3-t10-quality-logging.md)
