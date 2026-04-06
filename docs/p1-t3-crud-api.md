# P1-T3: Build CRUD API Endpoints for Prompts

> **Goal:** Build all the API routes for creating, reading, and versioning prompts — including a diff endpoint that shows what changed between two versions.

**Part of:** [P1-US1: Prompt Storage](p1-us1-prompt-storage.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 1
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are building the HTTP API that the React frontend will call. Five endpoints: create a prompt, list all prompts, get one prompt, save a new version of a prompt, and compare two versions to see what text changed. Each endpoint uses a Pydantic schema to validate inputs and shape outputs.

---

## Why this step matters

The API is the contract between your frontend and your database. Getting the endpoints right here means the frontend just calls URLs and gets clean JSON back. The diff endpoint in particular teaches you something important: storing versions as separate rows means you can compare any two at any time — you are not limited to "before/after".

---

## Prerequisites

- [ ] P1-T2 is complete — `prompts`, `prompt_versions`, and `tags` tables exist in PostgreSQL
- [ ] `models/prompt.py` has `Prompt`, `PromptVersion`, and `Tag` classes
- [ ] `db/session.py` has the `AsyncSessionLocal` and `get_db` dependency

---

## Step-by-step instructions

### Step 1 — Write the Pydantic schemas

Pydantic schemas do two things: validate incoming request data, and define the shape of outgoing response data.

Create `schemas/prompt.py`:

```python
from __future__ import annotations

import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


# ── Request schemas (what the API receives) ──────────────────────────────────

class PromptCreate(BaseModel):
    """Body for POST /prompts"""
    title: str = Field(..., min_length=1, max_length=200)
    model_target: Optional[str] = Field(None, max_length=100)
    tags: Optional[str] = Field(None, max_length=500)  # comma-separated
    body: str = Field(..., min_length=1)  # first version's text
    note: Optional[str] = Field(None, max_length=500)  # note for version 1


class PromptVersionCreate(BaseModel):
    """Body for POST /prompts/{id}/versions"""
    body: str = Field(..., min_length=1)
    note: Optional[str] = Field(None, max_length=500)


# ── Response schemas (what the API returns) ───────────────────────────────────

class PromptVersionOut(BaseModel):
    id: int
    prompt_id: int
    body: str
    version_num: int
    note: Optional[str]
    created_at: datetime.datetime

    model_config = {"from_attributes": True}  # Pydantic v2 way to read ORM objects


class PromptOut(BaseModel):
    id: int
    title: str
    model_target: Optional[str]
    tags: Optional[str]
    created_at: datetime.datetime
    versions: List[PromptVersionOut] = []

    model_config = {"from_attributes": True}


class PromptListItem(BaseModel):
    """Lighter response for the list view — no version bodies"""
    id: int
    title: str
    model_target: Optional[str]
    tags: Optional[str]
    created_at: datetime.datetime
    version_count: int

    model_config = {"from_attributes": True}


class DiffOut(BaseModel):
    """Response for the diff endpoint"""
    prompt_id: int
    version_a: int
    version_b: int
    body_a: str
    body_b: str
    diff_lines: List[str]  # unified diff lines
```

---

### Step 2 — Write a simple diff utility

Create `api/diff.py`:

```python
import difflib
from typing import List


def unified_diff(text_a: str, text_b: str, label_a: str = "version_a", label_b: str = "version_b") -> List[str]:
    """
    Return a list of unified diff lines between two strings.
    Each line is prefixed with +, -, or a space.
    """
    lines_a = text_a.splitlines(keepends=True)
    lines_b = text_b.splitlines(keepends=True)
    diff = list(
        difflib.unified_diff(
            lines_a,
            lines_b,
            fromfile=label_a,
            tofile=label_b,
            lineterm="",
        )
    )
    return diff
```

---

### Step 3 — Write the API router

Create `api/prompts.py`:

```python
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from api.diff import unified_diff
from db.session import get_db
from models.prompt import Prompt, PromptVersion
from schemas.prompt import (
    DiffOut,
    PromptCreate,
    PromptListItem,
    PromptOut,
    PromptVersionCreate,
    PromptVersionOut,
)

router = APIRouter(prefix="/prompts", tags=["prompts"])


# ── POST /prompts ─────────────────────────────────────────────────────────────

@router.post("/", response_model=PromptOut, status_code=status.HTTP_201_CREATED)
async def create_prompt(payload: PromptCreate, db: AsyncSession = Depends(get_db)):
    """Create a new prompt and its first version simultaneously."""
    # 1. Create the Prompt record
    prompt = Prompt(
        title=payload.title,
        model_target=payload.model_target,
        tags=payload.tags,
    )
    db.add(prompt)
    await db.flush()  # flush to get the auto-assigned prompt.id

    # 2. Create version 1
    version = PromptVersion(
        prompt_id=prompt.id,
        body=payload.body,
        version_num=1,
        note=payload.note,
    )
    db.add(version)
    await db.flush()

    # 3. Reload with relationships
    result = await db.execute(
        select(Prompt)
        .options(selectinload(Prompt.versions))
        .where(Prompt.id == prompt.id)
    )
    return result.scalar_one()


# ── GET /prompts ──────────────────────────────────────────────────────────────

@router.get("/", response_model=List[PromptListItem])
async def list_prompts(
    search: Optional[str] = Query(None, description="Filter by title substring"),
    tag: Optional[str] = Query(None, description="Filter by tag name"),
    db: AsyncSession = Depends(get_db),
):
    """List all prompts with version count. Supports search and tag filter."""
    # Subquery: count versions per prompt
    version_count_subq = (
        select(PromptVersion.prompt_id, func.count(PromptVersion.id).label("version_count"))
        .group_by(PromptVersion.prompt_id)
        .subquery()
    )

    query = (
        select(
            Prompt.id,
            Prompt.title,
            Prompt.model_target,
            Prompt.tags,
            Prompt.created_at,
            func.coalesce(version_count_subq.c.version_count, 0).label("version_count"),
        )
        .outerjoin(version_count_subq, Prompt.id == version_count_subq.c.prompt_id)
        .order_by(Prompt.created_at.desc())
    )

    if search:
        query = query.where(Prompt.title.ilike(f"%{search}%"))

    if tag:
        query = query.where(Prompt.tags.ilike(f"%{tag}%"))

    result = await db.execute(query)
    rows = result.mappings().all()

    return [PromptListItem(**row) for row in rows]


# ── GET /prompts/{id} ─────────────────────────────────────────────────────────

@router.get("/{prompt_id}", response_model=PromptOut)
async def get_prompt(prompt_id: int, db: AsyncSession = Depends(get_db)):
    """Get a single prompt with all its versions."""
    result = await db.execute(
        select(Prompt)
        .options(selectinload(Prompt.versions))
        .where(Prompt.id == prompt_id)
    )
    prompt = result.scalar_one_or_none()
    if not prompt:
        raise HTTPException(status_code=404, detail=f"Prompt {prompt_id} not found")
    return prompt


# ── POST /prompts/{id}/versions ───────────────────────────────────────────────

@router.post("/{prompt_id}/versions", response_model=PromptVersionOut, status_code=status.HTTP_201_CREATED)
async def create_version(
    prompt_id: int,
    payload: PromptVersionCreate,
    db: AsyncSession = Depends(get_db),
):
    """Save a new version of an existing prompt. Does NOT delete old versions."""
    # Check prompt exists
    prompt_result = await db.execute(select(Prompt).where(Prompt.id == prompt_id))
    prompt = prompt_result.scalar_one_or_none()
    if not prompt:
        raise HTTPException(status_code=404, detail=f"Prompt {prompt_id} not found")

    # Find the current highest version number
    max_version_result = await db.execute(
        select(func.max(PromptVersion.version_num)).where(PromptVersion.prompt_id == prompt_id)
    )
    current_max = max_version_result.scalar_one_or_none() or 0
    next_version_num = current_max + 1

    # Create the new version
    new_version = PromptVersion(
        prompt_id=prompt_id,
        body=payload.body,
        version_num=next_version_num,
        note=payload.note,
    )
    db.add(new_version)
    await db.flush()

    return new_version


# ── GET /prompts/{id}/versions/{v1}/diff/{v2} ─────────────────────────────────

@router.get("/{prompt_id}/versions/{v1}/diff/{v2}", response_model=DiffOut)
async def diff_versions(
    prompt_id: int,
    v1: int,
    v2: int,
    db: AsyncSession = Depends(get_db),
):
    """
    Return a unified diff between two versions of a prompt.
    v1 and v2 are version numbers (not IDs).
    """
    result = await db.execute(
        select(PromptVersion)
        .where(
            PromptVersion.prompt_id == prompt_id,
            PromptVersion.version_num.in_([v1, v2]),
        )
    )
    versions = {v.version_num: v for v in result.scalars().all()}

    if v1 not in versions:
        raise HTTPException(status_code=404, detail=f"Version {v1} not found")
    if v2 not in versions:
        raise HTTPException(status_code=404, detail=f"Version {v2} not found")

    diff_lines = unified_diff(
        versions[v1].body,
        versions[v2].body,
        label_a=f"v{v1}",
        label_b=f"v{v2}",
    )

    return DiffOut(
        prompt_id=prompt_id,
        version_a=v1,
        version_b=v2,
        body_a=versions[v1].body,
        body_b=versions[v2].body,
        diff_lines=diff_lines,
    )
```

---

### Step 4 — Register the router in main.py

Update `main.py` to include the prompts router:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import models.prompt  # noqa: F401
from api.prompts import router as prompts_router

app = FastAPI(
    title="PromptOS API",
    description="Personal prompt management system",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(prompts_router)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "promptos-api"}
```

---

### Step 5 — Test all endpoints

Restart the API container:

```bash
podman compose restart api
```

Open `http://localhost:8000/docs` and test each endpoint:

**Create a prompt:**
```
POST /prompts
{
  "title": "Python explainer",
  "model_target": "claude-sonnet-4-6",
  "tags": "python,explainer",
  "body": "Explain async/await in Python in 3 sentences for a beginner.",
  "note": "first version"
}
```

**List prompts:**
```
GET /prompts
```

**Create a new version:**
```
POST /prompts/1/versions
{
  "body": "Explain async/await in Python in exactly 3 sentences. Use a real-world analogy. Write for someone who knows JavaScript.",
  "note": "added analogy instruction and target audience"
}
```

**Diff two versions:**
```
GET /prompts/1/versions/1/diff/2
```

You should see something like:

```json
{
  "prompt_id": 1,
  "version_a": 1,
  "version_b": 2,
  "diff_lines": [
    "--- v1",
    "+++ v2",
    "@@ -1 +1,3 @@",
    "-Explain async/await in Python in 3 sentences for a beginner.",
    "+Explain async/await in Python in exactly 3 sentences. Use a real-world analogy. Write for someone who knows JavaScript."
  ]
}
```

---

## Visual overview

```
HTTP client (browser/curl)
         │
         ▼
┌───────────────────────────────────────────────────────┐
│  FastAPI  (main.py + api/prompts.py)                  │
│                                                       │
│  POST /prompts                                        │
│    → validates PromptCreate schema                    │
│    → INSERT INTO prompts                              │
│    → INSERT INTO prompt_versions (version_num=1)      │
│    → returns PromptOut                                │
│                                                       │
│  GET /prompts?search=...&tag=...                      │
│    → SELECT prompts + COUNT(versions)                 │
│    → returns List[PromptListItem]                     │
│                                                       │
│  GET /prompts/{id}                                    │
│    → SELECT prompts + JOIN prompt_versions            │
│    → returns PromptOut (with all versions)            │
│                                                       │
│  POST /prompts/{id}/versions                          │
│    → finds max version_num, adds +1                   │
│    → INSERT INTO prompt_versions                      │
│    → old versions untouched                           │
│                                                       │
│  GET /prompts/{id}/versions/{v1}/diff/{v2}            │
│    → fetches two PromptVersion rows                   │
│    → runs difflib.unified_diff on the bodies          │
│    → returns DiffOut                                  │
└───────────────────────────────────────────────────────┘
         │
         ▼
  PostgreSQL
  (prompts + prompt_versions tables)
```

---

## Done when

- [ ] All five endpoints exist and return correct responses
- [ ] `POST /prompts` creates both a `prompts` row and a `prompt_versions` row (version 1)
- [ ] `POST /prompts/{id}/versions` creates a new version row and does NOT modify old versions
- [ ] `GET /prompts/{id}/versions/{v1}/diff/{v2}` returns a unified diff
- [ ] FastAPI docs at `/docs` show all endpoints with their schemas
- [ ] A 404 is returned when requesting a prompt or version that does not exist

---

## Next step

→ After this, do [P1-T4: Build React Frontend](p1-t4-react-frontend.md)
