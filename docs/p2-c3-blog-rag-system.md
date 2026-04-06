# P2-C3: Blog Post — I Built a RAG System on My Own Files

> **Goal:** Write a detailed technical blog post about your P2 experience — including the architecture diagram, chunking experiment results table, and hallucination detection rate — so other developers can learn from your real build.

**Part of:** [P2-US4: Publish P2 Learnings](p2-us4-content-publish.md)
**Week:** 6
**Labels:** `content`, `p2-rag`

---

## What you are publishing

A real technical blog post. Not a tutorial. Not a polished "here's how you do it." A post about what you actually built, what broke, what you measured, and what you learned. Written in your voice.

Target length: 1,500 to 2,500 words.
Target platform: dev.to, your personal site, or Hashnode.

---

## Required sections

Your post MUST include these three elements — they are what make this post unique and valuable:

1. **Architecture diagram** — how all the pieces connect
2. **Chunking experiment results table** — your actual numbers from P2-T4
3. **Hallucination rate before/after detection** — your actual number from P2-T10

Without these three, it is just another RAG tutorial. With them, it is real.

---

## Post outline

Use this as your starting structure. Change anything that does not fit your voice — but keep the three required elements.

---

### Title options (pick one)

- "I Built a RAG System on My Own Homelab Files — Here's What I Learned"
- "RAG from Scratch: What the Tutorials Don't Tell You About Chunking"
- "Local RAG on My Homelab: Failures, Fixes, and Hallucination Rates"
- "I Can Now Ask My Home Assistant Config Questions in Plain English"

---

### Section 1: What I built and why

Write 2-4 paragraphs. Cover:
- What problem you were solving (searching your own homelab files)
- What RAG is in one plain-English sentence
- What documents you ingested (HA YAML, n8n workflows, markdown)
- That everything runs locally — no cloud API

**Example opening:**

> I have hundreds of YAML files across my Home Assistant setup, n8n workflows, and personal notes. Finding anything specific meant grepping or just... remembering where I put it. I built a RAG system so I can ask questions in plain English and get answers with citations.
>
> RAG (Retrieval-Augmented Generation) is simple in concept: take your files, split them into chunks, convert them to numbers (embeddings), store the numbers, and when someone asks a question, find the most similar chunks and feed them to an LLM as context.
>
> Simple in concept. Harder in practice. Here's what I found.

---

### Section 2: Architecture (REQUIRED — include diagram)

Explain what each piece does and how they connect. Include the ASCII diagram from the epic, or draw your own. Be explicit about which tools you chose and why.

**Template diagram to include:**

```
                    INGEST (run once)
Your files                    ChromaDB
┌──────────────┐              ┌────────────────────────┐
│ HA YAML      │  → chunk     │ [0.2, 0.9, 0.1, ...]  │
│ n8n JSON     │  → embed  ──►│ [0.7, 0.3, 0.5, ...]  │
│ Markdown     │              │ [0.1, 0.8, 0.4, ...]  │
└──────────────┘              └────────────────────────┘

                    QUERY (on every question)
Question                      ChromaDB
"Which workflow     embed  ──► find similar vectors
 handles groceries?" ─────────────────────────────►
                              return top-k chunks
                                     │
                              Reranker
                              (re-order by relevance)
                                     │
                              Ollama (llama3)
                              "Answer from context only"
                                     │
                              Answer + sources + hallucination check
```

**Stack table to include:**

| Component | What it does | Tool |
|-----------|-------------|------|
| Document loaders | Read HA YAML, n8n JSON | Python (custom) |
| Chunking | Split documents | LlamaIndex |
| Embedding | Convert text to vectors | Ollama + nomic-embed-text |
| Vector DB | Store and search vectors | ChromaDB |
| Reranking | Re-score by relevance | sentence-transformers |
| LLM | Generate answers | Ollama + llama3 |
| API | Serve queries | FastAPI |
| UI | Chat interface | HTML + vanilla JS |

---

### Section 3: The chunking experiment (REQUIRED — include results table)

This is the most educational part of the post. Explain what chunking is, why it matters, and show your actual results.

