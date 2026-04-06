# P3-T3: Create n8n Workflow Skeleton

> **Goal:** Build the full 6-agent pipeline in n8n as a skeleton — all nodes present, connected, and annotated — before adding any logic.

**Part of:** [P3-US1: Document and Design the Full Pipeline](p3-us1-pipeline-architecture.md)
**Week:** 4
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are creating a new n8n workflow with all 6 agent nodes already laid out and connected. Each node will be a placeholder — it will not have real prompts or logic yet. You will add Sticky Note nodes next to each agent to paste in the contract from P3-T1.

Think of this as building the skeleton of a building before adding walls and wiring.

**n8n concepts you will use:**
- **Workflow:** A canvas where you connect nodes to create automation logic
- **Node:** A single step in the workflow (e.g. "call an API", "run code", "send a message")
- **Sticky Note node:** A yellow note you can place on the canvas — great for inline documentation
- **Manual Trigger:** A button you click to run the workflow manually during development

---

## Why this step matters

Laying out the full skeleton first:
- Forces you to see the whole pipeline before you get lost in one agent
- Lets you verify the node connections make sense end-to-end
- Creates a visual reference you will use throughout weeks 5–8
- The Sticky Notes turn your workflow into living documentation

---

## Prerequisites

- [ ] [P3-T1](p3-t1-agent-contracts.md) complete — all 6 agent contracts written
- [ ] [P3-T2](p3-t2-api-keys-n8n.md) complete — all 4 API credentials added

---

## Step-by-step instructions

### Step 1 — Create a new workflow

1. In n8n, click **+ New Workflow** (top right or from the home screen)
2. Name it: `AI Research Pipeline`
3. Click **Save** (top right)

---

### Step 2 — Add the Manual Trigger node

The first node in every development workflow should be a Manual Trigger. It gives you a button to run the workflow during testing.

1. Click the **+** button to add a node
2. Search for: `Manual Trigger`
3. Add it to the canvas
4. In its settings, no changes needed

Later (when you go to production), you will swap this for a Schedule Trigger or Webhook trigger.

---

### Step 3 — Add the Set node for input

Before the Planner, you need to define the input — the topic to research.

1. Add a **Set** node after the Manual Trigger
2. Name it: `Input — Set Topic`
3. Add a field:
   - **Name:** `topic`
   - **Value:** `AI agents in healthcare 2025` (a test topic for development)
4. Connect Manual Trigger → Set node

This is where you will change the topic when testing.

---

### Step 4 — Add placeholder nodes for all 6 agents

For each agent, add a **"Message a Model"** node. Do not configure any prompts yet — just add and name them.

Add them in order and connect each one to the previous:

| Order | Node type | Name to use |
|-------|-----------|-------------|
| 1 | Message a Model | `Agent 1 — Planner` |
| 2 | Message a Model | `Agent 2 — Search` |
| 3 | Code | `Agent 3 — Pre-filter` |
| 4 | Message a Model | `Agent 4 — Validator` |
| 5 | Message a Model | `Agent 5 — Extractor` |
| 6 | Message a Model | `Agent 6 — Synthesizer` |

How to add each node:
1. Click the **+** icon that appears on the right edge of the previous node
2. Search for the node type
3. Add it
4. Rename it by double-clicking the node name

Connect them in sequence:
```
[Manual Trigger] → [Input — Set Topic] → [Agent 1 — Planner]
    → [Agent 2 — Search] → [Agent 3 — Pre-filter]
    → [Agent 4 — Validator] → [Agent 5 — Extractor]
    → [Agent 6 — Synthesizer]
```

For the "Message a Model" placeholder nodes:
- Set Model to any available model (you will change this later)
- Set Message to: `PLACEHOLDER — not implemented yet`

For the Code placeholder node (Pre-filter):
- In the code field, type: `// PLACEHOLDER — not implemented yet\nreturn $input.all();`

---

### Step 5 — Add a Telegram node at the end

1. Add a **Telegram** node after the Synthesizer
2. Name it: `Telegram — Send for Approval`
3. Do not configure it yet (you will need a Telegram bot token)
4. Set the message field to: `PLACEHOLDER`

---

### Step 6 — Add Sticky Notes for each agent

Sticky Notes are documentation nodes you place on the canvas. They do not affect workflow execution.

For each agent node:
1. Click **+** → search for `Sticky Note`
2. Drag it next to the agent node
3. Paste the agent contract from your `agent-contracts.md` file into the note

Your canvas should now look like this:

```
┌──────────────────────────────────────────────────────────────────────┐
│  n8n Canvas: AI Research Pipeline                                     │
│                                                                       │
│  [Manual   [Input —   [Agent 1 — [Agent 2 — [Agent 3 — [Agent 4 — ] │
│  Trigger]  Set Topic] Planner]   Search]    Pre-filter] Validator]   │
│                          │            │           │          │        │
│                       [Note:      [Note:      [Note:     [Note:      │
│                        Planner     Search      Pre-fil    Validator  │
│                        contract]   contract]   contract]  contract]  │
│                                                                       │
│  [Agent 5 — [Agent 6 —  [Telegram —                                  │
│  Extractor] Synthesizer] Send for Approval]                          │
│      │           │                                                    │
│   [Note:      [Note:                                                  │
│    Extractor   Synthesizer                                            │
│    contract]   contract]                                              │
└──────────────────────────────────────────────────────────────────────┘
```

---

### Step 7 — Save and verify

1. Click **Save** (top right)
2. Click **Execute Workflow** to test the skeleton runs without crashing
3. It will fail or pass — that is fine at this stage. You are just verifying n8n can load and connect the nodes.

---

## Visual overview

```
Input                                                              Output
  │                                                                  │
  ▼                                                                  ▼
[Manual  [Input] [PLANNER] [SEARCH] [PRE-FILTER] [VALIDATOR] [EXTRACTOR] [SYNTHESIZER] [Telegram]
Trigger]
           │         │         │         │            │           │           │
         [Note]   [Note]    [Note]    [Note]       [Note]      [Note]      [Note]
         topic    contract  contract  contract     contract    contract    contract

All nodes connected. No real logic yet.
This is your map before you start the journey.
```

---

## Learning checkpoint

> Write in your build log:
> "Looking at the full skeleton, which agent am I most uncertain about, and what specific question do I need to answer before I build it?"

---

## Done when

- [ ] Workflow named `AI Research Pipeline` exists in n8n
- [ ] All 6 agent nodes are present as placeholders
- [ ] Nodes are connected in the correct sequence
- [ ] Each agent node has a Sticky Note with its contract
- [ ] Telegram node is present at the end
- [ ] Workflow runs (even if it errors on placeholder nodes — that is expected)

---

## Next step

→ [P3-T4: Build Planner Agent](p3-t4-planner-agent.md)
