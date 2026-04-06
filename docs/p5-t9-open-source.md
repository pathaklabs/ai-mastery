# P5-T9: Publish Bot as Open Source with Configurable Rules File

> **Goal:** Package the review bot so any team can install it in minutes with their own custom rules, then publish it to GitHub with a README that explains exactly how.

**Part of:** [P5-US2: Evaluate and Tune Review Bot Quality](p5-us2-eval-quality.md)
**Week:** 12
**Labels:** `task`, `p5-codereview`

---

## What you are doing

Right now, the bot reviews PRs according to YOUR team's rules, defined in YOUR `review-rubric.yml`. The goal of this task is to make the bot configurable — so any team can drop in their own rules file and have the bot review PRs against their standards instead of yours.

You are also writing a README and publishing the project publicly, so developers who find it can set it up without asking you any questions.

---

## Why this step matters

Open source is one of the highest-leverage things you can do as a developer. A good open source tool:
- Demonstrates your skills to anyone who finds it
- Gets you feedback from real users with different use cases
- Compounds in value over time as others star, fork, and improve it

Publishing with a configurable rules file also forces you to think about your design differently: instead of "what works for me," you think "what would work for any team?"

---

## Prerequisites

- [ ] Review bot fully working (P5-T1 through P5-T8 complete)
- [ ] Eval completed and documented (P5-T7)
- [ ] Repository ready to be made public (or a separate public repo created)

---

## Step-by-step instructions

### Step 1 — Design the configurable rules schema

The current `review-rubric.yml` is your specific rubric. You need to make it a schema that teams customise.

Create `projects/05-codereview/review-rules.yml` as the user-facing configurable file:

