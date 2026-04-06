# P5-E1: GitHub PR Review Bot

> **Epic goal:** Build a GitHub Actions bot that reviews pull requests using your own engineering standards — and post a structured review comment automatically when a PR is opened.

**Weeks:** 8–12
**Labels:** `epic`, `p5-codereview`

---

## What you are building

A bot that reads every new pull request, checks it against a set of rules you define, and posts a review comment automatically.

```
Developer opens a Pull Request
          │
          ▼
  GitHub Actions triggers
          │
          ▼
  Python script fetches the diff
          │
          ▼
  Multi-step Claude review chain:
    1. Summarize the PR
    2. Check each review category
    3. Format as structured JSON
    4. Format as readable GitHub comment
          │
          ▼
  Bot posts review comment on PR
          │
          ▼
  Developer reads feedback
```

Example output on a PR:

```markdown
## AI Code Review

### Summary
This PR adds a new user authentication endpoint with JWT tokens.

### Review Results

| Category | Severity | Finding |
|----------|----------|---------|
| Security | 🔴 ERROR | JWT secret is hardcoded in line 42. Use environment variable. |
| Naming | 🟡 WARNING | Function `doAuth()` should be `authenticate_user()` per conventions. |
| Tests | 🟡 WARNING | No test for invalid token scenario. |
| Architecture | 🟢 INFO | Good separation of auth logic from route handler. |

**Cost guard:** This review cost approximately $0.012.
```

---

## Definition of done

- [ ] Review rubric defined as a structured prompt spec
- [ ] Multi-step review chain working (4 steps)
- [ ] GitHub Actions triggers on PR open/update
- [ ] Bot posts structured PR review comment
- [ ] Cost guard in place (skip if diff > 500 lines)
- [ ] Eval run on 10 past PRs — scored and documented

---

## Week 8 — Define Your Review Rubric

### Step 1 — Define review rubric as a structured prompt spec (P5-T1)

> **The quality of this spec = the quality of every review the bot produces.** This is not a quick task.

Create `projects/05-codereview/review-rubric.yml`:

```yaml
categories:
  - name: Security
    description: "Check for common security vulnerabilities"
    severity_levels:
      error: "Immediate security risk — must fix before merge"
      warning: "Potential security concern — recommend fixing"
    examples:
      good:
        - "API key loaded from environment variable: os.getenv('API_KEY')"
        - "SQL query uses parameterised inputs"
      bad:
        - "API key hardcoded as string in source code"
        - "Raw string concatenation in SQL query"

  - name: Naming Conventions
    description: "Functions, variables, and files follow project naming rules"
    severity_levels:
      error: "Breaks naming rules that affect external interfaces (API routes, DB columns)"
      warning: "Inconsistent naming that affects readability"
    examples:
      good:
        - "Function: get_user_by_id()"
        - "Variable: user_email"
      bad:
        - "Function: GetUserById() or doGetUser()"
        - "Variable: ue or userEmail"

  - name: Architecture
    description: "Code follows the project's layered architecture"
    severity_levels:
      error: "Business logic in route handler (should be in service layer)"
      warning: "Overly complex function that should be split"
    examples:
      good:
        - "Route handler calls service, service calls repository"
      bad:
        - "Route handler contains 100 lines of business logic"

  - name: Tests
    description: "New code has appropriate test coverage"
    severity_levels:
      error: "New API endpoint has no tests at all"
      warning: "Missing edge case tests (empty input, error states)"
    examples:
      good:
        - "Test for happy path AND error path"
      bad:
        - "Only happy path tested"
```

> **⚡ Learning checkpoint:** Same discipline as P1's prompt spec — now applied to production code quality. Write in your build log: how is defining a review rubric similar to writing a good prompt? How is it different?

---

## Week 9 — Build the Review Chain

### Step 2 — Build multi-step prompt chain for code review (P5-T2)

Why a multi-step chain instead of one big prompt?

```
One big prompt approach (does NOT work well):
──────────────────────────────────────────────
"Here is a 400-line diff. Review it for security, naming,
architecture, tests, performance, and documentation. Output
a structured report."

Result: shallow, misses things, inconsistent format

Multi-step approach (works well):
──────────────────────────────────
Step 1: Understand what the PR does (no evaluation yet)
Step 2: Evaluate security only
Step 3: Evaluate naming only
Step 4: Format everything as structured output

Result: thorough, focused, consistent
```

