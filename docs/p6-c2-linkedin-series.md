# P6-C2: LinkedIn Series — One Retrospective Post Per Project

> **Goal:** Publish 6 LinkedIn posts, one per project, each under 300 words with one concrete number or result.

**Part of:** [P6-US2: Public Portfolio](p6-us2-public-portfolio.md)
**Week:** 13–14
**Labels:** `content`, `p6-dashboard`

---

## What you are doing

You are writing 6 LinkedIn posts — one retrospective per project. Each post stands alone (someone who missed the previous posts can still follow along) and ends with a link to the live dashboard or the project repository.

Post one per week across Weeks 13–14, or post them over 2–3 days if you want to close the chapter quickly.

---

## Why this step matters

LinkedIn's algorithm rewards series content. When you post the first retrospective and get engagement, your second post reaches more people. By the sixth, you have established yourself as someone who builds and ships AI systems, not just talks about them.

Each post must contain one concrete number. Vague claims ("I learned a lot about RAG") do not perform. Specific ones do ("My RAG system reduces hallucinations by 23% compared to the no-retrieval baseline").

---

## The template for each post

```
[Hook — one sentence that creates curiosity or states a surprising result]

[2-3 sentences of context — what you built and why]

[The core insight — what you learned that you did not expect]

[One concrete number or result]

[What this made possible]

[Call to action — link or question]

#AIEngineering #BuildInPublic #PathakLabs
```

Keep each post between 200 and 300 words. LinkedIn buries long posts behind a "see more" click — make sure the hook and first concrete result appear before that fold.

---

## Post templates, one per project

---

### Post 1 — PromptOS

**Hook angle:** Prompt quality is measurable. Most people guess. Here is what happens when you rate 200 outputs.

**Template:**

```
I rated 200 AI outputs on a 5-point scale.

Here is what separates a 4.5 from a 2.0:

I built PromptOS — a prompt management system that stores, versions,
and scores AI outputs across multiple models. The idea was to stop
guessing which prompts work and start measuring.

After rating 200 outputs manually, one pattern emerged clearly:
prompts with concrete examples in the system message scored
1.3 points higher on average than prompts without them.

That one change — adding 2-3 examples — has more impact than
switching models.

The other finding: Claude performed better on long-form reasoning tasks.
Ollama (local, free) performed surprisingly well on short classification
tasks. So I use both, and PromptOS tracks which one got used each time.

Key metric: 47 prompts saved, 200 outputs rated, average score improved
from 3.1 in Week 1 to 4.2 by Week 3.

PromptOS is Project 1 of 6 in my 14-week AI Mastery build.
All 5 running projects are tracked live here: [dashboard link]

#AIEngineering #PromptEngineering #BuildInPublic #PathakLabs
```

---

### Post 2 — RAG Brain

**Hook angle:** I thought generation was the problem. It was retrieval.

**Template:**

```
I spent 3 weeks tuning my LLM.
I spent 1 day tuning my chunking strategy.

The chunking day had more impact.

I built RAG Brain — a personal knowledge base that answers questions
about my Home Assistant setup, technical notes, and project docs.
I expected the hard part to be the AI model. It was the retrieval layer.

The insight: if the wrong documents go into the context window, no model
can save you. Garbage in, hallucination out.

After building a basic hallucination detector (checking whether the answer
is actually grounded in the retrieved sources), I found that 23% of early
answers failed the check. That number dropped to 8% after I fixed the
chunking and added a reranker.

This is Project 2 of 6 in my 14-week PathakLabs AI build.

The hallucination rate, query count, and document count are tracked live
on the dashboard: [dashboard link]

What part of RAG systems do you find hardest?

#RAG #LLM #BuildInPublic #AIEngineering #PathakLabs
```

---

### Post 3 — Content Pipeline

**Hook angle:** I built a system to write LinkedIn posts. It now runs without me touching it.

**Template:**

```
I built a system that finds AI news, summarises it, and drafts
a LinkedIn post — every morning, automatically.

Here is what I learned after running it for 6 weeks:

The pipeline uses 3 agents: a researcher that finds articles,
a writer that summarises and drafts, and a publisher that sends
drafts to Telegram for my approval before anything goes live.

The "human in the loop" step was the most important design decision.
Fully automatic publishing would have sent things I did not want published.
The Telegram approval step means I spend 2 minutes per post instead of 20.

Results after 6 weeks:
- 4 runs per week
- 8-12 articles reviewed per run
- 3 posts sent to approval each run
- I approved about 60% of them
- Total manual time: ~10 minutes per week

This is Project 3 of 6 in the PathakLabs AI Mastery program.
Live pipeline metrics: [dashboard link]

How much of your content workflow could be automated without losing quality?

#AIAgents #ContentMarketing #BuildInPublic #PathakLabs
```

