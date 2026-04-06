# P5-T1: Define Review Rubric as Structured Prompt Spec

> **Goal:** Write a YAML file that defines exactly what the bot should check, what good looks like, what bad looks like, and how severe each problem is.

**Part of:** [P5-US1: Build an Automated PR Review Bot](p5-us1-review-bot.md)
**Week:** 8
**Labels:** `task`, `p5-codereview`

---

## What you are doing

You are creating a YAML file called `review-rubric.yml`. This file is the bot's "brain" — it defines every category of code quality the bot will check, with real examples of good and bad code in each category.

Think of it as writing a code review handbook, but structured so that a language model can read it and apply it consistently.

This is the same discipline you used in P1 when you wrote prompt specs for PromptOS. The difference is the audience: in P1, the spec shaped how the AI generates text. Here, the spec shapes how the AI evaluates code.

---

## Why this step matters

The quality of the rubric is the quality of every review the bot will ever produce. A vague rubric produces vague reviews. A precise rubric — with concrete examples — produces specific, actionable feedback.

If the bot gives bad reviews later, the first place to look is this file.

---

## Prerequisites

- [ ] Python environment set up (from earlier projects)
- [ ] A `projects/05-codereview/` folder created in your repository
- [ ] You have thought about what code quality means on your team (take 10 minutes to list categories before writing the YAML)

---

## Step-by-step instructions

### Step 1 — Create the project folder

```bash
mkdir -p projects/05-codereview
cd projects/05-codereview
touch review-rubric.yml
```

### Step 2 — Write the rubric YAML

Open `projects/05-codereview/review-rubric.yml` and write the following. Read each category carefully — this is your team's definition of good code.

```yaml
# review-rubric.yml
# This file defines what the PR review bot checks.
# Each category has: description, severity levels, and examples.
# The bot will quote these examples in its prompts to guide the model.

version: "1.0"

categories:

  - name: Security
    description: >
      Check for common security vulnerabilities including exposed secrets,
      injection risks, and insecure defaults.
    severity:
      error: "Immediate security risk — must fix before merge"
      warning: "Potential security concern — recommend fixing"
      info: "Security best practice suggestion"
    examples:
      good:
        - "API key loaded from environment: os.getenv('API_KEY')"
        - "SQL query uses parameterised inputs: cursor.execute('SELECT * FROM users WHERE id = %s', (user_id,))"
        - "Password hashed with bcrypt before storage"
        - "Secrets stored in GitHub Actions secrets, not in code"
      bad:
        - "API key hardcoded as string: api_key = 'sk-1234abcd'"
        - "Raw string concatenation in SQL: f'SELECT * FROM users WHERE id = {user_id}'"
        - "Password stored as plain text"
        - "Token committed to repository or visible in logs"

  - name: Naming Conventions
    description: >
      Functions, variables, classes, and files follow Python naming standards
      (PEP 8) and project conventions.
    severity:
      error: "Naming that breaks external interfaces (API routes, database column names)"
      warning: "Inconsistent naming that reduces code readability"
      info: "Minor naming improvement suggestion"
    examples:
      good:
        - "Function: get_user_by_id(user_id: int)"
        - "Variable: user_email, access_token, retry_count"
        - "Class: UserAuthService"
        - "Constant: MAX_RETRY_ATTEMPTS = 3"
      bad:
        - "Function: GetUserById() — wrong case, or doGetUser() — vague prefix"
        - "Variable: ue, accessTkn, x — too short or mixed case"
        - "Class: userAuthService or user_auth_service — wrong case for class"
        - "Constant: maxretryattempts — should be SCREAMING_SNAKE_CASE"

  - name: Architecture
    description: >
      Code follows the project's layered architecture.
      Routes handle HTTP. Services handle business logic. Repositories handle data.
      Each layer talks only to the layer below it.
    severity:
      error: "Business logic placed directly in route handler (should be in service layer)"
      warning: "Function does more than one job and should be split"
      info: "Architectural improvement suggestion"
    examples:
      good:
        - "Route handler: calls service function, returns HTTP response"
        - "Service: contains business logic, calls repository"
        - "Repository: only contains database queries"
        - "Each function has a single, clear responsibility"
      bad:
        - "Route handler contains 80+ lines of business logic and database queries"
        - "Service imports Flask/FastAPI directly — it knows about HTTP"
        - "One 200-line function that fetches data, transforms it, and sends email"

  - name: Test Coverage
    description: >
      New code has appropriate tests. Every new function or API endpoint
      should have at minimum a happy-path test. Error paths and edge cases
      should also be tested.
    severity:
      error: "New public API endpoint or exported function has no tests at all"
      warning: "Only happy path tested — missing error cases, empty inputs, or boundary values"
      info: "Additional test coverage suggestion"
    examples:
      good:
        - "test_create_user_success() — happy path"
        - "test_create_user_duplicate_email() — error case"
        - "test_create_user_empty_name() — edge case"
        - "test_get_user_not_found() — 404 case"
      bad:
        - "New /users endpoint with zero test file"
        - "Only test_create_user_success() — no error or edge cases"

  - name: Error Handling
    description: >
      Errors are caught, logged appropriately, and surfaced to callers
      with useful messages. Silent failures and bare except clauses are not allowed.
    severity:
      error: "Bare except that swallows all errors silently"
      warning: "Error caught but not logged, or generic error message that hides root cause"
      info: "Minor error handling improvement"
    examples:
      good:
        - "try/except catches specific exception type: except requests.Timeout"
        - "Error is logged with context: logger.error('Failed to fetch user %s: %s', user_id, e)"
        - "Caller receives useful error: raise ValueError(f'User {user_id} not found')"
      bad:
        - "Bare except: pass — silently swallows all errors"
        - "except Exception as e: print(e) — generic, no context"
        - "return None on error without any logging"
```

