# P1-T2: Design Prompt Data Model (SQLAlchemy + Alembic)

> **Goal:** Create the SQLAlchemy models for Prompt, PromptVersion, and Tag, then generate and run the first Alembic migration to create those tables in PostgreSQL.

**Part of:** [P1-US1: Prompt Storage](p1-us1-prompt-storage.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 1
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are designing the database schema for PromptOS. Three tables: `prompts` (the master record), `prompt_versions` (each revision of a prompt's text), and `tags` (labels for organising prompts). You will write these as Python classes using SQLAlchemy, then use Alembic to auto-generate a SQL migration and apply it to the running PostgreSQL database.

---

## Why this step matters

The data model is the foundation of everything. If the model is wrong, every API endpoint and UI built on top of it will need to change. Getting versioning right here — using a separate `prompt_versions` table instead of updating a single `body` column — is what makes "never lose a prompt" work.

---

## Prerequisites

- [ ] P1-T1 is complete — PostgreSQL is running via podman compose
- [ ] `db/session.py` exists with the `Base` class
- [ ] All Python packages from `requirements.txt` are installed in the container

---

## Step-by-step instructions

### Step 1 — Understand the design before writing code

This is the learning approach for this task: write the data model as a spec first, then hand it to Claude.

Before writing any Python, draw the tables on paper or in your editor:

```
Table: prompts
  id           INTEGER  PRIMARY KEY
  title        VARCHAR(200)  NOT NULL
  model_target VARCHAR(100)  -- e.g. "claude-sonnet-4-6"
  tags         VARCHAR(500)  -- comma-separated tag names (simple approach)
  created_at   TIMESTAMP  DEFAULT now()

Table: prompt_versions
  id           INTEGER  PRIMARY KEY
  prompt_id    INTEGER  FOREIGN KEY → prompts.id
  body         TEXT  NOT NULL    -- the actual prompt text
  version_num  INTEGER  NOT NULL -- 1, 2, 3, ...
  note         VARCHAR(500)      -- why you made this version
  created_at   TIMESTAMP  DEFAULT now()

Table: tags  (optional, for a cleaner tag system later)
  id           INTEGER  PRIMARY KEY
  name         VARCHAR(100)  UNIQUE NOT NULL
```

Key design decision: `body` lives in `prompt_versions`, NOT in `prompts`. This means you can never overwrite a prompt's content — every change creates a new row in `prompt_versions`.

---

### Step 2 — Write the SQLAlchemy models

Create `models/prompt.py`:

```python
import datetime

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from db.session import Base


class Prompt(Base):
    """
    The master prompt record. Stores metadata only.
    The actual prompt text lives in PromptVersion.
    """
    __tablename__ = "prompts"

    id           = Column(Integer, primary_key=True, index=True)
    title        = Column(String(200), nullable=False)
    model_target = Column(String(100), nullable=True)   # intended model
    tags         = Column(String(500), nullable=True)   # comma-separated
    created_at   = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationship: one Prompt → many PromptVersions
    versions = relationship(
        "PromptVersion",
        back_populates="prompt",
        order_by="PromptVersion.version_num",
        cascade="all, delete-orphan",
    )

    def latest_version(self):
        """Return the PromptVersion with the highest version_num."""
        if not self.versions:
            return None
        return max(self.versions, key=lambda v: v.version_num)


class PromptVersion(Base):
    """
    One version of a prompt's text.
    Creating a new version = inserting a new row here.
    Old versions are NEVER deleted.
    """
    __tablename__ = "prompt_versions"
    __table_args__ = (
        # A prompt cannot have two versions with the same number
        UniqueConstraint("prompt_id", "version_num", name="uq_prompt_version"),
    )

    id          = Column(Integer, primary_key=True, index=True)
    prompt_id   = Column(Integer, ForeignKey("prompts.id"), nullable=False)
    body        = Column(Text, nullable=False)        # the actual prompt text
    version_num = Column(Integer, nullable=False)     # 1, 2, 3, ...
    note        = Column(String(500), nullable=True)  # "changed tone to be friendlier"
    created_at  = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationship: many PromptVersions → one Prompt
    prompt = relationship("Prompt", back_populates="versions")


class Tag(Base):
    """
    Tag names for organising prompts.
    The simple approach uses Prompt.tags (comma string) for now.
    This table is for a future many-to-many implementation.
    """
    __tablename__ = "tags"

    id   = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
```

---

### Step 3 — Update main.py to import models on startup

SQLAlchemy needs to know about all models before Alembic can see them. Add to `main.py`:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import models so SQLAlchemy registers them with Base.metadata
import models.prompt  # noqa: F401

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


@app.get("/health")
async def health():
    return {"status": "ok", "service": "promptos-api"}
```

---

### Step 4 — Initialise Alembic

Run this inside the container (or your local virtual environment if you have one):

```bash
# If running locally with a venv:
cd projects/01-promptos
alembic init alembic
```

Or run it inside the API container:

```bash
podman exec -it 01-promptos_api_1 alembic init alembic
```

This creates an `alembic/` folder and an `alembic.ini` file.

---

### Step 5 — Configure alembic.ini

Open `alembic.ini` and find this line:

```
sqlalchemy.url = driver://user:pass@localhost/dbname
```

Comment it out (Alembic will read from env instead):

```ini
# sqlalchemy.url = driver://user:pass@localhost/dbname
```

---

### Step 6 — Configure alembic/env.py

Replace the content of `alembic/env.py` with this. The key changes are: reading `DATABASE_URL` from the environment, and importing your `Base` so Alembic can see the models.

```python
import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool

from alembic import context

# Import Base and all models so Alembic can detect them
from db.session import Base
import models.prompt  # noqa: F401 — registers models with Base

# Alembic Config object
config = context.config

# Set up Python logging from alembic.ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Tell Alembic to use your models for autogenerate
target_metadata = Base.metadata

# Read database URL from environment (sync driver for migrations)
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://promptos:promptos@localhost:5432/promptos"
)
config.set_main_option("sqlalchemy.url", DATABASE_URL)


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

---

### Step 7 — Generate the migration

```bash
alembic revision --autogenerate -m "create prompts and versions"
```

This creates a file in `alembic/versions/` that looks something like `abc123_create_prompts_and_versions.py`.

Open the file and verify it contains `CREATE TABLE` statements for `prompts`, `prompt_versions`, and `tags`. If the file is empty or wrong, the most common cause is that `models.prompt` was not imported before `target_metadata` was set in `env.py`.

---

### Step 8 — Apply the migration

```bash
alembic upgrade head
```

Expected output:

```
INFO  [alembic.runtime.migration] Running upgrade  -> abc123, create prompts and versions
```

Verify the tables exist:

```bash
podman exec -it 01-promptos_db_1 psql -U promptos -d promptos -c "\dt"
```

Expected output:

```
              List of relations
 Schema |      Name       | Type  |  Owner
--------+-----------------+-------+---------
 public | alembic_version | table | promptos
 public | prompt_versions | table | promptos
 public | prompts         | table | promptos
 public | tags            | table | promptos
```

---

## Visual overview

```
Python class                  PostgreSQL table
─────────────                 ────────────────

class Prompt(Base)    ──────► prompts
  id                            id SERIAL PK
  title                         title VARCHAR(200)
  model_target                  model_target VARCHAR(100)
  tags                          tags VARCHAR(500)
  created_at                    created_at TIMESTAMP
  versions (relationship)       (no column — handled by FK)

class PromptVersion(Base)  ──► prompt_versions
  id                            id SERIAL PK
  prompt_id (FK)                prompt_id INT FK→prompts.id
  body                          body TEXT
  version_num                   version_num INT
  note                          note VARCHAR(500)
  created_at                    created_at TIMESTAMP

class Tag(Base)       ──────► tags
  id                            id SERIAL PK
  name                          name VARCHAR(100) UNIQUE


Alembic workflow:
  You change Python models
       │
       ▼
  alembic revision --autogenerate
       │  (reads Base.metadata, compares to DB)
       ▼
  alembic/versions/XYZ_description.py
       │
       ▼
  alembic upgrade head
       │  (runs SQL against PostgreSQL)
       ▼
  Tables updated in DB
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> Before you ran `alembic upgrade head`, write down the exact SQL CREATE TABLE statements you expected Alembic to generate for `prompts` and `prompt_versions`. Then look at the generated migration file. How close was your prediction?
>
> Bonus: Why is `body` in `prompt_versions` instead of `prompts`? What would break if you put it in `prompts` and updated it in place?

---

## Done when

- [ ] `models/prompt.py` exists with `Prompt`, `PromptVersion`, and `Tag` classes
- [ ] Alembic is initialised and `env.py` is configured
- [ ] `alembic upgrade head` runs without errors
- [ ] `\dt` in psql shows the three new tables
- [ ] Migration file is committed to git (the generated `alembic/versions/` file)

---

## Next step

→ After this, do [P1-T3: Build CRUD API Endpoints](p1-t3-crud-api.md)
