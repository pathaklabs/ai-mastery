# P2-T10: Add Hallucination Detection Eval Loop

> **Goal:** Add a second AI call after every answer that asks "is this answer actually supported by the sources?" — and log the result so you can measure your RAG system's accuracy.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 6
**Labels:** `task`, `p2-rag`

---

## What is hallucination?

An AI model "hallucinates" when it states something as fact that it made up — something not in any source document.

**Example without hallucination detection:**

```
Question:  "What is the transition time for the hallway light?"

Sources retrieved:
  "Automation: Hallway Motion Light. Triggers on motion after sunset.
   Action: light.turn_on on light.hallway. Brightness: 128."
  (No transition time mentioned in any source chunk)

AI answer: "The hallway light has a 2 second transition time."
           ↑ This might be correct if the AI "remembers" it from somewhere,
             or it might be completely made up. You cannot tell.
```

**Example with hallucination detection:**

```
Same answer → Second AI call:
  "Here is the answer: 'The hallway light has a 2 second transition time.'
   Here are the source documents: [chunks shown above]
   Is this answer FULLY supported by these sources? YES or NO + reason."

AI verifier says:
  "NO — the sources mention brightness (128) but do not mention
   a transition time. The 2-second figure is not supported."

System flags: hallucination_detected = True
Logs: question, answer, sources, verification_response
```

This is not a perfect detector — the verifier is also an AI and can be wrong. But it catches obvious cases and gives you a **quality baseline**: "my RAG system gets flagged as possibly hallucinating on X% of questions."

---

## Why this step matters

This percentage is the single most important metric you will produce in this project. It is what turns your RAG system from a demo into something you can reason about:

- 0-10% flag rate: retrieval is probably working well
- 10-30%: common; chunking or retrieval needs tuning
- 30%+: something is wrong; revisit chunking strategy or min_score threshold

Every future blog post about RAG will reference this number.

---

## Prerequisites

- [ ] [P2-T8](p2-t8-query-endpoint.md) complete — `/query` endpoint returning answers with sources
- [ ] Ollama running with a chat model available

---

## Step-by-step instructions

### Step 1 — Create the hallucination detection module

Create `~/projects/rag-brain/hallucination.py`:

```python
"""
Hallucination Detection Module

After an answer is generated, makes a second LLM call to verify:
"Is this answer fully supported by the retrieved source chunks?"

Logs all results for analysis.
"""
import os
import json
import datetime
from pathlib import Path
from llm import ask_ollama

# ─── Configuration ────────────────────────────────────────────────────────────
LOG_FILE = os.getenv("HALLUCINATION_LOG", "logs/hallucination_log.jsonl")
# ─────────────────────────────────────────────────────────────────────────────


def build_verification_prompt(question: str, answer: str, source_texts: list[str]) -> str:
    """
    Build a prompt for the verifier LLM.

    The verifier reads the original question, the generated answer, and
    the source chunks — then decides if the answer is supported.
    """
    sources_combined = "\n\n---\n\n".join(source_texts)

    return f"""You are a strict fact-checker. Your job is to verify whether an answer is supported by provided source documents.

QUESTION THAT WAS ASKED:
{question}

ANSWER TO VERIFY:
{answer}

SOURCE DOCUMENTS USED TO GENERATE THE ANSWER:
{sources_combined}

TASK:
1. Read the answer carefully.
2. Check each factual claim in the answer against the source documents.
3. Respond with EXACTLY one of these two formats:

If FULLY supported:
YES — [one sentence explaining what in the sources supports it]

If NOT fully supported:
NO — [one sentence explaining what the answer claims that is not in the sources]

Your response must start with YES or NO. Do not add anything before YES or NO."""


def detect_hallucination(
    question: str,
    answer: str,
    sources: list[dict],
) -> dict:
    """
    Run the hallucination detection check.

    Args:
        question: The original user question.
        answer:   The generated answer from the RAG system.
        sources:  List of source dicts from the query response
                  (each has 'text', 'file', 'score').

    Returns:
        Dict with:
          - hallucination_detected: bool
          - verification_response: raw response from verifier
          - confidence: 'high' | 'low' (based on how clear YES/NO is)
    """
    if not answer or answer.startswith("I don't know"):
        # No hallucination possible if the system said "I don't know"
        return {
            "hallucination_detected": False,
            "verification_response": "SKIPPED — answer was 'I don't know'",
            "confidence": "high",
        }

    if not sources:
        # No sources = definitely hallucinated (or retrieval failed)
        return {
            "hallucination_detected": True,
            "verification_response": "NO — no source documents were retrieved",
            "confidence": "high",
        }

    # Build source texts list
    source_texts = [s.get("text", s.get("excerpt", "")) for s in sources]
    source_texts = [t for t in source_texts if t]  # filter empty

    if not source_texts:
        return {
            "hallucination_detected": True,
            "verification_response": "NO — source documents have no text content",
            "confidence": "high",
        }

    # Make the verification call
    prompt = build_verification_prompt(question, answer, source_texts)
    verification_response = ask_ollama(prompt)

    # Parse the response
    response_upper = verification_response.strip().upper()

    if response_upper.startswith("YES"):
        hallucination_detected = False
        confidence = "high"
    elif response_upper.startswith("NO"):
        hallucination_detected = True
        confidence = "high"
    else:
        # Ambiguous response — treat as possible hallucination
        hallucination_detected = True
        confidence = "low"

    return {
        "hallucination_detected": hallucination_detected,
        "verification_response": verification_response,
        "confidence": confidence,
    }


def log_result(
    question: str,
    answer: str,
    sources: list[dict],
    hallucination_result: dict,
) -> None:
    """
    Append the detection result to the JSONL log file.
    Each line in the log is one complete detection event.
    """
    log_path = Path(LOG_FILE)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    log_entry = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "question": question,
        "answer": answer,
        "source_count": len(sources),
        "source_files": [s.get("file", "unknown") for s in sources],
        "hallucination_detected": hallucination_result["hallucination_detected"],
        "confidence": hallucination_result["confidence"],
        "verification_response": hallucination_result["verification_response"],
    }

    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(log_entry) + "\n")
```