### Step 3 — Write a README for the rubric

Create `projects/05-codereview/RUBRIC_README.md` with a plain English explanation of each category. This helps future you (and your readers) understand why each category exists.

### Step 4 — Write in your build log

Answer these questions before moving on:

1. How is defining a review rubric similar to writing a good prompt?
2. How is it different?
3. What category did you almost skip that you are glad you kept?

These answers become your blog content.

---

## Visual overview

```
review-rubric.yml
│
├── version: "1.0"
│
└── categories:
    │
    ├── Security
    │   ├── description: "Check for secrets, injections..."
    │   ├── severity: { error, warning, info }
    │   └── examples: { good: [...], bad: [...] }
    │
    ├── Naming Conventions
    │   ├── description: "PEP 8 and project conventions..."
    │   ├── severity: { error, warning, info }
    │   └── examples: { good: [...], bad: [...] }
    │
    ├── Architecture
    │   └── ...
    │
    ├── Test Coverage
    │   └── ...
    │
    └── Error Handling
        └── ...

This file feeds directly into Step 2 (prompt chain).
Each category becomes a separate focused prompt.
```

---

## How the rubric connects to the prompt chain

```
review-rubric.yml
        │
        │  (P5-T2 reads this file)
        ▼
For each category in rubric:
  Build a prompt that includes:
  - category.description
  - category.examples.good
  - category.examples.bad
  - category.severity
        │
        ▼
Claude evaluates the diff against ONLY that category
(focused, not distracted by other rules)
```

---

## Learning checkpoint

> Same discipline as P1's prompt spec — now applied to production code quality.
>
> In P1, you defined inputs and outputs for a prompt. Here, you are defining rules and examples for an evaluator.
>
> Write in your build log: how is a review rubric similar to a prompt spec? How is it different?

---

## Done when

- [ ] `projects/05-codereview/review-rubric.yml` exists with at least 4 categories
- [ ] Each category has: description, severity levels (error/warning/info), and good + bad examples
- [ ] Build log updated with rubric reflection notes

---

## Next step

→ [P5-T2: Build Multi-Step Prompt Chain](p5-t2-review-chain.md)
