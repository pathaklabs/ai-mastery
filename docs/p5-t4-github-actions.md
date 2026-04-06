# P5-T4: Create GitHub Actions Workflow

> **Goal:** Create the YAML file that tells GitHub to run your review script automatically every time a pull request is opened or updated.

**Part of:** [P5-US1: Build an Automated PR Review Bot](p5-us1-review-bot.md)
**Week:** 9
**Labels:** `task`, `p5-codereview`

---

## What you are doing

You are creating a file at `.github/workflows/ai-review.yml` in your repository. This file is read by GitHub Actions — GitHub's built-in automation system.

GitHub Actions watches for events (like "a PR was opened") and runs a series of steps in response. Each run happens inside a clean Ubuntu virtual machine that GitHub provides. Your script runs inside that machine, does its job, then the machine is deleted.

Think of it as: every time someone opens a PR, GitHub spins up a fresh computer, installs your dependencies, runs your Python script, and then throws the computer away.

---

## Why this step matters

Without this file, the review chain only runs when you trigger it manually. With this file, it runs automatically on every PR — forever. This is what transforms a script into a bot.

Understanding GitHub Actions also unlocks almost every other automation in modern software engineering: deployments, tests, releases, and more.

---

## Prerequisites

- [ ] `review_chain.py` completed (P5-T2)
- [ ] `review_parser.py` completed (P5-T3)
- [ ] GitHub repository set up
- [ ] `ANTHROPIC_API_KEY` will be stored as a GitHub secret (instructions below)

---

## Step-by-step instructions

### Step 1 — Understand the key concepts

Before writing the YAML, understand three things:

**What is a GitHub Actions workflow?**
A YAML file in `.github/workflows/`. GitHub reads it and runs it when the trigger event fires.

**What is a "runner"?**
The machine that runs your workflow. You will use `ubuntu-latest` — a fresh Ubuntu VM provided by GitHub for free (with usage limits).

**What is a GitHub Secret?**
A way to store sensitive values (like API keys) so they are never visible in your code. You set them in the repository settings. Inside the workflow, you reference them as `${{ secrets.SECRET_NAME }}`.

```
GitHub repository
│
├── .github/
│   └── workflows/
│       └── ai-review.yml   ← this file
│
├── projects/05-codereview/
│   ├── review.py           ← main script (P5-T5)
│   ├── review_chain.py     ← chain (P5-T2)
│   ├── review_parser.py    ← parser (P5-T3)
│   └── review-rubric.yml   ← rubric (P5-T1)
│
└── ...
```

### Step 2 — Add the API key as a GitHub Secret

Before the workflow can use `ANTHROPIC_API_KEY`, you must store it as a secret:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `ANTHROPIC_API_KEY`
5. Value: your Anthropic API key
6. Click **Add secret**

The secret is now available inside workflows as `${{ secrets.ANTHROPIC_API_KEY }}`. It is never shown in logs.

### Step 3 — Create the workflow directory

```bash
mkdir -p .github/workflows
```

### Step 4 — Create the workflow file

Create `.github/workflows/ai-review.yml`:

```yaml
# .github/workflows/ai-review.yml
#
# AI Code Review Bot — runs on every pull request
# Triggered when a PR is opened or when new commits are pushed to it.

name: AI Code Review

on:
  pull_request:
    # "opened"       = new PR created
    # "synchronize"  = new commits pushed to an existing PR
    types: [opened, synchronize]

jobs:
  review:
    name: Run AI Review
    runs-on: ubuntu-latest   # fresh Ubuntu VM provided by GitHub

    # Permissions this job needs.
    # "write" on pull-requests lets the bot post comments.
    permissions:
      pull-requests: write
      contents: read

    steps:
      # ── Step 1: Check out the code ───────────────────────────────────────
      # This clones your repository into the Ubuntu VM.
      # fetch-depth: 0 means "clone full history" — needed to get the diff.
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # ── Step 2: Set up Python ─────────────────────────────────────────────
      # Installs Python 3.11 on the Ubuntu VM.
      - name: Set up Python 3.11
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      # ── Step 3: Cache pip packages ────────────────────────────────────────
      # Speeds up subsequent runs by caching downloaded packages.
      # Cache key includes the requirements file hash — if requirements
      # change, the cache is invalidated automatically.
      - name: Cache pip packages
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('projects/05-codereview/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      # ── Step 4: Install Python dependencies ──────────────────────────────
      - name: Install dependencies
        run: |
          pip install --upgrade pip
          pip install -r projects/05-codereview/requirements.txt

      # ── Step 5: Run the AI review script ─────────────────────────────────
      # Environment variables are passed to the script.
      # GITHUB_TOKEN is automatically available — GitHub generates it.
      # ANTHROPIC_API_KEY comes from the repository secret you set up.
      - name: Run AI review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN:      ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER:         ${{ github.event.number }}
          REPO:              ${{ github.repository }}
          BASE_SHA:          ${{ github.event.pull_request.base.sha }}
          HEAD_SHA:          ${{ github.event.pull_request.head.sha }}
        run: |
          cd projects/05-codereview
          python review.py
```

