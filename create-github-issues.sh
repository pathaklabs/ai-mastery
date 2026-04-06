#!/bin/bash
# ============================================================
# pathaklabs/ai-mastery — Bulk Issue Creator
# Prerequisites: gh CLI installed + authenticated
# Usage:
#   chmod +x create-github-issues.sh
#   ./create-github-issues.sh
# ============================================================

REPO="pathaklabs/ai-mastery"

echo ""
echo "============================================"
echo "🏷️  Creating labels..."
echo "============================================"

gh label create "epic"          --color "8B5CF6" --description "Epic level ticket"       --repo $REPO 2>/dev/null || true
gh label create "user-story"    --color "3B82F6" --description "User story"              --repo $REPO 2>/dev/null || true
gh label create "task"          --color "10B981" --description "Concrete task"           --repo $REPO 2>/dev/null || true
gh label create "content"       --color "F59E0B" --description "Content/publishing task" --repo $REPO 2>/dev/null || true
gh label create "blocked"       --color "EF4444" --description "Blocked"                 --repo $REPO 2>/dev/null || true
gh label create "learning"      --color "EC4899" --description "Learning checkpoint"     --repo $REPO 2>/dev/null || true
gh label create "p1-promptos"   --color "6366F1" --description "Project 1: PromptOS"    --repo $REPO 2>/dev/null || true
gh label create "p2-rag"        --color "0EA5E9" --description "Project 2: RAG Brain"   --repo $REPO 2>/dev/null || true
gh label create "p3-pipeline"   --color "14B8A6" --description "Project 3: Pipeline"    --repo $REPO 2>/dev/null || true
gh label create "p4-aiga"       --color "F97316" --description "Project 4: AIGA Public" --repo $REPO 2>/dev/null || true
gh label create "p5-codereview" --color "84CC16" --description "Project 5: Code Review" --repo $REPO 2>/dev/null || true
gh label create "p6-dashboard"  --color "A855F7" --description "Project 6: Dashboard"   --repo $REPO 2>/dev/null || true

echo "✅ Labels done"

# ============================================================
# CROSS-CUTTING SETUP
# ============================================================
echo ""
echo "⚙️  Cross-cutting setup..."

gh issue create --repo $REPO \
  --title "[EPIC] X-E1: Content System Setup" \
  --label "epic,content" \
  --body "## Goal
Establish the build-log → LinkedIn → blog → Instagram publishing pipeline from day 1.
## Week Target: 1
## Tasks
- [ ] X-T1: Create BUILD_LOG_TEMPLATE.md
- [ ] X-T2: Set up content folder structure
- [ ] X-T3: Create LinkedIn post template
- [ ] X-T4: Set up Medium or personal blog"

gh issue create --repo $REPO \
  --title "[TASK] X-T1: Create BUILD_LOG_TEMPLATE.md" \
  --label "task,content" \
  --body "## Week Target: 1
