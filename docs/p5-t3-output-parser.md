# P5-T3: Build Structured Output Parser and Validator

> **Goal:** Build a parser that converts the raw JSON strings from the review chain into validated Python objects, with a retry on failure and a plain-text fallback.

**Part of:** [P5-US1: Build an Automated PR Review Bot](p5-us1-review-bot.md)
**Week:** 9
**Labels:** `task`, `p5-codereview`

---

## What you are doing

In P5-T2, each category evaluation step returns a raw string from Claude — ideally a JSON array of findings. But language models are not perfectly reliable JSON generators. Sometimes they wrap the JSON in markdown code blocks. Sometimes they add explanation text before or after. Sometimes the JSON is malformed.

This task builds a parser that:
1. Tries to extract valid JSON from the raw string
2. Validates that each finding has the required fields
3. Retries once if the first parse fails (asking Claude to fix the output)
4. Falls back to plain text if the retry also fails

This is standard defensive programming for AI outputs.

---

## Why this step matters

Without a parser, one malformed response breaks the entire review. With a parser and fallback, the bot degrades gracefully — it might post a less-structured comment, but it never crashes and it never posts nothing.

In production AI systems, "graceful degradation" is a design goal, not an afterthought.

---

## Prerequisites

- [ ] `review_chain.py` completed (P5-T2)
- [ ] `anthropic` and `pyyaml` installed

---

## Step-by-step instructions

### Step 1 — Understand what can go wrong

Claude is instructed to return only a JSON array, but it might return any of these:

```
IDEAL output:
[{"category": "Security", "line": 42, "severity": "error", ...}]

COMMON problem 1 — wrapped in code block:
```json
[{"category": "Security", ...}]
```

COMMON problem 2 — explanation before JSON:
"Here are the security findings I found:
[{"category": "Security", ...}]"

COMMON problem 3 — malformed JSON:
[{"category": "Security", "line": 42, "severity": "error" "finding": "..."}]
                                                          ^ missing comma

COMMON problem 4 — empty string or "No issues found."
```

The parser must handle all of these.

### Step 2 — Create the parser file

Create `projects/05-codereview/review_parser.py`:

