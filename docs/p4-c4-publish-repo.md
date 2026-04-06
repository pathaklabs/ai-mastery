# P4-C4: Publish AIGA Repo with Strong README and Screenshots

> **Goal:** Make the AIGA GitHub repository public with a README that is clear enough to get GitHub stars from people who have never heard of the EU AI Act.

**Part of:** [P4-US3: Publish AIGA](p4-us3-content-publish.md)
**Week:** 8
**Labels:** `task`, `p4-aiga`, `content`

---

## What you are doing

A good README is the homepage of your open-source project. The majority of people who land on your repo will decide in 10 seconds whether it is worth their time.

This task makes the repo public-ready:
- Clean, browsable file structure
- README that delivers the "aha" moment in the first screen
- Working quickstart that does what it says
- Screenshots that show the product immediately
- All the "good housekeeping" signals that serious open-source projects have (licence, `.gitignore`, `CONTRIBUTING.md`)

---

## Why this step matters

GitHub stars correlate strongly with discoverability. More stars = higher in search results = more people trying it. A repo with a confusing README gets no stars even if the project is excellent. A repo with a sharp README gets shared.

The README is also the first thing a potential employer or collaborator reads when they click through from your blog post or LinkedIn profile.

---

## Prerequisites

- [ ] All AIGA code is working and tested
- [ ] `podman-compose up` confirmed working from a clean clone
- [ ] Screenshots taken during P4-T4 and P4-T6
- [ ] Blog post (P4-C1) is live (you will link to it)

---

## Step-by-step instructions

### Step 1 — Clean up the repository structure

Before making the repo public, the structure must be clean. Run:

```bash
cd projects/04-aiga

# Check what is in the repo
git status

# Check for secrets — make sure .env is NOT tracked
git ls-files | grep -i "\.env$"   # should return nothing

# Check for large files that should not be committed
find . -size +5M -not -path "./.git/*"
```

Your final directory structure should look like this:

```
aiga/
  api/
    Dockerfile
    requirements.txt
    main.py
    rag/
      __init__.py
      ingest.py
      query.py
      risk_classifier.py
      risk_schema.py
      metadata.py
  frontend/
    Dockerfile
    nginx.conf
    src/
      App.tsx
      components/
        ChatInterface.tsx
        PresetQuestions.tsx
        RiskAssessmentForm.tsx
      config/
        preset-questions.json
      types/
        risk-assessment.ts
  source-docs/
    sample/           ← ships with the repo
    templates/        ← ships with the repo
    raw/              ← in .gitignore (too large)
    cleaned/          ← in .gitignore (too large)
  config/
    preset-questions.json
  screenshots/
    chat-interface.png
    risk-assessment.png
    risk-result.png
  scripts/
    clean_docs.py
    create_samples.py
  podman-compose.yml
  start.sh
  .env.example
  .gitignore
  README.md
  LICENCE
  CONTRIBUTING.md
```

---

### Step 2 — Update `.gitignore`

```
# projects/04-aiga/.gitignore

# Environment variables — never commit these
.env

# Large source documents — only samples ship with the repo
source-docs/raw/
source-docs/cleaned/

# ChromaDB local data
chroma_data/

# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/
*.egg-info/

# Node
node_modules/
frontend/build/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
```

---

### Step 3 — Write the README

This is the most important deliverable in this task. Every line must earn its place.

