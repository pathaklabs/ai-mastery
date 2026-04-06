# P5-T6: Add Cost Guard — Skip if Diff Over 500 Lines

> **Goal:** Add a check that prevents the bot from reviewing oversized PRs, posts a helpful message instead, and logs the cost of every review that does run.

**Part of:** [P5-US1: Build an Automated PR Review Bot](p5-us1-review-bot.md)
**Week:** 10
**Labels:** `task`, `p5-codereview`

---

## What you are doing

Before making any call to the Claude API, the script checks how many lines changed in the PR. If the number exceeds 500, the bot posts a message asking the developer to split the PR, then exits without spending any API credits.

For PRs that do pass the check, the bot logs an estimated cost after the review completes.

This is a small amount of code but a big mindset shift: **production AI engineering treats cost as a first-class concern, not an afterthought.**

---

## Why this step matters

Without a cost guard, one developer could accidentally submit a 5,000-line PR (a refactor, a migration, a generated file) and cost you $5-10 in a single review. Multiply that by a busy team and an unguarded system becomes expensive quickly.

More importantly: large PRs are bad practice. A bot that refuses to review them and explains why is actually nudging your team toward better engineering habits.

---

## Prerequisites

- [ ] `review.py` completed (P5-T5)
- [ ] Anthropic API pricing understood (check [anthropic.com/pricing](https://anthropic.com/pricing))

---

## Step-by-step instructions

### Step 1 — Understand the cost model

Claude API pricing is based on tokens (roughly 4 characters = 1 token):

```
Input tokens  = tokens in your prompt (diff + rubric text + instructions)
Output tokens = tokens in Claude's response (the findings JSON)

Cost = (input_tokens × input_price) + (output_tokens × output_price)

For claude-3-5-haiku (fast, cheap model used for reviews):
  Input:  $0.80 per million tokens
  Output: $4.00 per million tokens

Example: 500-line diff ≈ 4,000 tokens
  5 categories × (4,000 input + 200 output) tokens
  = 5 × (4,000 × $0.00000080) + (200 × $0.00000400)
  = 5 × ($0.0032 + $0.0008)
  = 5 × $0.004
  = $0.020 per review

For a team of 10 with 5 PRs/day = $1.00/day = $30/month
Manageable. But a 5,000-line diff = $0.20 per review = much more expensive.
```

### Step 2 — Create the cost guard module

Create `projects/05-codereview/cost_guard.py`:

```python
"""
cost_guard.py
Prevents the bot from reviewing PRs that are too large,
and logs estimated costs for reviews that do run.

Why this exists:
  - Large PRs are expensive to review (more tokens = more cost)
  - Large PRs are also bad engineering practice
  - The bot enforces both constraints with one check
"""

import os
import time
import json
from datetime import datetime

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

MAX_DIFF_LINES = 500   # reject PRs with more than this many changed lines

# Approximate pricing for claude-3-5-haiku-20241022 (verify at anthropic.com/pricing)
# These are estimates — actual cost depends on exact token count
PRICE_PER_MILLION_INPUT_TOKENS  = 0.80   # USD
PRICE_PER_MILLION_OUTPUT_TOKENS = 4.00   # USD

# Rough token estimate: 1 line of diff ≈ 8 tokens
TOKENS_PER_LINE = 8


# ─────────────────────────────────────────────────────────────────────────────
# SIZE CHECK
# ─────────────────────────────────────────────────────────────────────────────

def count_diff_lines(diff: str) -> int:
    """
    Count the number of changed lines in a diff.
    We count only lines that start with '+' or '-' (actual changes).
    Lines starting with '+++' or '---' are file headers — skip those.
    Context lines (starting with ' ') are not changes — skip those.
    """
    changed_lines = 0
    for line in diff.splitlines():
        if line.startswith(("+++", "---", "@@")):
            continue   # file headers and chunk headers
        if line.startswith("+") or line.startswith("-"):
            changed_lines += 1
    return changed_lines


def check_diff_size(diff: str) -> bool:
    """
    Check if the PR diff is within the allowed size limit.

    Returns:
        True  — diff is within limit, proceed with review
        False — diff is too large, skip review
    """
    line_count = count_diff_lines(diff)
    total_lines = diff.count("\n")

    print(f"Diff size check:")
    print(f"  Total lines in diff file: {total_lines}")
    print(f"  Changed lines (+/-):      {line_count}")
    print(f"  Limit:                    {MAX_DIFF_LINES}")

    if line_count > MAX_DIFF_LINES:
        print(f"  Result: BLOCKED — {line_count} lines exceeds limit of {MAX_DIFF_LINES}")
        return False

    print(f"  Result: OK — proceeding with review")
    return True


def format_too_large_message(line_count: int) -> str:
    """
    Format the message posted when a PR is too large to review.
    Should be helpful and non-judgmental — the developer may not know
    about PR size best practices.
    """
    return f"""## AI Code Review — Skipped

This PR has **{line_count} changed lines**, which exceeds the automated review limit of **{MAX_DIFF_LINES} lines**.

### Why does this limit exist?

Automated review works best on focused, reviewable PRs. Large PRs are harder for both AI and humans to review well.

### What you can do

Consider splitting this PR into smaller, focused changes:

- **Feature + tests**: one PR for the implementation, one for test coverage
- **Refactor + feature**: one PR for the refactor, one for the new feature
- **Multiple features**: one PR per independent feature

Once split, each PR will get full automated review.

_If this PR intentionally contains large generated files (migrations, fixtures), reach out to configure an exclusion._
"""


# ─────────────────────────────────────────────────────────────────────────────
# COST ESTIMATION AND LOGGING
# ─────────────────────────────────────────────────────────────────────────────

def estimate_cost(diff: str, num_categories: int) -> float:
    """
    Estimate the cost of reviewing this diff.

    This is an approximation — actual cost depends on:
    - Exact token count (use tiktoken for accuracy if needed)
    - The specific model's current pricing
    - Length of the rubric text passed in each prompt

    Args:
        diff:           The PR diff text
        num_categories: Number of rubric categories being checked

    Returns:
        Estimated cost in USD
    """
    # Estimate input tokens: diff + rubric overhead per category
    diff_tokens    = len(diff) // 4            # rough: 4 chars per token
    rubric_tokens  = 500                        # approx rubric text per category
    summary_tokens = 300                        # summary step overhead

    input_tokens_per_category  = diff_tokens + rubric_tokens
    output_tokens_per_category = 300            # findings JSON per category

    total_input_tokens  = (input_tokens_per_category * num_categories) + summary_tokens
    total_output_tokens = output_tokens_per_category * num_categories

    input_cost  = (total_input_tokens  / 1_000_000) * PRICE_PER_MILLION_INPUT_TOKENS
    output_cost = (total_output_tokens / 1_000_000) * PRICE_PER_MILLION_OUTPUT_TOKENS

    return round(input_cost + output_cost, 4)


def log_review_cost(
    pr_number:     str,
    repo:          str,
    diff_lines:    int,
    estimated_cost: float,
    duration_secs: float,
    log_file:      str = "review_costs.jsonl"
):
    """
    Append a cost log entry for this review.

    Uses JSON Lines format (one JSON object per line) so you can:
    - grep for specific PRs
    - parse with pandas for cost analysis
    - ship to a monitoring tool later

    Args:
        pr_number:      PR number (string)
        repo:           Repository name
        diff_lines:     Number of changed lines reviewed
        estimated_cost: Estimated USD cost
        duration_secs:  How long the review took
        log_file:       Path to write cost log
    """
    entry = {
        "timestamp":      datetime.utcnow().isoformat() + "Z",
        "repo":           repo,
        "pr_number":      pr_number,
        "diff_lines":     diff_lines,
        "estimated_cost": estimated_cost,
        "duration_secs":  round(duration_secs, 2),
        "model":          "claude-3-5-haiku-20241022"
    }

    with open(log_file, "a") as f:
        f.write(json.dumps(entry) + "\n")

    print(f"\nCost log:")
    print(f"  Estimated cost:  ${estimated_cost:.4f}")
    print(f"  Duration:        {duration_secs:.1f}s")
    print(f"  Logged to:       {log_file}")


# ─────────────────────────────────────────────────────────────────────────────
# QUICK TEST
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("Testing cost guard...\n")

    # Test 1: Small diff — should pass
    small_diff = "\n".join([f"+line {i}" for i in range(100)])
    print("Test 1 — Small diff (100 lines):")
    result = check_diff_size(small_diff)
    print(f"  Passed check: {result}\n")

    # Test 2: Large diff — should be blocked
    large_diff = "\n".join([f"+line {i}" for i in range(600)])
    print("Test 2 — Large diff (600 lines):")
    result = check_diff_size(large_diff)
    print(f"  Passed check: {result}")
    if not result:
        msg = format_too_large_message(600)
        print(f"\n  Would post this message:\n{msg[:300]}...\n")

    # Test 3: Cost estimate
    test_diff = "\n".join([f"+line {i}" for i in range(300)])
    cost = estimate_cost(test_diff, num_categories=5)
    print(f"Test 3 — Cost estimate for 300-line diff, 5 categories:")
    print(f"  Estimated: ${cost:.4f}")
```

### Step 3 — Update `review.py` to use the cost guard

The cost guard is already imported in P5-T5's `review.py`. Double-check that the import and usage look like this:

```python
# In review.py — near the top of main()

import time
from cost_guard import check_diff_size, format_too_large_message, estimate_cost, log_review_cost

def main():
    start_time = time.time()   # start timer

    # ... fetch diff ...

    # Cost guard — BEFORE any AI API calls
    if not check_diff_size(diff):
        msg = format_too_large_message(count_diff_lines(diff))
        post_simple_comment(msg)
        print("Skipped: PR too large.")
        sys.exit(0)

    # ... run review chain ...

    # Log cost after review
    duration = time.time() - start_time
    line_count = count_diff_lines(diff)
    estimated = estimate_cost(diff, num_categories=5)
    log_review_cost(PR_NUMBER, REPO, line_count, estimated, duration)
```

### Step 4 — Test the cost guard

```bash
cd projects/05-codereview
python cost_guard.py
```

You should see both tests pass and the cost estimate printed.

---

## Visual overview

```
review.py starts
      │
      ▼
get_pr_diff()
      │
      ▼
count_diff_lines(diff)
      │
      ├── line_count > 500?
      │       │ YES
      │       ▼
      │   post_simple_comment(
      │     format_too_large_message(line_count)
      │   )
      │   sys.exit(0)   ← clean exit, no API call made
      │
      │ NO (line_count ≤ 500)
      │
      ▼
run_review_chain(diff)   ← AI API calls happen here
      │
      ▼
post_pr_review(comment)
      │
      ▼
log_review_cost(...)     ← appended to review_costs.jsonl
      │
      ▼
Done
```

---

## Cost log: what you get over time

After a few weeks, `review_costs.jsonl` will contain entries like:

```json
{"timestamp": "2025-04-10T09:15:00Z", "repo": "pathak-labs/api", "pr_number": "47", "diff_lines": 120, "estimated_cost": 0.0041, "duration_secs": 12.3, "model": "claude-3-5-haiku-20241022"}
{"timestamp": "2025-04-10T14:22:00Z", "repo": "pathak-labs/api", "pr_number": "48", "diff_lines": 340, "estimated_cost": 0.0108, "duration_secs": 18.7, "model": "claude-3-5-haiku-20241022"}
{"timestamp": "2025-04-11T10:05:00Z", "repo": "pathak-labs/api", "pr_number": "49", "diff_lines": 0, "estimated_cost": 0, "duration_secs": 0, "model": "SKIPPED-too-large"}
```

You can analyse this with a simple Python script or paste it into a spreadsheet to track your monthly AI spend.

---

## Learning checkpoint

> Write in your build log:
>
> 1. What would happen to a production AI system that had no cost guard and a developer submitted a 50,000-line PR (like checking in a large library)?
> 2. Beyond size, what other conditions might you want to guard against? (Hint: file types, certain directories, auto-generated files.)
> 3. How does the "refuse + explain" pattern differ from just silently skipping? Which is better for your team?

---

## Done when

- [ ] `projects/05-codereview/cost_guard.py` created
- [ ] `python cost_guard.py` passes both test cases
- [ ] `review.py` uses `check_diff_size()` before any AI API calls
- [ ] `review.py` calls `log_review_cost()` after each successful review
- [ ] `review_costs.jsonl` is added to `.gitignore` (it may grow large and contains cost data)

---

## Next step

→ [P5-T7: Eval — Run on 10 Past PRs](p5-t7-eval-past-prs.md)
