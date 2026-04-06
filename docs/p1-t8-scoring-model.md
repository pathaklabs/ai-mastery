# P1-T8: Build Scoring Data Model and API

> **Goal:** Create the OutputScore database table and API endpoints to save and retrieve ratings for individual model outputs.

**Part of:** [P1-US3: Output Scoring](p1-us3-output-scoring.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 3
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are adding a scoring layer to PromptOS. A new `output_scores` table stores ratings (1–5) on four dimensions — accuracy, format, tone, and completeness — linked to a specific prompt version and model name. You will write the SQLAlchemy model, an Alembic migration, and three API endpoints: save a score, get scores for a prompt version, and get aggregate scores.

---

## Why this step matters

Without a scoring layer, model comparison is subjective. This table turns "I think Claude was better" into "Claude averaged 4.2 on accuracy vs 3.1 for Llama 3 on this prompt." That difference matters when you need to justify which model to use in a production feature.

---

## Prerequisites

- [ ] P1-T7 is complete — comparison UI works
- [ ] The `prompt_versions` table exists and has data
- [ ] Alembic is configured and has run at least one migration

---

## Step-by-step instructions

### Step 1 — Add the OutputScore SQLAlchemy model

Add to `models/prompt.py` (at the bottom, after the `Tag` class):

```python
class OutputScore(Base):
    """
    A human rating of a model's output for a specific prompt version.

    One score row per (prompt_version, model) combination per scoring session.
    You can score the same output multiple times — each is a new row.
    """
    __tablename__ = "output_scores"

    id                = Column(Integer, primary_key=True, index=True)
    prompt_version_id = Column(Integer, ForeignKey("prompt_versions.id"), nullable=False)
    model             = Column(String(100), nullable=False)

    # Ratings: 1 (terrible) to 5 (excellent)
    accuracy          = Column(Integer, nullable=False)
    format            = Column(Integer, nullable=False)
    tone              = Column(Integer, nullable=False)
    completeness      = Column(Integer, nullable=False)

    annotation        = Column(Text, nullable=True)   # free-text notes
    created_at        = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationship back to the version
    version = relationship("PromptVersion", backref="scores")
```

---

### Step 2 — Add schemas for scoring

Add to `schemas/prompt.py`:

```python
# ── Scoring schemas ────────────────────────────────────────────────────────────

class ScoreCreate(BaseModel):
    """Body for POST /scores"""
    prompt_version_id: int
    model: str = Field(..., max_length=100)
    accuracy: int = Field(..., ge=1, le=5)
    format: int = Field(..., ge=1, le=5)
    tone: int = Field(..., ge=1, le=5)
    completeness: int = Field(..., ge=1, le=5)
    annotation: Optional[str] = None


class ScoreOut(BaseModel):
    id: int
    prompt_version_id: int
    model: str
    accuracy: int
    format: int
    tone: int
    completeness: int
    annotation: Optional[str]
    created_at: datetime.datetime

    model_config = {"from_attributes": True}


class AggregateScore(BaseModel):
    """Average scores for a prompt version + model combination."""
    prompt_version_id: int
    model: str
    avg_accuracy: float
    avg_format: float
    avg_tone: float
    avg_completeness: float
    avg_overall: float    # mean of all four dimensions
    score_count: int      # how many times this was scored
```

---

### Step 3 — Write the scoring API

Create `api/scores.py`:

```python
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from db.session import get_db
from models.prompt import OutputScore, PromptVersion
from schemas.prompt import AggregateScore, ScoreCreate, ScoreOut

router = APIRouter(prefix="/scores", tags=["scores"])


# ── POST /scores ──────────────────────────────────────────────────────────────

@router.post("/", response_model=ScoreOut, status_code=201)
async def create_score(payload: ScoreCreate, db: AsyncSession = Depends(get_db)):
    """Save a score for a model output."""
    # Verify the prompt version exists
    version_result = await db.execute(
        select(PromptVersion).where(PromptVersion.id == payload.prompt_version_id)
    )
    if not version_result.scalar_one_or_none():
        raise HTTPException(
            status_code=404,
            detail=f"PromptVersion {payload.prompt_version_id} not found"
        )

    score = OutputScore(
        prompt_version_id=payload.prompt_version_id,
        model=payload.model,
        accuracy=payload.accuracy,
        format=payload.format,
        tone=payload.tone,
        completeness=payload.completeness,
        annotation=payload.annotation,
    )
    db.add(score)
    await db.flush()
    return score


# ── GET /scores?prompt_version_id=N&model=X ───────────────────────────────────

@router.get("/", response_model=List[ScoreOut])
async def list_scores(
    prompt_version_id: Optional[int] = None,
    model: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """List scores, optionally filtered by prompt version and/or model."""
    query = select(OutputScore).order_by(OutputScore.created_at.desc())

    if prompt_version_id is not None:
        query = query.where(OutputScore.prompt_version_id == prompt_version_id)
    if model is not None:
        query = query.where(OutputScore.model == model)

    result = await db.execute(query)
    return result.scalars().all()


# ── GET /scores/aggregate?prompt_version_id=N ─────────────────────────────────

@router.get("/aggregate", response_model=List[AggregateScore])
async def aggregate_scores(
    prompt_version_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
):
    """
    Return average scores grouped by (prompt_version_id, model).
    If prompt_version_id is provided, filter to that version only.
    Used by the performance dashboard.
    """
    query = (
        select(
            OutputScore.prompt_version_id,
            OutputScore.model,
            func.avg(OutputScore.accuracy).label("avg_accuracy"),
            func.avg(OutputScore.format).label("avg_format"),
            func.avg(OutputScore.tone).label("avg_tone"),
            func.avg(OutputScore.completeness).label("avg_completeness"),
            func.avg(
                (OutputScore.accuracy + OutputScore.format +
                 OutputScore.tone + OutputScore.completeness) / 4.0
            ).label("avg_overall"),
            func.count(OutputScore.id).label("score_count"),
        )
        .group_by(OutputScore.prompt_version_id, OutputScore.model)
        .order_by(func.avg(
            (OutputScore.accuracy + OutputScore.format +
             OutputScore.tone + OutputScore.completeness) / 4.0
        ).desc())
    )

    if prompt_version_id is not None:
        query = query.where(OutputScore.prompt_version_id == prompt_version_id)

    result = await db.execute(query)
    rows = result.mappings().all()

    return [
        AggregateScore(
            prompt_version_id=row["prompt_version_id"],
            model=row["model"],
            avg_accuracy=round(float(row["avg_accuracy"]), 2),
            avg_format=round(float(row["avg_format"]), 2),
            avg_tone=round(float(row["avg_tone"]), 2),
            avg_completeness=round(float(row["avg_completeness"]), 2),
            avg_overall=round(float(row["avg_overall"]), 2),
            score_count=row["score_count"],
        )
        for row in rows
    ]
```

---

### Step 4 — Register the scores router in main.py

Add to `main.py`:

```python
from api.scores import router as scores_router
app.include_router(scores_router)
```

---

### Step 5 — Generate and apply the Alembic migration

The `OutputScore` model is new — Alembic needs to create the table:

```bash
alembic revision --autogenerate -m "add output_scores table"
alembic upgrade head
```

Verify the table exists:

```bash
podman exec -it 01-promptos_db_1 psql -U promptos -d promptos -c "\d output_scores"
```

Expected column list:

```
         Column          |            Type
-------------------------+-----------------------------
 id                      | integer
 prompt_version_id       | integer
 model                   | character varying(100)
 accuracy                | integer
 format                  | integer
 tone                    | integer
 completeness            | integer
 annotation              | text
 created_at              | timestamp without time zone
```

---

### Step 6 — Test the endpoints

Restart the API:

```bash
podman compose restart api
```

Save a score (replace `prompt_version_id` with a real ID from your database):

```bash
curl -X POST http://localhost:8000/scores \
  -H "Content-Type: application/json" \
  -d '{
    "prompt_version_id": 1,
    "model": "claude-sonnet-4-6",
    "accuracy": 5,
    "format": 4,
    "tone": 5,
    "completeness": 4,
    "annotation": "Clear and used a good analogy. Could be more concise."
  }'
```

Get aggregate scores:

```bash
curl "http://localhost:8000/scores/aggregate?prompt_version_id=1"
```

Expected response:

```json
[
  {
    "prompt_version_id": 1,
    "model": "claude-sonnet-4-6",
    "avg_accuracy": 5.0,
    "avg_format": 4.0,
    "avg_tone": 5.0,
    "avg_completeness": 4.0,
    "avg_overall": 4.5,
    "score_count": 1
  }
]
```

---

## Visual overview

```
User scores a model output:
  accuracy=5, format=4, tone=5, completeness=4

        │
        ▼
POST /scores
        │
        ▼
INSERT INTO output_scores
  prompt_version_id = 1
  model             = "claude-sonnet-4-6"
  accuracy          = 5
  format            = 4
  tone              = 5
  completeness      = 4
  annotation        = "Clear and used a good analogy"
  created_at        = now()

        │
        ▼
GET /scores/aggregate?prompt_version_id=1

        │
        ▼
SELECT
  prompt_version_id,
  model,
  AVG(accuracy),
  AVG(format),
  AVG(tone),
  AVG(completeness),
  AVG((acc+fmt+tone+comp)/4) AS avg_overall,
  COUNT(*) AS score_count
FROM output_scores
GROUP BY prompt_version_id, model

        │
        ▼
[{ prompt_version_id: 1, model: "claude-sonnet-4-6",
   avg_overall: 4.5, score_count: 1 }]
```

---

## Done when

- [ ] `output_scores` table exists in PostgreSQL (migration ran successfully)
- [ ] `POST /scores` saves a score with all four dimension ratings
- [ ] `GET /scores?prompt_version_id=N` returns all scores for that version
- [ ] `GET /scores/aggregate` returns averaged scores grouped by version + model
- [ ] Invalid ratings (0 or 6) are rejected with a 422 error (Pydantic validation)
- [ ] Scoring a non-existent `prompt_version_id` returns a 404

---

## Next step

→ After this, do [P1-T9: Add Scoring UI to Comparison View](p1-t9-scoring-ui.md)
