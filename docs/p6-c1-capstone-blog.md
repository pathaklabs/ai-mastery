# P6-C1: Capstone Blog — 14 Weeks, 6 AI Projects

> **Goal:** Write your most important piece of content: a 2000-word honest retrospective of the entire AI Mastery program.

**Part of:** [P6-E1: PathakLabs AI Monitoring Dashboard](p6-e1-ai-dashboard.md)
**Week:** 14
**Labels:** `content`, `p6-dashboard`, `capstone`

---

## What you are doing

You are writing a 2000-word blog post about the 14-week AI Mastery program. This post tells the full story: why you started, what you built, what surprised you, and what comes next.

This is not a technical tutorial. It is a reflection. It is the piece of content that will still be driving traffic and opening conversations 6 months from now.

Write it carefully.

---

## Why this step matters

Anyone can publish a repository. Very few people publish an honest, specific, numbered account of what it actually took to build something real.

Concrete numbers convert readers into believers:
- "I ran 5 AI projects for 14 weeks"
- "Total API spend: €47"
- "I published 12 build logs, 6 LinkedIn posts, and 3 blog posts"
- "My RAG system's hallucination detection caught 23% of answers"

These specifics make the post shareable, credible, and findable. Someone searching for "how to build a RAG system" will find this post and trust it because you show real numbers.

---

## Prerequisites

- [ ] All 6 projects are complete or meaningfully started
- [ ] The dashboard is deployed and you have real metrics to reference
- [ ] You have your build logs open — they contain the raw material

---

## The structure

**Title options:**
- "I built 6 AI projects in 14 weeks. Here is what I learned."
- "14 weeks, 6 AI projects, €47 in API costs: the PathakLabs retrospective"
- "From zero to 5 running AI systems: the honest story"

**Target length:** 2000 words
**Target platform:** Your blog (dev.to, Substack, personal site — wherever your audience is)
**Link to include:** The live dashboard URL

---

## Section-by-section outline with writing prompts

### Section 1 — Why I started (~200 words)

**What to write:** The gap you felt. What you could not do before this program. What you wanted to be able to say yes to.

**Prompts to answer:**
- What was the specific moment or realisation that made you start?
- What kind of work did you want to be able to take on?
- What did "AI engineering" mean to you before you started, and was that accurate?

**Example opening:**

> In January 2026 I could use ChatGPT. I could not build anything with AI. I wanted to change that. Not to chase a trend — but because I could see that the people building AI tools were going to be in a different position from the people only using them. This is the story of 14 weeks trying to cross that line.

---

### Section 2 — One lesson per project (6 paragraphs, ~800 words total, ~130 words each)

Write one paragraph per project. Each paragraph follows the same pattern:
1. What you built (one sentence)
2. The key technical challenge
3. The insight you took away — the thing that changed how you think

**Prompts per project:**

**P1 — PromptOS:**
- What surprised you about building a prompt management system?
- What did scoring 200+ outputs teach you about prompt quality?
- What would you tell someone who thinks prompt engineering is trivial?

Example: "PromptOS taught me that prompt quality is measurable. Before, I wrote prompts and guessed. After building a scoring system and rating 200 outputs myself, I could see patterns: long system prompts with examples consistently outscored short ones by 1.3 points on a 5-point scale. I did not expect to quantify creativity."

**P2 — RAG Brain:**
- What was the hardest part of building a reliable retrieval system?
- What does your hallucination detection actually catch?
- What did you learn about context windows and chunking?

Example: "RAG Brain taught me that retrieval is the bottleneck, not generation. I spent three weeks tuning the LLM and one day tuning the chunking strategy. The chunking day had more impact."

**P3 — Content Pipeline:**
- What did multi-agent orchestration actually look like in practice?
- How many hours of manual work per week does the pipeline save?
- What failed before it worked?

**P4 — AIGA:**
- What did you learn about AI governance by building a tool around it?
- What surprised you about the EU AI Act or other frameworks?
- What would you do differently in AIGA?

**P5 — PR Review Bot:**
- What is the false positive rate after tuning?
- What do AI code reviews miss that humans catch?
- What cost surprises came up?

**P6 — Dashboard:**
- What did seeing all 5 projects in one view change?
- What would you add to the dashboard if you had more time?
- What does the live dashboard prove that a README cannot?

---

### Section 3 — What I would do differently (~250 words)

**What to write:** Honest reflection. Three or four specific things you would change.

**Prompts:**
- Which project did you underestimate the most?
- What did you over-engineer that could have been simpler?
- What would you build first if you started over?
- When did you nearly quit, and what happened?

This section is important for credibility. Readers trust retrospectives that include failure. If everything sounds perfect, nobody believes it.

**Example:**

> If I started again, I would build the metrics API in Week 1 instead of Week 10. I spent 14 weeks flying blind on costs and performance. Having one place to see all 5 projects from the start would have changed every decision I made.

---

### Section 4 — What I can build now (~300 words)

**What to write:** Concrete before/after. What questions can you now say yes to?

**Prompts:**
- What can you build in a weekend that you could not build before?
- What job descriptions can you now apply to that you could not before?
- What would you say if a client asked you to build an AI system tomorrow?
- What is the most valuable skill you developed?

**Example:**

> Fourteen weeks ago if someone had asked me to build a document retrieval system with hallucination detection, I would have said I needed to learn more first. Now I would quote a timeline and start on Monday. That is the real output of this program — not six repositories, but the confidence to scope and start.

---

### Section 5 — What is next for PathakLabs (~200 words)

**What to write:** What comes after this program. Where you are taking these skills.

**Prompts:**
- What are the next 3 things you plan to build?
- Are you looking for freelance work, a job, or building your own products?
- What does PathakLabs look like in 12 months?
- Who should reach out to you and why?

End with a clear call to action — the link to the live dashboard.

---

## Writing tips

**Do not wait until it is perfect.** Write the draft in one session. Edit in the next. Publish in the one after that. Three sessions maximum.

**Use your build logs.** Open the docs folder. Every decision you documented is raw material for this post.

**Include the real numbers.** Whatever the costs were. However many posts you published. Whatever the false positive rate is. Real numbers are always better than vague claims.

**Link to the dashboard.** Put the link in the first 200 words and the last paragraph. It is the proof that supports every claim in the post.

**Start with a story, not a list.** The best technical retrospectives read like personal essays that happen to contain technical information.

---

## Draft outline (paste this into your writing tool)

```
Title: [Your chosen title]

Introduction — The gap I felt (200 words)
- The moment I decided to start
- What I wanted to be able to do

What I built — One lesson per project (800 words)
- P1 PromptOS: [lesson]
- P2 RAG Brain: [lesson]
- P3 Pipeline: [lesson]
- P4 AIGA: [lesson]
- P5 PR Review Bot: [lesson]
- P6 Dashboard: [lesson]

What I would do differently (250 words)
- [3-4 specific things]

What I can build now (300 words)
- Before vs after
- What I can say yes to

What is next for PathakLabs (200 words)
- Next 3 builds
- Call to action + dashboard link
```

---

## Done when

- [ ] Draft is written (aim for 2000 words, anything over 1500 is fine)
- [ ] Post includes at least 5 real numbers (costs, metrics, counts)
- [ ] Dashboard link is included and working
- [ ] Post is published and the URL is added to `content.json` in the dashboard
- [ ] Link shared on LinkedIn as a standard post or article

---

## Next step

→ [P6-C2: LinkedIn Series](p6-c2-linkedin-series.md) — 6 shorter posts, one per project.
→ [P6-C3: Instagram Reel](p6-c3-instagram-reel.md) — screen recording of the live dashboard.
