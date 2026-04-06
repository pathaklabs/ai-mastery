# P1-US2: Multi-Model Testing

> **"As a developer, I want to run the same prompt against multiple models and see outputs side-by-side."**

**Part of:** [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 2
**Labels:** `user-story`, `p1-promptos`

---

## What this user story delivers

When this story is complete, you can select a saved prompt, click "Run on all models," and see the outputs from Claude and at least one local Ollama model displayed side by side in the UI. Each column shows the model output, how many tokens were used, how long it took, and an estimated cost.

---

## Why this story matters

Different models give different outputs for the same prompt. Running them in parallel turns prompt engineering from a feeling into a comparison — you can see, concretely, which model handles your prompt better and whether the cost of the cloud API is justified over running locally.

---

## Acceptance criteria

These are your "definition of done" for the whole story:

- [ ] Claude (claude-sonnet-4-6 or equivalent) is callable from the FastAPI backend
- [ ] At least one local Ollama model (Qwen3 14B, Llama 3, or Mistral) is callable from the backend
- [ ] Both calls happen in parallel (not one after another) and results return together
- [ ] The UI shows outputs in side-by-side columns — one column per model
- [ ] Each column displays: model name, output text, token count, latency in ms, estimated cost
- [ ] Timeouts are handled gracefully — if Ollama is slow or offline, the UI shows an error in that column only

---

## Tasks in this story

| Task ID | Task | Doc |
|---------|------|-----|
| P1-T5 | Integrate Claude API with streaming | [p1-t5-claude-api.md](p1-t5-claude-api.md) |
| P1-T6 | Integrate local Ollama models | [p1-t6-ollama-integration.md](p1-t6-ollama-integration.md) |
| P1-T7 | Build side-by-side model comparison UI | [p1-t7-comparison-ui.md](p1-t7-comparison-ui.md) |

---

## How the tasks fit together

```
                    User submits a prompt from the UI
                                │
                                ▼
                    POST /run  (FastAPI endpoint)
                                │
              ┌─────────────────┴─────────────────┐
              │                                   │
              ▼                                   ▼
        P1-T5: Claude API               P1-T6: Ollama API
        (Anthropic SDK)                 (HTTP to homelab)
        Returns:                        Returns:
          - output text                   - output text
          - input tokens                  - latency ms
          - output tokens                 - model name
          - latency ms                    (no token count
          - cost estimate                  from Ollama)
              │                                   │
              └─────────────────┬─────────────────┘
                                │
                                ▼
               P1-T7: Side-by-side comparison UI
               (parallel columns, one per model)
```

P1-T5 and P1-T6 are independent and can be built in parallel. P1-T7 depends on both.

---

## Learning outcomes

After completing this user story you will understand:

- How to call the Anthropic Claude API and read token usage from the response
- How to call a local Ollama REST API and handle timeouts
- How to run multiple async calls in parallel using `asyncio.gather` in Python
- How to structure a React component that renders dynamic columns based on which models returned results
- The practical cost and latency difference between cloud AI and local AI — from real measurements, not theory

---

## Next step

After this story, move to [P1-US3: Output Scoring](p1-us3-output-scoring.md).
