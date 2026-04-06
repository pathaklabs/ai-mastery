# P6-US2: Deploy the Dashboard as a Public Portfolio

> **Goal:** The dashboard is live on shailesh-pathak.com and anyone in the world can see real metrics from 5 running AI systems.

**Part of:** [P6-E1: PathakLabs AI Monitoring Dashboard](p6-e1-ai-dashboard.md)
**Week:** 13–14
**Labels:** `user-story`, `p6-dashboard`

---

## The story

As a builder who wants to show their work publicly, I want the monitoring dashboard deployed on my personal domain so that potential employers, clients, and collaborators can see real evidence of 5 working AI systems without needing to give them access to anything private.

---

## Why this matters

This is the moment everything comes together. You have spent 14 weeks building. This user story is about making it visible to the world.

Think about it from the perspective of someone who just found your LinkedIn profile:

- Most developers: "I built a RAG chatbot" — and that is it. No proof.
- You: "Here is the live dashboard. These are the metrics from the last 7 days."

That second version ends the conversation differently. It converts attention into trust.

The public view is read-only by design. Anyone can look. Only you (via API key) can write. This is the right security model for a portfolio piece.

---

## What the public sees

```
┌─────────────────────────────────────────────────────────────────┐
│  PathakLabs AI Dashboard           shailesh-pathak.com/labs     │
│  Built in 14 weeks by Shailesh Pathak                           │
│  Last updated: 2 minutes ago                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────┐  ┌──────┐ │
│  │ PromptOS │  │RAG Brain │  │Pipeline  │  │ AIGA │  │ PRs  │ │
│  │  🟢 Live │  │  🟢 Live │  │  🟢 Live │  │ 🟢   │  │ 🟢   │ │
│  │          │  │          │  │          │  │      │  │      │ │
│  │ 47 saved │  │ 23 today │  │ Ran 2h   │  │ 8/d  │  │ 5/wk │ │
│  │ ▁▂▃▄▅▆▇█ │  │ ▁▁▂▃▃▄▅▇ │  │ ▁▂▁▃▂▄▁▂ │  │▃▄▃▄▅ │  │▂▂▃▃▄ │ │
│  │[GitHub↗] │  │[GitHub↗] │  │[GitHub↗] │  │[↗]   │  │[↗]   │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────┘  └──────┘ │
│                                                                  │
│  Cost today: €0.34   This month: €8.12   Budget: €15/mo         │
│                                                                  │
│  Content: 12 build logs  6 LinkedIn posts  3 blogs  2 carousels │
└─────────────────────────────────────────────────────────────────┘
```

---

## Acceptance criteria

- [ ] Dashboard deployed and accessible at shailesh-pathak.com (or a subdomain)
- [ ] Public view is read-only — visitors can see everything, change nothing
- [ ] Content publishing tracker shows progress across all 6 projects
- [ ] Page loads in under 3 seconds on a standard connection
- [ ] URL is shareable (no login, no redirect, no paywall)

---

## Tasks in this user story

| Task | What it does | Week |
|------|-------------|------|
| [P6-T6: Content Tracker](p6-t6-content-tracker.md) | Add publishing progress panel | 12 |
| [P6-T7: Deploy Publicly](p6-t7-deploy-public.md) | Get it live on your domain | 13 |
| [P6-C1: Capstone Blog](p6-c1-capstone-blog.md) | Write the 14-week retrospective | 14 |
| [P6-C2: LinkedIn Series](p6-c2-linkedin-series.md) | 6 retrospective posts | 13–14 |
| [P6-C3: Instagram Reel](p6-c3-instagram-reel.md) | Screen recording walkthrough | 14 |

---

## Done when

- [ ] A stranger can open the URL and see live data from all 5 projects
- [ ] The content tracker shows your publishing history
- [ ] You have shared the link on LinkedIn at least once
- [ ] The capstone blog post is live and linked from the dashboard

---

## Next step

→ [P6-T6: Content Tracker](p6-t6-content-tracker.md) — add the content panel before deploying, then deploy everything together in [P6-T7](p6-t7-deploy-public.md).