```python
"""
review_parser.py
Parses and validates the JSON output from the review chain.

Design:
  1. Try to extract JSON from raw string (handles markdown code blocks, prefixes)
  2. Validate each finding has required fields
  3. If parse fails: retry once with a repair prompt
  4. If retry fails: return plain-text fallback finding
"""

import re
import json
import anthropic

client = anthropic.Anthropic()
MODEL  = "claude-3-5-haiku-20241022"

# Fields every finding must have
REQUIRED_FIELDS = {"category", "severity", "finding", "suggestion"}
VALID_SEVERITIES = {"error", "warning", "info"}


# ─────────────────────────────────────────────────────────────────────────────
# JSON EXTRACTION
# ─────────────────────────────────────────────────────────────────────────────

def extract_json_from_string(raw: str) -> str:
    """
    Try to find a JSON array in a raw string.
    Handles markdown code blocks and leading/trailing text.

    Returns the extracted JSON string, or raises ValueError if none found.
    """
    raw = raw.strip()

    # 1. If it already starts with '[', try it directly
    if raw.startswith("["):
        return raw

    # 2. Strip markdown code blocks: ```json ... ``` or ``` ... ```
    code_block = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", raw)
    if code_block:
        return code_block.group(1).strip()

    # 3. Find the first '[' and last ']' and extract what's between
    start = raw.find("[")
    end   = raw.rfind("]")
    if start != -1 and end != -1 and end > start:
        return raw[start:end + 1]

    # 4. Nothing found — return empty array
    raise ValueError(f"No JSON array found in response: {raw[:200]}")


# ─────────────────────────────────────────────────────────────────────────────
# VALIDATION
# ─────────────────────────────────────────────────────────────────────────────

def validate_finding(finding: dict) -> tuple[bool, str]:
    """
    Validate a single finding dict.
    Returns (is_valid: bool, error_message: str).
    """
    # Check required fields
    missing = REQUIRED_FIELDS - set(finding.keys())
    if missing:
        return False, f"Missing fields: {missing}"

    # Check severity is valid
    if finding["severity"] not in VALID_SEVERITIES:
        return False, f"Invalid severity '{finding['severity']}' — must be error/warning/info"

    # Check finding and suggestion are non-empty strings
    if not finding["finding"].strip():
        return False, "Finding text is empty"

    if not finding["suggestion"].strip():
        return False, "Suggestion text is empty"

    return True, ""


def validate_findings(findings: list) -> list[dict]:
    """
    Validate a list of findings. Returns only valid findings.
    Logs any invalid ones so you can debug them.
    """
    valid = []
    for i, finding in enumerate(findings):
        is_valid, error = validate_finding(finding)
        if is_valid:
            valid.append(finding)
        else:
            print(f"  Warning: Skipping invalid finding {i}: {error}")
            print(f"  Finding was: {finding}")
    return valid


# ─────────────────────────────────────────────────────────────────────────────
# REPAIR (retry once with Claude)
# ─────────────────────────────────────────────────────────────────────────────

REPAIR_PROMPT = """The following string was supposed to be a JSON array of code review findings.
It is malformed or cannot be parsed. Please fix it.

Original string:
{raw}

Return ONLY a valid JSON array. Each item must have these fields:
- "category": string
- "line": integer or null
- "severity": "error", "warning", or "info"
- "finding": string (what is wrong)
- "suggestion": string (how to fix it)

If there are no real findings, return an empty array: []
Return ONLY the JSON array. No explanation.
"""

def repair_json(raw: str) -> list[dict]:
    """
    Ask Claude to repair malformed JSON. Returns list of findings.
    If repair also fails, returns empty list.
    """
    print("  Attempting JSON repair with Claude...")
    try:
        response = client.messages.create(
            model=MODEL,
            max_tokens=1000,
            messages=[{
                "role": "user",
                "content": REPAIR_PROMPT.format(raw=raw[:2000])  # limit input size
            }]
        )
        repaired = response.content[0].text.strip()
        json_str = extract_json_from_string(repaired)
        findings = json.loads(json_str)
        validated = validate_findings(findings)
        print(f"  Repair succeeded: {len(validated)} valid findings")
        return validated
    except Exception as e:
        print(f"  Repair failed: {e}")
        return []


# ─────────────────────────────────────────────────────────────────────────────
# MAIN PARSE FUNCTION
# ─────────────────────────────────────────────────────────────────────────────

def parse_findings(raw: str, category_name: str = "Unknown") -> list[dict]:
    """
    Parse a single category's raw JSON string.

    Flow:
      1. Extract JSON from raw string
      2. Parse JSON
      3. Validate findings
      4. If any step fails: retry once with repair prompt
      5. If repair fails: return a single plain-text fallback finding

    Args:
        raw:           Raw string output from Claude (should be a JSON array)
        category_name: Name of the category being parsed (for error messages)

    Returns:
        List of validated finding dicts (may be empty)
    """
    # Handle empty or "no issues" responses
    if not raw or raw.strip() in ("[]", "No issues found.", "No issues.", "None"):
        return []

    try:
        # Step 1: Extract JSON
        json_str = extract_json_from_string(raw)

        # Step 2: Parse
        findings = json.loads(json_str)

        # Handle case where model returned a single dict instead of array
        if isinstance(findings, dict):
            findings = [findings]

        # Step 3: Validate
        validated = validate_findings(findings)

        print(f"  {category_name}: {len(validated)} findings parsed successfully")
        return validated

    except Exception as e:
        print(f"  {category_name}: Parse failed ({e}). Attempting repair...")

        # Step 4: Retry with repair
        repaired = repair_json(raw)
        if repaired:
            return repaired

        # Step 5: Fallback — preserve the raw text as a plain finding
        print(f"  {category_name}: Using plain-text fallback")
        return [{
            "category":   category_name,
            "line":       None,
            "severity":   "info",
            "finding":    f"Review output could not be parsed. Raw output: {raw[:500]}",
            "suggestion": "Check the review_chain.py output for this category."
        }]


def parse_all_findings(raw_results: list[str], category_names: list[str] = None) -> list[dict]:
    """
    Parse findings from all categories.

    Args:
        raw_results:    List of raw JSON strings (one per category)
        category_names: Optional list of category names for better error messages

    Returns:
        Flat list of all validated findings from all categories
    """
    all_findings = []
    for i, raw in enumerate(raw_results):
        name = category_names[i] if category_names and i < len(category_names) else f"Category {i+1}"
        findings = parse_findings(raw, category_name=name)
        all_findings.extend(findings)

    print(f"\nTotal findings parsed: {len(all_findings)}")
    return all_findings


# ─────────────────────────────────────────────────────────────────────────────
# QUICK TEST
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("Testing parser with various inputs...\n")

    # Test 1: Perfect JSON
    test1 = '[{"category": "Security", "line": 42, "severity": "error", "finding": "Hardcoded API key", "suggestion": "Use os.getenv()"}]'
    print("Test 1 — Perfect JSON:")
    result = parse_findings(test1, "Security")
    print(f"  Result: {result}\n")

    # Test 2: Wrapped in markdown
    test2 = '```json\n[{"category": "Naming", "line": null, "severity": "warning", "finding": "Bad name", "suggestion": "Rename it"}]\n```'
    print("Test 2 — Wrapped in markdown code block:")
    result = parse_findings(test2, "Naming")
    print(f"  Result: {result}\n")

    # Test 3: Empty (no issues found)
    test3 = "[]"
    print("Test 3 — Empty array (no issues):")
    result = parse_findings(test3, "Architecture")
    print(f"  Result: {result}\n")

    # Test 4: Malformed JSON (missing comma)
    test4 = '[{"category": "Tests" "line": 10, "severity": "error", "finding": "No tests", "suggestion": "Add tests"}]'
    print("Test 4 — Malformed JSON (will trigger repair):")
    result = parse_findings(test4, "Tests")
    print(f"  Result: {result}\n")
```

