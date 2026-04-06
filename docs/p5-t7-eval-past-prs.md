# P5-T7: Eval — Run on 10 Past PRs and Score Review Quality

> **Goal:** Run the review bot against 10 real, already-merged PRs, manually score what it found and missed, and document results in a table that becomes both your eval report and your blog content.

**Part of:** [P5-US2: Evaluate and Tune Review Bot Quality](p5-us2-eval-quality.md)
**Weeks:** 10–11
**Labels:** `task`, `p5-codereview`

---

## What you are doing

You are testing the bot against history. You pick 10 PRs that were already reviewed and merged by humans. You run the bot on each one and compare what the bot found against what a human would have flagged.

This gives you real data: not "the bot seems to work," but "the bot caught 73% of real issues with a 22% false positive rate."

That number is your eval score. You will use it in P5-T8 to tune the prompt, and in P5-C1 to write your blog post.

---

## Why this step matters

An AI system without an eval is a system without accountability. You cannot improve what you cannot measure, and you cannot publish credible claims without evidence.

This task also produces your most valuable blog content: an honest table showing what the bot caught, what it missed, and what surprised you. Real numbers beat vague claims every time.

---

## Prerequisites

- [ ] Full review bot working end-to-end (P5-T1 through P5-T6 complete)
- [ ] Access to a GitHub repository with at least 10 merged PRs
- [ ] 1-2 hours of focused time (you need to manually score each PR)

---

## Step-by-step instructions

### Step 1 — Write an eval runner script

Instead of manually triggering the bot for each PR through GitHub Actions, write a local script to run it against any PR number:

Create `projects/05-codereview/eval_runner.py`:

```python
"""
eval_runner.py
Run the review bot against a list of PRs for evaluation purposes.

Usage:
  python eval_runner.py --prs 12,34,56,78,90,101,115,132,145,162

This fetches each PR's diff and runs the review chain locally,
saving the output to eval_results/ so you can score them manually.
"""

import os
import sys
import json
import argparse
import requests
from pathlib import Path
from datetime import datetime

from review_chain  import run_review_chain
from review_parser import parse_all_findings
from cost_guard    import check_diff_size, count_diff_lines

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
REPO         = os.environ.get("REPO")
GITHUB_API   = "https://api.github.com"
AUTH_HEADER  = {"Authorization": f"Bearer {GITHUB_TOKEN}"}

OUTPUT_DIR = Path("eval_results")
OUTPUT_DIR.mkdir(exist_ok=True)


def fetch_pr_data(pr_number: int) -> dict:
    """Fetch PR metadata and diff."""
    # Metadata
    meta_url = f"{GITHUB_API}/repos/{REPO}/pulls/{pr_number}"
    meta_resp = requests.get(
        meta_url,
        headers={**AUTH_HEADER, "Accept": "application/vnd.github+json"}
    )
    metadata = meta_resp.json() if meta_resp.status_code == 200 else {}

    # Diff
    diff_resp = requests.get(
        meta_url,
        headers={**AUTH_HEADER, "Accept": "application/vnd.github.diff"}
    )
    diff = diff_resp.text if diff_resp.status_code == 200 else ""

    return {
        "pr_number": pr_number,
        "title":     metadata.get("title", ""),
        "author":    metadata.get("user", {}).get("login", ""),
        "merged_at": metadata.get("merged_at", ""),
        "diff":      diff,
        "diff_lines": count_diff_lines(diff)
    }


def run_eval_on_pr(pr_number: int) -> dict:
    """Run the review chain on a single PR and save results."""
    print(f"\n{'='*60}")
    print(f"Evaluating PR #{pr_number}...")

    pr_data = fetch_pr_data(pr_number)
    print(f"  Title: {pr_data['title']}")
    print(f"  Lines: {pr_data['diff_lines']}")

    result = {
        "pr_number":  pr_number,
        "title":      pr_data["title"],
        "author":     pr_data["author"],
        "diff_lines": pr_data["diff_lines"],
        "skipped":    False,
        "skip_reason": None,
        "review_output": None,
        "timestamp":  datetime.utcnow().isoformat() + "Z"
    }

    # Check size
    if not check_diff_size(pr_data["diff"]):
        result["skipped"]    = True
        result["skip_reason"] = f"Diff too large ({pr_data['diff_lines']} lines)"
        print(f"  Skipped: too large")
        return result

    if not pr_data["diff"].strip():
        result["skipped"]    = True
        result["skip_reason"] = "Empty diff"
        return result

    # Run review chain
    try:
        review_comment = run_review_chain(pr_data["diff"])
        result["review_output"] = review_comment
        print(f"  Review complete ({len(review_comment)} chars)")
    except Exception as e:
        result["skipped"]    = True
        result["skip_reason"] = f"Review chain error: {e}"
        print(f"  ERROR: {e}")

    # Save to file for manual scoring
    output_path = OUTPUT_DIR / f"pr_{pr_number:04d}.json"
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"  Saved to: {output_path}")

    # Also save as markdown for easy reading
    if result["review_output"]:
        md_path = OUTPUT_DIR / f"pr_{pr_number:04d}_review.md"
        with open(md_path, "w") as f:
            f.write(f"# PR #{pr_number}: {pr_data['title']}\n\n")
            f.write(result["review_output"])
        print(f"  Markdown: {md_path}")

    return result


def main():
    parser = argparse.ArgumentParser(description="Run eval on past PRs")
    parser.add_argument("--prs", required=True, help="Comma-separated PR numbers")
    args = parser.parse_args()

    pr_numbers = [int(n.strip()) for n in args.prs.split(",")]
    print(f"Running eval on {len(pr_numbers)} PRs: {pr_numbers}")

    all_results = []
    for pr_num in pr_numbers:
        result = run_eval_on_pr(pr_num)
        all_results.append(result)

    # Save summary
    summary_path = OUTPUT_DIR / "eval_summary.json"
    with open(summary_path, "w") as f:
        json.dump(all_results, f, indent=2)

    print(f"\n{'='*60}")
    print(f"Eval complete. {len(all_results)} PRs processed.")
    print(f"Results saved to: {OUTPUT_DIR}/")
    print(f"Now: score each pr_NNNN_review.md manually using the scoring table.")


if __name__ == "__main__":
    main()
```