Create \`content/BUILD_LOG_TEMPLATE.md\`:
\`\`\`
# Build Log — [Date]
**Project:**
**Session duration:**
## What I tried
-
## What broke
-
## What I learned
-
## What surprised me
-
## Next session plan
-
\`\`\`
**Rule:** Fill this within 10 min of ending every session."

gh issue create --repo $REPO \
  --title "[TASK] X-T2: Set up content folder structure" \
  --label "task,content" \
  --body "## Week Target: 1
\`\`\`bash
mkdir -p content/build-logs
mkdir -p content/blog-drafts
mkdir -p content/linkedin
mkdir -p content/instagram
\`\`\`"

gh issue create --repo $REPO \
  --title "[TASK] X-T3: Create LinkedIn post template" \
  --label "task,content" \
  --body "## Week Target: 1
Create \`content/linkedin/POST_TEMPLATE.md\`:
\`\`\`
# LinkedIn Post — [Topic] — [Date]
## Hook (1-2 lines)
## The Problem (2-3 lines)
## What I Tried (bullets)
## What Actually Worked
## The Insight (1 punchy line)
## CTA (question to drive comments)
## Hashtags: #AIEngineering #BuildInPublic #PathakLabs
\`\`\`"

gh issue create --repo $REPO \
  --title "[EPIC] X-E2: Master CLAUDE.md Template" \
  --label "epic,learning" \
  --body "## Goal
Create the master CLAUDE.md template used across all 6 projects. This is the single most important habit change from vibe-coding to structured AI-assisted development.
## Week Target: 1"

gh issue create --repo $REPO \
  --title "[TASK] X-T5: Create master CLAUDE.md template" \
  --label "task,learning" \
  --body "## Week Target: 1
\`\`\`markdown
# Project: [Name]
## Project Context
[What this is, why it exists — 3-5 sentences]
## Tech Stack
- Language / Framework / Database / AI layer / APIs / Deployment
## Current Task
[UPDATE THIS EVERY SESSION]
## Architecture Decisions Already Made
[Do NOT re-debate these]
## Constraints
- Performance / Cost / Style / Security
## What NOT To Do
[Anti-patterns, failed experiments]
## Output Preferences
- Code style / Comment level / Test expectations
\`\`\`
**Rule:** Cannot fill every section = you don't know what you're building yet. Don't open Claude Code until complete."

echo "✅ Cross-cutting done"

# ============================================================
# PROJECT 1 — PROMPTOS
# ============================================================
echo ""
echo "📦 Project 1 — PromptOS (Weeks 1-3)..."

gh issue create --repo $REPO \
  --title "[EPIC] P1-E1: Build PromptOS — Personal Prompt Management System" \
  --label "epic,p1-promptos" \
  --body "## Goal
Personal prompt management system with versioning, multi-model testing, and output scoring.
## Week Target: 1–3 | Topic: Prompt Engineering & LLM Behavior
## Stack: FastAPI + PostgreSQL + React + Claude API + Ollama
## Definition of Done
- [ ] Store and version prompts with metadata
- [ ] Run same prompt across 2+ models side-by-side
- [ ] Score outputs with ratings and annotations
- [ ] View prompt performance dashboard"

gh issue create --repo $REPO \
  --title "[USER STORY] P1-US1: Prompt Storage & Versioning" \
  --label "user-story,p1-promptos" \
  --body "## Week Target: 1 | Parent: P1-E1
As a developer I want to store prompts with version history so I can track what changed and why quality shifted.
## Acceptance Criteria
- Prompt has: title, body, version, model target, tags, date
- Can create new version without deleting old
- Can diff between versions"

gh issue create --repo $REPO \
  --title "[TASK] P1-T1: Set up FastAPI project with podman compose" \
  --label "task,p1-promptos" \
  --body "## Week Target: 1 | Parent: P1-US1
- Init FastAPI: /api /models /schemas /db folders
- PostgreSQL via \`podman compose\`
- Create projects/01-promptos/CLAUDE.md from master template
**⚡ Learning:** Write CLAUDE.md fully before opening Claude Code. Compare output quality to previous vibe-coding. Log the difference."

gh issue create --repo $REPO \
  --title "[TASK] P1-T2: Design prompt data model (SQLAlchemy + Alembic)" \
  --label "task,p1-promptos" \
  --body "## Week Target: 1 | Parent: P1-US1
- Models: Prompt, PromptVersion, Tag
- Write Alembic migration
**⚡ Learning:** Write the model as a spec/prompt first. Hand to Claude. Document gap between what you expected and what it generated."

gh issue create --repo $REPO \
  --title "[TASK] P1-T3: Build CRUD API endpoints for prompts" \
  --label "task,p1-promptos" \
  --body "## Week Target: 1 | Parent: P1-US1
- POST /prompts, GET /prompts, GET /prompts/{id}
- POST /prompts/{id}/versions
- GET /prompts/{id}/versions/{v1}/diff/{v2}
- Pydantic schemas for validation"

gh issue create --repo $REPO \
  --title "[TASK] P1-T4: Build React frontend — prompt list and editor" \
  --label "task,p1-promptos" \
  --body "## Week Target: 2 | Parent: P1-US1
- Prompt list with search and tag filter
- Editor with version history sidebar
**⚡ AI Tool Practice:** Try v0.dev or Bolt for initial scaffolding. Document what it got right vs wrong."

gh issue create --repo $REPO \
  --title "[USER STORY] P1-US2: Multi-Model Testing" \
  --label "user-story,p1-promptos" \
  --body "## Week Target: 2 | Parent: P1-E1
As a developer I want to run the same prompt against multiple models and see outputs side-by-side.
## Acceptance Criteria
- Support: Claude + at least one local Ollama model
- Side-by-side output display
- Log latency and token count per model"

gh issue create --repo $REPO \
  --title "[TASK] P1-T5: Integrate Claude API with streaming" \
  --label "task,p1-promptos" \
  --body "## Week Target: 2 | Parent: P1-US2
- Add Anthropic SDK, handle streaming
- API key in .env only
- Log: tokens, latency, model version
**⚡ Learning:** Record actual token count and cost after first real call. Make cost awareness concrete."

gh issue create --repo $REPO \
  --title "[TASK] P1-T6: Integrate local Ollama models" \
  --label "task,p1-promptos" \
  --body "## Week Target: 2 | Parent: P1-US2
- Connect to Ollama on homelab via REST API
- Models: Qwen3 14B, Llama 3, Mistral
- Handle timeouts gracefully
**⚡ Learning:** Measure and document local vs cloud latency. When would you choose each?"

gh issue create --repo $REPO \
  --title "[TASK] P1-T7: Build side-by-side model comparison UI" \
  --label "task,p1-promptos" \
  --body "## Week Target: 2 | Parent: P1-US2
- Parallel columns per model
- Show: output, token count, latency, cost estimate"

gh issue create --repo $REPO \
  --title "[USER STORY] P1-US3: Output Scoring & Evaluation" \
  --label "user-story,p1-promptos" \
  --body "## Week Target: 3 | Parent: P1-E1
As a developer I want to score outputs to build intuition for what makes a good prompt.
## Acceptance Criteria
- Rate 1–5 on: accuracy, format, tone, completeness
- Free-text annotation per output
- Aggregate scores per prompt version"

gh issue create --repo $REPO \
  --title "[TASK] P1-T8: Build scoring data model and API" \
  --label "task,p1-promptos" \
  --body "## Week Target: 3 | Parent: P1-US3
Model: OutputScore — id, prompt_version_id, model, accuracy, format, tone, completeness, annotation, created_at"

gh issue create --repo $REPO \
  --title "[TASK] P1-T9: Add scoring UI to comparison view" \
  --label "task,p1-promptos" \
  --body "## Week Target: 3 | Parent: P1-US3
- Rating slider per dimension
- Text annotation field
- Submit button per model column"

gh issue create --repo $REPO \
  --title "[TASK] P1-T10: Build prompt performance dashboard" \
  --label "task,p1-promptos" \
  --body "## Week Target: 3 | Parent: P1-US3
- Top performing prompt versions
- Model win rate chart
- Score trend over time
**⚡ Learning:** This is your first AI eval system. Answer in your build log: how do you know if an AI output is actually good? This is the hardest open problem in AI."

gh issue create --repo $REPO \
  --title "[USER STORY] P1-US4: Content — Publish P1 Learnings" \
  --label "user-story,content,p1-promptos" \
  --body "## Week Target: 3 | Parent: P1-E1
- [ ] P1-C1: Write 3 build logs during P1
- [ ] P1-C2: LinkedIn — I built prompt version control
- [ ] P1-C3: Blog — What I learned building a prompt management system
- [ ] P1-C4: Instagram carousel — 5 things that make a great prompt"

gh issue create --repo $REPO \
  --title "[TASK] P1-C1: Write 3 build logs during P1" \
  --label "task,content" \
  --body "## Week Target: 1–3
Use BUILD_LOG_TEMPLATE.md after every session. Non-negotiable."

gh issue create --repo $REPO \
  --title "[TASK] P1-C2: LinkedIn — I built prompt version control" \
  --label "task,content" \
  --body "## Week Target: 3
Hook: 'I've been using AI tools for months. Turns out I was doing it completely wrong.'"

gh issue create --repo $REPO \
  --title "[TASK] P1-C3: Blog — What I learned building a prompt management system" \
  --label "task,content" \
  --body "## Week Target: 3
800–1200 words. Architecture diagram + one failure story + GitHub link."

gh issue create --repo $REPO \
  --title "[TASK] P1-C4: Instagram carousel — 5 things that make a great prompt" \
  --label "task,content" \
  --body "## Week Target: 3
7 slides: Hook → Role → Context → Task → Constraints → Format → CTA"

echo "✅ P1 done"

# ============================================================
# PROJECT 2 — RAG BRAIN
# ============================================================
echo ""
echo "📦 Project 2 — RAG Brain (Weeks 3-6)..."

gh issue create --repo $REPO \
  --title "[EPIC] P2-E1: Build Personal RAG System on Your Own Files" \
  --label "epic,p2-rag" \
  --body "## Goal
RAG pipeline over your own personal files. Fully local on homelab with Ollama. Break every layer deliberately to understand it.
## Week Target: 3–6 | Topic: RAG & Knowledge Systems
## Stack: Python + LlamaIndex + ChromaDB + Ollama + FastAPI

## Best Source Documents to Use (you know the ground truth = best for learning)
- Home Assistant YAML configs
- n8n workflow JSON exports
- GroceryTracker / other project READMEs and docs
- Personal markdown notes
- LinkedIn post history (export from LinkedIn Settings → Data Export)

## Definition of Done
- [ ] Ingest 3+ document types
- [ ] 3 chunking strategies compared with scored results
- [ ] Query returns answer + cited sources
- [ ] Hallucination detection layer working"

gh issue create --repo $REPO \
  --title "[TASK] P2-T1: Set up LlamaIndex + ChromaDB via podman compose" \
  --label "task,p2-rag" \
  --body "## Week Target: 3
**⚡ Learning:** Before coding — write your answer to: 'What does a vector DB store vs a relational DB?' Verify after."

gh issue create --repo $REPO \
  --title "[TASK] P2-T2: Build document loader for Home Assistant YAML configs" \
  --label "task,p2-rag" \
  --body "## Week Target: 3
Parse HA YAML, extract automation/entity content, preserve filename as citation metadata."

gh issue create --repo $REPO \
  --title "[TASK] P2-T3: Build document loader for n8n JSON workflow exports" \
  --label "task,p2-rag" \
  --body "## Week Target: 3–4
Extract: workflow name, node names, node descriptions, connections.
Goal: be able to query 'which workflow handles X?'"

gh issue create --repo $REPO \
  --title "[TASK] P2-T4: Implement and compare 3 chunking strategies" \
  --label "task,p2-rag,learning" \
  --body "## Week Target: 4
**Most important learning task in P2.**
- A: Fixed 512 token chunks with 50 token overlap
- B: Sentence-based chunks
- C: Semantic paragraph chunks (split on headings/double newlines)

Pick 10 questions you know the answers to. Run all 10 against all 3 strategies. Score retrieval. Document which won and WHY."

gh issue create --repo $REPO \
  --title "[TASK] P2-T5: Set up local embedding model via Ollama" \
  --label "task,p2-rag" \
  --body "## Week Target: 4
Use nomic-embed-text or mxbai-embed-large.
**⚡ Learning:** What is an embedding? Why does model choice affect retrieval? Write before verifying."

gh issue create --repo $REPO \
  --title "[TASK] P2-T6: Implement similarity search with score threshold" \
  --label "task,p2-rag" \
  --body "## Week Target: 4–5
Vector similarity search against ChromaDB. Min relevance threshold (start 0.7, tune). Return top-k with scores."

gh issue create --repo $REPO \
  --title "[TASK] P2-T7: Add reranking layer and compare results" \
  --label "task,p2-rag,learning" \
  --body "## Week Target: 5
Cross-encoder reranking on top-k results. Compare same 10 test questions with/without.
**⚡ Learning:** Why does retrieval ≠ relevance? Give a concrete example from your own results."

gh issue create --repo $REPO \
  --title "[TASK] P2-T8: Build FastAPI query endpoint with source citation" \
  --label "task,p2-rag" \
  --body "## Week Target: 5
POST /query → { answer, sources: [{ doc, chunk, score }] }
Never return answer without sources. Builds hallucination awareness."

gh issue create --repo $REPO \
  --title "[TASK] P2-T9: Build simple chat UI" \
  --label "task,p2-rag" \
  --body "## Week Target: 5
Chat interface, sources shown below each answer (collapsible), query history sidebar."

gh issue create --repo $REPO \
  --title "[TASK] P2-T10: Add hallucination detection eval loop" \
  --label "task,p2-rag,learning" \
  --body "## Week Target: 6
Second LLM call: 'Is this answer fully supported by these source chunks? YES/NO + reason.'
Log: question, answer, sources, verification result, hallucination_detected bool.
**⚡ Learning:** How often does it catch a hallucination? That rate is your RAG quality baseline."

gh issue create --repo $REPO \
  --title "[USER STORY] P2-US4: Content — Publish P2 Learnings" \
  --label "user-story,content,p2-rag" \
  --body "## Week Target: 6
- [ ] P2-C1: Write 3 build logs during P2
- [ ] P2-C2: LinkedIn — RAG explained from someone who broke it 5 times
- [ ] P2-C3: Blog — I built a RAG system on my own files (architecture + failures)
- [ ] P2-C4: Instagram carousel — What is RAG? (real example)"

gh issue create --repo $REPO \
  --title "[TASK] P2-C3: Blog — I built a RAG system on my own files" \
  --label "task,content" \
  --body "## Week Target: 6
Must include: architecture diagram, chunking experiment results table, hallucination rate before/after detection."

echo "✅ P2 done"

# ============================================================
# PROJECT 3 — 5-AGENT PIPELINE
# ============================================================
echo ""
echo "📦 Project 3 — 5-Agent Pipeline (Weeks 4-8)..."

gh issue create --repo $REPO \
  --title "[EPIC] P3-E1: Build Production Multi-Agent Research Pipeline in n8n" \
  --label "epic,p3-pipeline" \
  --body "## Goal
Planner → Search → Pre-filter → Validator → Extractor → Synthesizer. Full architectural understanding. Every agent has documented contract and quality scoring.
## Week Target: 4–8 | Topic: Agentic Workflows & Multi-agent Systems
## Stack: n8n + Tavily + Gemini + Claude + DeepSeek + MariaDB
## Definition of Done
- [ ] All 6 agent contracts documented before building
- [ ] Full pipeline runs end-to-end
- [ ] Output routes to Telegram for approval
- [ ] Per-agent quality scoring logged to DB"

gh issue create --repo $REPO \
  --title "[TASK] P3-T1: Document all 6 agent contracts before building any node" \
  --label "task,p3-pipeline,learning" \
  --body "## Week Target: 4
**Most important task in P3. Do not skip.**
For each agent: Input schema / Output schema / Failure mode / Fallback behavior.
Agents: Planner, Search, Pre-filter, Validator, Extractor, Synthesizer.
**Architecture before code. Always.**"

gh issue create --repo $REPO \
  --title "[TASK] P3-T2: Set up Tavily, Gemini, DeepSeek API keys in n8n" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 4"

gh issue create --repo $REPO \
  --title "[TASK] P3-T3: Create n8n workflow skeleton with all 6 agent nodes" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 4
Lay out all nodes with placeholder connections. Use sticky notes for agent contracts inline."

gh issue create --repo $REPO \
  --title "[TASK] P3-T4: Build Planner Agent" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 5
Input: topic. Output: JSON { queries: [{ text, priority }] } max 5 queries.
'Message a Model' node. Validate output schema with Code node before passing to Search."

gh issue create --repo $REPO \
  --title "[TASK] P3-T5: Build Search Agent" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 5
Input: query plan. Execute via Tavily HTTP Request node.
Output: { url, title, snippet, published_date, source_domain }. Include 30-day date filter."

gh issue create --repo $REPO \
  --title "[TASK] P3-T6: Build Pre-filter Agent" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 5
Filter OUT: older than 30 days, non-English, below relevance threshold, controversial or airline-demeaning.
Use Code node (not Function node). Log filter reasons."

gh issue create --repo $REPO \
  --title "[TASK] P3-T7: Build Validator Agent with deduplication" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 6
Score: credibility + uniqueness + relevance (0–10 each).
Store URL hashes in MariaDB to prevent repeated content across pipeline runs."

gh issue create --repo $REPO \
  --title "[TASK] P3-T8: Build Extractor Agent" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 6
Output per article: { key_facts[], notable_quote, statistics[], entities[], summary_one_line }"

gh issue create --repo $REPO \
  --title "[TASK] P3-T9: Build Synthesizer Agent" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 7
Input: top 3 validated+extracted articles.
Output: LinkedIn post draft + Instagram caption.
Use Claude (highest quality matters here). Route to Telegram for approval."

gh issue create --repo $REPO \
  --title "[TASK] P3-T10: Add per-agent quality scoring and logging" \
  --label "task,p3-pipeline,learning" \
  --body "## Week Target: 7
Log to MariaDB: agent_name, run_id, timestamp, input_count, output_count, quality_score, failed.
**⚡ Learning:** This is production AI observability. If an agent silently returns bad output, your pipeline is broken. Logging catches it."

gh issue create --repo $REPO \
  --title "[TASK] P3-T11: Build pipeline run summary dashboard" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 8
Last N runs / articles processed / per-agent success rate / posts sent to Telegram."

gh issue create --repo $REPO \
  --title "[TASK] P3-T12: Write agent failure runbook" \
  --label "task,p3-pipeline" \
  --body "## Week Target: 8
For each agent: most likely failure / how to detect / how to recover / how to prevent.
This is production engineering thinking applied to AI systems."

gh issue create --repo $REPO \
  --title "[USER STORY] P3-US5: Content — Publish P3 Learnings" \
  --label "user-story,content,p3-pipeline" \
  --body "## Week Target: 8
- [ ] P3-C1: Write 5 build logs during P3
- [ ] P3-C2: LinkedIn — 5-agent pipeline with architecture diagram
- [ ] P3-C3: Blog — Multi-agent orchestration: patterns, failures, lessons
- [ ] P3-C4: Instagram carousel — What is an AI agent?"

gh issue create --repo $REPO \
  --title "[TASK] P3-C2: LinkedIn — 5-agent pipeline architecture diagram post" \
  --label "task,content" \
  --body "## Week Target: 8
Include actual architecture diagram. Walk through each agent + one mistake made with it. This format (mistake per agent) is highly shareable."

echo "✅ P3 done"

# ============================================================
# PROJECT 4 — AIGA PUBLIC
# ============================================================
echo ""
echo "📦 Project 4 — AIGA Public (Weeks 5-8)..."

gh issue create --repo $REPO \
  --title "[EPIC] P4-E1: Build Open-Source AI Governance Assistant (AIGA)" \
  --label "epic,p4-aiga" \
  --body "## Goal
Deployable open-source AI governance assistant. RAG over EU AI Act, ISO 42001, NIST AI RMF. Risk classification chain. Packaged as podman compose for 5-minute deployment.
## Week Target: 5–8 | Topic: AI Governance & Enterprise AI
## Stack: Python + LlamaIndex + ChromaDB + FastAPI + React
## Definition of Done
- [ ] RAG over EU AI Act, NIST AI RMF, ISO 42001
- [ ] Risk classification chain (4 levels)
- [ ] Chat UI with source citation
- [ ] podman compose deployment
- [ ] GitHub repo with strong README and screenshots"

gh issue create --repo $REPO \
  --title "[TASK] P4-T1: Collect and clean governance source documents" \
  --label "task,p4-aiga" \
  --body "## Week Target: 5
- EU AI Act full text PDF (public)
- NIST AI Risk Management Framework PDF (public)
- ISO 42001 overview (public portions)
- Anthropic + OpenAI model cards (public)
- Create 2–3 anonymised personal AI policy templates"

gh issue create --repo $REPO \
  --title "[TASK] P4-T2: Build RAG pipeline over governance documents" \
  --label "task,p4-aiga" \
  --body "## Week Target: 5–6
Reuse P2 chunking and embedding code directly.
**⚡ Learning:** Notice how P2 transfers here without rebuilding. This is skill compounding — the payoff of doing projects in the right sequence."

gh issue create --repo $REPO \
  --title "[TASK] P4-T3: Build EU AI Act risk classification prompt chain" \
  --label "task,p4-aiga" \
  --body "## Week Target: 6
Input: plain-language AI use case description.
Output: { risk_level, reasoning, relevant_articles[], compliance_obligations[], documentation_required[] }
Multi-step chain — document the chain design before building."

gh issue create --repo $REPO \
  --title "[TASK] P4-T4: Build chat interface with source citation" \
  --label "task,p4-aiga" \
  --body "## Week Target: 6–7
Answer + cited article/section + risk level badge if applicable."

gh issue create --repo $REPO \
  --title "[TASK] P4-T5: Add policy Q&A mode" \
  --label "task,p4-aiga" \
  --body "## Week Target: 7
Preset questions: 'What does the EU AI Act say about facial recognition?' etc."

gh issue create --repo $REPO \
  --title "[TASK] P4-T6: Add use case risk assessment mode" \
  --label "task,p4-aiga" \
  --body "## Week Target: 7
Guided form: describe system → who it affects → what decisions it influences → risk classification + required actions."

gh issue create --repo $REPO \
  --title "[TASK] P4-T7: Package as podman compose for open-source deployment" \
  --label "task,p4-aiga" \
  --body "## Week Target: 7–8
All services in one podman compose file: API + ChromaDB + Frontend.
README with 5-minute setup. Include sample docs so it works out of the box."

gh issue create --repo $REPO \
  --title "[USER STORY] P4-US3: Content — Publish AIGA" \
  --label "user-story,content,p4-aiga" \
  --body "## Week Target: 8
- [ ] P4-C1: Blog — How I built an open-source AI governance assistant
- [ ] P4-C2: LinkedIn — The EU AI Act is 144 pages. I built an AI to navigate it.
- [ ] P4-C3: Instagram — AI Governance: 5 things every tech manager needs to know
- [ ] P4-C4: Publish GitHub repo with README and screenshots"

gh issue create --repo $REPO \
  --title "[TASK] P4-C1: Blog — How I built an open-source AI governance assistant" \
  --label "task,content" \
  --body "## Week Target: 8
**Highest-impact post across all 6 projects.**
Must include: architecture diagram, EU AI Act context, risk classification example with real output, GitHub link.
Target: engineering managers, CTOs, compliance leads in European tech."

gh issue create --repo $REPO \
  --title "[TASK] P4-C4: Publish AIGA repo with strong README and screenshots" \
  --label "task,content" \
  --body "## Week Target: 8
Good README = more GitHub stars = more reach.
Must include: what it does (2 sentences), screenshot, 5-min quickstart, blog link."

echo "✅ P4 done"

# ============================================================
# PROJECT 5 — CODE REVIEW AGENT
# ============================================================
echo ""
echo "📦 Project 5 — Code Review Agent (Weeks 8-12)..."

gh issue create --repo $REPO \
  --title "[EPIC] P5-E1: Build GitHub PR Review Bot with Custom Rules" \
  --label "epic,p5-codereview" \
  --body "## Goal
GitHub Actions bot reviewing PRs against custom rules: naming conventions, architectural patterns, security basics. Posts structured review as PR comment.
## Week Target: 8–12 | Topic: Agentic Workflows + Structured Prompting in Production
## Definition of Done
- [ ] Review rubric as structured prompt spec
- [ ] Multi-step review chain working
- [ ] GitHub Actions triggers on PR open/update
- [ ] Bot posts structured PR review comment
- [ ] Cost guard in place
- [ ] Eval run on 10 past PRs — scored and documented"

gh issue create --repo $REPO \
  --title "[TASK] P5-T1: Define review rubric as structured prompt spec" \
  --label "task,p5-codereview" \
  --body "## Week Target: 8
Categories with: description + good example + bad example + severity (error/warning/info).
**⚡ Learning:** Same prompt spec discipline as P1 — now applied to production code quality. Quality of this spec = quality of every review the bot produces."

gh issue create --repo $REPO \
  --title "[TASK] P5-T2: Build multi-step prompt chain for code review" \
  --label "task,p5-codereview" \
  --body "## Week Target: 9
4 steps: Summarize PR → Analyse each rubric category → Output JSON → Format as GitHub markdown.
**⚡ Learning:** Why does one big prompt fail here? Write the answer before testing. Verify with experiment."

gh issue create --repo $REPO \
  --title "[TASK] P5-T3: Build structured output parser and validator" \
  --label "task,p5-codereview" \
  --body "## Week Target: 9
Parse JSON from review chain. Validate schema — if malformed, retry once, then fallback to plain text."

gh issue create --repo $REPO \
  --title "[TASK] P5-T4: Create GitHub Actions workflow triggered on PR" \
  --label "task,p5-codereview" \
  --body "## Week Target: 9
Trigger: pull_request (opened, synchronize). Steps: checkout diff → run review script → post comment."

gh issue create --repo $REPO \
  --title "[TASK] P5-T5: Build Python script — fetch diff, run chain, post review comment" \
  --label "task,p5-codereview" \
  --body "## Week Target: 10
Fetch PR diff via GitHub API → pass to review chain → parse output → post as GitHub PR review (not just a comment)."

gh issue create --repo $REPO \
  --title "[TASK] P5-T6: Add cost guard — skip if diff over 500 lines" \
  --label "task,p5-codereview" \
  --body "## Week Target: 10
If diff > 500 lines: post 'PR too large for automated review. Please split.' Log cost per review.
**⚡ Learning:** Production AI = cost management is first-class. Build this habit now."

gh issue create --repo $REPO \
  --title "[TASK] P5-T7: Eval — run on 10 past PRs and score review quality" \
  --label "task,p5-codereview,learning" \
  --body "## Week Target: 10–11
Score: true positives / false positives / false negatives / tone.
Document in a table. This is your eval report and your blog content."

gh issue create --repo $REPO \
  --title "[TASK] P5-T8: Tune prompt based on eval results" \
  --label "task,p5-codereview" \
  --body "## Week Target: 11
Use PromptOS (P1) to version and test your prompt changes. Your tools now feed each other."

gh issue create --repo $REPO \
  --title "[TASK] P5-T9: Publish bot as open source with configurable rules file" \
  --label "task,p5-codereview,content" \
  --body "## Week Target: 12
Create review-rules.yml — teams define their own categories. README with setup instructions."

gh issue create --repo $REPO \
  --title "[TASK] P5-C1: Blog — I gave Claude my engineering standards and had it review PRs" \
  --label "task,content" \
  --body "## Week Target: 12
Most compelling angle: show the eval table. What it caught / missed / surprised you / what you changed in the prompt."

echo "✅ P5 done"

# ============================================================
# PROJECT 6 — AI DASHBOARD
# ============================================================
echo ""
echo "📦 Project 6 — AI Dashboard (Weeks 10-14)..."

gh issue create --repo $REPO \
  --title "[EPIC] P6-E1: Build PathakLabs AI Monitoring Dashboard" \
  --label "epic,p6-dashboard" \
  --body "## Goal
Personal dashboard: all 5 running AI projects, costs, model usage, prompt performance, pipeline health, content publishing status. Deploy publicly on shailesh-pathak.com as portfolio centrepiece.
## Week Target: 10–14 | Topic: AI Observability + Portfolio Synthesis
## Definition of Done
- [ ] Unified metrics API — all projects push events here
- [ ] Cost tracking per project per day
- [ ] React dashboard with project health cards
- [ ] Content publishing tracker
- [ ] Deployed on shailesh-pathak.com (public)"

gh issue create --repo $REPO \
  --title "[TASK] P6-T1: Define metrics schema for all 5 projects" \
  --label "task,p6-dashboard" \
  --body "## Week Target: 10
- PromptOS: prompt_runs, avg_score, model_usage
- RAG Brain: queries_per_day, retrieval_quality, hallucination_rate
- Pipeline: runs_per_week, articles_processed, posts_sent_to_approval
- AIGA: queries_per_day, top_topics, risk_assessments_run
- Code Review: prs_reviewed, issues_found, false_positive_rate, cost_per_review"

gh issue create --repo $REPO \
  --title "[TASK] P6-T2: Build unified metrics API" \
  --label "task,p6-dashboard" \
  --body "## Week Target: 10–11
FastAPI: POST /events — all projects push here.
Schema: { project, event_type, value, metadata, timestamp }
Store in PostgreSQL. API key auth."

gh issue create --repo $REPO \
  --title "[TASK] P6-T3: Add API cost tracking per project per day" \
  --label "task,p6-dashboard" \
  --body "## Week Target: 11
Daily spend per project. Alert if over threshold (€0.50/day per project).
This is the 'real numbers' blog post data."

gh issue create --repo $REPO \
  --title "[TASK] P6-T4: Build React dashboard with project health cards" \
  --label "task,p6-dashboard" \
  --body "## Week Target: 11–12
One card per project: status indicator / key metric / 7-day sparkline / GitHub link."

gh issue create --repo $REPO \
  --title "[TASK] P6-T5: Add cost breakdown charts" \
  --label "task,p6-dashboard" \
  --body "## Week Target: 12
Daily cost per project (stacked bar), model usage breakdown (pie), monthly total with projection."

gh issue create --repo $REPO \
  --title "[TASK] P6-T6: Add content publishing tracker" \
  --label "task,p6-dashboard" \
  --body "## Week Target: 12
Per project: build logs written / LinkedIn posts published / blog posts / Instagram carousels.
This holds you accountable to the content system."

gh issue create --repo $REPO \
  --title "[TASK] P6-T7: Deploy dashboard to shailesh-pathak.com" \
  --label "task,p6-dashboard" \
  --body "## Week Target: 13
Public portfolio view. Most powerful thing you can show a potential employer, client, or collaborator."

gh issue create --repo $REPO \
  --title "[TASK] P6-C1: Blog — 14 weeks, 6 AI projects: capstone retrospective" \
  --label "task,content" \
  --body "## Week Target: 14
**Your most important piece of content. Write it carefully.**
2000 words: why you started / one key lesson per project / what you'd do differently / what you can build now that you couldn't / what's next for PathakLabs."

gh issue create --repo $REPO \
  --title "[TASK] P6-C2: LinkedIn series — one retrospective post per project" \
  --label "task,content" \
  --body "## Week Target: 13–14
6 posts, one per project. Each under 300 words with one concrete number or result."

gh issue create --repo $REPO \
  --title "[TASK] P6-C3: Instagram reel — 14 weeks of AI projects, here's the result" \
  --label "task,content" \
  --body "## Week Target: 14
Screen recording walkthrough of the live dashboard. Raw and real builds trust more than polished."

echo ""
echo "============================================"
echo "✅ ALL DONE — pathaklabs/ai-mastery"
echo "============================================"
echo ""
echo "Summary:"
echo "  12 labels created"
echo "  6 project epics"
echo "  All user stories, tasks, content tickets"
echo "  All learning checkpoints embedded"
echo ""
echo "Next steps:"
echo "  1. github.com/pathaklabs/ai-mastery → Projects → New Project"
echo "  2. Name it: AI Mastery — PathakLabs"
echo "  3. Add issues to project"
echo "  4. Add custom fields: Type / Project / Status / Week Target"
echo "  5. Create Board view (group by Status)"
echo "  6. Create Roadmap view (group by Week Target)"
echo ""
echo "First Saturday build session: April 4 at 10:00."
echo "Start with X-T5 (CLAUDE.md template) then P1-T1."
echo "============================================"
