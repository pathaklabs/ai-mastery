# P3-C2: LinkedIn Post — 6-Agent Pipeline Architecture Diagram

> **Goal:** Write and publish a LinkedIn post that shows the full pipeline architecture and walks through one mistake made per agent.

**Part of:** [P3-US5: Publish P3 Learnings](p3-us5-content-publish.md)
**Week:** 8
**Labels:** `task`, `p3-pipeline`, `content`

---

## What you are doing

You are writing a LinkedIn post that:
1. Shows the full pipeline as an ASCII architecture diagram
2. Briefly explains what each agent does
3. Shares one real mistake you made while building each agent

This format works because it is honest. Most posts show polished results. This one shows the mistakes — which is what engineers actually want to read.

> "This format (mistake per agent) is highly shareable."

---

## Why this step matters

This post does three things for you:

1. **Proves you built something real** — You cannot fake specific mistakes. Listing one genuine mistake per agent shows you did the work.

2. **Teaches your audience** — People building similar things will see their future mistakes in your past ones. That is genuinely valuable.

3. **Builds your reputation** — Publishing technical content with real architecture diagrams positions you as an engineer, not just a content creator.

---

## Prerequisites

- [ ] Full pipeline built and tested (P3-T4 through P3-T9 complete)
- [ ] At least 2–3 real mistakes experienced while building (you have these — check your build logs)

---

## Step-by-step instructions

### Step 1 — Write down your real mistakes

Before writing the post, answer this for each agent (look at your build logs):

| Agent | One real mistake you made |
|-------|--------------------------|
| Planner | |
| Search | |
| Pre-filter | |
| Validator | |
| Extractor | |
| Synthesizer | |

If you cannot fill this table, go back and read your build logs. Real mistakes are the post's entire value.

---

### Step 2 — Draft the post

Use this structure:

```
[HOOK LINE — surprising fact or bold statement]

I built a 6-agent AI pipeline that researches any topic and drafts
LinkedIn posts. Here's the architecture — and one mistake I made
building each agent.

[ASCII DIAGRAM — copy from below]

Here's what went wrong:

1️⃣ PLANNER — [your mistake]
2️⃣ SEARCH — [your mistake]
3️⃣ PRE-FILTER — [your mistake]
4️⃣ VALIDATOR — [your mistake]
5️⃣ EXTRACTOR — [your mistake]
6️⃣ SYNTHESIZER — [your mistake]

[LESSON line]

[QUESTION for comments]

Stack: n8n + Tavily + Gemini + Claude + MariaDB
```

---

### Step 3 — The architecture diagram (use this)

Copy this ASCII diagram into your post:

```
Topic
  │
  ▼
┌──────────┐
│ PLANNER  │  Gemini → 5 search queries
└──────────┘
  │
  ▼
┌──────────┐
│  SEARCH  │  Tavily API → up to 50 raw articles
└──────────┘
  │
  ▼
┌────────────┐
│ PRE-FILTER │  Code rules → removes old/junk/non-English
└────────────┘
  │
  ▼
┌───────────┐
│ VALIDATOR │  Gemini scores → dedup via MariaDB
└───────────┘
  │
  ▼
┌───────────┐
│ EXTRACTOR │  DeepSeek → facts, quotes, stats per article
└───────────┘
  │
  ▼
┌─────────────┐
│ SYNTHESIZER │  Claude → LinkedIn post + Instagram caption
└─────────────┘
  │
  ▼
Telegram → Human review → Post
```

LinkedIn renders plain text. This diagram will display correctly as monospace text if you paste it into the post with no formatting changes.

---

### Step 4 — Write the mistake section

Here are example mistakes to replace with your real ones. **Do not use these — use your actual mistakes.**

