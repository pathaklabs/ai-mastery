# P1-US1: Prompt Storage and Versioning

> **"As a developer, I want to store prompts with version history so I can track what changed and why quality shifted."**

**Part of:** [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 1
**Labels:** `user-story`, `p1-promptos`

---

## What this user story delivers

When this story is complete, you will have a working back end that stores prompts in a PostgreSQL database with full version history. Every time you edit a prompt, the old version is kept — just like git commits for text. You will also have a React front end where you can browse your prompt library and see version history for each prompt.

---

## Why this story matters

Prompt engineering is iterative — you tweak wording and hope the output improves, but without history, you cannot tell what actually changed or go back to a version that worked. This story gives you the infrastructure to do prompt engineering systematically instead of guessing.

---

## Acceptance criteria

These are your "definition of done" for the whole story:

- [ ] A prompt record has: title, body, version number, model target, tags, and created date
- [ ] Creating a new version of a prompt does NOT delete the previous version
- [ ] You can request a diff between any two versions of a prompt
- [ ] The React UI lists all prompts and shows the version history sidebar for each one
- [ ] All endpoints return proper HTTP status codes and validated data (Pydantic schemas)

---

## Tasks in this story

| Task ID | Task | Doc |
|---------|------|-----|
| P1-T1 | Set up FastAPI project with podman compose | [p1-t1-fastapi-setup.md](p1-t1-fastapi-setup.md) |
| P1-T2 | Design prompt data model (SQLAlchemy + Alembic) | [p1-t2-data-model.md](p1-t2-data-model.md) |
| P1-T3 | Build CRUD API endpoints for prompts | [p1-t3-crud-api.md](p1-t3-crud-api.md) |
| P1-T4 | Build React frontend — prompt list and editor | [p1-t4-react-frontend.md](p1-t4-react-frontend.md) |

---

## How the tasks fit together

```
P1-T1: Project scaffold
  (podman + FastAPI skeleton)
          │
          ▼
P1-T2: Data model
  (Prompt, PromptVersion, Tag tables in PostgreSQL)
          │
          ▼
P1-T3: API endpoints
  (CRUD routes + Pydantic schemas + diff endpoint)
          │
          ▼
P1-T4: React frontend
  (Prompt list → Editor → Version history sidebar)
          │
          ▼
  User Story DONE: store, version, and browse prompts
```

Each task builds on the one before it. You cannot write the API without the database, and the frontend calls the API. Do them in order.

---

## Learning outcomes

After completing this user story you will understand:

- How to scaffold a FastAPI project with a real PostgreSQL database using podman compose
- How SQLAlchemy models map to database tables, and how Alembic migrations work
- What "versioning without deletion" means in data modeling — and how foreign keys enable it
- How to write Pydantic schemas that validate API input and shape API output
- How a React frontend fetches data from a FastAPI backend and renders it

---

## Next step

After this story, move to [P1-US2: Multi-Model Testing](p1-us2-multi-model-testing.md).
