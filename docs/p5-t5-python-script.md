# P5-T5: Build Python Script — Fetch Diff, Run Chain, Post Review

> **Goal:** Build the main `review.py` script that fetches the PR diff from GitHub, runs it through the review chain, and posts the formatted result as a PR review comment.

**Part of:** [P5-US1: Build an Automated PR Review Bot](p5-us1-review-bot.md)
**Week:** 10
**Labels:** `task`, `p5-codereview`

---

## What you are doing

This is the glue script. It is the entry point that GitHub Actions runs. It does three things in sequence:

1. **Fetch the PR diff** from GitHub's API (the raw text of what changed)
2. **Pass it through the review chain** (the 4-step chain from P5-T2)
3. **Post the result** as a GitHub PR review (not just a comment — an actual review)

The difference between a "comment" and a "review" in GitHub terms: a review is the formal mechanism that appears at the top of the PR conversation with an approve/request-changes status. Comments are more informal. This script posts a review.

---

## Why this step matters

This is the script that makes everything real. The rubric, the chain, the parser, the workflow — they all depend on this script working correctly. When `review.py` succeeds, the bot is live.

---

## Prerequisites

- [ ] `review_chain.py` completed (P5-T2)
- [ ] `review_parser.py` completed (P5-T3)
- [ ] GitHub Actions workflow created (P5-T4)
- [ ] Bot has `pull-requests: write` permission in the workflow YAML

---

## Step-by-step instructions

### Step 1 — Understand the GitHub API calls

The script makes two API calls:

**Call 1: GET the PR diff**
```
GET https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}
Header: Accept: application/vnd.github.diff

Returns: Raw text diff of all changed files
```

**Call 2: POST a PR review**
```
POST https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/reviews
Body: {
  "body": "## AI Code Review\n...",
  "event": "COMMENT"   (not APPROVE or REQUEST_CHANGES — just a comment review)
}
```

There is a difference between posting a PR review (`/reviews` endpoint) and posting a regular comment (`/issues/{number}/comments`). PR reviews appear in the review section of the PR, which is where humans expect code review feedback.

### Step 2 — Create the main script

Create `projects/05-codereview/review.py`:

```python
"""
review.py
Main entry point for the AI PR Review Bot.

This script is run by GitHub Actions on every pull_request event.
It expects these environment variables (set by the workflow YAML):
  - ANTHROPIC_API_KEY: your Anthropic API key
  - GITHUB_TOKEN:      GitHub token for API calls (auto-provided by Actions)
  - PR_NUMBER:         pull request number (e.g., "47")
  - REPO:              owner/repo string (e.g., "pathak-labs/my-api")
  - BASE_SHA:          base commit SHA (where PR branches from)
  - HEAD_SHA:          head commit SHA (latest commit in PR)
"""

import os
import sys
import requests

from review_chain  import run_review_chain
from review_parser import parse_all_findings

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — read from environment
# ─────────────────────────────────────────────────────────────────────────────

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
PR_NUMBER    = os.environ.get("PR_NUMBER")
REPO         = os.environ.get("REPO")

if not all([GITHUB_TOKEN, PR_NUMBER, REPO]):
    print("ERROR: Missing required environment variables.")
    print(f"  GITHUB_TOKEN: {'set' if GITHUB_TOKEN else 'MISSING'}")
    print(f"  PR_NUMBER:    {'set' if PR_NUMBER else 'MISSING'}")
    print(f"  REPO:         {'set' if REPO else 'MISSING'}")
    sys.exit(1)

GITHUB_API  = "https://api.github.com"
AUTH_HEADER = {"Authorization": f"Bearer {GITHUB_TOKEN}"}


# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: FETCH THE PR DIFF
# ─────────────────────────────────────────────────────────────────────────────

def get_pr_diff() -> str:
    """
    Fetch the raw diff for this pull request from GitHub API.

    The diff is a text file where:
      - Lines starting with '+' were added in this PR
      - Lines starting with '-' were removed in this PR
      - Lines starting with ' ' (space) are context (unchanged)
      - Lines starting with '@@' show where in the file each chunk is

    Returns the diff as a string.
    """
    url = f"{GITHUB_API}/repos/{REPO}/pulls/{PR_NUMBER}"
    headers = {
        **AUTH_HEADER,
        "Accept": "application/vnd.github.diff"   # request raw diff format
    }

    print(f"Fetching diff for PR #{PR_NUMBER} in {REPO}...")
    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        print(f"ERROR: GitHub API returned {response.status_code}")
        print(f"  Response: {response.text[:500]}")
        sys.exit(1)

    diff = response.text
    line_count = diff.count("\n")
    print(f"Diff fetched: {line_count} lines, {len(diff)} characters")
    return diff


def get_pr_metadata() -> dict:
    """
    Fetch PR metadata (title, author, branch names).
    Used for richer review context.
    """
    url = f"{GITHUB_API}/repos/{REPO}/pulls/{PR_NUMBER}"
    headers = {**AUTH_HEADER, "Accept": "application/vnd.github+json"}

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        return {
            "title":  data.get("title", ""),
            "author": data.get("user", {}).get("login", ""),
            "base":   data.get("base", {}).get("ref", ""),
            "head":   data.get("head", {}).get("ref", ""),
        }
    return {}


# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: RUN THE REVIEW CHAIN
# (imported from review_chain.py — see P5-T2)
# ─────────────────────────────────────────────────────────────────────────────

# run_review_chain(diff) → returns formatted markdown string


# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: POST THE REVIEW COMMENT
# ─────────────────────────────────────────────────────────────────────────────

def post_pr_review(body: str, event: str = "COMMENT") -> bool:
    """
    Post a PR review using the GitHub Reviews API.

    This appears in the "Review" section of the PR (more visible than
    a regular comment).

    event options:
      - "COMMENT"          = neutral review comment
      - "APPROVE"          = approves the PR
      - "REQUEST_CHANGES"  = requests changes (blocks merge)

    We use "COMMENT" so the bot does not block merges — it informs,
    not gatekeeps. A human should make the final call.

    Returns True on success, False on failure.
    """
    url = f"{GITHUB_API}/repos/{REPO}/pulls/{PR_NUMBER}/reviews"
    headers = {
        **AUTH_HEADER,
        "Accept": "application/vnd.github+json"
    }
    payload = {
        "body":  body,
        "event": event
    }

    print(f"Posting PR review to {url}...")
    response = requests.post(url, json=payload, headers=headers)

    if response.status_code in (200, 201):
        review_id = response.json().get("id", "unknown")
        print(f"Review posted successfully (id: {review_id})")
        return True
    else:
        print(f"ERROR: Failed to post review — status {response.status_code}")
        print(f"  Response: {response.text[:500]}")
        return False


def post_simple_comment(body: str) -> bool:
    """
    Fallback: post a regular PR comment (simpler, always works).
    Used when the reviews API is not available.
    """
    url = f"{GITHUB_API}/repos/{REPO}/issues/{PR_NUMBER}/comments"
    headers = {**AUTH_HEADER, "Accept": "application/vnd.github+json"}

    response = requests.post(url, json={"body": body}, headers=headers)
    if response.status_code in (200, 201):
        print("Comment posted successfully (fallback mode)")
        return True
    else:
        print(f"ERROR: Fallback comment also failed — {response.status_code}")
        print(response.text[:200])
        return False


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("AI PR Review Bot starting")
    print(f"  Repository: {REPO}")
    print(f"  PR number:  #{PR_NUMBER}")
    print("=" * 60)

    # ── 1. Fetch diff ──────────────────────────────────────────────────────
    diff = get_pr_diff()

    # ── 2. Cost guard — check BEFORE any AI API calls ─────────────────────
    # (P5-T6 adds this — imported here)
    from cost_guard import check_diff_size, format_too_large_message
    if not check_diff_size(diff):
        too_large_msg = format_too_large_message(diff.count("\n"))
        post_simple_comment(too_large_msg)
        print("PR is too large — skipping review. Cost guard triggered.")
        sys.exit(0)   # exit cleanly (not an error)

    # ── 3. Fetch metadata for richer context ──────────────────────────────
    metadata = get_pr_metadata()
    if metadata:
        print(f"PR: '{metadata['title']}' by @{metadata['author']}")

    # ── 4. Run the review chain ────────────────────────────────────────────
    print("\nRunning review chain...")
    rubric_path = os.path.join(os.path.dirname(__file__), "review-rubric.yml")
    review_comment = run_review_chain(diff, rubric_path=rubric_path)

    # ── 5. Post the review ─────────────────────────────────────────────────
    print("\nPosting review...")
    success = post_pr_review(review_comment)

    if not success:
        # Fallback to a regular comment
        success = post_simple_comment(review_comment)

    if success:
        print("\nReview bot completed successfully.")
    else:
        print("\nERROR: Failed to post review.")
        sys.exit(1)


if __name__ == "__main__":
    main()
```

