# P1-T6: Integrate Local Ollama Models

> **Goal:** Connect PromptOS to the Ollama instance running on your homelab, add at least three local models, and handle timeouts gracefully.

**Part of:** [P1-US2: Multi-Model Testing](p1-us2-multi-model-testing.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 2
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are adding support for local AI models to the `/run` endpoint. Ollama exposes a simple REST API on your homelab. You will write a service function that calls it the same way the Claude service does, register the Ollama runner in the model registry, and add graceful timeout handling so a slow or offline homelab does not crash the whole comparison view.

---

## Why this step matters

Running models locally is a real engineering choice — not just a fun experiment. Privacy, cost, and latency trade-offs are central to every AI system design decision. By measuring your own homelab Ollama results alongside Claude, you get concrete data to inform those decisions instead of guessing.

---

## Prerequisites

- [ ] P1-T5 is complete — Claude API integration works
- [ ] Ollama is running on your homelab and accessible from your development machine
- [ ] At least one model is pulled in Ollama (e.g., `ollama pull llama3` on the homelab)
- [ ] `OLLAMA_URL` is set in `.env` (e.g., `http://192.168.1.100:11434`)
- [ ] `httpx` is in `requirements.txt` (installed with the rest of the packages)

---

## Step-by-step instructions

### Step 1 — Verify Ollama is reachable from the API container

First, find your homelab IP address (run on the homelab machine):

```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

Update `.env` with the correct IP:

```
OLLAMA_URL=http://192.168.1.100:11434
```

Now test connectivity from inside the API container:

```bash
podman exec -it 01-promptos_api_1 curl http://192.168.1.100:11434/api/tags
```

Expected response (list of pulled models):

```json
{
  "models": [
    {"name": "llama3:latest", ...},
    {"name": "qwen3:14b", ...},
    {"name": "mistral:latest", ...}
  ]
}
```

If this times out, check that your homelab firewall allows port 11434 from your dev machine.

---

### Step 2 — Write the Ollama service module

Create `api/ollama_service.py`:

```python
import os
import time
from typing import Optional

import httpx

# Default timeout: 120 seconds. Local models can be slow on first load.
OLLAMA_TIMEOUT = 120.0


def get_ollama_url() -> str:
    """Read Ollama URL from environment."""
    url = os.getenv("OLLAMA_URL")
    if not url:
        raise ValueError("OLLAMA_URL is not set in environment")
    return url.rstrip("/")


def list_ollama_models() -> list[str]:
    """Return a list of model names available on the Ollama server."""
    base_url = get_ollama_url()
    try:
        response = httpx.get(f"{base_url}/api/tags", timeout=10.0)
        response.raise_for_status()
        data = response.json()
        return [m["name"] for m in data.get("models", [])]
    except httpx.ConnectError:
        raise RuntimeError(f"Cannot reach Ollama at {base_url} — is it running?")
    except Exception as e:
        raise RuntimeError(f"Error listing Ollama models: {e}")


def run_ollama(
    prompt_text: str,
    model: str = "llama3",
    timeout: float = OLLAMA_TIMEOUT,
    system: Optional[str] = None,
) -> dict:
    """
    Run a prompt through a local Ollama model via the REST API.

    Returns a dict with:
      output     - the text response
      model      - which model was used
      latency_ms - milliseconds the call took
      error      - None on success, error string on failure

    Note: Ollama does not return token counts in the non-streaming response
    by default. We set stream=False for simplicity here.
    """
    base_url = get_ollama_url()

    payload: dict = {
        "model": model,
        "prompt": prompt_text,
        "stream": False,
    }
    if system:
        payload["system"] = system

    start = time.monotonic()

    try:
        response = httpx.post(
            f"{base_url}/api/generate",
            json=payload,
            timeout=timeout,
        )
        response.raise_for_status()
    except httpx.ConnectError:
        return {
            "output": "",
            "model": model,
            "latency_ms": int((time.monotonic() - start) * 1000),
            "error": f"Cannot reach Ollama at {base_url}",
        }
    except httpx.TimeoutException:
        return {
            "output": "",
            "model": model,
            "latency_ms": int(timeout * 1000),
            "error": f"Ollama timed out after {int(timeout)}s — model may be loading",
        }
    except httpx.HTTPStatusError as e:
        return {
            "output": "",
            "model": model,
            "latency_ms": int((time.monotonic() - start) * 1000),
            "error": f"Ollama HTTP error {e.response.status_code}",
        }

    latency_ms = int((time.monotonic() - start) * 1000)
    data = response.json()

    return {
        "output": data.get("response", ""),
        "model": model,
        "latency_ms": latency_ms,
        # Ollama returns eval_count (output tokens) and prompt_eval_count (input tokens)
        "input_tokens": data.get("prompt_eval_count"),
        "output_tokens": data.get("eval_count"),
        "error": None,
    }
```

---

### Step 3 — Register Ollama in the model runner registry

Update `api/run.py` to add the Ollama runner:

```python
# At the top of api/run.py, add:
from api.ollama_service import run_ollama

# Replace the get_runner function with this expanded version:
def get_runner(model: str):
    """Return the correct runner function for a given model name."""
    if model.startswith("claude"):
        return lambda prompt, m=model: run_claude(prompt, model=m)
    
    # Any other model name is treated as an Ollama model
    # e.g., "llama3", "qwen3:14b", "mistral"
    return lambda prompt, m=model: run_ollama(prompt, model=m)
```

The router logic in `run.py` does not need to change — `asyncio.gather` will now run Claude and Ollama in parallel automatically.

---

### Step 4 — Add an endpoint to list available Ollama models

Add to `api/run.py`:

```python
from api.ollama_service import run_ollama, list_ollama_models

@router.get("/models")
async def available_models():
    """List all models available to run."""
    claude_models = [
        "claude-sonnet-4-6",
        "claude-3-5-haiku-20241022",
        "claude-opus-4-5",
    ]
    
    try:
        ollama_models = list_ollama_models()
    except RuntimeError as e:
        ollama_models = []
        ollama_error = str(e)
    else:
        ollama_error = None

    return {
        "claude": claude_models,
        "ollama": ollama_models,
        "ollama_error": ollama_error,
    }
```

---

### Step 5 — Test with both models in parallel

Restart the API:

```bash
podman compose restart api
```

First, check what models are available:

```bash
curl http://localhost:8000/run/models
```

Then run the same prompt on Claude and Llama 3 together:

```bash
curl -X POST http://localhost:8000/run \
  -H "Content-Type: application/json" \
  -d '{
    "body": "Explain async/await in Python in 3 sentences for a beginner.",
    "models": ["claude-sonnet-4-6", "llama3"]
  }'
