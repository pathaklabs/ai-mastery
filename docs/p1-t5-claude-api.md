# P1-T5: Integrate Claude API with Streaming

> **Goal:** Add a FastAPI endpoint that sends a prompt to Claude, streams the response, and returns token counts, latency, and model version.

**Part of:** [P1-US2: Multi-Model Testing](p1-us2-multi-model-testing.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 2
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are connecting PromptOS to the Anthropic Claude API. A new FastAPI endpoint will accept a prompt body and a model name, call Claude, and return the output text along with how many tokens were used, how long it took, and a cost estimate. You will store the API key in `.env` only — never in source code.

---

## Why this step matters

This is the first time you make a real, paid API call from your own system. Learning to track token usage and latency from the start turns cost awareness from an afterthought into a habit. Every production AI system in the world tracks this — you are building that muscle now.

---

## Prerequisites

- [ ] P1-T3 is complete — the prompts API is working
- [ ] You have an Anthropic API key (from [console.anthropic.com](https://console.anthropic.com))
- [ ] `.env` has `ANTHROPIC_API_KEY=sk-ant-...`
- [ ] The `anthropic` package is in `requirements.txt` and installed

---

## Step-by-step instructions

### Step 1 — Verify the Anthropic SDK is installed

Inside the running API container:

```bash
podman exec -it 01-promptos_api_1 python -c "import anthropic; print(anthropic.__version__)"
```

If it errors, rebuild the container:

```bash
podman compose down
podman compose up --build
```

---

### Step 2 — Write the Claude service module

Create `api/claude_service.py`:

```python
import os
import time
from typing import Optional

import anthropic

# Read API key from environment — never hardcode this
_client = None


def get_client() -> anthropic.Anthropic:
    """Return a cached Anthropic client."""
    global _client
    if _client is None:
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY is not set in environment")
        _client = anthropic.Anthropic(api_key=api_key)
    return _client


# Current pricing as of 2025 (USD per million tokens)
# Update these when Anthropic changes pricing
PRICING = {
    "claude-sonnet-4-6": {"input": 3.00, "output": 15.00},
    "claude-3-5-haiku-20241022": {"input": 0.80, "output": 4.00},
    "claude-opus-4-5": {"input": 15.00, "output": 75.00},
}


def estimate_cost(model: str, input_tokens: int, output_tokens: int) -> float:
    """Return estimated cost in USD for a given call."""
    prices = PRICING.get(model, {"input": 3.00, "output": 15.00})
    return (input_tokens * prices["input"] + output_tokens * prices["output"]) / 1_000_000


def run_claude(
    prompt_text: str,
    model: str = "claude-sonnet-4-6",
    max_tokens: int = 1024,
    system: Optional[str] = None,
) -> dict:
    """
    Run a prompt through the Claude API and return structured output.

    Returns a dict with:
      output        - the text response
      model         - which model was used
      input_tokens  - tokens in the prompt
      output_tokens - tokens in the response
      latency_ms    - milliseconds the API call took
      cost_usd      - estimated cost in US dollars
    """
    client = get_client()

    messages = [{"role": "user", "content": prompt_text}]

    kwargs = {
        "model": model,
        "max_tokens": max_tokens,
        "messages": messages,
    }
    if system:
        kwargs["system"] = system

    start = time.monotonic()

    try:
        response = client.messages.create(**kwargs)
    except anthropic.AuthenticationError:
        raise ValueError("Invalid ANTHROPIC_API_KEY — check your .env file")
    except anthropic.RateLimitError:
        raise RuntimeError("Claude API rate limit hit — wait a moment and try again")
    except anthropic.APIError as e:
        raise RuntimeError(f"Claude API error: {e}")

    latency_ms = int((time.monotonic() - start) * 1000)

    output_text = response.content[0].text if response.content else ""
    input_tokens = response.usage.input_tokens
    output_tokens = response.usage.output_tokens
    cost = estimate_cost(model, input_tokens, output_tokens)

    return {
        "output": output_text,
        "model": response.model,        # actual model used (may differ from requested)
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "latency_ms": latency_ms,
        "cost_usd": round(cost, 6),
    }
```

---

### Step 3 — Write the schemas for the run endpoint

Add to `schemas/prompt.py`:

```python
# Add these at the bottom of the file

class RunRequest(BaseModel):
    """Body for POST /run"""
    prompt_version_id: Optional[int] = None   # run a saved version
    body: Optional[str] = None                 # or run an ad-hoc prompt body
    models: List[str] = Field(
        default=["claude-sonnet-4-6"],
        description="List of model names to run"
    )
    max_tokens: int = Field(default=1024, ge=1, le=4096)

    def get_body(self) -> str:
        if self.body:
            return self.body
        raise ValueError("Must provide either prompt_version_id or body")


class ModelResult(BaseModel):
    """Result from one model run"""
    model: str
    output: str
    input_tokens: Optional[int] = None
    output_tokens: Optional[int] = None
    latency_ms: int
    cost_usd: Optional[float] = None
    error: Optional[str] = None   # set if the model call failed


class RunResponse(BaseModel):
    """Response for POST /run"""
    prompt_body: str
    results: List[ModelResult]
```

---

### Step 4 — Write the run API endpoint

Create `api/run.py`:

```python
import asyncio
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.claude_service import run_claude
from db.session import get_db
from models.prompt import PromptVersion
from schemas.prompt import ModelResult, RunRequest, RunResponse

router = APIRouter(prefix="/run", tags=["run"])

# Registry of known model runners
# Add Ollama runner in P1-T6
def get_runner(model: str):
    """Return the correct function for a given model name."""
    if model.startswith("claude"):
        return lambda prompt, m=model: run_claude(prompt, model=m)
    raise ValueError(f"Unknown model: {model}. Add it to get_runner().")


async def run_model_async(prompt_body: str, model: str) -> ModelResult:
    """Run a model call in a thread pool so async FastAPI stays unblocked."""
    runner = get_runner(model)
    try:
        # run_claude is synchronous (blocking) — run in executor to not block event loop
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(None, runner, prompt_body)
        return ModelResult(**result)
    except Exception as e:
        return ModelResult(
            model=model,
            output="",
            latency_ms=0,
            error=str(e),
        )


@router.post("/", response_model=RunResponse)
async def run_prompt(payload: RunRequest, db: AsyncSession = Depends(get_db)):
    """
    Run a prompt body (or a saved prompt version) against one or more models.
    Returns all model results in parallel.
    """
    # Resolve the prompt body
    if payload.prompt_version_id:
        result = await db.execute(
            select(PromptVersion).where(PromptVersion.id == payload.prompt_version_id)
        )
        version = result.scalar_one_or_none()
        if not version:
            raise HTTPException(status_code=404, detail="Prompt version not found")
        prompt_body = version.body
    elif payload.body:
        prompt_body = payload.body
    else:
        raise HTTPException(status_code=400, detail="Provide either prompt_version_id or body")

    # Run all models in parallel
    tasks = [run_model_async(prompt_body, model) for model in payload.models]
    results: List[ModelResult] = await asyncio.gather(*tasks)

    return RunResponse(prompt_body=prompt_body, results=results)
```

---

### Step 5 — Register the run router in main.py

Add to `main.py`:

```python
from api.run import router as run_router
app.include_router(run_router)
```

---

### Step 6 — Test it

Restart the API:

```bash
podman compose restart api
```

Test with the Swagger UI at `http://localhost:8000/docs`, or with curl:

```bash
curl -X POST http://localhost:8000/run \
  -H "Content-Type: application/json" \
  -d '{
    "body": "Explain async/await in Python in 3 sentences.",
    "models": ["claude-sonnet-4-6"]
  }'
```

Expected response:

```json
{
  "prompt_body": "Explain async/await in Python in 3 sentences.",
  "results": [
    {
      "model": "claude-sonnet-4-6",
      "output": "Async/await is Python's way of writing code that...",
      "input_tokens": 15,
      "output_tokens": 87,
      "latency_ms": 823,
      "cost_usd": 0.000045,
      "error": null
    }
  ]
}
```

---

## Visual overview

```
POST /run
    │
    ▼
Resolve prompt body
(from payload.body or from saved PromptVersion)
    │
    ▼
asyncio.gather() — all models run in parallel
    │
    ├──────────────────────────────────────┐
    ▼                                      ▼
run_claude("claude-sonnet-4-6")        (P1-T6 will add Ollama here)
    │  uses Anthropic SDK                  │
    │  blocks in thread pool              │
    ▼                                      ▼
ModelResult                           ModelResult
  model, output,                        model, output,
  tokens, latency,                      latency,
  cost_usd                              error (if timeout)
    │                                      │
    └──────────────────┬───────────────────┘
                       ▼
              RunResponse (all results)
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> After your first real Claude API call, look at the `input_tokens` and `output_tokens` in the response.
>
> Calculate the actual cost: go to [anthropic.com/pricing](https://www.anthropic.com/pricing) and plug in the numbers.
>
> Write the exact cost in your build log. Now estimate: if you run this prompt 1,000 times a day, what does that cost per month? Write that number too.
>
> Cost awareness is not optional in production AI systems.

---

## Done when

- [ ] `POST /run` endpoint exists and is registered in `main.py`
- [ ] A call to Claude with a prompt body returns output text, token counts, latency, and cost
- [ ] API key is read from `.env` only — not hardcoded anywhere in source
- [ ] Authentication errors and rate limit errors return readable error messages (not 500 crashes)
- [ ] The response `model` field reflects the actual model name returned by Anthropic

---

## Next step

→ After this, do [P1-T6: Integrate Local Ollama Models](p1-t6-ollama-integration.md)