```
1️⃣ PLANNER — I forgot to validate the JSON output.
The LLM returned valid-looking text that wasn't JSON. The pipeline
crashed 3 nodes later with a cryptic "Cannot read property of undefined."
Lesson: validate LLM output immediately at the source.

2️⃣ SEARCH — I set max_results: 50 without a date filter.
Got articles from 2021 dominating my results. The 30-day filter is
not optional — add it on day 1.

3️⃣ PRE-FILTER — My date comparison was comparing strings, not Date objects.
"2025-03-15" > "2024-12-01" evaluates to true (lexicographically).
"2025-03-15" > "2025-11-01" evaluates to false. Always parse dates.

4️⃣ VALIDATOR — I scored articles before checking for duplicates.
Wasted Gemini API calls on articles I had already processed.
Check duplicates first. Score what's new.

5️⃣ EXTRACTOR — My prompt said "return JSON" but forgot to say "no markdown."
The LLM wrapped the JSON in ```json ... ``` fences.
JSON.parse() failed. Now I strip code fences before every parse.

6️⃣ SYNTHESIZER — I referenced articles[1] without checking it existed.
If Validator only passed 2 articles, articles[2] is undefined.
Claude received "undefined" in the prompt. Output was... creative.
```

Replace every example above with your real mistake from your build logs.

---

### Step 5 — Write the closing lines

End with:
1. One lesson that ties it together (the insight behind all the mistakes)
2. A question for the comments

Example lesson line:
> The biggest lesson: write your agent contracts before building anything. I wasted 4 hours on problems that would have been obvious on paper.

Example questions that get comments:
- "Have you built a multi-agent system? What broke first?"
- "Which of these mistakes would you have made? Drop a number below."
- "What's the hardest part of multi-agent pipelines in your experience?"

---

### Step 6 — Publish

1. Go to LinkedIn
2. Create a new post
3. Paste the full post text
4. **Do not add images** — the ASCII diagram is your visual. Images hide text from search.
5. Post it
6. In the first comment, add the tech stack links (Tavily, n8n, etc.) — LinkedIn demotes posts with external links in the body

---

## Post length guide

LinkedIn posts perform best at 150–300 words for text-heavy posts like this. The architecture + 6 mistakes section will naturally land in this range.

Do not pad it. Do not shrink it. Write your mistakes honestly and stop when you are done.

---

## Full post template

Here is a complete draft you can fill in:

```
I automated my research workflow with a 6-agent AI pipeline.

[Hook: Add a surprising result, e.g. "It found 47 articles, filtered them
to 8, and drafted a LinkedIn post — in 3 minutes."]

Here's the architecture:

Topic
  │
  ▼
┌──────────┐
│ PLANNER  │  Gemini → 5 search queries
└──────────┘
  │
  ▼
┌──────────┐
│  SEARCH  │  Tavily API → up to 50 raw articles
└──────────┘
  │
  ▼
┌────────────┐
│ PRE-FILTER │  Code rules → removes old/junk/non-English
└────────────┘
  │
  ▼
┌───────────┐
│ VALIDATOR │  Gemini scores → dedup via MariaDB
└───────────┘
  │
  ▼
┌───────────┐
│ EXTRACTOR │  DeepSeek → facts, quotes, stats
└───────────┘
  │
  ▼
┌─────────────┐
│ SYNTHESIZER │  Claude → LinkedIn post + Instagram caption
└─────────────┘
  │
  ▼
Telegram → Human review → Post

Here's one mistake I made building each agent:

1️⃣ PLANNER — [YOUR REAL MISTAKE]
2️⃣ SEARCH — [YOUR REAL MISTAKE]
3️⃣ PRE-FILTER — [YOUR REAL MISTAKE]
4️⃣ VALIDATOR — [YOUR REAL MISTAKE]
5️⃣ EXTRACTOR — [YOUR REAL MISTAKE]
6️⃣ SYNTHESIZER — [YOUR REAL MISTAKE]

[LESSON]

Stack: n8n + Tavily + Gemini + Claude + DeepSeek + MariaDB

[QUESTION]
```

---

## Done when

- [ ] Real mistakes written for all 6 agents (from actual build experience)
- [ ] Architecture diagram included in the post
- [ ] Post is 150–300 words
- [ ] Post ends with a question
- [ ] Post published on LinkedIn
- [ ] Link to post saved in your build log

---

## Next step

→ [P3-C3: Blog — Multi-Agent Orchestration](p3-c3-blog-multi-agent.md)
