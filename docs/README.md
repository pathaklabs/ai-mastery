# AI Mastery — PathakLabs Docs

> **Your 14-week guide to building real AI projects, step by step.**
> Every Epic, User Story, and Task has its own detailed doc with instructions, code, and learning checkpoints.

---

## Program Map

```
Week  1   2   3   4   5   6   7   8   9  10  11  12  13  14
      ├───────────────────────────────────────────────────────
X-E1  ████ Content System Setup (always ongoing)
X-E2  ██   Master CLAUDE.md Template
      │
P1    ████████   PromptOS (Prompt Management)
P2          ████████████   RAG Brain (Personal Knowledge)
P3              ████████████████   5-Agent Pipeline
P4                  ████████   AI Governance Assistant
P5                          ████████████   PR Review Bot
P6                                  ████████████   AI Dashboard
```

---

## How to use these docs

1. Open the **Epic** doc for your current project — read the big picture first.
2. Open the **User Story** doc to understand what you are building this sprint.
3. Follow the **Task** docs in order — each has exact steps, code, and a done-when checklist.
4. Every `⚡ Learning checkpoint` is mandatory — write your answer in your build log before moving on.
5. Every `📝 Build log` reminder means: fill in `BUILD_LOG_TEMPLATE.md` right now.

---

## First steps (Week 1, Day 1)

```
Start here
    │
    ├── 1. x-t5-claude-md-template.md  → set up your CLAUDE.md habit
    ├── 2. x-t1-build-log-template.md  → set up your build log habit
    ├── 3. x-t2-content-folders.md     → create the content folder structure
    └── 4. p1-e1-promptos.md           → start building PromptOS
```

---

## Cross-Cutting Setup (Week 1)

### Epics
| ID | Doc | What it is |
|----|-----|-----------|
| X-E1 | [x-e1-content-system.md](x-e1-content-system.md) | Build-log → LinkedIn → Blog → Instagram pipeline |
| X-E2 | [x-e2-claude-md-template.md](x-e2-claude-md-template.md) | Master CLAUDE.md that structures every AI session |

### Overview
| Doc | What it covers |
|-----|---------------|
| [x-us-cross-cutting.md](x-us-cross-cutting.md) | How all 5 setup tasks connect and why they matter |

### Tasks
| ID | Doc | What you do |
|----|-----|------------|
| X-T1 | [x-t1-build-log-template.md](x-t1-build-log-template.md) | Create `BUILD_LOG_TEMPLATE.md` — your session diary |
| X-T2 | [x-t2-content-folders.md](x-t2-content-folders.md) | Create the 4 content folders |
| X-T3 | [x-t3-linkedin-template.md](x-t3-linkedin-template.md) | Create your reusable LinkedIn post template |
| X-T4 | [x-t4-blog-platform.md](x-t4-blog-platform.md) | Set up Medium or personal blog |
| X-T5 | [x-t5-claude-md-template.md](x-t5-claude-md-template.md) | Create the master CLAUDE.md template |

---

## Project 1 — PromptOS (Weeks 1–3)

**What you build:** Personal prompt management system with versioning, multi-model testing, and output scoring.
**Stack:** FastAPI + PostgreSQL + React + Claude API + Ollama

### Epic
| Doc | Summary |
|-----|---------|
| [p1-e1-promptos.md](p1-e1-promptos.md) | Full epic overview, architecture, week-by-week plan |

### User Stories
| ID | Doc | Week | Delivers |
|----|-----|------|---------|
| P1-US1 | [p1-us1-prompt-storage.md](p1-us1-prompt-storage.md) | 1 | Store and version prompts |
| P1-US2 | [p1-us2-multi-model-testing.md](p1-us2-multi-model-testing.md) | 2 | Run same prompt on Claude + Ollama side-by-side |
| P1-US3 | [p1-us3-output-scoring.md](p1-us3-output-scoring.md) | 3 | Score outputs and build evaluation intuition |
| P1-US4 | [p1-us4-content-publish.md](p1-us4-content-publish.md) | 3 | Publish P1 learnings (blog, LinkedIn, Instagram) |

