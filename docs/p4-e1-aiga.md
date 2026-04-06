# P4-E1: AIGA — Open-Source AI Governance Assistant

> **Epic goal:** Build a deployable tool that lets anyone ask questions about AI regulations (EU AI Act, NIST, ISO 42001) and get cited, structured answers — then share it as open source.

**Weeks:** 5–8
**Labels:** `epic`, `p4-aiga`
**Stack:** Python + LlamaIndex + ChromaDB + FastAPI + React

---

## Why this project matters

The EU AI Act became law in 2024. ISO 42001 is the new AI management standard. Companies building AI systems must understand their obligations — but the documents are 100+ pages of legal text.

AIGA turns that legal text into an interactive assistant anyone can query.

```
Without AIGA:
  Engineer: "Are we compliant?"
  Lawyer: "Read the 144-page Act."
  Engineer: "..."

With AIGA:
  Engineer: "What does the EU AI Act require for a hiring algorithm?"
  AIGA: "Under Article 6, hiring algorithms are High Risk systems.
         You must: (1) conduct conformity assessment, (2) register in
         EU database, (3) implement human oversight.
         [Source: EU AI Act, Article 6, Annex III, paragraph 4]"
```

---

## What you are building

```
┌─────────────────────────────────────────────────┐
│                 AIGA Interface                  │
│                                                 │
│  [Policy Q&A mode]  [Risk Assessment mode]      │
│  ─────────────────────────────────────────────  │
│                                                 │
│  Ask: "What are the rules for facial           │
│         recognition systems?"                  │
│                                                 │
│  Answer: Facial recognition falls under...     │
│  Risk Level: 🔴 HIGH RISK                       │
│  Sources:                                       │
│   • EU AI Act, Article 5(1)(d)                 │
│   • NIST AI RMF, Govern 1.1                    │
└─────────────────────────────────────────────────┘
```

---

## Definition of done

- [ ] RAG over EU AI Act, NIST AI RMF, and ISO 42001
- [ ] Risk classification chain (4 levels: Unacceptable / High / Limited / Minimal)
- [ ] Chat UI with source citation showing exact article/section
- [ ] podman compose deployment — one command to run the whole system
- [ ] GitHub repo with strong README and screenshots

---

## Week 5 — Collect Documents and Build RAG

### Step 1 — Collect and clean governance source documents (P4-T1)

Download these public documents:

| Document | Where to get it |
|----------|----------------|
| EU AI Act | Official EUR-Lex website — search "EU AI Act 2024 full text PDF" |
| NIST AI Risk Management Framework | nist.gov/artificial-intelligence — free download |
| ISO 42001 overview | iso.org — free public portions |
| Anthropic model card | anthropic.com/model-card |
| OpenAI model card | openai.com/research/gpt-4 |

Store them in `projects/04-aiga/source-docs/`.

Clean them up:
- Remove page headers/footers
- Remove table of contents (it confuses the chunker)
- Save as plain `.txt` files alongside the PDFs

Also create 2–3 simple AI policy templates (fictional company examples):

```markdown
# [Company Name] AI Use Policy — Template

## 1. Purpose
This policy governs the use of AI tools within [Company].

## 2. Prohibited Uses
- Using AI to make final employment decisions without human review
- Using AI-generated content without disclosure to affected parties
...
```

---

### Step 2 — Build RAG pipeline over governance documents (P4-T2)

> **⚡ Skill transfer moment:** You built this in P2 for your personal files. Now you are reusing that code for a different domain.

```python
# This is the same pattern as P2 — different documents, same architecture
from llama_index import VectorStoreIndex, SimpleDirectoryReader
from llama_index.vector_stores.chroma import ChromaVectorStore
import chromadb

# Load documents
documents = SimpleDirectoryReader("source-docs/").load_data()

# Build index (same as P2)
chroma_client = chromadb.HttpClient(host="localhost", port=8001)
collection = chroma_client.get_or_create_collection("aiga_governance")
vector_store = ChromaVectorStore(chroma_collection=collection)
index = VectorStoreIndex.from_documents(documents, vector_store=vector_store)
```

> **⚡ Learning checkpoint:** Notice that you are reusing P2 code here without rebuilding. Write in your build log: what changed between P2 and P4? What stayed the same? This is skill compounding — the payoff of building projects in a deliberate sequence.

---

## Week 6 — Risk Classification Chain

### Step 3 — Build the EU AI Act risk classification prompt chain (P4-T3)

The EU AI Act classifies AI systems into 4 risk levels:

```
UNACCEPTABLE RISK (banned)
  └── Examples: social scoring, real-time biometric surveillance in public
HIGH RISK (regulated, must comply)
  └── Examples: hiring tools, credit scoring, medical diagnosis
LIMITED RISK (transparency requirements)
  └── Examples: chatbots must disclose they are AI
MINIMAL RISK (no requirements)
  └── Examples: spam filters, AI in video games
```

Build a multi-step prompt chain:

**Step 1 of chain — Classify the system:**

