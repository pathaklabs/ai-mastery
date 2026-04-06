# P3-US1: Document and Design the Full 6-Agent Pipeline

> **Goal:** Design the complete 6-agent pipeline architecture — with every agent's contract written — before a single node is built in n8n.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 4
**Labels:** `user-story`, `p3-pipeline`

---

## What this user story covers

This user story is about one principle:

> **Architecture before code. Always.**

Before you touch n8n, you must know exactly what every agent does, what it receives, what it returns, and what happens when it fails.

This is not optional. Systems that skip this step get rebuilt. Systems that do this step get finished.

This user story has three tasks:

| Task | What you do |
|------|-------------|
| [P3-T1](p3-t1-agent-contracts.md) | Write contracts for all 6 agents |
| [P3-T2](p3-t2-api-keys-n8n.md) | Set up API keys in n8n |
| [P3-T3](p3-t3-workflow-skeleton.md) | Build the workflow skeleton in n8n |

---

## The pipeline you are designing

```
You type a topic
      │
      ▼
┌─────────────────────────────────────────────────────┐
│                   n8n Workflow                       │
│                                                      │
│  [1. PLANNER]                                        │
│   Input:  topic (string)                             │
│   Output: list of search queries                     │
│      │                                               │
│      ▼                                               │
│  [2. SEARCH]                                         │
│   Input:  search queries                             │
│   Output: raw articles from the web                  │
│      │                                               │
│      ▼                                               │
│  [3. PRE-FILTER]                                     │
│   Input:  raw articles                               │
│   Output: recent, relevant articles only             │
│      │                                               │
│      ▼                                               │
│  [4. VALIDATOR]                                      │
│   Input:  filtered articles                          │
│   Output: scored + deduplicated articles             │
│      │                                               │
│      ▼                                               │
│  [5. EXTRACTOR]                                      │
│   Input:  validated articles                         │
│   Output: structured facts per article               │
│      │                                               │
│      ▼                                               │
│  [6. SYNTHESIZER]                                    │
│   Input:  top 3 articles with facts                  │
│   Output: LinkedIn post + Instagram caption          │
└─────────────────────────────────────────────────────┘
      │
      ▼
  Telegram → You review → Approve → Post
```

---

## Why architecture-first matters

Imagine building a factory assembly line. You would not start welding machines together before you know what the factory is making.

The same logic applies here. Each agent is a station on the line:
- It needs to know exactly what arrives from the previous station
- It needs to produce output in exactly the format the next station expects
- If it breaks, the line must stop gracefully — not explode

Writing contracts first forces you to answer all of these questions on paper, where fixing mistakes is free.

---

## What is an "agent contract"?

An agent contract is a written agreement — with yourself — covering four things:

```
┌─────────────────────────────────────────────────────┐
│                 AGENT CONTRACT                       │
│                                                      │
│  INPUT SCHEMA   — What does this agent receive?      │
│  OUTPUT SCHEMA  — What does this agent return?       │
│  FAILURE MODES  — What can go wrong?                 │
│  FALLBACK       — What happens if it fails?          │
└─────────────────────────────────────────────────────┘
```

You will write one of these for each of the 6 agents in P3-T1.

---

## Definition of done

- [ ] All 6 agent contracts written (P3-T1 complete)
- [ ] All API credentials added to n8n (P3-T2 complete)
- [ ] Workflow skeleton exists in n8n with all 6 nodes connected (P3-T3 complete)
- [ ] Sticky notes on each node reference the agent contract

---

## Start here

→ [P3-T1: Document All 6 Agent Contracts](p3-t1-agent-contracts.md)
