# P1-US4: Content — Publish P1 Learnings

> **Goal:** Share what you built and what you learned from Project 1 across four content formats.

**Part of:** [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 3
**Labels:** `content`, `p1-promptos`, `build-in-public`

---

## What this user story delivers

Four pieces of public content documenting your Project 1 experience: three in-progress build logs written during weeks 1–3, a LinkedIn post announcing what you shipped, a long-form blog post with technical depth, and an Instagram carousel with practical prompt tips.

---

## Why this story matters

Building in public is a force multiplier for learning. Writing forces you to understand what you actually built. Sharing builds an audience that holds you accountable to finish the next project. The content tasks are not optional extras — they are part of the program.

---

## Tasks in this story

| Task ID | Task | Doc link |
|---------|------|----------|
| P1-C1 | Write 3 build logs during P1 | [See below: P1-C1](#p1-c1-build-logs) |
| P1-C2 | LinkedIn — I built prompt version control | [See below: P1-C2](#p1-c2-linkedin-post) |
| P1-C3 | Blog — What I learned building a prompt management system | [See below: P1-C3](#p1-c3-blog-post) |
| P1-C4 | Instagram carousel — 5 things that make a great prompt | [See below: P1-C4](#p1-c4-instagram-carousel) |

---

## Acceptance criteria

- [ ] Three build logs filled in (one per week) using the `x-t1-build-log-template.md` format
- [ ] LinkedIn post published with a link to the GitHub repo
- [ ] Blog post published (800–1200 words) with architecture diagram and GitHub link
- [ ] Instagram carousel posted (5–7 slides)

---

---

## P1-C1: Build Logs

Write one build log per week during Project 1. Use the template at [x-t1-build-log-template.md](x-t1-build-log-template.md).

### When to write each log

| Log | Write it | Topic focus |
|-----|----------|-------------|
| Build Log 1 | End of Week 1 | Setting up the project, the data model, what surprised you about Alembic |
| Build Log 2 | End of Week 2 | Claude API vs Ollama — real latency numbers, token costs, what you learned |
| Build Log 3 | End of Week 3 | The scoring system, your eval rubric, what "good output" means to you now |

### What to include in each log

Answer these questions in plain English (bullet points are fine):

```
1. What did I build this week? (3–5 sentences, explain like a 6th-grader)
2. What was the hardest part?
3. What did Claude Code help with? What did it get wrong?
4. What surprised me most?
5. One specific number: a token count, latency measurement, or score result
6. What am I changing next week based on what I learned?
```

### Tips

- Write the log BEFORE you polish the code. Raw observations are more valuable.
- If you got stuck for 3 hours on something, write that. It is honest and relatable.
- One paragraph per question is enough. These are not essays.

---

## P1-C2: LinkedIn Post

### Goal

Announce that you shipped prompt version control. This is a technical achievement post — not a motivational quote. Show what you built.

### Length

150–250 words. LinkedIn rewards concise posts with a hook in the first line.

### Template

Adapt this — do not copy it word for word:

```
I just shipped something I've wanted for years:
version control for AI prompts. 🚀

Here's what it does:
→ Save prompts with full version history (like git for text)
→ Run the same prompt on Claude AND local Ollama models
→ Score each output on accuracy, format, tone, and completeness

Here's what I learned building it:

1. Prompt quality is measurable if you define your rubric first.
   I now rate every output 1–5 on 4 dimensions.

2. Local models (Llama 3 on my homelab) run in ~4 seconds.
   Claude responds in ~800ms. Cloud wins on speed; local wins on privacy.

3. Writing a CLAUDE.md before opening Claude Code made a huge difference.
   Context = quality output.

The whole stack: FastAPI + PostgreSQL + React + Anthropic SDK + Ollama.
All containerised with podman compose.

GitHub: [link]

Part of my 14-week AI Mastery program — building 6 real AI projects
in public. Follow along if you're doing the same.

#AIEngineering #PromptEngineering #BuildInPublic #FastAPI #LLM
```

### What makes this post work

- First line is a hook, not a title
- Numbers are specific (4 seconds, 800ms, 4 dimensions)
- Shows the real stack — signals technical credibility
- Ends with a call to follow the series

### Before you post

- [ ] Push your code to GitHub and make the repo public
- [ ] Add a README with a screenshot of the comparison UI
- [ ] Include the GitHub link in the post

---

## P1-C3: Blog Post

### Goal

A 800–1200 word technical post that teaches readers something real. This is not a tutorial — it is a reflection with code snippets.

### Platform suggestions

- Dev.to (free, developer audience, great SEO)
- Hashnode (your own subdomain, markdown)
- Your own site if you have one

### Outline

Use this structure:

```
Title: What I Learned Building a Prompt Management System
(or: Why Your AI Prompts Need Version Control)

--- HOOK (50–100 words) ---
A concrete problem statement:
"I kept rewriting prompts and forgetting what worked.
 Three weeks ago I decided to fix that."

--- WHAT I BUILT (150–200 words) ---
- Describe PromptOS in plain English
- Include the architecture ASCII diagram from p1-e1-promptos.md
- Link to GitHub repo

--- THE INTERESTING TECHNICAL DECISION (200–300 words) ---
Pick ONE thing that was non-obvious and explain it:

Option A: Why I chose "immutable versioning" for prompts
  (new version = new row, never update the body column)
Option B: How I parallelised Claude + Ollama calls with asyncio.gather
Option C: What building an eval rubric taught me about what "good" means

--- ONE FAILURE STORY (150–200 words) ---
Something that went wrong. Be specific:
- "I mixed sync and async code in FastAPI and spent 2 hours debugging"
- "My first Alembic migration was wrong and I had to drop the table"
- "The Ollama timeout I set was too low and the model always errored"

--- WHAT I LEARNED (200–250 words) ---
3–5 real lessons, each 2–3 sentences:
1. CLAUDE.md changes everything — context is the variable
2. Local vs cloud is a real trade-off, not just cost
3. Scoring outputs forces clarity about what you actually want
4. Version history reveals patterns you can't see in the moment

--- CLOSE + NEXT STEPS ---
One paragraph on what you're building next.
Link to the full 14-week program repo.
```

### What to include

- [ ] At least one code snippet (the data model or the async parallel call)
- [ ] One ASCII diagram or screenshot
- [ ] The GitHub repo link
- [ ] A link back to the full ai-mastery repo

### Writing tips

- Write a rough draft first, edit second. Do not edit while writing.
- Use short paragraphs (2–4 sentences max).
- Every section should teach something or reveal something — no filler.

---

## P1-C4: Instagram Carousel

### Goal

A 5–7 slide carousel on "5 things that make a great prompt." Visual, practical, beginner-friendly. This is your most shareable format.

### Slide structure

```
Slide 1 — COVER
  Big text: "5 things that make a great prompt"
  Subtext: "I learned this building a prompt management system"
  Your handle / PathakLabs branding

Slide 2 — Tip 1: CONTEXT IS EVERYTHING
  "The more context you give the model, the less it has to guess.
   Bad: 'Summarise this.'
   Good: 'Summarise this for a non-technical product manager
          in 3 bullet points.'"

Slide 3 — Tip 2: SPECIFY THE FORMAT
  "If you don't say how you want the answer structured,
   you'll get something you have to reformat anyway.
   Add: 'Return as a numbered list.' or 'Use markdown headers.'"

Slide 4 — Tip 3: ONE GOAL PER PROMPT
  "Multi-task prompts get mediocre results on everything.
   Split complex tasks into focused single-goal prompts."

Slide 5 — Tip 4: TEMPERATURE = HOW CREATIVE
  "High temp (0.9) = creative and varied.
   Low temp (0.1) = precise and consistent.
   For code: low. For brainstorming: high."

Slide 6 — Tip 5: TEST ON MULTIPLE MODELS
  "Claude, GPT, and Llama will give different answers.
   What works on one may not work on another.
   Always test your important prompts on at least 2 models."

Slide 7 — CTA
  "I built a tool that does all of this automatically.
   Link in bio → GitHub repo
   Follow for weekly AI engineering posts."
```

### Design tips

- Use a consistent colour palette for all slides (2–3 colours max)
- Big text, minimal words per slide — people swipe fast
- Code examples: use a dark code block background (VS Code screenshot is fine)
- Tools: Canva, Figma, or Adobe Express all work
- Dimensions: 1080x1080 or 1080x1350 (portrait)

### Caption template

```
5 things that make a great prompt 🧠

Swipe through to learn what I discovered after building
a prompt management system from scratch.

I tracked 50+ prompt iterations in 3 weeks.
These patterns showed up every time.

---

Built as part of my 14-week AI Mastery program.
Full code + build logs → link in bio.

#PromptEngineering #AIEngineering #BuildInPublic
#LLM #AITips #PathakLabs
```

---

## Done when

- [ ] Build Log 1 written (end of Week 1)
- [ ] Build Log 2 written (end of Week 2)
- [ ] Build Log 3 written (end of Week 3)
- [ ] LinkedIn post published with GitHub link
- [ ] Blog post published with architecture diagram, code snippet, and GitHub link
- [ ] Instagram carousel posted (5–7 slides)