> **⚡ Learning checkpoint:** Before testing, write in your build log: WHY do you think one big prompt fails for code review? After testing both, verify your prediction.

---

**Step 1 of chain — Summarize PR:**

```
You are a code reviewer. Read this pull request diff and write a
2-3 sentence summary of what this PR does. Do not evaluate it yet.
Just describe the change.

PR diff:
{{ diff }}
```

**Step 2 of chain — Evaluate each category:**

(Loop through each category from your rubric)

```
You are reviewing a pull request for {{ category.name }}.

Rule: {{ category.description }}

Good examples:
{{ category.examples.good }}

Bad examples:
{{ category.examples.bad }}

PR diff:
{{ diff }}

List every finding. For each finding return:
{
  "line": 42,                  (or null if general)
  "severity": "error",         (error / warning / info)
  "finding": "...",            (what is wrong)
  "suggestion": "..."          (how to fix it)
}

Return a JSON array. Return empty array [] if no issues found.
```

**Step 3 of chain — Validate output:**

Parse the JSON. If malformed, retry once. If still failing, fall back to plain text.

**Step 4 of chain — Format as GitHub markdown:**

```
Convert these review findings into a GitHub PR review comment.
Use a markdown table. Group by severity: errors first, then warnings, then info.
Add a summary at the top. Add cost information at the bottom.

Findings:
{{ all_findings_json }}
```

---

### Step 3 — Build structured output parser and validator (P5-T3)

```python
import json

def parse_review_output(raw_output: str) -> list[dict]:
    """Parse and validate the JSON output from the review chain."""
    try:
        findings = json.loads(raw_output)
        # Validate each finding has required fields
        required_fields = {"severity", "finding", "suggestion"}
        for finding in findings:
            if not required_fields.issubset(finding.keys()):
                raise ValueError(f"Missing fields in finding: {finding}")
        return findings
    except (json.JSONDecodeError, ValueError):
        # Retry once
        return None  # caller will handle retry

def format_as_github_comment(summary: str, findings: list[dict]) -> str:
    """Format findings as a GitHub PR review comment in markdown."""
    errors   = [f for f in findings if f["severity"] == "error"]
    warnings = [f for f in findings if f["severity"] == "warning"]
    infos    = [f for f in findings if f["severity"] == "info"]

    lines = ["## AI Code Review", "", f"**Summary:** {summary}", ""]
    if errors or warnings or infos:
        lines += ["| Category | Severity | Finding |", "|----------|----------|---------|"]
        for f in errors:
            lines.append(f"| {f.get('category','')} | 🔴 ERROR | {f['finding']} |")
        for f in warnings:
            lines.append(f"| {f.get('category','')} | 🟡 WARNING | {f['finding']} |")
        for f in infos:
            lines.append(f"| {f.get('category','')} | 🟢 INFO | {f['finding']} |")
    else:
        lines.append("No issues found.")

    return "\n".join(lines)
```

---

### Step 4 — Create GitHub Actions workflow (P5-T4)

Create `.github/workflows/ai-review.yml` in the target repository:

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write   # needed to post comments

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0     # full history needed for diff

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: pip install anthropic requests

      - name: Run AI review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.number }}
          REPO: ${{ github.repository }}
        run: python review.py
```

---

## Week 10 — Python Script and Cost Guard

### Step 5 — Build the Python review script (P5-T5)

Create `review.py` — the main script that ties everything together:

```python
import os
import requests
import anthropic

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
PR_NUMBER = os.environ["PR_NUMBER"]
REPO = os.environ["REPO"]

def get_pr_diff():
    """Fetch the diff for this PR from the GitHub API."""
    url = f"https://api.github.com/repos/{REPO}/pulls/{PR_NUMBER}"
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.diff"   # returns raw diff
    }
    response = requests.get(url, headers=headers)
    return response.text

def post_review_comment(body: str):
    """Post a comment on the PR."""
    url = f"https://api.github.com/repos/{REPO}/issues/{PR_NUMBER}/comments"
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}"}
    requests.post(url, json={"body": body}, headers=headers)

