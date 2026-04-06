# X-E2: Master CLAUDE.md Template

> **Epic goal:** Create the one file that changes how you use AI tools forever — from guessing to directing.

**Week:** 1
**Labels:** `epic`, `learning`

---

## Why this matters

When you open Claude Code (or any AI assistant) without context, you get generic answers. When you give it a structured brief — you get precise, project-aware help.

```
Without CLAUDE.md                 With CLAUDE.md
─────────────────                 ──────────────
You: "add auth"                   You: "add auth"
AI: writes JWT, bcrypt,           AI: uses your exact stack,
    random structure,                 follows your naming rules,
    ignores your DB schema            respects your DB schema
```

The CLAUDE.md file lives in each project folder and is the first thing Claude reads. It is your project briefing document.

**Rule:** You cannot open Claude Code on a project until `CLAUDE.md` is fully filled in. If you cannot fill every section, you do not know what you are building yet.

---

## The master template

Create a file called `CLAUDE.md` in each project folder. Copy this template:

```markdown
# Project: [Name]

## Project Context
[What this is, why it exists — 3 to 5 sentences.
Who uses it? What problem does it solve? Why are you building it?]

## Tech Stack
- Language:
- Framework:
- Database:
- AI layer:
- APIs used:
- Deployment:

## Current Task
[UPDATE THIS EVERY SESSION — one sentence saying what you are working on right now]

## Architecture Decisions Already Made
[List decisions that are locked in. Claude should not re-debate these.]
- e.g. "We use PostgreSQL, not SQLite — do not suggest switching"
- e.g. "API is REST, not GraphQL"

## Constraints
- Performance: [e.g. "API must respond in under 500ms"]
- Cost: [e.g. "Claude API calls must be batched, not per keystroke"]
- Style: [e.g. "All code uses snake_case, no camelCase"]
- Security: [e.g. "No secrets in code — use .env only"]

## What NOT To Do
[Anti-patterns and failed experiments. Claude should not repeat your mistakes.]
- e.g. "Do not use raw SQL — use SQLAlchemy ORM only"
- e.g. "Do not use setTimeout hacks for async — use proper async/await"

## Output Preferences
- Code style: [e.g. "Concise, no comments unless logic is non-obvious"]
- Test expectations: [e.g. "Write pytest tests for every API endpoint"]
- Comment level: [e.g. "Only comment the why, not the what"]
```

---

## Step-by-step instructions

### Step 1 — Create the master template file

In your `ai-mastery` repo root, create:

```
ai-mastery/
├── CLAUDE.md              ← master template (this file)
└── projects/
    ├── 01-promptos/
    │   └── CLAUDE.md      ← copy + fill per project
    ├── 02-rag-brain/
    │   └── CLAUDE.md
    └── ...
```

---

### Step 2 — Fill in the master template right now

Do not leave it blank. Fill in what you know today. Example:

```markdown
# Project: AI Mastery — PathakLabs

## Project Context
A 14-week self-directed program to build 6 production AI projects while
documenting publicly. The goal is to go from AI user to AI engineer.
Each project builds real skills in a real tech stack. This repo tracks
all 6 projects, content, and learning notes.

## Tech Stack
- Language: Python (backend), TypeScript/React (frontend)
- Framework: FastAPI
- Database: PostgreSQL, ChromaDB (vector)
- AI layer: Claude API, Ollama (local)
- APIs used: Anthropic, Tavily, Gemini, GitHub
- Deployment: podman compose on homelab

## Current Task
[Week 1] Setting up content system and CLAUDE.md habit.

## Architecture Decisions Already Made
- All services run via podman compose, not Docker
- Ollama runs on homelab — not in podman compose
- PostgreSQL for relational data, ChromaDB for vector data

## Constraints
- Cost: Track API token usage. Never call Claude in a loop without a cost check.
- Security: All API keys in .env — never hardcoded.

## What NOT To Do
- Do not suggest Docker if podman works — homelab is podman-based.

## Output Preferences
- Code style: snake_case, explicit types, no magic numbers.
- Tests: pytest for every API endpoint.
```

---

### Step 3 — Create a project-specific CLAUDE.md for P1

When you start Project 1 (PromptOS), copy the master template into `projects/01-promptos/CLAUDE.md` and fill it in for that specific project before writing a single line of code.

```bash
mkdir -p projects/01-promptos
cp CLAUDE.md projects/01-promptos/CLAUDE.md
# Now open and fill it in for PromptOS specifically
```

---

## The habit checklist

Before every session:

```
[ ] Open projects/XX-name/CLAUDE.md
[ ] Update "Current Task" to what you are doing TODAY
[ ] Add any new "Architecture Decisions" or "What NOT To Do"
[ ] Then open Claude Code
```

> **Why update every session?** Claude reads this file fresh each time. Stale context gives stale answers.

---

## Done when

- [ ] `CLAUDE.md` master template created in repo root
- [ ] You have filled every section — no blank sections
- [ ] `projects/01-promptos/CLAUDE.md` created and filled before starting P1
- [ ] You have compared AI output quality with vs without CLAUDE.md and noted the difference in your build log