### Step 2 — Run the eval

```bash
cd projects/05-codereview

export GITHUB_TOKEN="your-personal-access-token"
export REPO="your-username/your-repo"
export ANTHROPIC_API_KEY="your-key"

# Replace with your actual PR numbers
python eval_runner.py --prs 12,34,56,78,90,101,115,132,145,162
```

This creates `eval_results/pr_0012_review.md`, `eval_results/pr_0034_review.md`, etc.

### Step 3 — Score each review manually

Open each `pr_NNNN_review.md` and compare it against your memory of that PR (or look at the PR's actual human review comments on GitHub).

For each finding the bot made, decide:
- **True positive (TP):** The bot found a real issue that a human would have flagged
- **False positive (FP):** The bot flagged something that was not actually a problem
- **False negative (FN):** A real issue existed that the bot missed

For **false negatives**, you need to know what was actually wrong with the PR. Look at the human review comments on GitHub for each PR to find things the bot missed.

### Step 4 — Fill in the scoring table

Create `projects/05-codereview/eval_results/EVAL_REPORT.md` with this table:

```markdown
# PR Review Bot — Eval Report
Date: [date]
Model: claude-3-5-haiku-20241022
Rubric version: 1.0

## Scoring key
- TP (True positive):  Bot found a real issue
- FP (False positive): Bot flagged a non-issue
- FN (False negative): Real issue the bot missed
- Precision = TP / (TP + FP) — of what it flagged, how much was correct?
- Recall    = TP / (TP + FN) — of real issues, how many did it catch?

## Results table

| PR # | Title (short) | Lines | TP | FP | FN | Precision | Recall | Tone | Notes |
|------|--------------|-------|----|----|-----|-----------|--------|------|-------|
| #12  | Add login endpoint | 120 | 3 | 1 | 0 | 75% | 100% | Good | Caught hardcoded secret |
| #34  | Refactor auth module | 89 | 2 | 0 | 1 | 100% | 67%  | Good | Missed missing test for 401 |
| #56  | Add user search | 200 | 1 | 3 | 2 | 25% | 33%  | Harsh | Too many false positives on style |
| #78  | Fix race condition | 45 | 0 | 2 | 1 | 0%  | 0%   | N/A  | Race condition too subtle |
| #90  | Update dependencies | 310 | 0 | 0 | 0 | N/A | N/A  | N/A  | No code changes to review |
| #101 | Add rate limiting | 178 | 4 | 1 | 1 | 80% | 80%  | Good | Strong on security category |
| #115 | Improve error msgs | 95  | 2 | 0 | 0 | 100%| 100% | Good | Clean PR, clean review |
| #132 | Add pagination | 230 | 3 | 2 | 1 | 60% | 75%  | OK   | FPs on naming were nitpicky |
| #145 | DB index migration | 67  | 1 | 0 | 2 | 100%| 33%  | Good | Missed missing tests |
| #162 | Add email verification | 189 | 4 | 1 | 1 | 80% | 80%  | Good | Best review of the batch |
| **Total** | | **1523** | **20** | **10** | **9** | | | | |

## Aggregate scores
- **Total findings:**    30 (20 TP + 10 FP)
- **Total real issues:** 29 (20 TP + 9 FN)
- **Precision:**         20 / 30 = **67%**
- **Recall:**            20 / 29 = **69%**

## What the bot does well
- Security category: catches hardcoded secrets and SQL injection risks reliably
- Simple naming violations: clear-cut PEP 8 issues are flagged correctly
- Missing tests on new API endpoints: high recall in this category

## What the bot gets wrong
- Complex/subtle bugs (race conditions, logic errors): low recall
- Style opinions: too opinionated on minor naming, inflating false positives
- Dependency-only PRs: flags irrelevant findings when there is no real code change

## Prompt changes to try (input for P5-T8)
1. Add instruction: "Do not flag minor style preferences — only flag violations of explicit rules"
2. Add instruction: "Skip analysis for PRs that only contain dependency updates or generated files"
3. Improve test category: add examples of subtle missing test cases, not just "no tests at all"
```

### Step 5 — Calculate your aggregate scores

Use this formula:

```
Precision = Total TP / (Total TP + Total FP)

Example: 20 TP, 10 FP
Precision = 20 / (20 + 10) = 20/30 = 67%

Recall = Total TP / (Total TP + Total FN)

Example: 20 TP, 9 FN
Recall = 20 / (20 + 9) = 20/29 = 69%
```

A score of 67% precision and 69% recall is a reasonable starting point. After prompt tuning (P5-T8), you are aiming for both above 80%.

---

## Visual overview

```
10 merged PRs (already reviewed by humans)
         │
         ▼
eval_runner.py
  For each PR:
    1. Fetch diff via GitHub API
    2. Run review chain
    3. Save output to eval_results/pr_NNNN_review.md
         │
         ▼
Manual scoring (you read each output + compare to GitHub human reviews)
  For each finding:
    TP → bot was right
    FP → bot was wrong
  For each missed issue:
    FN → bot should have caught this
         │
         ▼
Scoring table (EVAL_REPORT.md)
    │
    ├── Precision = TP / (TP + FP)
    └── Recall    = TP / (TP + FN)
         │
         ▼
Input for P5-T8 (prompt tuning)
+
Blog content for P5-C1
```

---

## Learning checkpoint

> After completing the scoring table, answer in your build log:
>
> 1. What surprised you most about the bot's performance?
> 2. Which rubric category performed best? Which worst?
> 3. Were there patterns in the false positives? (e.g., always about a specific category?)
> 4. What would you change about the rubric first?

These answers drive P5-T8.

---

## Done when

- [ ] `projects/05-codereview/eval_runner.py` created
- [ ] Eval runner executed against 10 past PRs
- [ ] `eval_results/` folder contains 10 review markdown files
- [ ] `eval_results/EVAL_REPORT.md` created with complete scoring table
- [ ] Precision and recall calculated and documented
- [ ] "What to change" section written — inputs for P5-T8

---

## Next step

→ [P5-T8: Tune Prompt Based on Eval Results](p5-t8-tune-prompt.md)
