# P2-T2: Build Document Loader for Home Assistant YAML

> **Goal:** Write a Python loader that reads your Home Assistant YAML config files, converts them into text that an AI can understand, and tags each piece with the source filename so you always know where an answer came from.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 3
**Labels:** `task`, `p2-rag`

---

## What you are doing

Home Assistant stores automations, scripts, and entity configurations as YAML files. YAML is human-readable but structured — it has keys, nested values, and lists. A plain AI cannot search your YAML directly. You need to:

1. **Read** each YAML file
2. **Convert** it to readable text (flatten the structure)
3. **Tag** it with the source filename (this becomes your citation)
4. **Hand it to LlamaIndex** for chunking and embedding

The most important principle in this task: **never lose track of which file the text came from**. Without that, you cannot cite sources.

---

## Why this step matters

The source citation is the whole point of a trustworthy RAG system. If your system says "your motion sensor automation triggers at sunset," you need to be able to say "...and I found that in `automations/hallway-motion.yaml` line 24." Without the citation, you cannot verify the answer, and you cannot trust the system.

---

## Prerequisites

- [ ] [P2-T1](p2-t1-llamaindex-setup.md) complete — LlamaIndex + ChromaDB running
- [ ] Your Home Assistant YAML files accessible on the machine running this code
- [ ] Python virtual environment active with `requirements.txt` installed

---

## Step-by-step instructions

### Step 1 — Copy your HA YAML files into the data folder

```bash
# Copy your automations.yaml and any other HA config files
cp /path/to/homeassistant/config/automations.yaml ~/projects/rag-brain/data/ha-yaml/
cp /path/to/homeassistant/config/scripts.yaml ~/projects/rag-brain/data/ha-yaml/
cp /path/to/homeassistant/config/scenes.yaml ~/projects/rag-brain/data/ha-yaml/

# Or if your HA runs in a Docker/podman container, use podman cp:
# podman cp homeassistant:/config/automations.yaml ~/projects/rag-brain/data/ha-yaml/
```

If you do not have access to your HA files yet, create a test file to work with:

```bash
cat > ~/projects/rag-brain/data/ha-yaml/test-automations.yaml << 'EOF'
- id: "hallway_motion_light"
  alias: "Hallway Motion Light"
  description: "Turn on hallway light when motion detected after sunset"
  trigger:
    - platform: state
      entity_id: binary_sensor.hallway_motion
      to: "on"
  condition:
    - condition: sun
      after: sunset
  action:
    - service: light.turn_on
      target:
        entity_id: light.hallway
      data:
        brightness: 128
        transition: 2

- id: "morning_coffee"
  alias: "Morning Coffee Routine"
  description: "Start coffee maker on weekdays at 7am"
  trigger:
    - platform: time
      at: "07:00:00"
  condition:
    - condition: time
      weekday:
        - mon
        - tue
        - wed
        - thu
        - fri
  action:
    - service: switch.turn_on
      target:
        entity_id: switch.coffee_maker
EOF
```

---

### Step 2 — Create the HA loader module

Create `~/projects/rag-brain/loaders/ha_loader.py`:

```python
"""
Home Assistant YAML Document Loader

Loads HA config files and converts them to LlamaIndex Document objects.
Each document preserves its source filename as metadata for citations.
"""
import yaml
from pathlib import Path
from llama_index.core import Document


def _automation_to_text(automation: dict) -> str:
    """
    Convert a single automation dict to a human-readable string.
    This makes it much easier for the embedding model to understand.
    """
    lines = []

    alias = automation.get("alias", "Unnamed automation")
    description = automation.get("description", "")
    automation_id = automation.get("id", "")

    lines.append(f"Automation: {alias}")
    if description:
        lines.append(f"Description: {description}")
    if automation_id:
        lines.append(f"ID: {automation_id}")

    # Triggers
    triggers = automation.get("trigger", [])
    if isinstance(triggers, dict):
        triggers = [triggers]
    if triggers:
        lines.append("Triggers:")
        for t in triggers:
            platform = t.get("platform", "unknown")
            entity = t.get("entity_id", "")
            at_time = t.get("at", "")
            if platform == "state":
                to_state = t.get("to", "")
                lines.append(f"  - When {entity} changes to '{to_state}'")
            elif platform == "time":
                lines.append(f"  - At time: {at_time}")
            else:
                lines.append(f"  - Platform: {platform} {entity} {at_time}".strip())

    # Conditions
    conditions = automation.get("condition", [])
    if isinstance(conditions, dict):
        conditions = [conditions]
    if conditions:
        lines.append("Conditions:")
        for c in conditions:
            cond_type = c.get("condition", "unknown")
            if cond_type == "sun":
                lines.append(f"  - Sun: {c.get('after', '')} {c.get('before', '')}".strip())
            elif cond_type == "time":
                weekdays = c.get("weekday", [])
                if weekdays:
                    lines.append(f"  - Weekdays: {', '.join(weekdays)}")
            else:
                lines.append(f"  - {cond_type}")

    # Actions
    actions = automation.get("action", [])
    if isinstance(actions, dict):
        actions = [actions]
    if actions:
        lines.append("Actions:")
        for a in actions:
            service = a.get("service", "")
            target = a.get("target", {})
            entity = target.get("entity_id", "")
            if service:
                lines.append(f"  - Call service: {service} on {entity}".strip())

    return "\n".join(lines)


def _yaml_to_text(content, filename: str) -> str:
    """
    Convert any YAML content to a readable string.
    Handles both list-of-automations format and key-value config format.
    """
    # If it's a list (like automations.yaml), convert each item
    if isinstance(content, list):
        parts = []
        for i, item in enumerate(content):
            if isinstance(item, dict) and ("alias" in item or "id" in item):
                # Looks like an automation
                parts.append(_automation_to_text(item))
            else:
                # Generic list item — just dump it as YAML text
                parts.append(yaml.dump(item, default_flow_style=False))
        return f"\n\n---\n\n".join(parts)

    # If it's a dict (like configuration.yaml), dump it as readable YAML
    if isinstance(content, dict):
        return yaml.dump(content, default_flow_style=False, allow_unicode=True)

    # Fallback: convert to string
    return str(content)


def load_ha_yaml_folder(folder_path: str) -> list[Document]:
    """
    Load all YAML files from a folder and return LlamaIndex Document objects.

    Each Document has:
    - text: human-readable version of the YAML content
    - metadata: source file info for citations

    Args:
        folder_path: path to folder containing .yaml or .yml files

    Returns:
        list of LlamaIndex Document objects ready for indexing
    """
    documents = []
    folder = Path(folder_path)

    if not folder.exists():
        print(f"Warning: folder {folder_path} does not exist. Returning empty list.")
        return []

    yaml_files = list(folder.glob("*.yaml")) + list(folder.glob("*.yml"))

    if not yaml_files:
        print(f"Warning: no YAML files found in {folder_path}")
        return []

    for yaml_file in sorted(yaml_files):
        print(f"Loading: {yaml_file.name}")
        try:
            with open(yaml_file, "r", encoding="utf-8") as f:
                content = yaml.safe_load(f)

            if content is None:
                print(f"  Skipping {yaml_file.name} — empty file")
                continue

            text = _yaml_to_text(content, yaml_file.name)

            # This metadata is what shows up in citations
            doc = Document(
                text=text,
                metadata={
                    "source": str(yaml_file),          # full path
                    "filename": yaml_file.name,         # just the filename
                    "type": "home_assistant_yaml",
                    "folder": folder_path,
                }
            )
            documents.append(doc)
            print(f"  Loaded {len(text)} characters")

        except yaml.YAMLError as e:
            print(f"  Error parsing {yaml_file.name}: {e}")
        except Exception as e:
            print(f"  Error loading {yaml_file.name}: {e}")

    print(f"\nLoaded {len(documents)} HA YAML documents from {folder_path}")
    return documents


def load_ha_yaml_file(file_path: str) -> Document:
    """
    Load a single YAML file and return one LlamaIndex Document.
    Useful for re-ingesting a specific file after it changes.
    """
    yaml_file = Path(file_path)

    with open(yaml_file, "r", encoding="utf-8") as f:
        content = yaml.safe_load(f)

    text = _yaml_to_text(content, yaml_file.name)

    return Document(
        text=text,
        metadata={
            "source": str(yaml_file),
            "filename": yaml_file.name,
            "type": "home_assistant_yaml",
        }
    )
```

---

### Step 3 — Create the `__init__.py` for the loaders package

Create `~/projects/rag-brain/loaders/__init__.py`:

```python
from .ha_loader import load_ha_yaml_folder, load_ha_yaml_file
```

---

### Step 4 — Write a test script to verify the loader

Create `~/projects/rag-brain/test_ha_loader.py`:

```python
"""
Test the HA YAML loader.
Run: python test_ha_loader.py
"""
from loaders.ha_loader import load_ha_yaml_folder

docs = load_ha_yaml_folder("data/ha-yaml")

print(f"\n=== Loaded {len(docs)} documents ===\n")

for doc in docs:
    print(f"File: {doc.metadata['filename']}")
    print(f"Type: {doc.metadata['type']}")
    print(f"Text preview:")
    print("  " + doc.text[:300].replace("\n", "\n  "))
    print("---")
```

