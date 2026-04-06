# P5-US2: Evaluate and Tune Review Bot Quality

> **"As a developer, I want to measure how well the bot reviews real PRs so I can tune the prompt and know when the bot is actually useful."**

**Part of:** [P5-E1: GitHub PR Review Bot](p5-e1-pr-review-bot.md)
**Weeks:** 10–12
**Labels:** `user-story`, `p5-codereview`

---

## What this user story delivers

When this story is complete, you will have:

- An eval report: a scored table showing how the bot performed across 10 real PRs
- A tuned prompt: improved based on what the eval revealed, versioned in PromptOS (your P1 tool)
- Blog content: the eval table is your most compelling public evidence that you built something real

This is the difference between "I built a bot" and "I built a bot that I measured and improved."

---

## Why this story matters

Any AI system in production needs to be measured. Without eval, you do not know whether changes make things better or worse. You are guessing.

This story also demonstrates **skill compounding** — you built PromptOS in P1 to version and test prompts. Now, in P5, you use PromptOS to manage the review bot's prompts. Your own tools are feeding each other.

---

## Acceptance criteria

- [ ] Eval run on 10 past PRs with results in a scored table (true positives, false positives, false negatives, tone)
- [ ] Prompt tuned based on eval findings using PromptOS (P1) to version the changes
- [ ] Precision and recall calculated for both the original and tuned prompt

---

## Tasks in this story

| Task ID | Task | Doc |
|---------|------|-----|
| P5-T7 | Eval — run on 10 past PRs and score review quality | [p5-t7-eval-past-prs.md](p5-t7-eval-past-prs.md) |
| P5-T8 | Tune prompt based on eval results | [p5-t8-tune-prompt.md](p5-t8-tune-prompt.md) |
| P5-T9 | Publish bot as open source with configurable rules file | [p5-t9-open-source.md](p5-t9-open-source.md) |
| P5-C1 | Blog post | [p5-c1-blog-pr-review.md](p5-c1-blog-pr-review.md) |

---

## How the tasks fit together

```
P5-T7: Run the bot on 10 past PRs
  (collect raw output — what did it find?)
          │
          ▼
  Score each result manually:
  - True positive  = bot found a real issue
  - False positive = bot found a non-issue
  - False negative = bot missed a real issue
          │
          ▼
  Calculate precision and recall
          │
          ▼
P5-T8: Load findings into PromptOS
  (open the review prompt, create a new version,
   change wording where the bot failed, re-run same 10 PRs,
   compare scores)
          │
          ▼
P5-T9: Package for the world
  (review-rules.yml for teams to customise,
   README with 5-step setup)
          │
          ▼
P5-C1: Write the blog post
  (show the eval table — this is your proof)
          │
          ▼
  User Story DONE: measured, tuned, published bot
```

---

## What "precision" and "recall" mean (plain English)

Imagine the bot reviewed 10 PRs and found 20 issues:

```
Of those 20 issues:
  - 14 were real problems the human agreed with
  -  6 were false alarms (bot was wrong)

Precision = 14/20 = 70%
  (of everything the bot flagged, 70% was correct)

Now imagine across those 10 PRs, there were 18 real issues total:
  - Bot found 14 of them
  -  4 were missed

Recall = 14/18 = 78%
  (of all real issues, the bot caught 78% of them)
```

A good bot has high precision (doesn't cry wolf) AND high recall (doesn't miss things). After tuning, both numbers should improve.

---

## Learning outcomes

After completing this user story you will understand:

- How to run a structured eval on an AI system (not just "does it seem to work?")
- What precision and recall mean and why both matter
- How to use your own PromptOS tool to version and test prompt improvements
- How to turn eval data into compelling public content

---

## Next step

After this story, the full P5 epic is complete. Move to [P6-E1: AI Dashboard](p6-e1-ai-dashboard.md).
