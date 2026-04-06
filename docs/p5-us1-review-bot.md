# P5-US1: Automated PR Review Bot

> **"As a developer, I want an automated bot to review every pull request against my team's engineering standards so I get consistent, structured feedback without waiting for a human reviewer."**

**Part of:** [P5-E1: GitHub PR Review Bot](p5-e1-pr-review-bot.md)
**Weeks:** 8–12
**Labels:** `user-story`, `p5-codereview`

---

## What this user story delivers

When this story is complete, you will have a working GitHub Actions bot that:

- Triggers automatically whenever a pull request is opened or updated
- Fetches the changed code (the "diff") from GitHub
- Sends it through a multi-step Claude review chain
- Posts a structured review comment back on the PR with colour-coded severity levels
- Refuses to review oversized PRs to keep API costs controlled

The result is a bot that acts like a tireless code reviewer who never forgets your team's standards.

---

## Why this story matters

Code review is one of the highest-value engineering activities — but it is inconsistent. Humans miss things when tired, apply rules differently, or skip reviews when busy. An automated bot does not get tired. It checks every PR against the same rubric every time.

More importantly: this story teaches you to think like a production AI engineer. You will define quality rules as data, build a prompt chain instead of a single prompt, and wire everything together in a CI/CD pipeline.

---

## Acceptance criteria

- [ ] Review rubric defined as a structured YAML prompt spec (categories, severity levels, good/bad examples)
- [ ] Bot triggers automatically on `pull_request` event (opened, synchronize) via GitHub Actions
- [ ] Bot posts a structured review comment with severity levels (ERROR / WARNING / INFO)
- [ ] Cost guard prevents reviewing PRs with more than 500 changed lines

---

## Tasks in this story

| Task ID | Task | Doc |
|---------|------|-----|
| P5-T1 | Define review rubric as structured prompt spec | [p5-t1-review-rubric.md](p5-t1-review-rubric.md) |
| P5-T2 | Build multi-step prompt chain for code review | [p5-t2-review-chain.md](p5-t2-review-chain.md) |
| P5-T3 | Build structured output parser and validator | [p5-t3-output-parser.md](p5-t3-output-parser.md) |
| P5-T4 | Create GitHub Actions workflow | [p5-t4-github-actions.md](p5-t4-github-actions.md) |
| P5-T5 | Build Python script (fetch diff, run chain, post comment) | [p5-t5-python-script.md](p5-t5-python-script.md) |
| P5-T6 | Add cost guard — skip if diff over 500 lines | [p5-t6-cost-guard.md](p5-t6-cost-guard.md) |

---

## How the tasks fit together

```
P5-T1: Define what "good code" means
  (review-rubric.yml — categories, examples, severity)
          │
          ▼
P5-T2: Build the review brain
  (4-step prompt chain that reads diff, checks each rule,
   outputs structured JSON, formats as markdown)
          │
          ▼
P5-T3: Build the safety net
  (parse JSON output, validate it, retry once on failure)
          │
          ▼
P5-T4: Wire up the trigger
  (.github/workflows/ai-review.yml — GitHub runs this on every PR)
          │
          ▼
P5-T5: Build the glue script
  (review.py — fetches diff, runs chain, posts comment)
          │
          ▼
P5-T6: Add the cost guard
  (check line count before ANY API call)
          │
          ▼
  User Story DONE: bot reviews every PR automatically
```

---

## What a completed review looks like

```
Developer opens PR #47 "Add user authentication"
                │
                ▼
    GitHub Actions starts (within ~30 seconds)
                │
                ▼
    review.py runs in Ubuntu container:
      - Fetches diff (340 lines — within 500 limit)
      - Passes to 4-step Claude chain
      - Parses JSON output
      - Formats as markdown
                │
                ▼
    Bot posts comment on PR #47:

    ┌─────────────────────────────────────────────┐
    │ ## AI Code Review                            │
    │                                              │
    │ Summary: This PR adds JWT authentication...  │
    │                                              │
    │ | Category  | Severity    | Finding        | │
    │ |-----------|-------------|----------------| │
    │ | Security  | 🔴 ERROR    | JWT secret ... | │
    │ | Naming    | 🟡 WARNING  | doAuth() ...   | │
    │ | Tests     | 🟡 WARNING  | No test for... | │
    │ | Structure | 🟢 INFO     | Good separation| │
    │                                              │
    │ Cost: $0.012                                 │
    └─────────────────────────────────────────────┘
```

---

## Learning outcomes

After completing this user story you will understand:

- How to translate human code review knowledge into a structured YAML spec
- Why multi-step prompt chains outperform single prompts for complex analysis tasks
- How GitHub Actions works and how to trigger scripts on PR events
- How to use the GitHub REST API to fetch diffs and post comments
- Why cost guarding is a first-class concern in production AI systems

---

## Next step

After this story, move to [P5-US2: Evaluate and Tune Review Quality](p5-us2-eval-quality.md).
