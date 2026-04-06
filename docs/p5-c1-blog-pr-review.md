# P5-C1: Blog Post — I Gave Claude My Engineering Standards and Had It Review PRs

> **Goal:** Write a blog post that shows the eval table, explains what the bot caught and missed, and tells the honest story of building and measuring an AI code reviewer.

**Part of:** [P5-E1: GitHub PR Review Bot](p5-e1-pr-review-bot.md)
**Week:** 12
**Labels:** `task`, `p5-codereview`, `content`

---

## What you are doing

You are writing a technical blog post for a developer audience. The most compelling angle is honesty: you did not just build a bot, you measured it. You have a table that shows exactly how well it performed, and you changed the prompt based on what you found.

Most "I built an AI thing" posts show screenshots of it working. Yours shows a precision/recall table. That is what makes it stand out.

---

## Why this step matters

The eval table from P5-T7 is your most valuable content asset. It is specific, it is honest, and it is rare. Most developers who build AI tools never measure them.

Publishing this also closes the loop on the project: you built it, you measured it, you improved it, you explained it. That is a complete engineering story.

---

## Prerequisites

- [ ] Eval report completed (P5-T7) — you need the real numbers
- [ ] Prompt tuning done (P5-T8) — you need the before/after comparison
- [ ] Bot live and running on at least one real PR (P5-T9) — screenshot to include

---

## Blog post structure

### What makes this post compelling

The compelling angle is **showing your work**:
- Not "the bot is amazing" — but "here is what it caught and what it missed"
- Not "I improved the prompt" — but "precision went from 67% to 81% after this specific change"
- Not vague claims — but a real table from real PRs

The reader should come away thinking: "I could build this, and I could measure it the same way."

---

## Step-by-step instructions

### Step 1 — Draft the post outline

Before writing, nail the structure. A good structure for this post:

```
1. Hook (the most interesting finding from your eval)
2. What you built (one paragraph + screenshot)
3. How it works (the 4-step chain — ASCII diagram or image)
4. The eval — show the table (this is the meat of the post)
5. What the table revealed
6. What you changed in the prompt (specific change, not vague)
7. Before vs. after numbers
8. What surprised you
9. What you would do next
10. How to get the code (link to GitHub)
```

### Step 2 — Write the post

Use this template as a starting point. Fill in your real numbers and real findings.

---

**Draft template:**

```markdown
# I Gave Claude My Engineering Standards and Had It Review PRs

Code review is valuable but inconsistent. Human reviewers miss things when tired,
apply rules differently, and sometimes skip reviews when busy.

So I built a bot that reviews every PR against my team's engineering standards —
automatically, every time, using the same rules. Then I measured how well it worked.
The results were more interesting than I expected.

## What I built

A GitHub Actions bot that:
- Triggers on every pull request (opened or updated)
- Fetches the changed code (the "diff")
- Sends it through a 4-step Claude review chain
- Posts a structured comment with severity levels: 🔴 ERROR / 🟡 WARNING / 🟢 INFO

[Screenshot of a real review comment here]

## How it works: the 4-step chain

I did not use a single "review everything" prompt. I used four focused steps:

Step 1: Summarise the PR (what does it do?)
Step 2: Evaluate each rule category separately (one API call per category)
Step 3: Parse and validate the JSON output
Step 4: Format as a GitHub markdown comment

Why multi-step? A single "review this 400-line diff for security, naming,
architecture, and tests" prompt produces shallow, inconsistent results.
Focused prompts produce thorough ones.

## The eval: did it actually work?

I ran the bot against 10 past PRs that were already reviewed and merged by humans.
For each one, I scored what the bot found against what a human would have flagged.

Here are the results:

| PR # | Lines | TP | FP | FN | Precision | Recall | Notes |
|------|-------|----|----|-----|-----------|--------|-------|
| #12  | 120   |  3 |  1 |  0 |    75%    |  100%  | Caught hardcoded secret |
| #34  |  89   |  2 |  0 |  1 |   100%    |   67%  | Missed test for 401 |
| #56  | 200   |  1 |  3 |  2 |    25%    |   33%  | Too many false positives |
| ... | ... | ... | ... | ... | ... | ... | ... |
| **Total** | **1523** | **20** | **10** | **9** | **67%** | **69%** |  |

**Overall: 67% precision, 69% recall.**

That means: of everything the bot flagged, 67% was actually a problem. Of all
real problems, the bot caught 69% of them.

Honestly, better than I expected for a first version.

## What went wrong

**False positives were mostly in the naming category.**

The bot was flagging things like "this function name could be clearer" when the
name was already following conventions. The prompt was being too opinionated.

**False negatives were mostly subtle logic bugs.**

The bot is good at pattern matching against rules. It is bad at reasoning about
whether a piece of code is logically correct. I expected this.

**The security category was the standout performer.**

Hardcoded secrets, SQL injection risks, unvalidated inputs — the bot caught these
reliably. Probably because they match clear patterns in the rubric examples.

## What I changed in the prompt

I added one instruction to the category review prompt:

> "Only flag issues that CLEARLY violate the rules and examples above. Do not flag
> personal style preferences or minor nitpicks. When in doubt, do NOT include a
> finding. Fewer accurate findings are better than many inaccurate ones."

That is it. One sentence.

## Before vs. after

| Metric    | v1    | v2 (after one change) |
|-----------|-------|----------------------|
| Precision | 67%   | 81%                  |
| Recall    | 69%   | 65%                  |

Precision improved substantially. Recall dropped slightly — the bot became more
conservative. That is the right trade-off for code review: fewer false alarms
matter more than catching every possible issue.

## What surprised me

**The rubric is everything.** When the rubric had vague descriptions, the bot gave
vague feedback. When I added concrete good/bad examples, the quality jumped.
This is the same principle as good prompt engineering — specificity beats generality.

**I used my own tool to manage the prompts.** In Project 1 of this program, I
built PromptOS — a tool to store and version AI prompts. Here in Project 5,
I used PromptOS to version the review bot's prompts and compare scores.
Building tools that feed your own future tools is the compounding effect of
systematic AI engineering.

**Cost is small but worth tracking.** A typical 200-line PR costs about $0.01 USD
to review. I added a cost guard that skips PRs over 500 lines and logs every
review's estimated cost. Small habit, big payoff over time.

## What I would do next

- Improve recall on missing-test cases — the rubric examples need to be more specific
- Add a category for documentation (currently disabled)
- Try claude-3-5-sonnet for higher-stakes PRs and compare quality

## Get the code

The bot is open source and configurable. Drop in your own `review-rules.yml`
and it reviews against your team's standards, not mine.

[Link to GitHub repository]

Setup takes about 10 minutes.
```

