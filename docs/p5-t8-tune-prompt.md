# P5-T8: Tune Prompt Based on Eval Results

> **Goal:** Use the eval report from P5-T7 to make targeted improvements to the review prompts, version those changes in PromptOS (your P1 tool), re-run the same 10 PRs, and compare scores.

**Part of:** [P5-US2: Evaluate and Tune Review Bot Quality](p5-us2-eval-quality.md)
**Week:** 11
**Labels:** `task`, `p5-codereview`

---

## What you are doing

You are treating the review prompt the same way a software engineer treats buggy code: you have a bug report (the eval results), you identify the root cause, you make a targeted change, and you test the fix.

The eval told you what went wrong. This task is where you fix it.

And here is the skill compounding moment: you built PromptOS in P1 specifically to version, test, and compare prompts. Now, in week 11 of the program, you are using your own tool to manage the prompts for a completely different system. Your tools are feeding each other.

---

## Why this step matters

Without this task, the bot is a snapshot — it performs as well as the first prompt you wrote. With this task, the bot gets better because you have a systematic process for improving it.

This is also the task that demonstrates the most important AI engineering habit: **measure, change one thing, measure again.** Not "change everything and hope for the best."

---

## Prerequisites

- [ ] Eval report completed (P5-T7) with documented precision/recall scores
- [ ] PromptOS running (from P1) — you will use it to store and version prompts
- [ ] Clear list of what went wrong from P5-T7's "Prompt changes to try" section

---

## Step-by-step instructions

### Step 1 — Load your current prompts into PromptOS

Open PromptOS (your P1 application). Create a new prompt entry for each of the four prompts in the review chain:

| Prompt name | What it does |
|-------------|-------------|
| `p5-summarise-v1` | Step 1 — summarise the PR |
| `p5-category-review-v1` | Step 2 — evaluate one rubric category |
| `p5-repair-v1` | Parser repair prompt |
| `p5-format-v1` | Step 4 — format as GitHub markdown |

For each one:
1. Copy the prompt text from `review_chain.py`
2. Create a new prompt in PromptOS with the name above
3. Add tags: `p5-codereview`, `v1`
4. Add a note in the description: "Initial version — eval score: 67% precision, 69% recall"

Now you have a baseline snapshot. If any future change makes things worse, you can roll back.

### Step 2 — Identify the highest-impact changes

Look at your eval report's "What to change" section. Prioritise changes that address the most common failure mode.

For example, if your eval showed too many false positives on minor style issues:

```
PROBLEM: Bot flags too many style preferences (inflating FP rate)

ROOT CAUSE: The category-review prompt does not distinguish between
"clear rule violation" and "personal preference"

TARGETED FIX: Add this instruction to the category-review prompt:
"Only flag issues that clearly violate the explicit rules and examples
above. Do not flag personal style preferences. When in doubt, do not flag."
```

Always change one thing at a time. If you change three things and the score improves, you do not know which change helped.

### Step 3 — Create prompt v2 in PromptOS

In PromptOS, open `p5-category-review-v1` and create a new version (`v2`). Make your targeted change.

Example: the category review prompt before and after:

**Before (v1):**
```
You are reviewing a pull request specifically for: {category_name}
...
List every finding. For each finding return: { ... }
Return a JSON array.
```

**After (v2) — with precision-boosting instruction:**
```
You are reviewing a pull request specifically for: {category_name}
...
Important review guidelines:
- Only flag issues that CLEARLY violate the rules and examples above.
- Do not flag personal style preferences or minor nitpicks.
- Do not flag issues in lines you cannot see (outside the diff).
- When in doubt, do NOT include a finding. Fewer accurate findings
  are better than many inaccurate ones.

List your findings. For each finding return: { ... }
Return a JSON array.
```

Save this as `p5-category-review-v2` in PromptOS with a note:
"v2 — added precision guidance. Hypothesis: reduces false positives."

### Step 4 — Update the chain to use the new prompt

In `review_chain.py`, update `CATEGORY_REVIEW_PROMPT` with the v2 text. Keep the v1 text in a comment so you can compare:

```python
# v1 prompt (kept for reference — v1 eval: 67% precision, 69% recall)
# CATEGORY_REVIEW_PROMPT_V1 = """..."""

# v2 prompt (added precision guidance)
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

Important review guidelines:
- Only flag issues that CLEARLY violate the rules and examples above.
- Do not flag personal style preferences or minor nitpicks.
- Do not flag issues in code you cannot see (outside the provided diff).
- When in doubt, do NOT include a finding. Fewer accurate findings
  are better than many inaccurate ones.

Now review this pull request diff for ONLY the "{category_name}" category.

Pull request diff:
{diff}

Return a JSON array. Each finding must have:
{{
  "category": "{category_name}",
  "line": <integer or null>,
  "severity": "<error | warning | info>",
  "finding": "<specific quote from the code + what is wrong>",
  "suggestion": "<concrete fix>"
}}

Return ONLY the JSON array. If no clear violations, return [].
"""
```

### Step 5 — Re-run the eval

Run the eval runner against the same 10 PRs using the updated prompt:

```bash
cd projects/05-codereview
python eval_runner.py --prs 12,34,56,78,90,101,115,132,145,162
```

Save the new outputs to `eval_results_v2/` to keep them separate from v1 results:

```python
# In eval_runner.py, change OUTPUT_DIR for the v2 run:
OUTPUT_DIR = Path("eval_results_v2")
```

### Step 6 — Score the v2 results and compare

Fill in a second table using the same format as your v1 eval report. Then compare:

```markdown
## Before vs. After comparison

| Metric    | v1 (original) | v2 (tuned) | Change |
|-----------|---------------|------------|--------|
| Precision | 67%           | 81%        | +14%   |
| Recall    | 69%           | 65%        | -4%    |
| FP count  | 10            | 5          | -50%   |
| FN count  | 9             | 11         | +22%   |

Interpretation:
- Precision improved significantly — fewer false alarms
- Recall dropped slightly — the stricter guidance made the bot more conservative
- Net effect: better for developer experience (fewer false alarms to ignore)
- Next change: improve recall by making FN categories more specific in rubric
```

### Step 7 — Record everything in PromptOS

In PromptOS, update `p5-category-review-v2`:
- Add the v2 eval scores in the description
- Add a note on what the change was and what it achieved

This is your experiment log. In 6 months, when you want to improve the bot again, you will be able to see exactly what you tried and what the results were.

---

## Visual overview

```
P5-T7 Eval Report
  └── 67% precision, 69% recall
  └── Root cause: too many style-preference FPs
        │
        ▼
PromptOS (your P1 tool)
  └── Load p5-category-review-v1 (baseline)
  └── Create p5-category-review-v2 (targeted fix)
        │
        ▼
review_chain.py updated with v2 prompt
        │
        ▼
eval_runner.py — same 10 PRs, new prompt
  └── outputs saved to eval_results_v2/
        │
        ▼
Manual scoring — same process as P5-T7
        │
        ▼
v2 scores: 81% precision, 65% recall
        │
        ├── Precision improved: success
        └── Recall dropped slightly: next iteration target
        │
        ▼
Update PromptOS with v2 scores
  └── Complete experiment record for both versions
```

---

## The compound effect — this is the point

```
Week 1-4: You built PromptOS (P1)
  A tool to store, version, and compare prompts

Week 5-7: You built the RAG Brain (P2)

Week 8-10: You built the PR Review Bot (P5)
  The bot has prompts that need versioning

Week 11: You use PromptOS to manage the review bot's prompts
  ↑
  Your P1 tool is now being used to improve your P5 system.
  Two tools, built weeks apart, feeding each other.

This is not coincidence — it is the design.
Each project produces something you actually use in the next one.
```

---

## Done when

- [ ] All 4 review chain prompts loaded into PromptOS as v1
- [ ] At least one targeted change identified and implemented as v2
- [ ] Eval re-run on same 10 PRs using v2 prompt
- [ ] Before/after comparison table documented
- [ ] PromptOS updated with v2 eval scores
- [ ] Build log updated with what changed and why

---

## Next step

→ [P5-T9: Publish Bot as Open Source](p5-t9-open-source.md)