### Tasks
| ID | Doc | Week | What you build |
|----|-----|------|---------------|
| P1-T1 | [p1-t1-fastapi-setup.md](p1-t1-fastapi-setup.md) | 1 | FastAPI project + podman compose + CLAUDE.md |
| P1-T2 | [p1-t2-data-model.md](p1-t2-data-model.md) | 1 | SQLAlchemy models + Alembic migration |
| P1-T3 | [p1-t3-crud-api.md](p1-t3-crud-api.md) | 1 | CRUD API endpoints for prompts |
| P1-T4 | [p1-t4-react-frontend.md](p1-t4-react-frontend.md) | 2 | React prompt list + editor UI |
| P1-T5 | [p1-t5-claude-api.md](p1-t5-claude-api.md) | 2 | Claude API with streaming + token logging |
| P1-T6 | [p1-t6-ollama-integration.md](p1-t6-ollama-integration.md) | 2 | Ollama homelab integration |
| P1-T7 | [p1-t7-comparison-ui.md](p1-t7-comparison-ui.md) | 2 | Side-by-side model comparison UI |
| P1-T8 | [p1-t8-scoring-model.md](p1-t8-scoring-model.md) | 3 | OutputScore data model + API |
| P1-T9 | [p1-t9-scoring-ui.md](p1-t9-scoring-ui.md) | 3 | Rating sliders + annotation UI |
| P1-T10 | [p1-t10-performance-dashboard.md](p1-t10-performance-dashboard.md) | 3 | Prompt performance dashboard |

---

## Project 2 — RAG Brain (Weeks 3–6)

**What you build:** Local RAG system over your own files (Home Assistant YAML, n8n workflows, markdown notes) with hallucination detection.
**Stack:** Python + LlamaIndex + ChromaDB + Ollama + FastAPI

### Epic
| Doc | Summary |
|-----|---------|
| [p2-e1-rag-brain.md](p2-e1-rag-brain.md) | Full epic overview, RAG concepts, week-by-week plan |

### User Stories
| ID | Doc | Week | Delivers |
|----|-----|------|---------|
| P2-US1 | [p2-us1-personal-rag.md](p2-us1-personal-rag.md) | 3–6 | Full local RAG with citations |
| P2-US4 | [p2-us4-content-publish.md](p2-us4-content-publish.md) | 6 | Publish P2 learnings |

### Tasks
| ID | Doc | Week | What you build |
|----|-----|------|---------------|
| P2-T1 | [p2-t1-llamaindex-setup.md](p2-t1-llamaindex-setup.md) | 3 | LlamaIndex + ChromaDB via podman compose |
| P2-T2 | [p2-t2-ha-yaml-loader.md](p2-t2-ha-yaml-loader.md) | 3 | Document loader for Home Assistant YAML |
| P2-T3 | [p2-t3-n8n-loader.md](p2-t3-n8n-loader.md) | 3–4 | Document loader for n8n workflow JSON |
| P2-T4 | [p2-t4-chunking-strategies.md](p2-t4-chunking-strategies.md) | 4 | 3 chunking strategies compared with scored experiment |
| P2-T5 | [p2-t5-embedding-model.md](p2-t5-embedding-model.md) | 4 | Local embedding model via Ollama |
| P2-T6 | [p2-t6-similarity-search.md](p2-t6-similarity-search.md) | 4–5 | Similarity search with score threshold |
| P2-T7 | [p2-t7-reranking.md](p2-t7-reranking.md) | 5 | Reranking layer + before/after comparison |
| P2-T8 | [p2-t8-query-endpoint.md](p2-t8-query-endpoint.md) | 5 | FastAPI query endpoint with source citation |
| P2-T9 | [p2-t9-chat-ui.md](p2-t9-chat-ui.md) | 5 | Simple chat UI with collapsible sources |
| P2-T10 | [p2-t10-hallucination-detection.md](p2-t10-hallucination-detection.md) | 6 | Hallucination detection eval loop |

