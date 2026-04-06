# X-T3: Create LinkedIn Post Template

> **Goal:** Create a reusable LinkedIn post template so you can write a compelling, structured post after every project — without staring at a blank page.

**Part of:** [X-E1: Content System Setup](x-e1-content-system.md)
**Week:** 1
**Labels:** `task`, `content`

---

## What you are doing

You are creating a markdown file called `POST_TEMPLATE.md` inside `content/linkedin/`. This template gives you a seven-part structure for every LinkedIn post you write. Instead of starting from scratch each time, you copy the template, fill in the blanks, and post.

The structure is designed specifically for developer build-in-public posts — it hooks readers with something real, explains a problem, shows your process, and ends with a question that drives comments.

---

## Why this matters

LinkedIn rewards posts that get comments in the first hour. A template helps you write posts that follow a structure proven to work: hook, problem, process, insight, call-to-action. Without a template, posts either never get written (too much friction) or they ramble without a point. A 6-post output across 6 projects becomes a real audience over 14 weeks — but only if you actually post.

---

## Prerequisites

Before starting this task, make sure:
- [ ] [X-T2: Content folder structure](x-t2-content-folders.md) is complete — `content/linkedin/` must exist

---

## Step-by-step instructions

### Step 1 — Navigate to your project root

```bash
cd ~/GitHub/ai-mastery
```

---

### Step 2 — Create the template file

```bash
touch content/linkedin/POST_TEMPLATE.md
```

Open it in your editor:

```bash
code content/linkedin/POST_TEMPLATE.md
```

---

### Step 3 — Paste in the template

Copy and paste the following into the file exactly as written:

```markdown
# LinkedIn Post — [Topic] — [Date]

## Hook (1-2 lines)
Make someone stop scrolling. Use: a surprising fact, a failure, or a bold claim.
Example: "I spent 4 hours debugging an AI agent. The fix was one word."

## The Problem (2-3 lines)
What was broken or confusing before you figured it out?
Write this as if explaining to a colleague who knows the field but not your project.

## What I Tried (bullets)
- Attempt 1 and what happened
- Attempt 2 and what happened
- Attempt 3 — what finally worked

## What Actually Worked
One clear, direct answer. No hedging. Write it like advice to your past self.

## The Insight (1 punchy line)
The thing you wish someone had told you before you started.
Example: "Chunking strategy matters more than your embedding model."

## CTA (question to drive comments)
Ask the reader something specific. Not "what do you think?" — something they can answer.
Example: "What's your go-to chunking strategy for long documents?"

## Hashtags
#AIEngineering #BuildInPublic #PathakLabs
```

Save the file.

---

### Step 4 — Understand the anatomy of each section

Here is why each section exists and what makes it work:

```
HOOK
 │  Stop the scroll. LinkedIn shows only the first 2 lines
 │  before the "see more" cut. If this is boring, nobody reads.
 │
 ▼
THE PROBLEM
 │  Show you were confused or stuck. This builds trust.
 │  People relate to problems, not success stories.
 │
 ▼
WHAT I TRIED
 │  Show your process. This is what separates a learning post
 │  from a press release. Other developers love seeing the path.
 │
 ▼
WHAT WORKED
 │  Give the answer clearly. No vagueness. Be useful.
 │
 ▼
THE INSIGHT
 │  One memorable line. This is what people screenshot and share.
 │
 ▼
CTA
    Ask a question. Comments in the first hour = reach.
    Ask something specific — vague questions get no answers.
```

---

### Step 5 — Write your first draft (right now)

Do not wait until you finish a project. Write a post about setting up the content system itself. Use the template:

```bash
cp content/linkedin/POST_TEMPLATE.md \
   content/linkedin/2026-04-06-content-system-setup.md
```

Open the new file and fill it in for this week's setup work. Even a rough draft counts.

---

## Visual overview

```
content/linkedin/
├── POST_TEMPLATE.md                        ← blank template (never edit)
├── 2026-04-06-content-system-setup.md      ← Week 1 post draft
├── 2026-04-20-p1-promptos-launch.md        ← P1 post draft
├── 2026-05-04-p2-rag-brain.md              ← P2 post draft
└── ...

One template → six post drafts → six published posts → growing audience
```

---

## Learning checkpoint

> Write your answer to this question BEFORE moving on: What is the most interesting thing you have learned or built in the last month that you have NOT shared publicly? That is your first post.

Write the topic in your build log.

---

## Done when

- [ ] `content/linkedin/POST_TEMPLATE.md` exists and contains all seven sections
- [ ] You have written at least one draft post by copying the template

---

## Next step

-> After this task, continue with [X-T4: Set up Medium or personal blog](x-t4-blog-platform.md)
