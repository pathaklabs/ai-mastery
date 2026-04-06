# P5-T2: Build Multi-Step Prompt Chain for Code Review

> **Goal:** Build a 4-step prompt chain that summarises the PR, evaluates each rubric category, outputs structured JSON, and formats it as a GitHub markdown comment.

**Part of:** [P5-US1: Build an Automated PR Review Bot](p5-us1-review-bot.md)
**Week:** 9
**Labels:** `task`, `p5-codereview`

---

## What you are doing

You are writing Python code that sends the PR diff through four prompts in sequence. Each prompt does one focused job, then passes its output to the next step.

A "PR diff" is the raw text showing every line that changed in a pull request. Lines starting with `+` were added. Lines starting with `-` were removed. This is what the bot reads.

A "prompt chain" means you call the AI multiple times, where each call builds on the output of the previous one. It is the opposite of stuffing everything into a single prompt.

---

## Why this step matters

This is where the bot gets its intelligence. Without this chain, there is no review — just a trigger with nothing to trigger.

The discipline of chaining prompts also teaches you one of the most important AI engineering skills: **decomposition**. Complex tasks work better when you break them into focused subtasks.

---

## Prerequisites

- [ ] `review-rubric.yml` completed (P5-T1)
- [ ] Anthropic Python SDK installed: `pip install anthropic pyyaml`
- [ ] `ANTHROPIC_API_KEY` set as environment variable

---

## Step-by-step instructions

### Step 1 — Understand WHY one big prompt fails

Before writing any code, write the answer to this question in your build log:

> **Why do you think one big prompt ("review this 400-line diff for security, naming, architecture, tests, and error handling") will produce worse results than four focused prompts?**

Write your hypothesis. Then after you build and test both, verify it.

Here is what you will find:

```
ONE BIG PROMPT:
──────────────────────────────────────────────────────
"Review this diff for: security, naming, architecture,
 tests, error handling, documentation, performance..."

Problems:
  1. Attention is diluted — the model tries to do
     everything at once and does each thing shallowly
  2. Output format is inconsistent — hard to parse
  3. Context window fills up fast on large diffs
  4. One category's findings bleed into another

Result: vague, inconsistent, often misses real issues

MULTI-STEP CHAIN:
──────────────────────────────────────────────────────
Step 1: "What does this PR do?" (no evaluation yet)
Step 2: "Check ONLY security. Here are the rules..."
Step 3: "Check ONLY naming. Here are the rules..."
Step 4: "Format everything as a GitHub comment."

Benefits:
  1. Each step is focused — the model gives full
     attention to ONE job
  2. Output is predictable — JSON from step 2-3,
     markdown from step 4
  3. Easier to debug — if security review is wrong,
     you fix just that step
  4. Easier to extend — add a new category by adding
     one more step

Result: thorough, consistent, parseable
```

### Step 2 — Create the chain file

Create `projects/05-codereview/review_chain.py`:

```python
"""
review_chain.py
Multi-step Claude prompt chain for PR code review.

Steps:
  1. Summarise the PR (no evaluation)
  2. Evaluate each rubric category (one call per category)
  3. Collect all findings into structured JSON
  4. Format as GitHub markdown comment
"""

import os
import json
import yaml
import anthropic

# Initialise the Anthropic client.
# It reads ANTHROPIC_API_KEY from the environment automatically.
client = anthropic.Anthropic()
MODEL = "claude-3-5-haiku-20241022"   # fast and cost-effective for review tasks


def load_rubric(path: str = "review-rubric.yml") -> dict:
    """Load the review rubric from YAML file."""
    with open(path, "r") as f:
        return yaml.safe_load(f)


# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Summarise the PR
# Goal: understand what the PR does before evaluating it.
# We pass ONLY the diff — no rules yet. This gives the model a clean context.
# ─────────────────────────────────────────────────────────────────────────────

SUMMARISE_PROMPT = """You are a senior software engineer reviewing a pull request.

Read this pull request diff carefully and write a 2-3 sentence summary of:
1. What the PR does (the feature or fix it implements)
2. Which files or areas of the codebase it touches

Do NOT evaluate the code yet. Do NOT comment on quality. Just describe the change.

Pull request diff:
{diff}
"""

def step1_summarise(diff: str) -> str:
    """Step 1: Get a plain-English summary of what the PR does."""
    print("Step 1: Summarising PR...")
    response = client.messages.create(
        model=MODEL,
        max_tokens=300,
        messages=[{
            "role": "user",
            "content": SUMMARISE_PROMPT.format(diff=diff)
        }]
    )
    summary = response.content[0].text.strip()
    print(f"  Summary: {summary[:80]}...")
    return summary


# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Evaluate each rubric category
# Goal: focused evaluation — one call per category.
# We include the good/bad examples from the rubric so the model knows
# what your team considers acceptable.
# ─────────────────────────────────────────────────────────────────────────────

CATEGORY_REVIEW_PROMPT = """You are reviewing a pull request specifically for: {category_name}

Rule definition:
{description}

What GOOD code looks like in this category:
{good_examples}

What BAD code looks like in this category:
{bad_examples}

Severity guide:
- error:   {severity_error}
- warning: {severity_warning}
- info:    {severity_info}

Now review this pull request diff for ONLY the "{category_name}" category.
Do not comment on anything outside this category.

Pull request diff:
{diff}

Return your findings as a JSON array. Each finding must have these exact fields:
{{
  "category": "{category_name}",
  "line": <line number as integer, or null if general>,
  "severity": "<error | warning | info>",
  "finding": "<what is wrong — be specific, quote the actual code>",
  "suggestion": "<how to fix it — be concrete>"
}}

If you find no issues, return an empty array: []
Return ONLY the JSON array. No explanation, no markdown code blocks.
"""

def step2_evaluate_category(diff: str, category: dict) -> list[dict]:
    """
    Step 2: Evaluate the diff against a single rubric category.
    Returns a list of findings (may be empty if no issues found).
    """
    good_examples = "\n".join(f"  - {ex}" for ex in category["examples"]["good"])
    bad_examples  = "\n".join(f"  - {ex}" for ex in category["examples"]["bad"])
    severity      = category.get("severity", {})

    prompt = CATEGORY_REVIEW_PROMPT.format(
        category_name    = category["name"],
        description      = category["description"],
        good_examples    = good_examples,
        bad_examples     = bad_examples,
        severity_error   = severity.get("error",   "Must fix before merge"),
        severity_warning = severity.get("warning", "Recommend fixing"),
        severity_info    = severity.get("info",    "Nice to have"),
        diff             = diff
    )

    print(f"  Checking category: {category['name']}...")

    response = client.messages.create(
        model=MODEL,
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )

    raw = response.content[0].text.strip()
    return raw   # raw JSON string — step 3 will parse this


def step2_evaluate_all_categories(diff: str, rubric: dict) -> list[str]:
    """
    Run step 2 for every category in the rubric.
    Returns a list of raw JSON strings (one per category).
    """
    results = []
    for category in rubric["categories"]:
        raw_json = step2_evaluate_category(diff, category)
        results.append(raw_json)
    return results


# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Parse and validate JSON findings
# (This step lives in review_parser.py — see P5-T3)
# ─────────────────────────────────────────────────────────────────────────────


# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Format as GitHub markdown comment
# Goal: take the validated findings JSON and turn it into a readable
# GitHub PR comment with severity-colour-coded table.
# ─────────────────────────────────────────────────────────────────────────────

FORMAT_PROMPT = """You are formatting a code review report as a GitHub pull request comment.

PR Summary:
{summary}

Review findings (JSON):
{findings_json}

Format this as a GitHub markdown comment following these rules:
1. Start with "## AI Code Review" as the heading
2. Include the PR summary under "### Summary"
3. Create a markdown table with columns: Category | Severity | Line | Finding | Suggestion
4. Sort rows: errors first (🔴 ERROR), then warnings (🟡 WARNING), then info (🟢 INFO)
5. If findings_json is empty or has no items, write "No issues found. Good work!"
6. End with a horizontal rule and a note: "_This review was generated automatically._"

Return ONLY the formatted markdown. No extra explanation.
"""

def step4_format_as_markdown(summary: str, all_findings: list[dict]) -> str:
    """
    Step 4: Format findings as a GitHub PR comment.
    Uses Claude to handle the formatting for consistency.
    """
    print("Step 4: Formatting review comment...")
    findings_json = json.dumps(all_findings, indent=2)

    response = client.messages.create(
        model=MODEL,
        max_tokens=2000,
        messages=[{
            "role": "user",
            "content": FORMAT_PROMPT.format(
                summary=summary,
                findings_json=findings_json
            )
        }]
    )
    return response.content[0].text.strip()


# ─────────────────────────────────────────────────────────────────────────────
# MAIN CHAIN: orchestrate all 4 steps
# ─────────────────────────────────────────────────────────────────────────────

def run_review_chain(diff: str, rubric_path: str = "review-rubric.yml") -> str:
    """
    Run the full 4-step review chain.
    Returns a formatted GitHub markdown comment string.
    """
    # Load rubric
    rubric = load_rubric(rubric_path)

    # Step 1: Summarise
    summary = step1_summarise(diff)

    # Step 2: Evaluate each category (returns list of raw JSON strings)
    raw_results = step2_evaluate_all_categories(diff, rubric)

    # Step 3: Parse (imported from review_parser.py — see P5-T3)
    from review_parser import parse_all_findings
    all_findings = parse_all_findings(raw_results)

    # Step 4: Format as markdown
    review_comment = step4_format_as_markdown(summary, all_findings)

    return review_comment


# Quick test — run this file directly to test the chain
if __name__ == "__main__":
    # Minimal test diff
    test_diff = """
+++ b/auth.py
@@ -0,0 +1,15 @@
+import os
+from flask import Flask, request
+
+app = Flask(__name__)
+API_KEY = "sk-1234abcd5678"   # TODO: move to env
+
+def doAuth(u, p):
+    if u == "admin" and p == "password123":
+        return True
+    return False
+
+@app.route('/login', methods=['POST'])
+def login():
+    username = request.form['username']
+    password = request.form['password']
+    if doAuth(username, password):
+        return "Logged in"
+    return "Bad credentials", 401
"""
    result = run_review_chain(test_diff)
    print("\n" + "="*60)
    print("REVIEW OUTPUT:")
    print("="*60)
    print(result)
```