```yaml
# review-rules.yml
# ─────────────────────────────────────────────────────────────────────────────
# AI PR Review Bot — Custom Rules Configuration
#
# Copy this file into your repository as review-rules.yml and customise it.
# The bot will use these rules instead of the defaults.
#
# Full documentation: https://github.com/your-username/ai-pr-review-bot
# ─────────────────────────────────────────────────────────────────────────────

version: "1.0"

# ── GLOBAL SETTINGS ──────────────────────────────────────────────────────────

settings:
  # Maximum number of changed lines to review.
  # PRs larger than this will get a "too large" message instead of a review.
  max_diff_lines: 500

  # Which Claude model to use. Haiku is fast and cheap; Sonnet is more thorough.
  # Options: claude-3-5-haiku-20241022 | claude-3-5-sonnet-20241022
  model: claude-3-5-haiku-20241022

  # Review event type posted on GitHub.
  # "COMMENT" — neutral review (does not block merge)
  # "REQUEST_CHANGES" — blocks merge until dismissed (use with caution)
  review_event: COMMENT

  # Minimum severity to report. Lower severities are silently dropped.
  # Options: error | warning | info
  min_severity: warning


# ── REVIEW CATEGORIES ────────────────────────────────────────────────────────
# Add, remove, or modify categories to match your team's standards.
# Each category runs as a separate focused AI review pass.
# The more specific your examples, the better the review quality.

categories:

  # ── Security ─────────────────────────────────────────────────────────────
  - name: Security
    enabled: true
    description: >
      Check for common security vulnerabilities: exposed secrets, injection
      risks, insecure defaults, and improper authentication.
    severity:
      error:   "Immediate security risk — must fix before merge"
      warning: "Potential security concern — recommend fixing"
      info:    "Security best practice"
    examples:
      good:
        - "API key loaded from environment: os.getenv('API_KEY')"
        - "SQL query uses parameterised inputs"
        - "Passwords hashed with bcrypt or argon2"
      bad:
        - "API key hardcoded as string: api_key = 'sk-abc123'"
        - "Raw string concatenation in SQL query"
        - "Password stored as plain text"

  # ── Naming Conventions ────────────────────────────────────────────────────
  # Customise these rules for your language and team conventions.
  - name: Naming Conventions
    enabled: true
    description: >
      Functions, variables, classes, and files follow project naming standards.
      Adjust the examples below for your language (Python PEP 8 shown here).
    severity:
      error:   "Naming that breaks external interfaces (API routes, DB columns)"
      warning: "Inconsistent naming that reduces readability"
      info:    "Minor naming improvement"
    examples:
      good:
        - "Function: get_user_by_id(user_id: int)"
        - "Variable: access_token, retry_count"
        - "Class: UserAuthService"
      bad:
        - "Function: GetUserById() or doGetUser()"
        - "Variable: x, accessTkn, u"
        - "Class: userAuthService"
    # Optional: override naming convention for your language
    # convention: snake_case   # python default
    # convention: camelCase    # javascript
    # convention: PascalCase   # C#

  # ── Architecture ─────────────────────────────────────────────────────────
  - name: Architecture
    enabled: true
    description: >
      Code follows the project's layered architecture.
      Business logic in services. Data access in repositories. HTTP in routes.
    severity:
      error:   "Business logic in route handler — should be in service layer"
      warning: "Function does more than one job and should be split"
      info:    "Architecture improvement"
    examples:
      good:
        - "Route calls service, service calls repository"
        - "Each function has a single clear responsibility"
      bad:
        - "Route handler contains 80+ lines of business logic"
        - "Service imports Flask/FastAPI (it knows about HTTP)"

  # ── Test Coverage ─────────────────────────────────────────────────────────
  - name: Test Coverage
    enabled: true
    description: >
      New public functions and API endpoints have appropriate test coverage.
    severity:
      error:   "New API endpoint has no tests at all"
      warning: "Only happy path tested — missing error cases or edge cases"
      info:    "Additional coverage suggestion"
    examples:
      good:
        - "Tests for both success and failure paths"
        - "Edge cases covered: empty input, boundary values"
      bad:
        - "New endpoint with zero test coverage"
        - "Only the success case is tested"

  # ── Error Handling ────────────────────────────────────────────────────────
  - name: Error Handling
    enabled: true
    description: >
      Errors are caught and handled appropriately. Silent failures and
      bare except clauses are not acceptable.
    severity:
      error:   "Bare except that silently swallows errors"
      warning: "Error caught but not logged, or generic message"
      info:    "Minor error handling improvement"
    examples:
      good:
        - "except requests.Timeout as e: logger.error(...)"
        - "Raises descriptive exception: raise ValueError(f'...')"
      bad:
        - "except: pass"
        - "except Exception: return None"

  # ── OPTIONAL: Add your own category ──────────────────────────────────────
  # Uncomment and customise:
  #
  # - name: Documentation
  #   enabled: false
  #   description: >
  #     Public functions and classes have docstrings.
  #   severity:
  #     error:   "Public API function with no docstring"
  #     warning: "Complex function with no explanation"
  #     info:    "Could benefit from inline comments"
  #   examples:
  #     good:
  #       - "def get_user(user_id: int) -> User:\n    \"\"\"Fetch user by ID. Raises ValueError if not found.\"\"\""
  #     bad:
  #       - "def get_user(user_id):\n    ..."
```

### Step 2 — Update the bot to read from `review-rules.yml`

Update `review_chain.py` to read global settings from the rules file:

```python
def load_rubric(path: str = "review-rules.yml") -> dict:
    """Load rules from the configurable review-rules.yml file."""
    with open(path, "r") as f:
        rubric = yaml.safe_load(f)

    # Apply settings to module-level config
    settings = rubric.get("settings", {})
    global MAX_DIFF_LINES, MODEL
    MAX_DIFF_LINES = settings.get("max_diff_lines", 500)
    MODEL = settings.get("model", "claude-3-5-haiku-20241022")

    # Filter to only enabled categories
    rubric["categories"] = [
        cat for cat in rubric.get("categories", [])
        if cat.get("enabled", True)
    ]

    return rubric
```

### Step 3 — Update the GitHub Actions workflow to use the rules file

Teams will put `review-rules.yml` in their repository root. Update the workflow to find it:

```yaml
      - name: Run AI review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN:      ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER:         ${{ github.event.number }}
          REPO:              ${{ github.repository }}
          # Point to the user's rules file (in their repo root)
          RULES_FILE:        ${{ github.workspace }}/review-rules.yml
        run: |
          cd projects/05-codereview
          python review.py
```