### Step 5 — Create a requirements.txt file

Create `projects/05-codereview/requirements.txt`:

```
anthropic>=0.40.0
requests>=2.31.0
pyyaml>=6.0.1
```

### Step 6 — Commit and push

```bash
git add .github/workflows/ai-review.yml
git add projects/05-codereview/requirements.txt
git commit -m "feat: add GitHub Actions workflow for AI PR review"
git push
```

### Step 7 — Test by opening a PR

Create a test branch, make a small change, and open a PR:

```bash
git checkout -b test/ai-review-bot
echo "# test" >> README.md
git add README.md
git commit -m "test: trigger AI review bot"
git push origin test/ai-review-bot
```

Then open a PR on GitHub from this branch. Watch the **Actions** tab — you should see the workflow start within seconds.

---

## Visual overview

```
Developer opens PR (or pushes new commits to PR)
                │
                ▼
  GitHub detects: pull_request event (opened | synchronize)
                │
                ▼
  GitHub reads: .github/workflows/ai-review.yml
                │
                ▼
  GitHub starts a fresh Ubuntu VM ("runner")
                │
                ▼
  Runner executes steps in order:

    Step 1: actions/checkout@v4
    ├── Clones repository into /home/runner/work/
    └── Full history available (fetch-depth: 0)

    Step 2: actions/setup-python@v5
    └── Python 3.11 installed

    Step 3: actions/cache@v4
    └── Pip cache restored (if available)

    Step 4: pip install
    └── anthropic, requests, pyyaml installed

    Step 5: python review.py
    ├── Reads: ANTHROPIC_API_KEY, GITHUB_TOKEN, PR_NUMBER, REPO
    ├── Fetches PR diff from GitHub API
    ├── Runs review chain (P5-T2)
    ├── Parses output (P5-T3)
    └── Posts comment on PR

                │
                ▼
  Runner is deleted (clean slate for next run)
                │
                ▼
  Developer sees review comment on their PR
```

---

## Understanding the environment variables

| Variable | Source | What it is |
|----------|--------|-----------|
| `ANTHROPIC_API_KEY` | Repository secret | Your Anthropic API key |
| `GITHUB_TOKEN` | Automatic | Token GitHub generates for each run — allows posting comments |
| `PR_NUMBER` | `github.event.number` | The PR number (e.g., 47) |
| `REPO` | `github.repository` | Owner and repo name (e.g., `pathak-labs/my-repo`) |
| `BASE_SHA` | `github.event.pull_request.base.sha` | The commit the PR branches from |
| `HEAD_SHA` | `github.event.pull_request.head.sha` | The latest commit in the PR |

---

## Troubleshooting common issues

**Workflow does not appear in the Actions tab**
- Make sure the file is at exactly `.github/workflows/ai-review.yml`
- Make sure it is on the main branch (or the branch the PR targets)

**"Resource not accessible by integration" error when posting comment**
- The `permissions: pull-requests: write` block is missing or misindented

**"ANTHROPIC_API_KEY not found" error**
- The secret was not set, or the name does not match exactly (case-sensitive)

**Workflow runs but review.py is not found**
- Check the `run:` step — it does `cd projects/05-codereview` before running `python review.py`

---

## Done when

- [ ] `.github/workflows/ai-review.yml` committed to repository
- [ ] `projects/05-codereview/requirements.txt` committed
- [ ] `ANTHROPIC_API_KEY` stored as GitHub Actions secret
- [ ] Test PR opened and workflow appears in the Actions tab (even if it fails — that is okay for now)

---

## Next step

→ [P5-T5: Build Python Review Script](p5-t5-python-script.md)
