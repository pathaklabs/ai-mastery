# AI Mastery — PathakLabs

> **14 weeks. 6 production AI projects. Built in public.**

A self-directed program to go from AI user to AI engineer — by building real tools, documenting every session, and publishing the learning publicly.

---

## What this is

This repo contains 6 AI projects built week-by-week, each one teaching a different layer of the AI engineering stack:

| # | Project | Weeks | What you learn |
|---|---------|-------|---------------|
| P1 | [PromptOS](#project-1--promptos) | 1–3 | Prompt engineering, LLM behaviour, eval |
| P2 | [RAG Brain](#project-2--rag-brain) | 3–6 | RAG, vector databases, embeddings |
| P3 | [5-Agent Pipeline](#project-3--5-agent-pipeline) | 4–8 | Multi-agent orchestration, n8n |
| P4 | [AIGA](#project-4--aiga) | 5–8 | AI governance, EU AI Act, enterprise AI |
| P5 | [PR Review Bot](#project-5--pr-review-bot) | 8–12 | Agentic workflows, structured prompting in prod |
| P6 | [AI Dashboard](#project-6--ai-dashboard) | 10–14 | AI observability, portfolio synthesis |

---

## Program timeline

```
Week  1   2   3   4   5   6   7   8   9  10  11  12  13  14
      ─────────────────────────────────────────────────────────
P1    ████████
P2          ████████████
P3              ████████████████
P4                  ████████
P5                          ████████████
P6                                  ████████████

Build session: every Saturday, 10:00
```

---

## Project 1 — PromptOS

**Personal prompt management system with versioning, multi-model testing, and output scoring.**

- Store prompts with full version history — like git for your prompts
- Run the same prompt on Claude and local Ollama models side-by-side
- Score each output to build intuition for what makes a great prompt
- Dashboard showing which prompts perform best over time

**Stack:** FastAPI · PostgreSQL · React · Claude API · Ollama

📁 [`projects/01-promptos/`](projects/01-promptos/)
📖 [Step-by-step guide](docs/p1-e1-promptos.md)

---

## Project 2 — RAG Brain

**Local RAG system over your own personal files — with hallucination detection.**

- Ingest Home Assistant YAML configs, n8n workflow exports, markdown notes
- Three chunking strategies compared with scored experiments
- Fully local — runs on homelab with Ollama, no cloud APIs needed
- Hallucination detection layer that verifies every answer against its sources

**Stack:** Python · LlamaIndex · ChromaDB · Ollama · FastAPI

📁 [`projects/02-rag-brain/`](projects/02-rag-brain/)
📖 [Step-by-step guide](docs/p2-e1-rag-brain.md)

---

## Project 3 — 5-Agent Pipeline

**Production multi-agent research pipeline in n8n.**

- 6 agents: Planner → Search → Pre-filter → Validator → Extractor → Synthesizer
- Automatically researches topics, filters junk, validates sources, drafts LinkedIn posts
- Sends output to Telegram for human approval before publishing
- Per-agent quality scoring logged to MariaDB

**Stack:** n8n · Tavily · Gemini · Claude · DeepSeek · MariaDB

📁 [`projects/03-pipeline/`](projects/03-pipeline/)
📖 [Step-by-step guide](docs/p3-e1-agent-pipeline.md)

---

## Project 4 — AIGA

**Open-source AI governance assistant.**

- RAG over EU AI Act, NIST AI RMF, and ISO 42001
- Risk classification chain: describe your AI system → get risk level + compliance obligations
- Chat UI with exact article/section citations
- Deployable anywhere with one `podman compose up`

**Stack:** Python · LlamaIndex · ChromaDB · FastAPI · React

📁 [`projects/04-aiga/`](projects/04-aiga/)
📖 [Step-by-step guide](docs/p4-e1-aiga.md)

---

## Project 5 — PR Review Bot

**GitHub Actions bot that reviews PRs against your custom engineering standards.**

- Review rubric defined as a structured prompt spec
- Multi-step chain: Summarize → Review each category → Output JSON → Format as comment
- Posts structured review to every PR automatically
- Eval run on 10 past PRs with precision/recall scoring

📁 [`projects/05-codereview/`](projects/05-codereview/)
📖 [Step-by-step guide](docs/p5-e1-pr-review-bot.md)

---

## Project 6 — AI Dashboard

**Unified monitoring dashboard for all 5 running projects.**

- All projects push metrics to a single API
- Cost tracking per project per day with budget alerts
- React dashboard with project health cards and sparklines
- Content publishing tracker
- Deployed publicly at [shailesh-pathak.com](https://shailesh-pathak.com)

**Stack:** FastAPI · PostgreSQL · React · Recharts

📁 [`projects/06-dashboard/`](projects/06-dashboard/)
📖 [Step-by-step guide](docs/p6-e1-ai-dashboard.md)

---

## Repo structure

```
ai-mastery/
├── README.md                 ← you are here
├── CLAUDE.md                 ← master AI context file
├── create-github-issues.sh   ← bulk GitHub issue creator
│
├── projects/
│   ├── 01-promptos/          ← Project 1 source code
│   ├── 02-rag-brain/         ← Project 2 source code
│   ├── 03-pipeline/          ← Project 3 n8n workflows + config
│   ├── 04-aiga/              ← Project 4 source code
│   ├── 05-codereview/        ← Project 5 source code
│   └── 06-dashboard/         ← Project 6 source code
│
├── content/
│   ├── build-logs/           ← session diary (one file per session)
│   ├── blog-drafts/          ← blog posts before publishing
│   ├── linkedin/             ← LinkedIn post drafts
│   └── instagram/            ← carousel and reel notes
│
└── docs/                     ← step-by-step guides for every task
    ├── README.md             ← full docs index
    ├── p1-e1-promptos.md
    └── ...93 files total
```

---

## Documentation

Every Epic, User Story, and Task has a dedicated step-by-step doc:

- Plain English explanations — no assumed knowledge
- Exact commands and copy-paste code
- ASCII architecture diagrams
- Learning checkpoints to write in your build log

**→ [Browse all docs](docs/README.md)**

---

## GitHub Project

All tasks are tracked on the GitHub Project board:

**→ [pathaklabs/ai-mastery — GitHub Project](https://github.com/orgs/pathaklabs/projects/4)**

Labels used:

| Label | Meaning |
|-------|---------|
| `epic` | Epic-level ticket |
| `user-story` | User story |
| `task` | Concrete implementation task |
| `content` | Content/publishing task |
| `learning` | Learning checkpoint |
| `p1-promptos` through `p6-dashboard` | Project tags |

---

## Tech stack summary

| Layer | Technology |
|-------|-----------|
| Backend | Python 3.11 · FastAPI · SQLAlchemy · Alembic |
| Frontend | TypeScript · React · Recharts |
| Databases | PostgreSQL · ChromaDB (vector) · MariaDB |
| AI — cloud | Claude API (Anthropic) · Gemini · DeepSeek |
| AI — local | Ollama (Qwen3 14B · Llama 3 · nomic-embed-text) |
| Automation | n8n (self-hosted) |
| Infrastructure | podman compose · homelab |
| CI/CD | GitHub Actions |

---

## Build-in-public

Every project is documented as it is built:

- **Build logs** — session notes filled in within 10 minutes of ending each session
- **LinkedIn** — one post per project, written from failure and learning
- **Blog** — architecture + code + honest retrospective per project
- **Instagram** — visual explainers of AI concepts

Follow the journey: [PathakLabs](https://www.linkedin.com/in/shailesh-pathak)

---

## Getting started (for contributors / learners)

If you want to follow this program yourself:

1. Fork this repo
2. Read [`docs/README.md`](docs/README.md) — the full step-by-step index
3. Start with [`docs/x-e2-claude-md-template.md`](docs/x-e2-claude-md-template.md) — set up your CLAUDE.md habit
4. Then [`docs/x-e1-content-system.md`](docs/x-e1-content-system.md) — set up your build log habit
5. Then [`docs/p1-e1-promptos.md`](docs/p1-e1-promptos.md) — start building

Every doc is written so someone following from scratch can complete each task without googling anything basic.

---

*Built by [Shailesh Pathak](https://shailesh-pathak.com) · [PathakLabs](https://github.com/pathaklabs)*
