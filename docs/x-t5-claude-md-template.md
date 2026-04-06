# X-T5: Create Master CLAUDE.md Template

> **Goal:** Create the master briefing file that tells Claude Code exactly what you are building, how you build it, and what mistakes to avoid — so every AI-assisted session is precise instead of generic.

**Part of:** [X-E2: Master CLAUDE.md Template](x-e2-claude-md-template.md)
**Week:** 1
**Labels:** `task`, `learning`

---

## What you are doing

You are creating a file called `CLAUDE.md` in the root of your `ai-mastery` repo. This file is a structured briefing document — like a mission brief you hand to a contractor before they start work. It tells Claude Code your project context, tech stack, constraints, and the mistakes you have already made so it does not repeat them.

You will copy this master template into each project folder and fill it in specifically for that project before starting any coding work.

---

## Why this matters

When you open Claude Code without context, you get generic answers. When you give it a completed CLAUDE.md, you get answers that use your exact tech stack, follow your naming conventions, respect your architecture decisions, and avoid your known failure modes. A good CLAUDE.md is the difference between an AI assistant and an AI collaborator.

**The rule:** You cannot open Claude Code on a project until `CLAUDE.md` is fully filled in. If you cannot fill every section, you do not know what you are building yet. Stop and think before you code.

---

## Prerequisites

Before starting this task, make sure:
- [ ] You are in the `ai-mastery` project root
- [ ] You have read the [X-E2: Master CLAUDE.md Template](x-e2-claude-md-template.md) epic to understand the full context

---

## Step-by-step instructions

### Step 1 — Navigate to your project root

```bash
cd ~/GitHub/ai-mastery
```

---

### Step 2 — Create the master CLAUDE.md file

```bash
touch CLAUDE.md
code CLAUDE.md
```

---

### Step 3 — Paste in the master template

Copy and paste the following into `CLAUDE.md`:

```markdown
# Project: [Name]

## Project Context
[What this is, why it exists — 3 to 5 sentences.
Who uses it? What problem does it solve? Why are you building it?
What does success look like when it is done?]

## Tech Stack
- Language:
- Framework:
- Database:
- AI layer:
- APIs used:
- Deployment:

## Current Task
[UPDATE THIS EVERY SESSION — one sentence saying what you are working on right now.
Example: "Implementing ChromaDB ingestion pipeline for PDF uploads"]

## Architecture Decisions Already Made
[List decisions that are locked in. Claude should NOT re-debate these.
If you do not have any yet, write "None yet" — do not leave blank.]
- e.g. "We use PostgreSQL, not SQLite — do not suggest switching"
- e.g. "API is REST, not GraphQL"

## Constraints
- Performance: [e.g. "API must respond in under 500ms"]
- Cost: [e.g. "Claude API calls must be batched — never called in a loop without a cost check"]
- Style: [e.g. "All Python code uses snake_case — no camelCase"]
- Security: [e.g. "No secrets in code — .env only, never hardcoded"]

## What NOT To Do
[Anti-patterns and failed experiments. Claude should not repeat your mistakes.
Update this whenever you hit a dead end.]
- e.g. "Do not use raw SQL — use SQLAlchemy ORM only"
- e.g. "Do not use setTimeout hacks for async — use proper async/await"

## Output Preferences
- Code style: [e.g. "Concise, no comments unless logic is non-obvious"]
- Test expectations: [e.g. "Write pytest tests for every API endpoint"]
- Comment level: [e.g. "Only comment the WHY, never the WHAT"]
```

Save the file.

---

### Step 4 — Fill in the master template for the ai-mastery repo

Do not leave it blank. Fill it in right now for the overall `ai-mastery` program. Here is a completed example you can adapt:

