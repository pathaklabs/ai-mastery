# P6-US1: Unified Metrics for All 5 Projects

> **Goal:** Every project pushes events to a single metrics API, and a single dashboard shows the health of everything in one place.

**Part of:** [P6-E1: PathakLabs AI Monitoring Dashboard](p6-e1-ai-dashboard.md)
**Week:** 10–12
**Labels:** `user-story`, `p6-dashboard`

---

## The story

As a builder running 5 AI projects, I want to see all their health metrics in one dashboard so I can spot problems, track costs, and prove everything is working — without checking 5 separate places.

---

## Why this matters

By Week 10 you have five real systems running. That is impressive — but only if you can see them working. Right now, to check on everything you would need to:

- SSH into your homelab and check PromptOS logs
- Open a different terminal and check the RAG Brain query log
- Check Telegram to see if the Pipeline published anything today
- Open GitHub to see if the PR Review Bot ran
- Check your notes to find what AIGA returned last week

That is exhausting. The unified metrics system replaces all of that with one page.

More importantly: the dashboard is public proof. When someone visits your portfolio and sees live data from 5 real systems, it says more than any CV line ever could.

---

## What gets built

```
┌──────────────────────────────────────────────────────────────┐
│                 PathakLabs AI Dashboard                      │
│                                                              │
│  [PromptOS]  [RAG Brain]  [Pipeline]  [AIGA]  [PR Review]   │
│                                                              │
│  Each card: status / key metric / 7-day sparkline / link     │
│                                                              │
│  [Cost Charts]     [Content Tracker]     [Last updated: now] │
└──────────────────────────────────────────────────────────────┘
         ▲                    ▲
         │                    │
    Reads from           Reads from
    metrics API          same API
         ▲
         │
    ┌────┴─────────────────────────────────────┐
    │  POST /events  (authenticated write)     │
    └──────────────────────────────────────────┘
         ▲    ▲    ▲    ▲    ▲
         │    │    │    │    │
    P1   P2   P3   P4   P5
```

---

## Acceptance criteria

- [ ] Unified metrics API accepts events from all 5 projects
- [ ] Each project has the `track()` client function installed and calling the API
- [ ] Cost is tracked per project per day with a daily alert threshold of €0.50
- [ ] React dashboard shows a health card per project with status indicator, key metric, and 7-day sparkline
- [ ] Dashboard is readable in a browser without any login

---

## Tasks in this user story

| Task | What it does | Week |
|------|-------------|------|
| [P6-T1: Metrics Schema](p6-t1-metrics-schema.md) | Define what each project sends | 10 |
| [P6-T2: Metrics API](p6-t2-metrics-api.md) | Build the FastAPI endpoint + PostgreSQL | 10–11 |
| [P6-T3: Cost Tracking](p6-t3-cost-tracking.md) | Track daily API spend per project | 11 |
| [P6-T4: React Dashboard](p6-t4-react-dashboard.md) | Build the health card UI | 11–12 |
| [P6-T5: Cost Charts](p6-t5-cost-charts.md) | Add spend visualisation | 12 |

---

## Done when

- [ ] All 5 projects are sending events to the metrics API
- [ ] The React dashboard loads and shows live data for all 5 projects
- [ ] Cost totals are visible and updating daily
- [ ] No project can make the dashboard crash — each project's failure is isolated

---

## Next step

→ Start with [P6-T1: Metrics Schema](p6-t1-metrics-schema.md) — write out exactly what each project will send before building anything.