### Step 3 — Test the chain manually

Before wiring it into GitHub Actions, test it locally:

```bash
cd projects/05-codereview
export ANTHROPIC_API_KEY="your-key-here"
python review_chain.py
```

You should see each step log its progress, then a formatted review comment at the end.

### Step 4 — Write in your build log

After testing, answer:
1. Was your hypothesis about one big prompt correct?
2. Which category produced the most useful findings?
3. Which category had false positives (wrong findings)?

---

## Visual overview

```
diff (raw text)
      │
      ▼
┌─────────────────────────────────────────────┐
│  STEP 1: Summarise                          │
│  Prompt: "What does this PR do?"            │
│  Output: 2-3 sentence plain English summary │
└─────────────────────────────────────────────┘
      │ summary
      ▼
┌─────────────────────────────────────────────┐
│  STEP 2: Evaluate categories (loop)         │
│  For each category in rubric:               │
│    Prompt: "Check ONLY [category]..."       │
│    Output: JSON array of findings           │
│                                             │
│   Category 1: Security   → [...findings]   │
│   Category 2: Naming     → [...findings]   │
│   Category 3: Architecture → [...findings] │
│   Category 4: Tests      → [...findings]   │
│   Category 5: Errors     → [...findings]   │
└─────────────────────────────────────────────┘
      │ list of JSON strings
      ▼
┌─────────────────────────────────────────────┐
│  STEP 3: Parse + validate JSON              │
│  (lives in review_parser.py — P5-T3)        │
│  Output: list of validated finding dicts    │
└─────────────────────────────────────────────┘
      │ all_findings (Python list)
      ▼
┌─────────────────────────────────────────────┐
│  STEP 4: Format as GitHub markdown          │
│  Prompt: "Format these findings as a        │
│           GitHub PR comment..."             │
│  Output: Markdown string                    │
└─────────────────────────────────────────────┘
      │
      ▼
  GitHub PR comment (posted by P5-T5)
```

---

## Learning checkpoint

> Before testing, write in your build log: WHY do you think one big prompt fails for code review?
> After testing both approaches, verify your prediction.
> This is how real AI engineers develop intuition — hypothesise, test, update.

---

## Done when

- [ ] `projects/05-codereview/review_chain.py` created with all 4 steps
- [ ] Chain runs locally on the test diff and produces a formatted review comment
- [ ] Each step logs progress so you can see what is happening
- [ ] Build log updated with your multi-step vs. single-prompt experiment results

---

## Next step

→ [P5-T3: Build Structured Output Parser](p5-t3-output-parser.md)