```

Expected response shape:

```json
{
  "prompt_body": "Explain async/await in Python in 3 sentences for a beginner.",
  "results": [
    {
      "model": "claude-sonnet-4-6",
      "output": "Async/await is...",
      "input_tokens": 17,
      "output_tokens": 89,
      "latency_ms": 812,
      "cost_usd": 0.000046,
      "error": null
    },
    {
      "model": "llama3",
      "output": "In Python, async/await...",
      "input_tokens": 17,
      "output_tokens": 102,
      "latency_ms": 4230,
      "cost_usd": null,
      "error": null
    }
  ]
}
```

Note that both results come back in the same response, but the latency for Ollama will be much higher.

---

### Step 6 — Test timeout handling

Test what happens when Ollama is slow or offline. Set a very short timeout in your test:

In `ollama_service.py`, temporarily change `OLLAMA_TIMEOUT = 1.0` and make a request. You should get:

```json
{
  "model": "llama3",
  "output": "",
  "latency_ms": 1000,
  "error": "Ollama timed out after 1s — model may be loading",
  "cost_usd": null
}
```

Change `OLLAMA_TIMEOUT` back to `120.0` after testing.

---

## Visual overview

```
POST /run  { models: ["claude-sonnet-4-6", "llama3"] }
    │
    ▼
asyncio.gather() — runs both in parallel
    │
    ├───────────────────────────────────────────────────┐
    ▼                                                   ▼
run_claude("claude-sonnet-4-6")               run_ollama("llama3")
    │                                                   │
    │ Anthropic SDK                                     │ httpx.post()
    │ api.anthropic.com                                 │ 192.168.1.100:11434
    │ ~800ms                                            │ ~4000ms
    ▼                                                   ▼
ModelResult                                   ModelResult
  tokens + cost                                no cost (local = free)
  error = null                                 error = null (or timeout msg)
    │                                                   │
    └──────────────────────┬────────────────────────────┘
                           ▼
              RunResponse: both results together

Homelab network:
  ┌─────────────────┐
  │  Dev machine    │
  │  (this laptop)  │──────────────────────────►  Homelab
  │  podman api     │  HTTP :11434               ┌──────────┐
  │  container      │                            │  Ollama  │
  └─────────────────┘                            │  Llama3  │
                                                 │  Qwen3   │
                                                 │  Mistral │
                                                 └──────────┘
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> Run the same prompt through Claude and at least one Ollama model (Llama 3 or Qwen3 14B).
> Record these exact numbers:
> - Claude latency: ___ ms
> - Ollama latency: ___ ms
> - Latency difference: ___x slower
> - Claude cost per call: $___
> - Ollama cost per call: $0.00 (it is free)
>
> Now answer: given these numbers, when would you choose Ollama over Claude in a real project?
> Write 3–5 specific use cases where local models make more sense than cloud.

---

## Done when

- [ ] `GET /run/models` lists both Claude models and available Ollama models
- [ ] `POST /run` with `"models": ["claude-sonnet-4-6", "llama3"]` returns results from both
- [ ] Both results come back in a single response (parallel, not sequential)
- [ ] Timeout errors return a clean error message in the result, not a 500 crash
- [ ] `OLLAMA_URL` is read from `.env` only

---

## Next step

→ After this, do [P1-T7: Build Side-by-Side Model Comparison UI](p1-t7-comparison-ui.md)
