# P2-T3: Build Document Loader for n8n JSON Workflows

> **Goal:** Write a Python loader that reads your n8n workflow JSON exports, pulls out the meaningful content (workflow name, nodes, connections), and stores it so you can later ask "which workflow handles X?" and get a real answer.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 3–4
**Labels:** `task`, `p2-rag`

---

## What you are doing

n8n stores workflows as JSON files. Each JSON file contains:
- The workflow name
- A list of nodes (each node is a step in the automation: webhook, HTTP request, send Telegram message, etc.)
- Connections between nodes (the flow/order)
- Node-level notes or descriptions

Raw JSON is not great for embedding because it has a lot of structural noise (`{`, `}`, `"`, `:`). Your job is to extract the useful semantic content and turn it into sentences that describe what the workflow actually does.

The goal for retrieval: if you ask *"which workflow sends me Telegram alerts?"* the system should find the workflow that has a Telegram node — even if the word "Telegram" is not in the question the same way it appears in the JSON.

---

## Why this step matters

n8n workflows are where your homelab automations live. Being able to query them naturally ("what runs when my front door opens?", "which workflow processes my grocery list?") is one of the most practical uses of this RAG system. Good extraction here = good retrieval later.

---

## Prerequisites

- [ ] [P2-T1](p2-t1-llamaindex-setup.md) complete — LlamaIndex + ChromaDB running
- [ ] [P2-T2](p2-t2-ha-yaml-loader.md) complete — you understand the loader pattern
- [ ] n8n workflow JSON exports in `data/n8n-exports/`

---

## Step-by-step instructions

### Step 1 — Export your n8n workflows

In n8n:
1. Go to **Settings → API** or use the n8n UI export feature
2. Or export individual workflows: open a workflow → three-dot menu → **Download**
3. Save the `.json` files to `~/projects/rag-brain/data/n8n-exports/`

If you do not have exports yet, create a test file:

```bash
cat > ~/projects/rag-brain/data/n8n-exports/test-workflow.json << 'EOF'
{
  "name": "GroceryTracker_v2",
  "active": true,
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "notes": "Receives POST from grocery app when list is updated",
      "parameters": {
        "path": "grocery-update",
        "responseMode": "onReceived"
      }
    },
    {
      "name": "Parse Items",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "notes": "Extracts item names and quantities from webhook payload",
      "parameters": {}
    },
    {
      "name": "Send Telegram Summary",
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1,
      "notes": "Sends shopping summary to personal Telegram chat",
      "parameters": {
        "chatId": "YOUR_CHAT_ID",
        "text": "Grocery list updated"
      }
    }
  ],
  "connections": {
    "Webhook Trigger": {
      "main": [[{"node": "Parse Items", "type": "main", "index": 0}]]
    },
    "Parse Items": {
      "main": [[{"node": "Send Telegram Summary", "type": "main", "index": 0}]]
    }
  }
}
EOF
```

---

### Step 2 — Understand what to extract

Not everything in the JSON is useful for embedding. Here is what matters:

```
USEFUL for retrieval:
  ✓ Workflow name          ("GroceryTracker_v2")
  ✓ Node names             ("Send Telegram Summary", "Webhook Trigger")
  ✓ Node types             ("n8n-nodes-base.telegram", "webhook")
  ✓ Node notes/descriptions ("Sends shopping summary to personal Telegram chat")
  ✓ Connection flow        (which node connects to which)

NOT very useful:
  ✗ Raw parameter values   (chat IDs, credentials, internal IDs)
  ✗ Position/layout data   (x, y coordinates)
  ✗ Version numbers        (typeVersion: 1)
  ✗ UUID node IDs
```

---

### Step 3 — Create the n8n loader module

Create `~/projects/rag-brain/loaders/n8n_loader.py`:

```python
"""
n8n Workflow JSON Document Loader

Loads n8n workflow exports and converts them to LlamaIndex Document objects.
Each workflow becomes one document with readable text describing what it does.
"""
import json
from pathlib import Path
from llama_index.core import Document


def _node_type_to_readable(node_type: str) -> str:
    """
    Convert n8n internal node type names to human-readable strings.
    e.g. "n8n-nodes-base.telegram" → "Telegram"
    """
    # Strip the prefix
    short = node_type.replace("n8n-nodes-base.", "").replace("n8n-nodes-", "")

    # Map common types to friendly names
    type_map = {
        "webhook": "Webhook (HTTP trigger)",
        "telegram": "Telegram",
        "slack": "Slack",
        "gmail": "Gmail",
        "httpRequest": "HTTP Request",
        "code": "Code / JavaScript",
        "if": "Condition / If-Else",
        "set": "Set Variables",
        "merge": "Merge",
        "splitInBatches": "Split in Batches",
        "function": "Function (JavaScript)",
        "cron": "Scheduled Trigger (Cron)",
        "interval": "Interval Trigger",
        "emailSend": "Send Email",
        "mqtt": "MQTT",
        "homeAssistant": "Home Assistant",
        "postgres": "PostgreSQL",
        "mysql": "MySQL",
        "redis": "Redis",
        "noOp": "No Operation",
        "start": "Manual Trigger",
    }

    return type_map.get(short, short.title())


def _extract_connections_text(connections: dict) -> str:
    """
    Convert the connections object into a readable flow description.
    e.g. "Webhook Trigger → Parse Items → Send Telegram Summary"
    """
    if not connections:
        return ""

    # Build a simple adjacency representation
    flow_lines = []
    for source_node, outputs in connections.items():
        targets = []
        for output_group in outputs.values():
            for connection_list in output_group:
                for conn in connection_list:
                    if isinstance(conn, dict):
                        targets.append(conn.get("node", ""))

        if targets:
            flow_lines.append(f"{source_node} → {', '.join(t for t in targets if t)}")

    return "\n".join(flow_lines)


def _workflow_to_text(workflow: dict) -> str:
    """
    Convert an n8n workflow dict to a human-readable description.
    This is what gets embedded and retrieved.
    """
    lines = []

    # Workflow header
    name = workflow.get("name", "Unnamed workflow")
    active = workflow.get("active", False)
    lines.append(f"Workflow: {name}")
    lines.append(f"Status: {'Active' if active else 'Inactive'}")
    lines.append("")

    # Node descriptions
    nodes = workflow.get("nodes", [])
    if nodes:
        lines.append(f"This workflow has {len(nodes)} nodes:")
        lines.append("")
        for node in nodes:
            node_name = node.get("name", "")
            node_type_raw = node.get("type", "")
            node_type = _node_type_to_readable(node_type_raw)
            notes = node.get("notes", "").strip()

            line = f"  - {node_name} ({node_type})"
            if notes:
                line += f": {notes}"
            lines.append(line)

    lines.append("")

    # Flow / connections
    connections = workflow.get("connections", {})
    flow_text = _extract_connections_text(connections)
    if flow_text:
        lines.append("Flow:")
        for flow_line in flow_text.split("\n"):
            lines.append(f"  {flow_line}")

    # Tags if present
    tags = workflow.get("tags", [])
    if tags:
        tag_names = [t.get("name", t) if isinstance(t, dict) else str(t) for t in tags]
        lines.append("")
        lines.append(f"Tags: {', '.join(tag_names)}")

    return "\n".join(lines)


def load_n8n_workflows_folder(folder_path: str) -> list[Document]:
    """
    Load all n8n workflow JSON files from a folder.

    Each workflow becomes one Document with:
    - text: human-readable description of the workflow
    - metadata: source file + workflow name for citations

    Args:
        folder_path: path to folder containing .json files

    Returns:
        list of LlamaIndex Document objects
    """
    documents = []
    folder = Path(folder_path)

    if not folder.exists():
        print(f"Warning: folder {folder_path} does not exist.")
        return []

    json_files = list(folder.glob("*.json"))

    if not json_files:
        print(f"Warning: no JSON files found in {folder_path}")
        return []

    for json_file in sorted(json_files):
        print(f"Loading: {json_file.name}")
        try:
            with open(json_file, "r", encoding="utf-8") as f:
                workflow = json.load(f)

            # n8n sometimes exports a list of workflows in one file
            if isinstance(workflow, list):
                for i, wf in enumerate(workflow):
                    text = _workflow_to_text(wf)
                    wf_name = wf.get("name", f"workflow_{i}")
                    doc = Document(
                        text=text,
                        metadata={
                            "source": str(json_file),
                            "filename": json_file.name,
                            "workflow_name": wf_name,
                            "type": "n8n_workflow",
                        }
                    )
                    documents.append(doc)
                    print(f"  Loaded workflow: {wf_name} ({len(text)} chars)")
            else:
                text = _workflow_to_text(workflow)
                wf_name = workflow.get("name", json_file.stem)
                doc = Document(
                    text=text,
                    metadata={
                        "source": str(json_file),
                        "filename": json_file.name,
                        "workflow_name": wf_name,
                        "type": "n8n_workflow",
                    }
                )
                documents.append(doc)
                print(f"  Loaded workflow: {wf_name} ({len(text)} chars)")

        except json.JSONDecodeError as e:
            print(f"  Error parsing {json_file.name}: {e}")
        except Exception as e:
            print(f"  Error loading {json_file.name}: {e}")

    print(f"\nLoaded {len(documents)} n8n workflow documents")
    return documents
```

---

### Step 4 — Add n8n loader to the `__init__.py`

Edit `~/projects/rag-brain/loaders/__init__.py`:

```python
from .ha_loader import load_ha_yaml_folder, load_ha_yaml_file
from .n8n_loader import load_n8n_workflows_folder
```

---

### Step 5 — Test the loader

Create `~/projects/rag-brain/test_n8n_loader.py`:

```python
"""
Test the n8n workflow loader.
Run: python test_n8n_loader.py
"""
from loaders.n8n_loader import load_n8n_workflows_folder

docs = load_n8n_workflows_folder("data/n8n-exports")

print(f"\n=== Loaded {len(docs)} workflow documents ===\n")

for doc in docs:
    print(f"File:     {doc.metadata['filename']}")
    print(f"Workflow: {doc.metadata['workflow_name']}")
    print(f"Type:     {doc.metadata['type']}")
    print("Text:")
    print(doc.text)
    print("---\n")
```