```markdown
# Project: AI Mastery — PathakLabs

## Project Context
A 14-week self-directed program to build 6 production-grade AI projects while
documenting publicly. The goal is to develop real AI engineering skills —
not tutorials, but actual systems that run on a homelab. Each project
builds skills that stack on the previous one. This repo tracks all 6 projects,
content drafts, and learning notes.

## Tech Stack
- Language: Python (backend), TypeScript/React (frontend where needed)
- Framework: FastAPI
- Database: PostgreSQL (relational), ChromaDB (vector)
- AI layer: Claude API (via Anthropic SDK), Ollama (local inference)
- APIs used: Anthropic, Tavily, Gemini, GitHub
- Deployment: podman compose on homelab

## Current Task
[Week 1] Setting up content system and CLAUDE.md habit.

## Architecture Decisions Already Made
- All services run via podman compose, not Docker — homelab is podman-based
- Ollama runs directly on homelab hardware, not inside a container
- PostgreSQL for relational data, ChromaDB for vectors — do not suggest other vector DBs

## Constraints
- Cost: Track API token usage. Never call Claude in a loop without a token cost estimate.
- Security: All API keys in .env — never hardcoded, never committed to git.
- Style: Python uses snake_case. No magic numbers — use named constants.

## What NOT To Do
- Do not suggest Docker if podman is available — homelab is podman-based
- Do not use synchronous requests in async FastAPI routes

## Output Preferences
- Code style: Explicit types everywhere. No implicit Any in Python.
- Tests: pytest for every API endpoint — no exceptions.
- Comment level: Comment the why, not the what. Short functions need no comments.
```

---

### Step 5 — Set up the per-project CLAUDE.md workflow

When you start Project 1, you will copy this master template into the project folder and fill it in specifically for that project:

```bash
mkdir -p projects/01-promptos
cp CLAUDE.md projects/01-promptos/CLAUDE.md
# Open projects/01-promptos/CLAUDE.md and fill it in for PromptOS specifically
```

The resulting folder structure will look like this:

```
ai-mastery/
├── CLAUDE.md                     ← master template (program-level context)
└── projects/
    ├── 01-promptos/
    │   └── CLAUDE.md             ← P1 specific (copy + fill before starting P1)
    ├── 02-rag-brain/
    │   └── CLAUDE.md             ← P2 specific (copy + fill before starting P2)
    ├── 03-agent-pipeline/
    │   └── CLAUDE.md
    ├── 04-aiga/
    │   └── CLAUDE.md
    ├── 05-pr-review-bot/
    │   └── CLAUDE.md
    └── 06-ai-dashboard/
        └── CLAUDE.md
```

---

### Step 6 — Build the pre-session habit

Before every single coding session, do this in order:

```
[ ] 1. Open projects/XX-name/CLAUDE.md
[ ] 2. Update "Current Task" to what you are doing TODAY
[ ] 3. Add any new failed experiments to "What NOT To Do"
[ ] 4. Add any new locked-in decisions to "Architecture Decisions Already Made"
[ ] 5. Open Claude Code
```

Never skip step 1-4. Claude reads this file fresh each session. Stale context gives stale answers.

---

## Visual overview

```
BEFORE CLAUDE.md                        AFTER CLAUDE.md
────────────────                        ───────────────

You: "add authentication"               You: "add authentication"

Claude: Here's a JWT implementation     Claude: Using your FastAPI stack with
using bcrypt, stored in a users         PostgreSQL, here's an auth endpoint
table. You'll need to choose your       using SQLAlchemy ORM (per your
database and ORM...                     constraints), snake_case naming,
                                        .env for the JWT secret, and
                                        pytest tests for each route.

Generic → precise
Slow    → fast
Wasteful → targeted
```

---

## Learning checkpoint

> Write your answer to this question BEFORE moving on: Open an AI assistant right now and ask it the same coding question twice — once with no context, once after pasting in your filled CLAUDE.md. Write down the difference in your build log.

This is the most important experiment of Week 1.

---

## Done when

- [ ] `CLAUDE.md` exists in the repo root
- [ ] Every section is filled in — no blank sections, no placeholder text left in
- [ ] You understand the pre-session update habit (steps 1-4 in Step 6)
- [ ] You are ready to copy it into `projects/01-promptos/CLAUDE.md` when P1 starts

---

## Next step

-> After this task, you have completed all X-series setup tasks. Review the full picture in [X-US: Cross-Cutting Setup Overview](x-us-cross-cutting.md), then move to Project 1: [P1-E1: PromptOS](p1-e1-promptos.md)