---

### Step 3 — Add your real numbers

Replace every placeholder with your actual eval results:
- Your real PR numbers
- Your real TP/FP/FN counts
- Your real precision/recall scores
- The specific change you made to the prompt
- The specific category that performed best/worst

A post with made-up numbers reads like a made-up post. Your real numbers — even if they are modest — read like a real engineering story.

### Step 4 — Choose a platform and publish

Recommended platforms for developer content:
- **dev.to** — large developer community, good discoverability, free
- **Hashnode** — developer-focused, supports custom domain
- **Substack** — better for building a newsletter audience over time
- **Your own site** — best for control, harder to grow audience

Cross-post to LinkedIn with a 3-5 sentence summary and a link.

### Step 5 — Share it

After publishing:
- Post on LinkedIn with the key finding from your eval table
- Post on X/Twitter if you use it
- Share in any Slack communities or Discord servers relevant to AI engineering
- Add the link to your GitHub profile README

---

## What makes a post successful

The goal is not viral traffic. The goal is **one person** finding your post, reading it, and thinking "this person knows how to build and measure AI systems." That person might be a recruiter, a potential collaborator, or someone who becomes a regular reader.

One honest, measured, detailed post beats ten vague "here is my AI project" posts.

---

## Visual overview

```
Your eval results (P5-T7)
        │
        ├── Precision: 67% → 81%
        ├── Best category: Security
        ├── Worst: subtle logic bugs
        └── Key finding: one prompt change → major precision gain

        │
        ▼
Blog post structure:
  Hook (most interesting finding)
        │
        ▼
  What you built + screenshot
        │
        ▼
  How the 4-step chain works
        │
        ▼
  The eval table (the proof)
        │
        ▼
  What went wrong + what you changed
        │
        ▼
  Before/after numbers
        │
        ▼
  What surprised you
        │
        ▼
  Get the code (GitHub link)
```

---

## Done when

- [ ] Blog post drafted with your real eval numbers filled in
- [ ] Screenshot of a real review comment included
- [ ] Before/after comparison table included
- [ ] Post published on your chosen platform
- [ ] Link shared on LinkedIn and any other channels
- [ ] Link added to your `projects/05-codereview/README.md`

---

## Project 5 complete

You have built a PR review bot that:
- Triggers automatically on every pull request
- Reviews against your custom engineering rules
- Posts structured, severity-coded feedback
- Guards against oversized PRs and runaway costs
- Was evaluated on 10 real PRs with documented precision/recall
- Was improved through targeted prompt tuning
- Is published open source for any team to use

Write in your build log: what was the hardest part? What are you most proud of?

→ Next: [P6-E1: AI Dashboard](p6-e1-ai-dashboard.md)