### Step 3 — Test locally (before relying on GitHub Actions)

You can test the script locally by simulating the environment variables:

```bash
cd projects/05-codereview

# Set the environment variables
export ANTHROPIC_API_KEY="your-key"
export GITHUB_TOKEN="your-personal-access-token"
export PR_NUMBER="1"   # use a real PR number from your repo
export REPO="your-username/your-repo"

# Run the script
python review.py
```

To get a personal access token for local testing:
- Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Generate a token with `repo` scope
- Use it as `GITHUB_TOKEN`

### Step 4 — Read the output carefully

When the script runs, look for:
- "Diff fetched: N lines" — confirms the diff was received
- "Step 1: Summarising PR..." — confirms the chain started
- "Checking category: Security..." — confirms each category runs
- "Review posted successfully" — confirms the comment appeared on GitHub

If anything fails, the error messages tell you which step failed.

---

## Visual overview

```
GitHub Actions runner
│
├── Environment variables:
│   ├── ANTHROPIC_API_KEY (from secret)
│   ├── GITHUB_TOKEN      (auto-provided)
│   ├── PR_NUMBER         (from event payload)
│   └── REPO              (from event payload)
│
└── python review.py
    │
    ├── get_pr_diff()
    │   └── GET /repos/{REPO}/pulls/{PR_NUMBER}
    │       Accept: application/vnd.github.diff
    │       Returns: raw diff text
    │
    ├── check_diff_size(diff)    ← cost guard (P5-T6)
    │   ├── if > 500 lines: post warning + exit
    │   └── if ≤ 500 lines: continue
    │
    ├── run_review_chain(diff)   ← 4-step chain (P5-T2)
    │   ├── step1_summarise()
    │   ├── step2_evaluate_all_categories()
    │   ├── parse_all_findings()       ← parser (P5-T3)
    │   └── step4_format_as_markdown()
    │   Returns: formatted markdown string
    │
    └── post_pr_review(review_comment)
        └── POST /repos/{REPO}/pulls/{PR_NUMBER}/reviews
            Body: { "body": "...", "event": "COMMENT" }
            Result: review appears on PR
```

---

## What the posted review looks like

On the PR page, the bot's review appears in the "Reviewers" section and in the conversation thread:

```
┌────────────────────────────────────────────────────────────┐
│  🤖 ai-review-bot reviewed 2 hours ago                     │
│                                                            │
│  ## AI Code Review                                         │
│                                                            │
│  ### Summary                                               │
│  This PR adds JWT authentication to the /login endpoint... │
│                                                            │
│  | Category     | Severity    | Line | Finding           | │
│  |--------------|-------------|------|-------------------| │
│  | Security     | 🔴 ERROR    | 42   | Hardcoded secret  | │
│  | Naming       | 🟡 WARNING  | 15   | doAuth() → ...    | │
│  | Tests        | 🟡 WARNING  | —    | No test for 401   | │
│  | Architecture | 🟢 INFO     | —    | Good separation   | │
│                                                            │
│  _This review was generated automatically._               │
└────────────────────────────────────────────────────────────┘
```

---

## Done when

- [ ] `projects/05-codereview/review.py` created
- [ ] Script runs locally and fetches a real PR diff
- [ ] Script posts a review comment on the PR (visible on GitHub)
- [ ] All three modules import correctly: `review_chain`, `review_parser`, `cost_guard`

---

## Next step

→ [P5-T6: Add Cost Guard](p5-t6-cost-guard.md)