```bash
python test_n8n_loader.py
```

Expected output for the test workflow:

```
Loading: test-workflow.json
  Loaded workflow: GroceryTracker_v2 (342 chars)

=== Loaded 1 workflow documents ===

File:     test-workflow.json
Workflow: GroceryTracker_v2
Type:     n8n_workflow
Text:
Workflow: GroceryTracker_v2
Status: Active

This workflow has 3 nodes:

  - Webhook Trigger (Webhook (HTTP trigger)): Receives POST from grocery app when list is updated
  - Parse Items (Code / JavaScript): Extracts item names and quantities from webhook payload
  - Send Telegram Summary (Telegram): Sends shopping summary to personal Telegram chat

Flow:
  Webhook Trigger → Parse Items
  Parse Items → Send Telegram Summary
---
```

---

### Step 6 — Add n8n ingestion to the ingest script

Update `~/projects/rag-brain/ingest.py` to include n8n workflows:

```python
"""
Ingestion script — loads all document types and stores them in ChromaDB.
Run: python ingest.py
"""
import chromadb
from llama_index.core import VectorStoreIndex, StorageContext
from llama_index.vector_stores.chroma import ChromaVectorStore

from loaders.ha_loader import load_ha_yaml_folder
from loaders.n8n_loader import load_n8n_workflows_folder

# --- Connect to ChromaDB ---
chroma_client = chromadb.HttpClient(host="localhost", port=8001)

# --- Load all document types ---
print("=" * 50)
print("Loading Home Assistant YAML documents...")
ha_docs = load_ha_yaml_folder("data/ha-yaml")

print("\nLoading n8n workflow documents...")
n8n_docs = load_n8n_workflows_folder("data/n8n-exports")

all_docs = ha_docs + n8n_docs
print(f"\nTotal documents to index: {len(all_docs)}")

if not all_docs:
    print("No documents loaded. Check your data folders.")
    exit(1)

# --- Store in ChromaDB ---
collection = chroma_client.get_or_create_collection("rag_brain")
vector_store = ChromaVectorStore(chroma_collection=collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

print("\nIndexing documents into ChromaDB collection 'rag_brain'...")
index = VectorStoreIndex.from_documents(
    all_docs,
    storage_context=storage_context,
    show_progress=True,
)

count = collection.count()
print(f"\nIngestion complete. ChromaDB collection 'rag_brain' has {count} chunks.")
print(f"  HA YAML:      {len(ha_docs)} documents")
print(f"  n8n Workflows: {len(n8n_docs)} documents")
```

```bash
python ingest.py
```

---

## Visual overview

```
n8n (your homelab)
┌──────────────────────────────────┐
│  GroceryTracker_v2 workflow      │
│  AlertRouter_v2 workflow         │
│  MorningBriefing workflow        │
│  ...                             │
└──────────────────────────────────┘
        │
        │ Export as JSON
        ▼
data/n8n-exports/
┌──────────────────────────────────┐
│  grocery-tracker.json            │
│  alert-router.json               │
│  morning-briefing.json           │
└──────────────────────────────────┘
        │
        │ n8n_loader.py
        │ - reads JSON
        │ - extracts: name, nodes, notes, connections
        │ - converts to readable text
        │ - tags with source filename
        ▼
LlamaIndex Documents
┌──────────────────────────────────────────────────────┐
│ Document 1:                                          │
│   text: "Workflow: GroceryTracker_v2\nStatus: Active │
│          3 nodes: Webhook Trigger (Webhook)...       │
│          Telegram node: sends shopping summary..."   │
│   metadata: { filename: grocery-tracker.json,        │
│               workflow_name: GroceryTracker_v2 }     │
├──────────────────────────────────────────────────────┤
│ Document 2: ...                                      │
└──────────────────────────────────────────────────────┘
        │
        │ ChromaDB
        ▼
Stored as vectors — searchable by meaning, not just keywords

Later:
  Question: "which workflow handles Telegram alerts?"
  → Finds Document 1 (Telegram node in the text)
  → Returns: "GroceryTracker_v2 (Source: grocery-tracker.json)"
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"You have two workflows: one named 'grocery-tracker' and one named 'alert-router'. Both use Telegram. If someone asks 'which workflow sends Telegram messages?', will the RAG system find both or just one? What determines which one ranks higher?"**
>
> You do not need to be right yet — you will be able to verify this once you have search working in P2-T6.

---

## Done when

- [ ] `loaders/n8n_loader.py` created and exports readable text for each workflow
- [ ] `python test_n8n_loader.py` shows workflow name, nodes, and flow in output
- [ ] Each document's metadata contains `filename` and `workflow_name`
- [ ] `python ingest.py` ingests both HA YAML and n8n workflows together
- [ ] Learning checkpoint answered in build log

---

## Next step

→ [P2-T4: Implement and compare 3 chunking strategies](p2-t4-chunking-strategies.md)