### Step 3 — Run the tests

```bash
cd projects/05-codereview
python review_parser.py
```

You should see:
- Test 1: parsed successfully
- Test 2: extracted from code block, parsed successfully
- Test 3: empty list (no issues)
- Test 4: repair attempted, then succeeds or falls back

### Step 4 — Connect to the chain

Update `review_chain.py` to import and use the parser. In the `run_review_chain` function, the import is already shown:

```python
from review_parser import parse_all_findings

# Get category names for better error messages
category_names = [cat["name"] for cat in rubric["categories"]]

# Parse all findings
all_findings = parse_all_findings(raw_results, category_names)
```

---

## Visual overview

```
raw string from Claude (one per category)
          │
          ▼
┌─────────────────────────────────────────────────┐
│ extract_json_from_string()                       │
│                                                  │
│  Input: '```json\n[...]\n```'                    │
│  Output: '[...]'  ← just the JSON part          │
└─────────────────────────────────────────────────┘
          │
          ▼ (success)     ╳ (failure)
          │                    │
          ▼                    ▼
┌──────────────────┐  ┌────────────────────────┐
│  json.loads()    │  │  repair_json()          │
│  Parse the JSON  │  │  Ask Claude to fix it  │
└──────────────────┘  └────────────────────────┘
          │                    │
          ▼                    ▼ (success)   ╳ (failure)
          │                    │                  │
          ▼                    ▼                  ▼
┌──────────────────────────────┐     ┌────────────────────┐
│  validate_findings()          │     │  plain-text        │
│  Check required fields        │     │  fallback finding  │
│  Check severity values        │     └────────────────────┘
└──────────────────────────────┘
          │
          ▼
  list of validated finding dicts
  → passed to step4_format_as_markdown()
```

---

## Done when

- [ ] `projects/05-codereview/review_parser.py` created
- [ ] All 4 test cases pass when running `python review_parser.py`
- [ ] `review_chain.py` imports and uses `parse_all_findings`
- [ ] Full chain test (`python review_chain.py`) produces a formatted review comment

---

## Next step

→ [P5-T4: Create GitHub Actions Workflow](p5-t4-github-actions.md)