---

### Step 2 — Wire hallucination detection into the query endpoint

Update `~/projects/rag-brain/main.py` to call detection on every query:

```python
# Add this import at the top of main.py:
from hallucination import detect_hallucination, log_result

# Update the QueryResponse model to include hallucination info:
class QueryResponse(BaseModel):
    question: str
    answer: str
    sources: list[SourceCitation]
    source_count: int
    model_used: str
    hallucination_check: dict | None = None  # NEW


# Update the query endpoint — replace the return statement at the end:
@app.post("/query", response_model=QueryResponse)
async def query(request: QueryRequest):
    # ... (all existing code stays the same until the end) ...

    # Build sources list (same as before)
    sources = [
        SourceCitation(
            file=r["metadata"].get("filename", r["source"]),
            score=r.get("rerank_score", r["score"]),
            excerpt=r["text"][:300],
        )
        for r in results
    ]

    # --- NEW: Hallucination detection ---
    sources_for_detection = [
        {"text": r["text"], "file": r["metadata"].get("filename", ""), "score": r["score"]}
        for r in results
    ]

    hallucination_result = detect_hallucination(
        question=question,
        answer=answer,
        sources=sources_for_detection,
    )

    # Log every result (including non-hallucinations)
    log_result(
        question=question,
        answer=answer,
        sources=sources_for_detection,
        hallucination_result=hallucination_result,
    )

    return QueryResponse(
        question=question,
        answer=answer,
        sources=sources,
        source_count=len(sources),
        model_used=os.getenv("CHAT_MODEL", "llama3"),
        hallucination_check=hallucination_result,  # NEW
    )
```

---

### Step 3 — Test hallucination detection manually

Create `~/projects/rag-brain/test_hallucination.py`:

```python
"""
Test hallucination detection with known cases.
Run: python test_hallucination.py
"""
from hallucination import detect_hallucination

# ─── Test 1: Supported answer — should return hallucination_detected=False ───
print("TEST 1: Well-supported answer")
result = detect_hallucination(
    question="Which entity does the hallway automation control?",
    answer="The hallway automation controls light.hallway.",
    sources=[
        {
            "text": "Action: light.turn_on on light.hallway. Transition: 2 seconds.",
            "file": "automations.yaml",
            "score": 0.94,
        }
    ],
)
print(f"  Hallucination detected: {result['hallucination_detected']}")
print(f"  Response: {result['verification_response']}")
print(f"  Expected: False\n")

# ─── Test 2: Unsupported claim — should return hallucination_detected=True ──
print("TEST 2: Answer with unsupported claim")
result = detect_hallucination(
    question="What transition time does the hallway automation use?",
    answer="The hallway light has a 5 second transition time.",
    sources=[
        {
            "text": "Action: light.turn_on on light.hallway. Brightness: 128.",
            "file": "automations.yaml",
            "score": 0.88,
        }
    ],
)
print(f"  Hallucination detected: {result['hallucination_detected']}")
print(f"  Response: {result['verification_response']}")
print(f"  Expected: True (5 seconds not mentioned in source)\n")

# ─── Test 3: "I don't know" answer — should skip detection ─────────────────
print("TEST 3: 'I don't know' answer")
result = detect_hallucination(
    question="What is the weather today?",
    answer="I don't know — I couldn't find this in your files.",
    sources=[],
)
print(f"  Hallucination detected: {result['hallucination_detected']}")
print(f"  Response: {result['verification_response']}")
print(f"  Expected: False (system correctly said 'I don't know')\n")
```