### Content
| ID | Doc | What you publish |
|----|-----|----------------|
| P2-C3 | [p2-c3-blog-rag-system.md](p2-c3-blog-rag-system.md) | Blog: I built a RAG system on my own files |

---

## Project 3 — 5-Agent Pipeline (Weeks 4–8)

**What you build:** Production multi-agent research pipeline in n8n. 6 agents: Planner → Search → Pre-filter → Validator → Extractor → Synthesizer.
**Stack:** n8n + Tavily + Gemini + Claude + DeepSeek + MariaDB

### Epic
| Doc | Summary |
|-----|---------|
| [p3-e1-agent-pipeline.md](p3-e1-agent-pipeline.md) | Full epic overview, agent contracts concept, week-by-week plan |

### User Stories
| ID | Doc | Week | Delivers |
|----|-----|------|---------|
| P3-US1 | [p3-us1-pipeline-architecture.md](p3-us1-pipeline-architecture.md) | 4 | Full pipeline designed + documented before any code |
| P3-US5 | [p3-us5-content-publish.md](p3-us5-content-publish.md) | 8 | Publish P3 learnings |

### Tasks
| ID | Doc | Week | What you build |
|----|-----|------|---------------|
| P3-T1 | [p3-t1-agent-contracts.md](p3-t1-agent-contracts.md) | 4 | All 6 agent contracts documented (DO NOT skip) |
| P3-T2 | [p3-t2-api-keys-n8n.md](p3-t2-api-keys-n8n.md) | 4 | Tavily, Gemini, DeepSeek API keys in n8n |
| P3-T3 | [p3-t3-workflow-skeleton.md](p3-t3-workflow-skeleton.md) | 4 | n8n workflow skeleton with placeholder nodes |
| P3-T4 | [p3-t4-planner-agent.md](p3-t4-planner-agent.md) | 5 | Planner Agent |
| P3-T5 | [p3-t5-search-agent.md](p3-t5-search-agent.md) | 5 | Search Agent (Tavily) |
| P3-T6 | [p3-t6-prefilter-agent.md](p3-t6-prefilter-agent.md) | 5 | Pre-filter Agent |
| P3-T7 | [p3-t7-validator-agent.md](p3-t7-validator-agent.md) | 6 | Validator Agent with deduplication |
| P3-T8 | [p3-t8-extractor-agent.md](p3-t8-extractor-agent.md) | 6 | Extractor Agent |
| P3-T9 | [p3-t9-synthesizer-agent.md](p3-t9-synthesizer-agent.md) | 7 | Synthesizer Agent → Telegram |
| P3-T10 | [p3-t10-quality-logging.md](p3-t10-quality-logging.md) | 7 | Per-agent quality scoring + MariaDB logging |
| P3-T11 | [p3-t11-run-dashboard.md](p3-t11-run-dashboard.md) | 8 | Pipeline run summary dashboard |
| P3-T12 | [p3-t12-failure-runbook.md](p3-t12-failure-runbook.md) | 8 | Agent failure runbook |

### Content
| ID | Doc | What you publish |
|----|-----|----------------|
| P3-C2 | [p3-c2-linkedin-architecture.md](p3-c2-linkedin-architecture.md) | LinkedIn: 5-agent pipeline with architecture diagram |
| P3-C3 | [p3-c3-blog-multi-agent.md](p3-c3-blog-multi-agent.md) | Blog: Multi-agent orchestration patterns and failures |

---

## Project 4 — AIGA (Weeks 5–8)

**What you build:** Open-source AI governance assistant. RAG over EU AI Act, NIST AI RMF, ISO 42001. Risk classification chain. One-command podman deploy.
**Stack:** Python + LlamaIndex + ChromaDB + FastAPI + React

### Epic
| Doc | Summary |
|-----|---------|
| [p4-e1-aiga.md](p4-e1-aiga.md) | Full epic overview, EU AI Act explainer, week-by-week plan |