def main():
    diff = get_pr_diff()

    # Cost guard — check diff size first
    line_count = diff.count("\n")
    if line_count > 500:
        post_review_comment(
            "⚠️ **AI Review skipped:** PR diff is over 500 lines. "
            "Please split this PR into smaller changes for automated review."
        )
        return

    # Run the review chain
    # ... (call functions from steps 2 and 3)

    review_comment = run_review_chain(diff)
    post_review_comment(review_comment)

if __name__ == "__main__":
    main()
```

---

### Step 6 — Add cost guard (P5-T6)

The cost guard lives at the top of `main()` — check before making ANY API calls:

```python
MAX_DIFF_LINES = 500

line_count = diff.count("\n")
print(f"PR diff: {line_count} lines")

if line_count > MAX_DIFF_LINES:
    post_review_comment(
        f"⚠️ **AI Review skipped:** This PR has {line_count} lines changed. "
        f"Maximum is {MAX_DIFF_LINES}. Please split into smaller PRs."
    )
    return  # exit — no API call made

# Log cost after each review
print(f"Review cost: ${estimated_cost:.4f}")
```

> **⚡ Learning checkpoint:** Why is cost management a first-class engineering concern for AI applications? What would happen to an unguarded system if a developer submitted a 10,000-line PR? Write your answer in the build log.

---

## Weeks 10–11 — Evaluation

### Step 7 — Eval on 10 past PRs (P5-T7)

Take 10 real PRs from your GitHub history. Run the bot on each one.

For each PR, score the review:

| PR | True positives (real bugs caught) | False positives (wrong findings) | False negatives (missed real issues) | Tone |
|----|----------------------------------|----------------------------------|--------------------------------------|------|
| PR #1 | 3 | 1 | 0 | Good |
| PR #2 | 2 | 3 | 2 | Too harsh |
| ... | | | | |

Calculate:
- **Precision:** TP / (TP + FP) — of the issues it found, how many were real?
- **Recall:** TP / (TP + FN) — of the real issues, how many did it find?

Write this table in your build log. This is both your eval report and your blog content.

---

### Step 8 — Tune prompt based on eval results (P5-T8)

Use PromptOS (from P1) to version and test your prompt changes:

```
1. Open PromptOS
2. Load your current review prompt
3. Create a new version with your changes
4. Run the same 10 PRs against the new version
5. Compare scores
6. Repeat until precision and recall both improve
```

Your own tools are now feeding each other. This is the compound effect.

---

## Week 12 — Open Source and Content

### Step 9 — Publish bot as open source (P5-T9)

Create `review-rules.yml` as a user-configurable file:

```yaml
# Customise these rules for your team
categories:
  - name: Security
    enabled: true
    severity_threshold: error   # only report errors for security
  - name: Naming
    enabled: true
    prefix: "snake_case"        # override naming convention
  - name: Tests
    enabled: false              # disable if your team handles tests separately
```

README must include:
- What it does (2 sentences)
- Screenshot of a real review comment
- Setup in 5 steps
- How to customise `review-rules.yml`

---

### Content tasks

| Task | What to do |
|------|-----------|
| P5-C1 | Blog: "I gave Claude my engineering standards and had it review PRs" — show the eval table. What it caught / missed / surprised you / what you changed in the prompt. |

---

## Full task checklist

### Week 8
- [ ] P5-T1: Define review rubric as structured prompt spec

### Week 9
- [ ] P5-T2: Build multi-step prompt chain (4 steps)
- [ ] P5-T3: Build structured output parser and validator
- [ ] P5-T4: Create GitHub Actions workflow

### Week 10
- [ ] P5-T5: Build Python script (fetch diff, run chain, post comment)
- [ ] P5-T6: Add cost guard — skip if diff over 500 lines

### Weeks 10–11
- [ ] P5-T7: Eval — run on 10 past PRs and score review quality

### Week 11
- [ ] P5-T8: Tune prompt based on eval results (use PromptOS)

### Week 12
- [ ] P5-T9: Publish bot as open source with configurable rules file
- [ ] P5-C1: Blog post (include eval table)