**Include this explanation:**

> Chunking is how you split documents before embedding them. I assumed it was a minor implementation detail. I was wrong. It was the single biggest factor in retrieval quality.

**Include your actual results table:**

```markdown
| Question | Strategy A (Fixed 512) | Strategy B (Sentence) | Strategy C (Semantic) |
|----------|:---------------------:|:--------------------:|:--------------------:|
| Q1: ... |          ✓            |          ✓           |          ✓           |
| Q2: ... |          ✗            |          ✓           |          ✓           |
| Q3: ... |          ✗            |          ✗           |          ✓           |
| ...      |          ...          |          ...         |          ...         |
| **Score** |        _/10          |         _/10         |         _/10         |
```

Fill this in from your P2-T4 experiment results.

**Write why your winner won.** This is the most valuable part — your explanation of WHY the winning strategy worked for your specific document types.

---

### Section 4: What broke

Write honestly about at least 3 things that did not work on the first try. Examples:

- The embedding model was not consistent between ingest and query (vectors were incompatible — retrieval returned nothing)
- The score threshold (0.7) was too high — the system kept returning empty results for valid questions
- The reranker took 30 seconds per query because sentence-transformers was downloading the model on every API restart
- A YAML file with nested anchors caused the loader to crash silently
- The hallucination detector called the answer hallucinated when it was actually correct (false positive)

Format: "What broke" → "The error" → "How I fixed it"

---

### Section 5: Hallucination detection (REQUIRED — include your rate)

Explain what hallucination detection is, how you implemented it, and show your actual number.

**Include this explanation:**

> After generating every answer, I make a second LLM call: "Here is the answer. Here are the source documents. Is this answer fully supported by the sources?" The model responds YES or NO with a reason.
>
> This is not a perfect detector — the verifier can be wrong too. But it gives me a measurable baseline.

**Include your actual detection rate:**

> After running [N] queries, my system flagged [X]% as possibly hallucinated.

Then explain what the flagged cases had in common. Were they questions where retrieval failed? Edge cases? Questions about things not in your files?

---

### Section 6: What I would do differently

3-5 bullet points. Honest reflection. Examples:

- Test chunking strategy on Day 1, not Week 4. It affects everything downstream.
- Add JSONL logging from the start. I had no way to replay queries until I added it.
- Use a lower `min_score` threshold (0.5 instead of 0.7) at retrieval time and let the reranker filter.
- Build the hallucination detection eval loop before the UI — it tells you more about system quality than the UI does.

---

### Section 7: Result — what the system can do now

End with what you can actually do now that you could not do before. Be concrete.

**Example:**

> I can now ask in plain English:
> - "Which automation runs when the front door sensor triggers?" → Correct answer with source citation in 3 seconds
> - "Which n8n workflow handles my grocery tracker?" → Correct answer
> - "What entity does the morning coffee automation use?" → Correct answer
>
> The system says "I don't know" for questions not in my files, rather than making something up.
> My hallucination detection baseline is [X]%. That number will guide my next improvement — [next thing you are fixing].

---

## Checklist before publishing

- [ ] Architecture diagram included (ASCII is fine)
- [ ] Chunking experiment results table included with your actual scores
- [ ] Hallucination detection rate included with your actual number
- [ ] At least 2 "what broke" stories with specific errors
- [ ] Honest reflection on what you would do differently
- [ ] Stack table included
- [ ] Cross-linked to GitHub repo or code snippets (optional but valuable)
- [ ] Proofread for clarity — have someone who does not know RAG read the first paragraph

---

## Publishing

When the post is live:
- Share the URL in your build log
- Post on LinkedIn with a 3-sentence summary and the link (this is your P2-C2 content)
- Save the URL somewhere permanent — you will reference this post in future projects

---

## Done when

- [ ] Draft written (all required sections present)
- [ ] Three required elements confirmed: diagram + table + hallucination rate
- [ ] Post published publicly (not a draft)
- [ ] URL saved and shared

---

## Next project

→ [P3-E1: Agent Pipeline](p3-e1-agent-pipeline.md)