```bash
python test_ha_loader.py
```

Expected output:

```
Loading: test-automations.yaml
  Loaded 612 characters

=== Loaded 1 documents ===

File: test-automations.yaml
Type: home_assistant_yaml
Text preview:
  Automation: Hallway Motion Light
  Description: Turn on hallway light when motion detected after sunset
  ID: hallway_motion_light
  Triggers:
    - When binary_sensor.hallway_motion changes to 'on'
  Conditions:
    - Sun: sunset
  Actions:
    - Call service: light.turn_on on light.hallway
---
```

---

### Step 5 — Ingest the HA documents into ChromaDB

Create `~/projects/rag-brain/ingest.py` (you will expand this in future tasks):

```python
"""
Ingestion script — loads documents and stores them in ChromaDB.
Run: python ingest.py

You will add more loaders to this file in P2-T3 (n8n) and beyond.
"""
import chromadb
from llama_index.core import VectorStoreIndex, StorageContext
from llama_index.vector_stores.chroma import ChromaVectorStore

from loaders.ha_loader import load_ha_yaml_folder

# --- Connect to ChromaDB ---
chroma_client = chromadb.HttpClient(host="localhost", port=8001)

# Get or create the collection for HA documents
ha_collection = chroma_client.get_or_create_collection("ha_documents")

# --- Load documents ---
print("Loading Home Assistant YAML documents...")
ha_docs = load_ha_yaml_folder("data/ha-yaml")

if not ha_docs:
    print("No documents loaded. Check data/ha-yaml/ folder.")
    exit(1)

# --- Store in ChromaDB via LlamaIndex ---
vector_store = ChromaVectorStore(chroma_collection=ha_collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

print(f"\nIndexing {len(ha_docs)} documents into ChromaDB...")
print("Note: Embedding will run once you have set up the embedding model in P2-T5.")
print("For now, LlamaIndex will use a default embedding. Replace in P2-T5.")

index = VectorStoreIndex.from_documents(
    ha_docs,
    storage_context=storage_context,
    show_progress=True,
)

print(f"\nIngestion complete. {len(ha_docs)} documents stored in ChromaDB collection 'ha_documents'.")

# Verify by checking document count
count = ha_collection.count()
print(f"ChromaDB collection 'ha_documents' now has {count} chunks.")
```

```bash
python ingest.py
```

Note: The default LlamaIndex embedding is fine for now. You will replace it with a local Ollama embedding model in P2-T5.

---

## Visual overview

```
data/ha-yaml/                     ChromaDB
┌─────────────────────┐           ┌────────────────────────────────┐
│ automations.yaml    │           │ collection: ha_documents        │
│ scripts.yaml        │           │                                 │
│ scenes.yaml         │           │  chunk 1: "Automation: Hallway  │
│ configuration.yaml  │           │   Motion Light..."              │
└─────────────────────┘           │  metadata: {                    │
         │                        │    filename: automations.yaml   │
         │ load_ha_yaml_folder()   │    type: home_assistant_yaml   │
         ▼                        │  }                              │
┌─────────────────────┐           │                                 │
│ ha_loader.py        │           │  chunk 2: "Automation: Morning  │
│                     │           │   Coffee Routine..."            │
│ 1. Read YAML        │  index    │  metadata: {                    │
│ 2. Parse structure  │ ────────► │    filename: automations.yaml   │
│ 3. Convert to text  │           │  }                              │
│ 4. Tag with source  │           │                                 │
│ 5. Return Documents │           │  ... more chunks ...            │
└─────────────────────┘           └────────────────────────────────┘

Later, when you ask a question:
  "Which automation controls the hallway light?"
        │
        ▼ (vector search — covered in P2-T6)
  Returns chunk 1 above, with metadata saying: automations.yaml
        │
        ▼
  Answer: "The 'Hallway Motion Light' automation turns on light.hallway
           when motion is detected after sunset."
  Source: automations.yaml
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"Why do we convert YAML to human-readable text instead of embedding the raw YAML structure directly? What would happen to retrieval quality if we embedded raw YAML?"**

---

## Done when

- [ ] `loaders/ha_loader.py` created and loads documents without errors
- [ ] `python test_ha_loader.py` shows readable text with source metadata
- [ ] `python ingest.py` completes and ChromaDB collection shows document count > 0
- [ ] Each document's metadata contains `filename` and `type`
- [ ] Learning checkpoint answered in your build log

---

## Next step

→ [P2-T3: Build document loader for n8n JSON exports](p2-t3-n8n-loader.md)