```
You are an EU AI Act compliance expert.

User's AI system description:
{{ user_description }}

Based on the EU AI Act, classify this system:
- UNACCEPTABLE_RISK
- HIGH_RISK
- LIMITED_RISK
- MINIMAL_RISK

Return JSON:
{
  "risk_level": "HIGH_RISK",
  "reasoning": "This system affects employment decisions which is listed in Annex III...",
  "relevant_articles": ["Article 6", "Annex III, paragraph 4"]
}
```

**Step 2 of chain — Get compliance obligations:**

```
The system has been classified as {{ risk_level }}.
Relevant articles: {{ relevant_articles }}

What are the specific compliance obligations?

Return JSON:
{
  "compliance_obligations": ["Conduct conformity assessment", "Register in EU database", ...],
  "documentation_required": ["Technical documentation", "Risk management records", ...],
  "human_oversight_required": true
}
```

Document this chain design BEFORE building it. Draw it out first.

---

### Step 4 — Build the chat interface with source citation (P4-T4)

Every answer must include:
1. The answer text
2. A risk level badge if applicable
3. The exact article/section of the law it came from

```
┌──────────────────────────────────────────────┐
│ Q: What does the EU AI Act say about         │
│    emotion recognition in workplaces?        │
├──────────────────────────────────────────────┤
│ A: Emotion recognition systems in workplaces │
│    are classified as HIGH RISK under the     │
│    EU AI Act...                              │
│                                              │
│ Risk Level: 🔴 HIGH RISK                     │
│                                              │
│ Sources:                                     │
│ • EU AI Act, Article 6, Annex III            │
│   "...biometric categorisation systems..."   │
│ • NIST AI RMF, MAP 5.1                      │
│   "...context-specific risk assessment..."  │
└──────────────────────────────────────────────┘
```

---

## Week 7 — Modes and Deployment

### Step 5 — Add Policy Q&A mode (P4-T5)

A set of preset questions that users can click instead of typing:

```
┌─────────────────────────────────────────────┐
│  Quick questions:                           │
│                                             │
│  [What does the EU AI Act say about         │
│   facial recognition?]                     │
│                                             │
│  [What is a "high-risk AI system"?]         │
│                                             │
│  [What documentation do I need for          │
│   a hiring algorithm?]                     │
│                                             │
│  [How does NIST AI RMF define governance?]  │
└─────────────────────────────────────────────┘
```

Store preset questions in a JSON config file so they can be updated without code changes.

---

### Step 6 — Add Use Case Risk Assessment mode (P4-T6)

A guided form that walks someone through describing their AI system:

```
Step 1: Describe your AI system
  "What does it do?" [text field]

Step 2: Who does it affect?
  ○ Employees / job applicants
  ○ Customers / consumers
  ○ Students / children
  ○ General public

Step 3: What decisions does it influence?
  ○ Employment / hiring
  ○ Credit / financial
  ○ Healthcare
  ○ Law enforcement
  ○ Other [text field]

↓

[Assess Risk Level]

Results:
  Risk Level: HIGH RISK
  Required actions:
    1. Conduct conformity assessment
    2. Register in EU AI database
    3. Implement human oversight
    4. Maintain technical documentation
```

---

### Step 7 — Package as podman compose for open-source deployment (P4-T7)

Create `podman-compose.yml` in the root of the AIGA repo:

```yaml
version: "3.9"
services:
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8001:8000"
    volumes:
      - chromadata:/chroma/chroma

  api:
    build: ./api
    ports:
      - "8000:8000"
    depends_on:
      - chromadb
    environment:
      - CHROMA_URL=http://chromadb:8000
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - api

volumes:
  chromadata:
```

Include sample documents in `source-docs/sample/` so the system works out of the box without any additional downloads.

**5-minute setup test:** Ask someone who has never seen the project to follow your README. If they cannot get it running in 5 minutes, the README is not good enough.

---

## Week 8 — Content

| Task | What to do |
|------|-----------|
| P4-C1 | **Highest-impact blog post of the program.** Title: "How I built an open-source AI governance assistant." Must include: architecture diagram, EU AI Act risk level table, a real example of classification with output, GitHub link. Target: engineering managers, CTOs, compliance leads in European tech. |
| P4-C2 | LinkedIn: "The EU AI Act is 144 pages. I built an AI to navigate it." Show one real example of the risk classification output. |
| P4-C3 | Instagram carousel: "AI Governance: 5 things every tech manager needs to know" |
| P4-C4 | Publish GitHub repo. Good README = more stars = more reach. Must include: what it does (2 sentences), screenshot, 5-min quickstart, blog link. |

---

## Full task checklist

### Week 5
- [ ] P4-T1: Collect and clean governance source documents
- [ ] P4-T2: Build RAG pipeline over governance documents (reuse P2 code)

### Week 6
- [ ] P4-T3: Build EU AI Act risk classification prompt chain
- [ ] P4-T4: Build chat interface with source citation

### Week 7
- [ ] P4-T5: Add Policy Q&A mode
- [ ] P4-T6: Add use case risk assessment mode
- [ ] P4-T7: Package as podman compose for open-source deployment

### Week 8
- [ ] P4-C1: Blog post (highest-impact post of the program)
- [ ] P4-C2: LinkedIn post
- [ ] P4-C3: Instagram carousel
- [ ] P4-C4: Publish GitHub repo with strong README and screenshots
