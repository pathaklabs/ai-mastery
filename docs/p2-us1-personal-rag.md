# P2-US1: Personal RAG System

> **Goal:** Build a fully local RAG system over your own files that answers questions in plain English, always shows source citations, and can detect when it is making things up.

**Part of:** [P2-E1: RAG Brain](p2-e1-rag-brain.md)
**Weeks:** 3–6
**Labels:** `user-story`, `p2-rag`

---

## The story

> As a homelab operator, I want to ask questions about my own files — Home Assistant automations, n8n workflows, personal notes — and get accurate answers with citations, so I never have to grep through hundreds of files again.

---

## What you are building

You have hundreds of configuration files spread across your homelab. Right now, finding something specific means grepping, searching, or just remembering where you put it. This project builds an AI assistant that KNOWS your files.

The key ideas:

- **Retrieval-Augmented Generation (RAG):** Instead of asking a general AI, you feed it YOUR files first. The AI only answers from what it has retrieved from your files.
- **Citations:** Every answer must say which file and which section it came from. This is how you catch errors.
- **Hallucination detection:** A second AI call independently checks whether the answer is actually supported by the source material.

---

## What "done" looks like

You type: `Which n8n workflow sends me Telegram alerts?`

You get back:

```
Answer: The "AlertRouter_v2" workflow handles Telegram alerts. It uses a
        webhook trigger and routes to a Telegram Send Message node.

Sources:
  - n8n-exports/alert-router-v2.json  (score: 0.94)
    "...Telegram Send Message node configured with chat_id..."
  - n8n-exports/alert-router-v2.json  (score: 0.87)
    "...trigger: webhook, connected to filter node, then Telegram..."

Hallucination check: PASSED — answer is fully supported by sources.
```

---

## System overview

```
                        YOUR HOMELAB
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│   Your files                  ChromaDB (vector store)         │
│   ┌──────────────┐            ┌────────────────────────────┐  │
│   │ HA YAML      │  ingest    │ [0.2, 0.9, 0.1, ...]  ←── │  │
│   │ n8n JSON     │ ─────────► │ [0.7, 0.3, 0.5, ...]      │  │
│   │ Markdown     │  (once)    │ [0.1, 0.8, 0.4, ...]      │  │
│   └──────────────┘            └────────────────────────────┘  │
│                                          │                     │
│   FastAPI server                         │ similarity search   │
│   ┌──────────────────────────────────────▼──────────────────┐ │
│   │  POST /query                                            │ │
│   │   1. Embed question                                     │ │
│   │   2. Search ChromaDB → top-k chunks                    │ │
│   │   3. Rerank → best chunks                              │ │
│   │   4. Ask Ollama (llama3 or similar) with chunks        │ │
│   │   5. Ask Ollama again → hallucination check            │ │
│   │   6. Return answer + sources + hallucination result    │ │
│   └─────────────────────────────────────────────────────────┘ │
│                                                                │
│   Chat UI (simple HTML/JS or Gradio)                          │
│   ┌─────────────────────────────────────────────────────────┐ │
│   │  [ Your question here... ]  [Ask]                       │ │
│   │                                                         │ │
│   │  Answer: ...                                            │ │
│   │  Sources: ▶ file1.yaml (0.94)  ▶ file2.json (0.87)    │ │
│   └─────────────────────────────────────────────────────────┘ │
│                                                                │
│   Ollama (local LLM inference)                                │
│   ┌─────────────────────────────────────────────────────────┐ │
│   │  llama3 (or mistral, phi3, etc.)                        │ │
│   │  nomic-embed-text (embedding model)                     │ │
│   └─────────────────────────────────────────────────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Tasks in this story

| Task | Description | Week |
|------|-------------|------|
| [P2-T1](p2-t1-llamaindex-setup.md) | Set up LlamaIndex + ChromaDB via podman compose | 3 |
| [P2-T2](p2-t2-ha-yaml-loader.md) | Build document loader for Home Assistant YAML | 3 |
| [P2-T3](p2-t3-n8n-loader.md) | Build document loader for n8n JSON exports | 3–4 |
| [P2-T4](p2-t4-chunking-strategies.md) | Implement and compare 3 chunking strategies | 4 |
| [P2-T5](p2-t5-embedding-model.md) | Set up local embedding model via Ollama | 4 |
| [P2-T6](p2-t6-similarity-search.md) | Implement similarity search with score threshold | 4–5 |
| [P2-T7](p2-t7-reranking.md) | Add reranking layer and compare results | 5 |
| [P2-T8](p2-t8-query-endpoint.md) | Build FastAPI query endpoint with citations | 5 |
| [P2-T9](p2-t9-chat-ui.md) | Build simple chat UI | 5 |
| [P2-T10](p2-t10-hallucination-detection.md) | Add hallucination detection eval loop | 6 |

---

## Acceptance criteria

- [ ] System ingests Home Assistant YAML files with filename preserved as citation metadata
- [ ] System ingests n8n JSON workflow exports with workflow name preserved
- [ ] System ingests personal markdown notes
- [ ] Chunking strategy selected based on a real experiment comparing 3 strategies
- [ ] Embedding model runs locally on Ollama (no cloud API)
- [ ] Query returns answer AND sources — answer without sources is not accepted
- [ ] Hallucination detection runs on every query and logs the result
- [ ] Chat UI shows sources below every answer
- [ ] Everything runs on the homelab with no internet required at query time

---

## Start here

→ [P2-T1: Set up LlamaIndex + ChromaDB](p2-t1-llamaindex-setup.md)