---

### Post 4 — AIGA (AI Governance Assistant)

**Hook angle:** I built a governance chatbot and it changed how I think about the EU AI Act.

**Template:**

```
Before building AIGA, I had read about the EU AI Act.
After building a chatbot that helps assess AI systems against it,
I understand it differently.

AIGA is a RAG-based governance assistant. You describe an AI system —
what it does, who it affects, what decisions it makes — and it returns
a risk classification and relevant obligations under the EU AI Act,
UK AI Act, and other frameworks.

The surprising part: most of the AI systems I hear about in daily life
fall into higher risk categories than their builders realise.
Real-time credit scoring, facial recognition at events, automated hiring
screening — all of these have specific obligations that most teams
are not meeting.

Building the tool forced me to read the actual legislation carefully.
That is a very different experience from reading a summary about it.

In 6 weeks of use: 47 governance queries processed.
Most common risk level returned: medium (62% of queries).

Project 4 of 6. Live metrics: [dashboard link]

Are you tracking AI regulatory risk in your systems?

#AIGovernance #EUAIAct #BuildInPublic #PathakLabs
```

---

### Post 5 — PR Review Bot

**Hook angle:** I built a bot that reviews my code. Here is the false positive rate after tuning.

**Template:**

```
I built a GitHub bot that reviews every pull request with Claude.

After 6 weeks and 47 PRs reviewed, here is what I learned about
automated code review:

The bot is good at: style inconsistencies, missing error handling,
obvious security patterns (hardcoded secrets, SQL injection risks),
and overly complex functions.

The bot is bad at: understanding business logic, knowing whether
a test covers an important edge case, and anything requiring
context that is not in the diff.

Early false positive rate: 34% (35% of "issues" found were not real).
After adding better context in the system prompt and a confidence
threshold: 11% false positive rate.

The remaining issues it catches are genuinely useful. It found a
missing null check in production code that I had missed in review.

Total cost for 47 PR reviews: $3.74 (about 8 cents per review).

Project 5 of 6. Live metrics and cost data: [dashboard link]

What would you want an automated PR reviewer to focus on?

#CodeReview #DevTools #BuildInPublic #PathakLabs
```

---

### Post 6 — The Dashboard (Final Retrospective)

**Hook angle:** 14 weeks. 6 projects. One dashboard. Here is the total cost.

**Template:**

```
14 weeks ago I could use AI tools.
Now I build them.

Here is the final tally from the PathakLabs AI Mastery program:

Projects built: 6
- PromptOS: prompt management system
- RAG Brain: personal knowledge base
- Content Pipeline: automated content drafting
- AIGA: AI governance assistant
- PR Review Bot: automated code review
- This dashboard: real-time monitoring for all 5

Total API cost for 14 weeks: $[your real number]
Most expensive project: [your answer]
Cheapest: [your answer]

The dashboard tracks all of it in real time.

The most important thing I built is not any single project —
it is the habit of building and measuring. Every project pushed
metrics to a central API. Every cost event was tracked. Every
decision was documented.

That discipline is what turns side projects into a portfolio.

Live dashboard (genuinely live, real data): [dashboard link]
14-week retrospective blog post: [blog link]

If you are thinking about an AI engineering program — it is worth it.
Not because of what you will learn, but because of what you will ship.

#BuildInPublic #AIEngineering #PathakLabs #AIMonitoring
```

---

## Posting schedule

| Week | Post | Project |
|------|------|---------|
| 13   | Post 1 | PromptOS |
| 13   | Post 2 | RAG Brain |
| 13   | Post 3 | Pipeline |
| 14   | Post 4 | AIGA |
| 14   | Post 5 | PR Review Bot |
| 14   | Post 6 | Dashboard retrospective |

Space posts at least 24 hours apart. Do not post the same day as your capstone blog.

---

## Tips for LinkedIn performance

- **Post in the morning** — 7–9am weekdays, your target timezone
- **First comment** — add a comment with links after posting (LinkedIn suppresses links in the main post)
- **Respond to every comment** — even just "thanks, exactly" keeps the algorithm ranking the post
- **Tag sparingly** — 3–5 relevant hashtags, no more
- **No carousel for these** — text performs better than carousels for retrospective content

---

## Done when

- [ ] All 6 posts are written and saved as drafts
- [ ] Each post contains one concrete number
- [ ] Each post links to the dashboard or a project repository
- [ ] All 6 posts are published over Weeks 13–14
- [ ] URLs are added to `content.json` in the dashboard

---

## Next step

→ [P6-C3: Instagram Reel](p6-c3-instagram-reel.md) — screen recording of the live dashboard.
→ [P6-C1: Capstone Blog](p6-c1-capstone-blog.md) — the long-form retrospective.
