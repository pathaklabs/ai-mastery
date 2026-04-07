# AI Mastery — PathakLabs

> **14 weeks. 6 production AI projects. Built in public.**

A self-directed program to go from AI user to AI engineer — by building real tools, documenting every session, and sharing the learning publicly.

---

## Program at a glance

```
Week  1   2   3   4   5   6   7   8   9  10  11  12  13  14
      ─────────────────────────────────────────────────────────
X     ██   Cross-cutting setup (CLAUDE.md + content system)
P1    ████████   PromptOS — Prompt Management
P2          ████████████   RAG Brain — Personal Knowledge
P3              ████████████████   5-Agent Pipeline
P4                  ████████   AI Governance Assistant (AIGA)
P5                          ████████████   PR Review Bot
P6                                  ████████████   AI Dashboard
```

---

## Start here — Week 1 Setup

Before writing any project code, complete these 5 tasks in order:

| Step | Doc | What you do |
|------|-----|-------------|
| 1 | [X-E2 Epic: Master CLAUDE.md](docs/x-e2-claude-md-template.md) | Understand why CLAUDE.md changes everything |
| 2 | [X-T5: Create CLAUDE.md template](docs/x-t5-claude-md-template.md) | Create the master template used in every project |
| 3 | [X-E1 Epic: Content System](docs/x-e1-content-system.md) | Understand the build-log → publish pipeline |
| 4 | [X-T1: Build log template](docs/x-t1-build-log-template.md) | Create your session diary template |
| 5 | [X-T2: Content folders](docs/x-t2-content-folders.md) | Create the 4 content folders |
| 6 | [X-T3: LinkedIn template](docs/x-t3-linkedin-template.md) | Create your reusable post template |
| 7 | [X-T4: Blog platform](docs/x-t4-blog-platform.md) | Set up Medium or personal blog |

> See the full cross-cutting overview: [X-US: Cross-cutting setup](docs/x-us-cross-cutting.md)

---

## Project 1 — PromptOS (Weeks 1–3)

**What you build:** Personal prompt management system — store, version, compare, and score prompts across Claude and local Ollama models.

**Stack:** FastAPI · PostgreSQL · React · Claude API · Ollama

📖 **[P1-E1 Epic overview — start here](docs/p1-e1-promptos.md)**

