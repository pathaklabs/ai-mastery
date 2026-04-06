# P1-US3: Output Scoring

> **"As a developer, I want to score outputs to build intuition for what makes a good prompt."**

**Part of:** [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 3
**Labels:** `user-story`, `p1-promptos`

---

## What this user story delivers

When this story is complete, every model output in the comparison view has a scoring panel below it. You rate each output 1–5 on four dimensions (accuracy, format, tone, completeness), write a free-text annotation, and hit Save. A dashboard then aggregates all your scores and shows you which prompt versions perform best and which models win head-to-head.

---

## Why this story matters

Scoring outputs forces you to be precise about what "good" means for a specific prompt. Over weeks and projects, your score history becomes a personal dataset of what makes AI outputs useful — which is the foundation of proper AI evaluation (eval) systems used in production.

---

## Acceptance criteria

These are your "definition of done" for the whole story:

- [ ] Each output can be rated 1–5 on: accuracy, format, tone, and completeness
- [ ] Each output can have a free-text annotation (your notes on why you scored it this way)
- [ ] Scores are saved to the database linked to the prompt version and model name
- [ ] The performance dashboard shows: top-scoring prompt versions, model win rates, and score trends over time
- [ ] Aggregate scores can be queried per prompt version (e.g., "average score for prompt v3 across all models")

---

## Tasks in this story

| Task ID | Task | Doc |
|---------|------|-----|
| P1-T8 | Build scoring data model and API | [p1-t8-scoring-model.md](p1-t8-scoring-model.md) |
| P1-T9 | Add scoring UI to comparison view | [p1-t9-scoring-ui.md](p1-t9-scoring-ui.md) |
| P1-T10 | Build prompt performance dashboard | [p1-t10-performance-dashboard.md](p1-t10-performance-dashboard.md) |

---

## How the tasks fit together

```
P1-T8: Scoring data model + API
  (OutputScore table, POST /scores, GET /scores/aggregate)
          │
          ▼
P1-T9: Scoring UI
  (Rating sliders + annotation field below each model column)
          │
          ▼
P1-T10: Performance dashboard
  (Queries aggregate scores → renders 3 charts)
          │
          ▼
  User Story DONE: score outputs and visualise what works
```

The database and API must exist before you build the UI. The dashboard depends on having real scores in the database, so score at least 5–10 outputs before building the charts.

---

## Learning outcomes

After completing this user story you will understand:

- How to design a relational data model for scores linked to versioned content
- How to write aggregate SQL queries through SQLAlchemy (AVG, GROUP BY, COUNT)
- What a basic AI evaluation rubric looks like and why dimensions matter
- How to build a dashboard from real data — and what the data tells you about your own prompt quality
- Why "what makes a good AI output" is the hardest open problem in AI engineering — and how to form your own informed opinion

---

## Next step

After this story, complete the content tasks in [P1-US4: Content — Publish P1 Learnings](p1-us4-content-publish.md).