### User Stories
| ID | Doc | Week | Delivers |
|----|-----|------|---------|
| P4-US1 | [p4-us1-governance-rag.md](p4-us1-governance-rag.md) | 5–6 | RAG over governance docs with citations |
| P4-US3 | [p4-us3-content-publish.md](p4-us3-content-publish.md) | 8 | Publish AIGA (highest-impact content of the program) |

### Tasks
| ID | Doc | Week | What you build |
|----|-----|------|---------------|
| P4-T1 | [p4-t1-collect-documents.md](p4-t1-collect-documents.md) | 5 | Collect + clean EU AI Act, NIST, ISO docs |
| P4-T2 | [p4-t2-governance-rag.md](p4-t2-governance-rag.md) | 5–6 | RAG pipeline (reuses P2 code) |
| P4-T3 | [p4-t3-risk-classification.md](p4-t3-risk-classification.md) | 6 | EU AI Act risk classification prompt chain |
| P4-T4 | [p4-t4-chat-interface.md](p4-t4-chat-interface.md) | 6–7 | Chat UI with source citation + risk badges |
| P4-T5 | [p4-t5-policy-qa-mode.md](p4-t5-policy-qa-mode.md) | 7 | Preset policy Q&A questions |
| P4-T6 | [p4-t6-risk-assessment-mode.md](p4-t6-risk-assessment-mode.md) | 7 | Guided use case risk assessment form |
| P4-T7 | [p4-t7-podman-deployment.md](p4-t7-podman-deployment.md) | 7–8 | podman compose open-source deployment |

### Content
| ID | Doc | What you publish |
|----|-----|----------------|
| P4-C1 | [p4-c1-blog-governance.md](p4-c1-blog-governance.md) | Blog: How I built an open-source AI governance assistant |
| P4-C2 | [p4-c2-linkedin-eu-ai-act.md](p4-c2-linkedin-eu-ai-act.md) | LinkedIn: The EU AI Act is 144 pages. I built an AI to navigate it. |
| P4-C4 | [p4-c4-publish-repo.md](p4-c4-publish-repo.md) | Publish AIGA GitHub repo with strong README |

---

## Project 5 — PR Review Bot (Weeks 8–12)

**What you build:** GitHub Actions bot that reviews PRs against your custom engineering standards and posts structured review comments automatically.

### Epic
| Doc | Summary |
|-----|---------|
| [p5-e1-pr-review-bot.md](p5-e1-pr-review-bot.md) | Full epic overview, review chain concept, week-by-week plan |

### User Stories
| ID | Doc | Week | Delivers |
|----|-----|------|---------|
| P5-US1 | [p5-us1-review-bot.md](p5-us1-review-bot.md) | 8–10 | Working bot that posts reviews on PRs |
| P5-US2 | [p5-us2-eval-quality.md](p5-us2-eval-quality.md) | 10–12 | Eval + tuning loop using PromptOS |

### Tasks
| ID | Doc | Week | What you build |
|----|-----|------|---------------|
| P5-T1 | [p5-t1-review-rubric.md](p5-t1-review-rubric.md) | 8 | Review rubric as structured prompt spec |
| P5-T2 | [p5-t2-review-chain.md](p5-t2-review-chain.md) | 9 | 4-step multi-prompt review chain |
| P5-T3 | [p5-t3-output-parser.md](p5-t3-output-parser.md) | 9 | JSON output parser + validator |
| P5-T4 | [p5-t4-github-actions.md](p5-t4-github-actions.md) | 9 | GitHub Actions workflow on PR open |
| P5-T5 | [p5-t5-python-script.md](p5-t5-python-script.md) | 10 | Python script: fetch diff → review → post comment |
| P5-T6 | [p5-t6-cost-guard.md](p5-t6-cost-guard.md) | 10 | Cost guard: skip if diff > 500 lines |
| P5-T7 | [p5-t7-eval-past-prs.md](p5-t7-eval-past-prs.md) | 10–11 | Eval on 10 past PRs with scored table |
| P5-T8 | [p5-t8-tune-prompt.md](p5-t8-tune-prompt.md) | 11 | Tune prompt using PromptOS (tools feed each other) |
| P5-T9 | [p5-t9-open-source.md](p5-t9-open-source.md) | 12 | Publish as open source with configurable rules |