### User Story 1 — Prompt Storage & Versioning (Week 1)
📋 [P1-US1 User story](docs/p1-us1-prompt-storage.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P1-T1 | [FastAPI project setup](docs/p1-t1-fastapi-setup.md) | Project scaffold + podman compose + CLAUDE.md |
| P1-T2 | [Data model](docs/p1-t2-data-model.md) | SQLAlchemy Prompt/PromptVersion models + Alembic migration |
| P1-T3 | [CRUD API endpoints](docs/p1-t3-crud-api.md) | POST/GET prompts, versions, diff endpoint |

### User Story 2 — Multi-Model Testing (Week 2)
📋 [P1-US2 User story](docs/p1-us2-multi-model-testing.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P1-T4 | [React frontend](docs/p1-t4-react-frontend.md) | Prompt list + editor with version history sidebar |
| P1-T5 | [Claude API integration](docs/p1-t5-claude-api.md) | Streaming responses + token/cost logging |
| P1-T6 | [Ollama integration](docs/p1-t6-ollama-integration.md) | Connect to homelab Ollama models |
| P1-T7 | [Comparison UI](docs/p1-t7-comparison-ui.md) | Side-by-side model output view |

### User Story 3 — Output Scoring & Evaluation (Week 3)
📋 [P1-US3 User story](docs/p1-us3-output-scoring.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P1-T8 | [Scoring data model](docs/p1-t8-scoring-model.md) | OutputScore model + API |
| P1-T9 | [Scoring UI](docs/p1-t9-scoring-ui.md) | Rating sliders + annotation field |
| P1-T10 | [Performance dashboard](docs/p1-t10-performance-dashboard.md) | Top prompts, model win rate, score trend charts |

### User Story 4 — Publish P1 Learnings (Week 3)
📋 [P1-US4 Content tasks](docs/p1-us4-content-publish.md)

---

## Project 2 — RAG Brain (Weeks 3–6)

**What you build:** Local RAG system over your own files (Home Assistant YAML, n8n workflows, notes) — with hallucination detection. Runs entirely on your homelab.

**Stack:** Python · LlamaIndex · ChromaDB · Ollama · FastAPI

📖 **[P2-E1 Epic overview — start here](docs/p2-e1-rag-brain.md)**

### User Story 1 — Build the RAG System (Weeks 3–6)
📋 [P2-US1 User story](docs/p2-us1-personal-rag.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P2-T1 | [LlamaIndex + ChromaDB setup](docs/p2-t1-llamaindex-setup.md) | podman compose, ChromaDB, test connection |
| P2-T2 | [Home Assistant YAML loader](docs/p2-t2-ha-yaml-loader.md) | Ingest HA configs with citation metadata |
| P2-T3 | [n8n workflow loader](docs/p2-t3-n8n-loader.md) | Ingest n8n JSON exports, query by workflow name |
| P2-T4 | [Chunking strategies](docs/p2-t4-chunking-strategies.md) | ⭐ 3 strategies compared with 10-question scored experiment |
| P2-T5 | [Embedding model](docs/p2-t5-embedding-model.md) | Local nomic-embed-text via Ollama |
| P2-T6 | [Similarity search](docs/p2-t6-similarity-search.md) | Vector search with relevance score threshold |
| P2-T7 | [Reranking layer](docs/p2-t7-reranking.md) | Cross-encoder rerank + before/after comparison |
| P2-T8 | [Query endpoint](docs/p2-t8-query-endpoint.md) | FastAPI POST /query → answer + cited sources |
| P2-T9 | [Chat UI](docs/p2-t9-chat-ui.md) | Chat interface with collapsible source citations |
| P2-T10 | [Hallucination detection](docs/p2-t10-hallucination-detection.md) | Second LLM call that verifies every answer |

### User Story 4 — Publish P2 Learnings (Week 6)
📋 [P2-US4 Content tasks](docs/p2-us4-content-publish.md)
📝 [P2-C3: Blog post guide](docs/p2-c3-blog-rag-system.md)

---

## Project 3 — 5-Agent Pipeline (Weeks 4–8)

**What you build:** Production multi-agent research pipeline in n8n. 6 agents that research a topic, filter sources, and draft LinkedIn posts sent to Telegram for approval.

**Stack:** n8n · Tavily · Gemini · Claude · DeepSeek · MariaDB

📖 **[P3-E1 Epic overview — start here](docs/p3-e1-agent-pipeline.md)**

### User Story 1 — Architecture Before Code (Week 4)
📋 [P3-US1 User story](docs/p3-us1-pipeline-architecture.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P3-T1 | [Agent contracts](docs/p3-t1-agent-contracts.md) | ⭐ All 6 agent input/output/failure contracts — DO THIS FIRST |
| P3-T2 | [API keys in n8n](docs/p3-t2-api-keys-n8n.md) | Tavily, Gemini, Claude, DeepSeek credentials |
| P3-T3 | [Workflow skeleton](docs/p3-t3-workflow-skeleton.md) | All 6 nodes laid out before any logic |

### Build the Agents (Weeks 5–7)

| Task | Doc | Agent |
|------|-----|-------|
| P3-T4 | [Planner Agent](docs/p3-t4-planner-agent.md) | Topic → search query plan (max 5 queries) |
| P3-T5 | [Search Agent](docs/p3-t5-search-agent.md) | Queries → web results via Tavily (30-day filter) |
| P3-T6 | [Pre-filter Agent](docs/p3-t6-prefilter-agent.md) | Remove old, off-topic, non-English results |
| P3-T7 | [Validator Agent](docs/p3-t7-validator-agent.md) | Score credibility + uniqueness, deduplicate via MariaDB |
| P3-T8 | [Extractor Agent](docs/p3-t8-extractor-agent.md) | Pull key facts, quotes, stats per article |
| P3-T9 | [Synthesizer Agent](docs/p3-t9-synthesizer-agent.md) | Draft LinkedIn post → Telegram for approval |

### Observability & Operations (Weeks 7–8)

| Task | Doc | What you build |
|------|-----|----------------|
| P3-T10 | [Quality logging](docs/p3-t10-quality-logging.md) | Per-agent scores logged to MariaDB |
| P3-T11 | [Run dashboard](docs/p3-t11-run-dashboard.md) | Pipeline run history + per-agent success rates |
| P3-T12 | [Failure runbook](docs/p3-t12-failure-runbook.md) | How to detect, recover, and prevent each failure |

### User Story 5 — Publish P3 Learnings (Week 8)
📋 [P3-US5 Content tasks](docs/p3-us5-content-publish.md)
📝 [P3-C2: LinkedIn architecture post](docs/p3-c2-linkedin-architecture.md)
📝 [P3-C3: Blog post guide](docs/p3-c3-blog-multi-agent.md)

---

## Project 4 — AIGA (Weeks 5–8)

**What you build:** Open-source AI governance assistant. Ask questions about the EU AI Act, NIST AI RMF, and ISO 42001 in plain English — get cited answers and risk classification.

**Stack:** Python · LlamaIndex · ChromaDB · FastAPI · React

📖 **[P4-E1 Epic overview — start here](docs/p4-e1-aiga.md)**

### User Story 1 — Governance RAG (Weeks 5–6)
📋 [P4-US1 User story](docs/p4-us1-governance-rag.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P4-T1 | [Collect documents](docs/p4-t1-collect-documents.md) | Download + clean EU AI Act, NIST, ISO 42001 PDFs |
| P4-T2 | [Governance RAG pipeline](docs/p4-t2-governance-rag.md) | Reuse P2 code — ingest governance docs |
| P4-T3 | [Risk classification chain](docs/p4-t3-risk-classification.md) | Describe AI system → risk level + compliance obligations |
| P4-T4 | [Chat interface](docs/p4-t4-chat-interface.md) | Chat UI with article citations + risk level badges |
| P4-T5 | [Policy Q&A mode](docs/p4-t5-policy-qa-mode.md) | Preset questions for common governance topics |
| P4-T6 | [Risk assessment mode](docs/p4-t6-risk-assessment-mode.md) | Guided form: describe system → get risk assessment |
| P4-T7 | [podman compose deployment](docs/p4-t7-podman-deployment.md) | One-command open-source deploy |

### User Story 3 — Publish AIGA (Week 8)
📋 [P4-US3 Content tasks](docs/p4-us3-content-publish.md)
📝 [P4-C1: Blog post guide](docs/p4-c1-blog-governance.md) ← highest-impact post of the program
📝 [P4-C2: LinkedIn post](docs/p4-c2-linkedin-eu-ai-act.md)
📝 [P4-C4: Publish GitHub repo](docs/p4-c4-publish-repo.md)

---

## Project 5 — PR Review Bot (Weeks 8–12)

**What you build:** GitHub Actions bot that reviews pull requests against your custom engineering standards and posts a structured review comment automatically.

📖 **[P5-E1 Epic overview — start here](docs/p5-e1-pr-review-bot.md)**

### User Story 1 — Build the Bot (Weeks 8–10)
📋 [P5-US1 User story](docs/p5-us1-review-bot.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P5-T1 | [Review rubric](docs/p5-t1-review-rubric.md) | ⭐ Engineering standards as a structured prompt spec |
| P5-T2 | [Review chain](docs/p5-t2-review-chain.md) | 4-step prompt chain (Summarize → Review → JSON → Format) |
| P5-T3 | [Output parser](docs/p5-t3-output-parser.md) | Parse + validate JSON, retry on failure |
| P5-T4 | [GitHub Actions workflow](docs/p5-t4-github-actions.md) | Trigger on PR open/update |
| P5-T5 | [Python script](docs/p5-t5-python-script.md) | Fetch diff → run review → post comment |
| P5-T6 | [Cost guard](docs/p5-t6-cost-guard.md) | Skip review if diff > 500 lines |

### User Story 2 — Eval & Tune (Weeks 10–12)
📋 [P5-US2 User story](docs/p5-us2-eval-quality.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P5-T7 | [Eval on 10 past PRs](docs/p5-t7-eval-past-prs.md) | Precision/recall scoring table |
| P5-T8 | [Tune prompt](docs/p5-t8-tune-prompt.md) | Use PromptOS (P1) to version and test prompt changes |
| P5-T9 | [Open source release](docs/p5-t9-open-source.md) | Configurable review-rules.yml + README |

📝 [P5-C1: Blog post guide](docs/p5-c1-blog-pr-review.md)

---

## Project 6 — AI Dashboard (Weeks 10–14)

**What you build:** Unified monitoring dashboard for all 5 running projects — cost tracking, health cards, content publishing status. Deployed publicly as your portfolio centrepiece.

**Stack:** FastAPI · PostgreSQL · React · Recharts

📖 **[P6-E1 Epic overview — start here](docs/p6-e1-ai-dashboard.md)**

### User Story 1 — Unified Metrics (Weeks 10–12)
📋 [P6-US1 User story](docs/p6-us1-unified-metrics.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P6-T1 | [Metrics schema](docs/p6-t1-metrics-schema.md) | Define what each of the 5 projects will send |
| P6-T2 | [Metrics API](docs/p6-t2-metrics-api.md) | FastAPI POST /events + `track()` client for all projects |
| P6-T3 | [Cost tracking](docs/p6-t3-cost-tracking.md) | Daily spend per project + budget alerts |
| P6-T4 | [React dashboard](docs/p6-t4-react-dashboard.md) | Project health cards with status + sparklines |
| P6-T5 | [Cost charts](docs/p6-t5-cost-charts.md) | Stacked bar, model usage pie, monthly projection |
| P6-T6 | [Content tracker](docs/p6-t6-content-tracker.md) | Publishing progress across all 6 projects |

### User Story 2 — Public Portfolio (Weeks 13–14)
📋 [P6-US2 User story](docs/p6-us2-public-portfolio.md)

| Task | Doc | What you build |
|------|-----|----------------|
| P6-T7 | [Deploy publicly](docs/p6-t7-deploy-public.md) | Live at shailesh-pathak.com |

### Capstone Content (Week 14)
📝 [P6-C1: Capstone blog post](docs/p6-c1-capstone-blog.md) ← your most important piece of content
📝 [P6-C2: LinkedIn retrospective series](docs/p6-c2-linkedin-series.md) ← 6 posts, one per project
📝 [P6-C3: Instagram reel](docs/p6-c3-instagram-reel.md)

---

## Repo structure

```
ai-mastery/
├── README.md                    ← you are here
├── CLAUDE.md                    ← master AI context file (update every session)
├── create-github-issues.sh      ← bulk GitHub issue creator
│
├── projects/
│   ├── 01-promptos/             ← Project 1 source code
│   ├── 02-rag-brain/            ← Project 2 source code
│   ├── 03-pipeline/             ← Project 3 n8n exports + config
│   ├── 04-aiga/                 ← Project 4 source code
│   ├── 05-codereview/           ← Project 5 source code
│   └── 06-dashboard/            ← Project 6 source code
│
├── content/
│   ├── build-logs/              ← session diary, one file per session
│   ├── blog-drafts/             ← blog posts before publishing
│   ├── linkedin/                ← LinkedIn post drafts
│   └── instagram/               ← carousel and reel notes
│
└── docs/                        ← step-by-step guide for every task
    ├── README.md                ← full docs index
    ├── x-e1-content-system.md
    ├── x-e2-claude-md-template.md
    ├── x-t1-build-log-template.md
    ├── x-t2-content-folders.md
    ├── x-t3-linkedin-template.md
    ├── x-t4-blog-platform.md
    ├── x-t5-claude-md-template.md
    ├── x-us-cross-cutting.md
    ├── p1-e1-promptos.md
    ├── p1-us1-prompt-storage.md
    ├── p1-t1-fastapi-setup.md   ... (and 80+ more)
    └── p6-c3-instagram-reel.md
```

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Backend | Python 3.11 · FastAPI · SQLAlchemy · Alembic |
| Frontend | TypeScript · React · Recharts |
| Databases | PostgreSQL · ChromaDB (vector) · MariaDB |
| AI — cloud | Claude API · Gemini · DeepSeek |
| AI — local | Ollama · nomic-embed-text · Llama 3 · Qwen3 14B |
| Automation | n8n (self-hosted on homelab) |
| Infrastructure | podman compose · homelab |
| CI/CD | GitHub Actions |

---

## GitHub Project board

All Epics, User Stories, and Tasks are tracked here:
**→ [pathaklabs/ai-mastery — Project Board](https://github.com/orgs/pathaklabs/projects/4)**

---

## For public learners

Every doc is written so you can follow from scratch without any assumed knowledge. To run this program yourself:

1. Fork this repo
2. Read [docs/x-e2-claude-md-template.md](docs/x-e2-claude-md-template.md) — set up your CLAUDE.md habit
3. Read [docs/x-e1-content-system.md](docs/x-e1-content-system.md) — set up your build log
4. Start [docs/p1-e1-promptos.md](docs/p1-e1-promptos.md) — build Project 1

---

*Built by [Shailesh Pathak](https://shailesh-pathak.com) · [PathakLabs](https://github.com/pathaklabs)*