```bash
python test_hallucination.py
```

---

### Step 4 — Create an analysis script for the log

Create `~/projects/rag-brain/analyze_hallucinations.py`:

```python
"""
Analyze the hallucination detection log.
Run: python analyze_hallucinations.py

Use this after running 20+ queries to see your RAG quality baseline.
"""
import json
from pathlib import Path

LOG_FILE = "logs/hallucination_log.jsonl"

log_path = Path(LOG_FILE)
if not log_path.exists():
    print(f"No log file found at {LOG_FILE}.")
    print("Ask some questions first using the API or chat UI.")
    exit(0)

entries = []
with open(log_path, "r") as f:
    for line in f:
        line = line.strip()
        if line:
            entries.append(json.loads(line))

if not entries:
    print("Log file is empty.")
    exit(0)

total = len(entries)
detected = sum(1 for e in entries if e["hallucination_detected"])
skipped = sum(1 for e in entries if "SKIPPED" in e.get("verification_response", ""))
high_conf = sum(1 for e in entries if e.get("confidence") == "high")

print("=" * 60)
print("HALLUCINATION DETECTION ANALYSIS")
print("=" * 60)
print(f"Total queries analyzed: {total}")
print(f"Hallucinations detected: {detected} ({100*detected/total:.1f}%)")
print(f"Skipped (I don't know): {skipped}")
print(f"High-confidence verdicts: {high_conf} ({100*high_conf/total:.1f}%)")
print()

# Show all detected hallucinations
hallucinations = [e for e in entries if e["hallucination_detected"]]
if hallucinations:
    print(f"DETECTED HALLUCINATIONS ({len(hallucinations)}):")
    print("-" * 60)
    for e in hallucinations:
        print(f"Q: {e['question']}")
        print(f"A: {e['answer'][:150]}...")
        print(f"Verifier: {e['verification_response'][:200]}")
        print()
else:
    print("No hallucinations detected in the log.")

print("=" * 60)
print(f"RAG QUALITY BASELINE: {100*detected/total:.1f}% hallucination rate")
print("Write this number in your build log and blog post.")
print("=" * 60)
```

```bash
# First: make 20+ queries via the chat UI or API
# Then run:
python analyze_hallucinations.py
```

---

### Step 5 — Run your baseline experiment

Ask at least 20 questions using the chat UI. Mix of:

- Questions where you know the answer is in your files (10+)
- Questions where the answer is NOT in your files (5+)
- Edge cases: vague questions, partial information (5+)

Then run `python analyze_hallucinations.py` and record the output in your build log.

---

## Visual overview

```
Normal RAG query (P2-T8):
┌──────────────────────────────────────────────────────┐
│  Question → Retrieve → Generate Answer → Return      │
└──────────────────────────────────────────────────────┘

With hallucination detection (P2-T10):
┌──────────────────────────────────────────────────────┐
│  Question → Retrieve → Generate Answer               │
│                              │                       │
│                              ▼  Second LLM call      │
│                     "Is this answer supported        │
│                      by these sources?"              │
│                              │                       │
│                    YES       │      NO               │
│                    ┌─────────┴──────────┐            │
│                    ▼                    ▼            │
│            hallucination=False  hallucination=True   │
│                    │                    │            │
│                    └─────────┬──────────┘            │
│                              │                       │
│                         Log to JSONL                 │
│                              │                       │
│                         Return response              │
│                         (with hallucination_check)   │
└──────────────────────────────────────────────────────┘

logs/hallucination_log.jsonl (one JSON object per line):
{
  "timestamp": "2026-04-06T14:23:01Z",
  "question": "What transition time does the hallway automation use?",
  "answer": "The transition is 2 seconds.",
  "source_count": 2,
  "source_files": ["automations.yaml"],
  "hallucination_detected": false,
  "confidence": "high",
  "verification_response": "YES — the source mentions 'Transition: 2 seconds.'"
}
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"After running 20+ queries, what is your hallucination detection rate? What types of questions triggered detections most often — questions with good retrieval, bad retrieval, or out-of-scope questions? What does this tell you about which part of your pipeline needs the most improvement?"**
>
> This rate is your RAG quality baseline. It goes in your blog post.

---

## Done when

- [ ] `hallucination.py` created with `detect_hallucination()` and `log_result()`
- [ ] `python test_hallucination.py` passes all 3 test cases
- [ ] `main.py` updated — every `/query` response includes `hallucination_check`
- [ ] `logs/hallucination_log.jsonl` being written after each query
- [ ] 20+ queries run via UI or API
- [ ] `python analyze_hallucinations.py` prints a summary with detection rate
- [ ] Baseline rate recorded in build log
- [ ] Learning checkpoint answered

---

## Next step

→ [P2-US4: Publish your P2 learnings](p2-us4-content-publish.md)