Update `review.py` to use this environment variable:

```python
RULES_FILE = os.environ.get("RULES_FILE", "review-rules.yml")
# Pass to run_review_chain:
review_comment = run_review_chain(diff, rubric_path=RULES_FILE)
```

### Step 4 — Write the README

Create `projects/05-codereview/README.md`:

```markdown
# AI PR Review Bot

An automated GitHub Actions bot that reviews pull requests against your team's
engineering standards using Claude AI.

## What it does

Every time a PR is opened or updated, the bot:
1. Reads the changed code
2. Checks it against your custom rules (defined in `review-rules.yml`)
3. Posts a structured review comment with severity levels

Example review comment:

| Category     | Severity    | Line | Finding                          |
|-------------|-------------|------|----------------------------------|
| Security    | 🔴 ERROR    | 42   | API key hardcoded — use env var |
| Tests       | 🟡 WARNING  | —    | No test for error path           |
| Naming      | 🟢 INFO     | 15   | Consider renaming doAuth()       |

## Setup (5 steps)

### 1. Add your API key

In your GitHub repository: **Settings → Secrets and variables → Actions → New secret**

- Name: `ANTHROPIC_API_KEY`
- Value: your Anthropic API key (get one at console.anthropic.com)

### 2. Copy the workflow file

Copy `.github/workflows/ai-review.yml` from this repo into your repository.

### 3. Copy the rules file

Copy `review-rules.yml` into your repository root and customise it for your team.

### 4. Copy the Python scripts

Copy the `projects/05-codereview/` folder (excluding `eval_results/`) into your repository.

### 5. Open a PR

Open a pull request. The bot will run within 60 seconds and post a review comment.

## Customise your rules

Edit `review-rules.yml` to match your team's standards:

```yaml
categories:
  - name: Security
    enabled: true       # set to false to skip this category
    description: "..."
    examples:
      good: [...]
      bad:  [...]
```

Add new categories, disable ones that don't apply, adjust severity levels, and add your own good/bad examples.

## Cost

Using `claude-3-5-haiku` (default), a typical 200-line PR costs approximately $0.005-$0.015 USD.
PRs over 500 lines are automatically skipped with a helpful message.

## Eval results

This bot was evaluated on 10 past PRs:
- Precision: 81% (after prompt tuning)
- Recall: 65%
- Best category: Security
- Weakest category: subtle logic bugs

See [eval_results/EVAL_REPORT.md](eval_results/EVAL_REPORT.md) for the full report.
```

### Step 5 — Clean up before publishing

Before making the repository public or sharing the link:

```bash
# Files to exclude from the public repo
echo "eval_results/" >> .gitignore
echo "review_costs.jsonl" >> .gitignore
echo ".env" >> .gitignore
echo "*.pyc" >> .gitignore
echo "__pycache__/" >> .gitignore
```

Remove any personal information from eval results if sharing those.

---

## Visual overview

```
Your private bot (today)          Configurable open source bot (after this task)
─────────────────────             ──────────────────────────────────────────────
review-rubric.yml                 review-rules.yml
(your specific rules)             (schema any team can fill in)

review_chain.py                   review_chain.py
(hardcoded to your rubric)        (reads from RULES_FILE env var)

.github/workflows/ai-review.yml  .github/workflows/ai-review.yml
(works only in your repo)         (teams copy this into their repos)

                                  README.md
                                  (5-step setup, no questions needed)
```

---

## Done when

- [ ] `review-rules.yml` created with complete schema including at least 5 categories
- [ ] `review_chain.py` reads settings and filters categories from the rules file
- [ ] `review.py` uses `RULES_FILE` environment variable
- [ ] `README.md` created with setup instructions and eval results
- [ ] `.gitignore` updated to exclude cost logs and eval results
- [ ] Repository published (or a public repo created with the bot code)
- [ ] Bot installed in at least one real repository and tested with a live PR

---

## Next step

→ [P5-C1: Write the Blog Post](p5-c1-blog-pr-review.md)
