# P4-US1: Governance RAG System

> **Goal:** Build a RAG system over EU AI Act, NIST AI RMF, and ISO 42001 that returns cited answers — with every answer pointing to the exact article or section it came from.

**Part of:** [P4-E1: AIGA](p4-e1-aiga.md)
**Weeks:** 5–6
**Labels:** `user-story`, `p4-aiga`

---

## The story

> As a developer or compliance lead, I want to ask plain-English questions about AI regulations and get answers that cite the exact law — so I can understand what my company needs to do without reading 200+ pages of legal text.

---

## What you are building

The EU AI Act is 144 pages. NIST AI RMF is another 60+ pages. ISO 42001 adds more. Nobody reads all of that before shipping an AI product.

This user story builds the core engine of AIGA: a RAG system that has read all those documents for you and can answer questions about them in plain English — always telling you exactly where the answer came from.

The core ideas:

- **Retrieval-Augmented Generation (RAG):** The AI does not answer from memory. It first searches the governance documents for the most relevant sections, then forms an answer from those sections only.
- **Citations are not optional:** Every answer must name the specific article, section, and document. "The EU AI Act requires this" is not acceptable. "EU AI Act, Article 9, paragraph 2 requires this" is.
- **Fully local:** The entire system runs on your homelab via podman compose. No data leaves your network.

---

## What "done" looks like

You type:

```
What does the EU AI Act require for a hiring algorithm?
```

You get back:

```
Hiring algorithms are classified as HIGH RISK AI systems under the EU AI Act.

Required actions:
  1. Conduct a conformity assessment before deployment
  2. Register the system in the EU AI database
  3. Implement meaningful human oversight
  4. Maintain technical documentation for 10 years
  5. Provide transparency to affected job applicants

Sources:
  EU AI Act, Article 6 — Definition of high-risk AI systems
    "...AI systems used in employment, workers management and access to
     self-employment... shall be considered high-risk AI systems..."

  EU AI Act, Annex III, paragraph 4
    "...AI systems intended to be used for recruitment or selection of
     natural persons, in particular for advertising vacancies, screening
     or filtering applications..."

  NIST AI RMF, MAP 5.1
    "...likelihood and magnitude of each identified impact are evaluated
     in the context of the technical task and sociotechnical system..."
```

---

## System overview

```
  Your question
       │
       ▼
┌──────────────────┐
│  Embed question  │  ← turn question into a vector (list of numbers)
└──────────┬───────┘
           │
           ▼
┌──────────────────────────────────────────────────┐
│  ChromaDB (vector store)                         │
│                                                  │
│  EU AI Act chunks:    [0.2, 0.9, 0.1, ...]       │
│  NIST AI RMF chunks:  [0.7, 0.3, 0.5, ...]       │
│  ISO 42001 chunks:    [0.1, 0.8, 0.4, ...]       │
│                                                  │
│  ← find the chunks most similar to your question │
└──────────────────────┬───────────────────────────┘
                       │  top 5 most relevant chunks
                       ▼
         ┌─────────────────────────┐
         │  Ollama (local LLM)     │
         │  "Answer this question  │
         │  using ONLY these       │
         │  chunks. Cite the       │
         │  source for everything."│
         └─────────────┬───────────┘
                       │
                       ▼
              Answer + Citations
```

---

## Acceptance criteria

- [ ] RAG system ingests the EU AI Act full text and chunks it by article
- [ ] RAG system ingests NIST AI RMF and chunks it by section
- [ ] RAG system ingests ISO 42001 overview material
- [ ] Every answer cites the exact article/section/paragraph it came from
- [ ] Source citations include a short quote from the original text (not just the reference)
- [ ] System runs fully locally via podman compose — no external API calls at query time
- [ ] The API returns a structured JSON response with `answer`, `sources[]`, and `risk_level` fields

---

## Tasks in this story

| Task | Description | Week |
|------|-------------|------|
| [P4-T1](p4-t1-collect-documents.md) | Collect and clean governance source documents | 5 |
| [P4-T2](p4-t2-governance-rag.md) | Build RAG pipeline over governance documents | 5–6 |

---

## Why this is the foundation

Everything else in AIGA depends on this story:

```
P4-US1: Governance RAG (this story)
    │
    ├──► P4-T3: Risk Classification Chain
    │         (uses RAG to look up articles for each risk level)
    │
    ├──► P4-T4: Chat Interface
    │         (displays RAG answers with citations)
    │
    ├──► P4-T5: Policy Q&A Mode
    │         (preset questions → RAG → cited answers)
    │
    └──► P4-T6: Risk Assessment Mode
              (user describes system → RAG finds obligations)
```

If the RAG citations are wrong, every feature above is wrong. Build this right first.

---

## Start here

→ [P4-T1: Collect and clean governance source documents](p4-t1-collect-documents.md)