### Content
| ID | Doc | What you publish |
|----|-----|----------------|
| P5-C1 | [p5-c1-blog-pr-review.md](p5-c1-blog-pr-review.md) | Blog: I gave Claude my engineering standards and had it review PRs |

---

## Project 6 — AI Dashboard (Weeks 10–14)

**What you build:** Unified monitoring dashboard for all 5 running projects — cost tracking, health cards, content publishing tracker. Deployed publicly as your portfolio centrepiece.
**Stack:** FastAPI + PostgreSQL + React + Recharts

### Epic
| Doc | Summary |
|-----|---------|
| [p6-e1-ai-dashboard.md](p6-e1-ai-dashboard.md) | Full epic overview, metrics architecture, week-by-week plan |

### User Stories
| ID | Doc | Week | Delivers |
|----|-----|------|---------|
| P6-US1 | [p6-us1-unified-metrics.md](p6-us1-unified-metrics.md) | 10–12 | All 5 projects visible in one dashboard |
| P6-US2 | [p6-us2-public-portfolio.md](p6-us2-public-portfolio.md) | 13–14 | Dashboard live at shailesh-pathak.com |

### Tasks
| ID | Doc | Week | What you build |
|----|-----|------|---------------|
| P6-T1 | [p6-t1-metrics-schema.md](p6-t1-metrics-schema.md) | 10 | Metrics schema for all 5 projects |
| P6-T2 | [p6-t2-metrics-api.md](p6-t2-metrics-api.md) | 10–11 | Unified metrics API + `track()` client |
| P6-T3 | [p6-t3-cost-tracking.md](p6-t3-cost-tracking.md) | 11 | Daily cost tracking + alerts |
| P6-T4 | [p6-t4-react-dashboard.md](p6-t4-react-dashboard.md) | 11–12 | React dashboard with project health cards |
| P6-T5 | [p6-t5-cost-charts.md](p6-t5-cost-charts.md) | 12 | Cost breakdown charts (bar, pie, projection) |
| P6-T6 | [p6-t6-content-tracker.md](p6-t6-content-tracker.md) | 12 | Content publishing tracker |
| P6-T7 | [p6-t7-deploy-public.md](p6-t7-deploy-public.md) | 13 | Deploy to shailesh-pathak.com |

### Content
| ID | Doc | What you publish |
|----|-----|----------------|
| P6-C1 | [p6-c1-capstone-blog.md](p6-c1-capstone-blog.md) | Blog: 14 weeks, 6 AI projects — capstone retrospective |
| P6-C2 | [p6-c2-linkedin-series.md](p6-c2-linkedin-series.md) | LinkedIn: 6 retrospective posts, one per project |
| P6-C3 | [p6-c3-instagram-reel.md](p6-c3-instagram-reel.md) | Instagram reel: 14 weeks of AI projects |

---

## Full file count

| Section | Epics | User Stories | Tasks | Content | Total |
|---------|-------|-------------|-------|---------|-------|
| Cross-cutting | 2 | 1 | 5 | — | 8 |
| P1 PromptOS | 1 | 4 | 10 | — | 15 |
| P2 RAG Brain | 1 | 2 | 10 | 1 | 14 |
| P3 5-Agent Pipeline | 1 | 2 | 12 | 2 | 17 |
| P4 AIGA | 1 | 2 | 7 | 3 | 13 |
| P5 PR Review Bot | 1 | 2 | 9 | 1 | 13 |
| P6 AI Dashboard | 1 | 2 | 7 | 3 | 13 |
| **Total** | **8** | **15** | **60** | **10** | **93** |