```markdown
# AIGA — AI Governance Assistant

> Ask questions about the EU AI Act, NIST AI RMF, and ISO 42001 in plain English.
> Get cited answers and classify your AI system's risk level in under a minute.

![AIGA chat interface screenshot](screenshots/chat-interface.png)

---

## What it does

AIGA is an open-source RAG assistant over AI governance documents.
Ask any governance question and get an answer that cites the exact article
or section it came from. Describe your AI system and get a compliance
checklist in seconds.

---

## 5-minute quickstart

**You need:** [Ollama](https://ollama.ai) + [podman-compose](https://github.com/containers/podman-compose)

```bash
git clone https://github.com/PathakLabs/aiga.git
cd aiga
./start.sh
```

Open **http://localhost:3000**

The ingestion step runs automatically on first start. Sample governance documents
are included so the system works immediately without any downloads.

---

## Example

**Policy Q&A:**

> Q: What does the EU AI Act say about hiring algorithms?
>
> A: Hiring algorithms are classified as HIGH RISK under Article 6 and Annex III,
> paragraph 4. Before deployment you must: (1) conduct a conformity assessment,
> (2) register in the EU AI database, (3) implement human oversight,
> (4) maintain technical documentation for 10 years.
>
> Sources:
> - EU AI Act, Article 6 (relevance: 94%)
> - EU AI Act, Annex III, paragraph 4 (relevance: 91%)

**Risk Assessment mode:**

![Risk assessment result screenshot](screenshots/risk-assessment.png)

---

## Documents included

| Document | Source |
|----------|--------|
| EU AI Act (2024) | EUR-Lex (official EU publication) |
| NIST AI Risk Management Framework 1.0 | NIST (US Department of Commerce) |
| ISO 42001 overview | ISO (public portions) |
| Anthropic Claude model card | Anthropic |
| OpenAI GPT-4 system card | OpenAI |
| Sample AI policy templates | Included (fictional, for demo) |

To use the full documents instead of samples, download the PDFs and run:
```bash
python scripts/clean_docs.py
```

---

## Architecture

```
User → React frontend (port 3000)
         │
         ▼ /api/*
     FastAPI backend (port 8000)
         │              │
         ▼              ▼
     ChromaDB      Ollama (local LLM)
     (vector store) llama3 + nomic-embed-text
     (port 8001)
```

Full write-up: [How I Built an Open-Source AI Governance Assistant](blog-url)

---

## Configuration

Copy `.env.example` to `.env` and set your Ollama URL:

```bash
cp .env.example .env
```

If Ollama runs on the same machine: `OLLAMA_URL=http://host-gateway:11434`

If Ollama runs on another machine (e.g. homelab): `OLLAMA_URL=http://192.168.1.50:11434`

---

## Stack

- **LlamaIndex** — RAG pipeline and document indexing
- **ChromaDB** — vector store (runs in a container)
- **Ollama** — local LLM inference (llama3) and embeddings (nomic-embed-text)
- **FastAPI** — REST API
- **React + TypeScript** — frontend
- **podman compose** — deployment

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

---

## Licence

MIT — use it, fork it, build on it.
```

---

### Step 4 — Write CONTRIBUTING.md

```markdown
# Contributing to AIGA

Thank you for your interest in contributing.

## Ways to contribute

- **Add preset questions:** Edit `config/preset-questions.json` — no code required.
- **Add source documents:** Download additional governance documents, clean them,
  and add them to `source-docs/sample/`. Open a PR with the new documents and
  example queries that use them.
- **Improve chunking:** The current chunk size (512 tokens) was chosen by
  experiment. If you find a better strategy for legal documents, open an issue.
- **Improve the risk classifier:** The two-step prompt chain is in
  `api/rag/risk_classifier.py`. Test improvements with the 4-case test suite in
  `test_risk_classifier.py`.
- **Report wrong answers:** If AIGA gives an incorrect or misleading answer,
  open an issue with the question, the answer it gave, and what the correct
  answer should be (with the article reference).

## Development setup

```bash
git clone https://github.com/PathakLabs/aiga.git
cd aiga
cp .env.example .env
# Edit .env with your Ollama URL
podman-compose up --build
```

## Running tests

```bash
cd projects/04-aiga
python test_rag.py                # RAG pipeline
python test_risk_classifier.py    # Risk classification chain
```

## Licence

By contributing, you agree that your contributions are licensed under the MIT Licence.
```

---

### Step 5 — Add a licence

```bash
cat > LICENCE << 'EOF'
MIT License

Copyright (c) 2025 PathakLabs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
```

---

### Step 6 — Take final screenshots

Take these 3 screenshots at `1280x800` resolution (standard laptop width):

1. **`screenshots/chat-interface.png`**
   - Question asked: "What does the EU AI Act say about facial recognition?"
   - Answer visible with at least one source citation showing

2. **`screenshots/risk-assessment.png`**
   - The risk assessment form, filled in with a hiring algorithm description
   - Step 4 (ready to submit)

3. **`screenshots/risk-result.png`**
   - The results screen after submitting a HIGH RISK system
   - Risk badge, reasoning, and obligations all visible

---

### Step 7 — Make the repo public and record the URL

```bash
# On GitHub.com:
# Settings → General → Danger Zone → Change repository visibility → Make public

# Record the URL
echo "https://github.com/PathakLabs/aiga" >> projects/04-aiga/content/links.md
```

---

### Step 8 — The 5-minute test

This is your final quality check. Do this on a machine or directory that has NEVER had AIGA running:

```bash
# In a fresh directory (NOT projects/04-aiga):
cd /tmp
git clone https://github.com/PathakLabs/aiga.git aiga-test
cd aiga-test
./start.sh
# Time this — it must succeed in under 5 minutes
```

If it takes more than 5 minutes or fails, fix the issue before calling this task done. The README promise must be true.

---

## Visual overview

```
GitHub repo landing page (what visitors see):

  PathakLabs/aiga

  "Ask questions about the EU AI Act in plain English.
   Get cited answers and classify your AI system's risk level."

  [screenshot of chat interface]

  5-minute quickstart:
    git clone ...
    ./start.sh
    Open localhost:3000

  Example Q&A with cited output

  Architecture overview

  Contributing + Licence
```

---

## Done when

- [ ] `.gitignore` prevents `.env` and large docs from being committed
- [ ] `git status` is clean (no untracked important files)
- [ ] `./start.sh` works from a fresh clone in under 5 minutes (tested)
- [ ] README has: 2-sentence summary, screenshot, quickstart, example, architecture, contributing, licence
- [ ] `CONTRIBUTING.md` written
- [ ] `LICENCE` file added (MIT)
- [ ] `.env.example` committed
- [ ] 3 screenshots committed to `screenshots/`
- [ ] Repo is public on GitHub
- [ ] Repo URL recorded in `content/links.md`

---

## Next step

→ [P4-C1: Write the blog post](p4-c1-blog-governance.md)
