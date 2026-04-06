# P4-T2: Build RAG Pipeline Over Governance Documents

> **Goal:** Build the LlamaIndex + ChromaDB RAG pipeline that ingests the cleaned governance documents and answers questions with source citations — reusing the pattern you built in Project 2.

**Part of:** [P4-US1: Governance RAG System](p4-us1-governance-rag.md)
**Weeks:** 5–6
**Labels:** `task`, `p4-aiga`

---

## What you are doing

You are building the search-and-answer engine of AIGA. When someone asks "What does the EU AI Act say about facial recognition?", this pipeline:

1. Converts the question into a vector (a list of numbers representing its meaning)
2. Searches ChromaDB for the document chunks that are most similar to that vector
3. Sends those chunks to a local LLM (via Ollama) with the question
4. Gets back an answer that cites the exact article the chunks came from

This is the exact same pattern you used in P2 for your personal files. The only difference is the documents being searched.

---

## Why this step matters

This is the moment the program's architecture pays off. You are not rebuilding RAG from scratch — you are applying code you already understand to a new domain. That is the difference between a beginner and someone who can ship quickly.

> **Skill transfer moment:** In P2, you built RAG over Home Assistant YAML and n8n JSON files. Here you are running the same engine over legal documents. The LlamaIndex and ChromaDB code is almost identical. What changes: the documents, the metadata (article numbers instead of filenames), and the prompts (asking for legal citations instead of config values).

---

## Prerequisites

- [ ] P4-T1 completed — cleaned `.txt` files exist in `source-docs/cleaned/`
- [ ] ChromaDB running via podman (`podman run -p 8001:8000 chromadb/chroma:latest`)
- [ ] Ollama running locally with `llama3` and `nomic-embed-text` models pulled
- [ ] Python dependencies installed:

```bash
pip install llama-index llama-index-vector-stores-chroma \
            llama-index-embeddings-ollama llama-index-llms-ollama \
            chromadb
```

---

## Step-by-step instructions

### Step 1 — Set up the project structure

```bash
mkdir -p projects/04-aiga/api
mkdir -p projects/04-aiga/api/rag
touch projects/04-aiga/api/rag/__init__.py
touch projects/04-aiga/api/rag/ingest.py
touch projects/04-aiga/api/rag/query.py
touch projects/04-aiga/api/rag/metadata.py
```

Your project structure:

```
projects/04-aiga/
  api/
    rag/
      __init__.py
      ingest.py      ← loads documents into ChromaDB
      query.py       ← searches and answers questions
      metadata.py    ← extracts article/section info from chunks
  source-docs/
    cleaned/         ← text files from P4-T1
```

---

### Step 2 — Write the metadata extractor

Before ingesting, you need a way to extract article numbers from the text chunks. This is what makes citations work.

```python
# projects/04-aiga/api/rag/metadata.py

import re
from typing import Optional

def extract_article_reference(text: str, source_doc: str) -> dict:
    """
    Try to find an article or section reference in a chunk of text.
    Returns metadata dict that gets stored alongside the chunk in ChromaDB.

    Examples of what this catches:
      EU AI Act:   "Article 6", "Annex III", "Article 5(1)(d)"
      NIST AI RMF: "GOVERN 1.1", "MAP 5.2", "MEASURE 2.3"
      ISO 42001:   "Clause 6", "Section 4.1"
    """

    metadata = {
        "source_doc": source_doc,
        "article_ref": None,
        "section_ref": None,
    }

    # EU AI Act article pattern
    eu_article = re.search(r'Article\s+(\d+)(?:\s*\([\d\w]+\))*', text, re.IGNORECASE)
    if eu_article and "eu-ai-act" in source_doc.lower():
        metadata["article_ref"] = eu_article.group(0).strip()

    # EU AI Act Annex pattern
    eu_annex = re.search(r'Annex\s+(I{1,3}V?|VI*|[A-Z]+)(?:,\s*(?:paragraph|point|section)\s+[\d\w]+)?',
                         text, re.IGNORECASE)
    if eu_annex and "eu-ai-act" in source_doc.lower():
        metadata["article_ref"] = eu_annex.group(0).strip()

    # NIST AI RMF function pattern (GOVERN 1.1, MAP 5.2, etc.)
    nist_ref = re.search(r'(GOVERN|MAP|MEASURE|MANAGE)\s+(\d+\.\d+)', text, re.IGNORECASE)
    if nist_ref and "nist" in source_doc.lower():
        metadata["section_ref"] = nist_ref.group(0).strip()

    # ISO 42001 clause pattern
    iso_clause = re.search(r'Clause\s+(\d+(?:\.\d+)*)', text, re.IGNORECASE)
    if iso_clause and "iso" in source_doc.lower():
        metadata["section_ref"] = iso_clause.group(0).strip()

    return metadata


def format_citation(metadata: dict) -> str:
    """
    Format metadata into a human-readable citation string.
    Example: "EU AI Act, Article 6" or "NIST AI RMF, MAP 5.1"
    """
    doc_names = {
        "eu-ai-act": "EU AI Act",
        "nist-ai-rmf": "NIST AI RMF",
        "iso-42001": "ISO 42001",
        "anthropic-model-card": "Anthropic Model Card",
        "openai-gpt4-system-card": "OpenAI GPT-4 System Card",
    }

    source = metadata.get("source_doc", "Unknown document")
    doc_label = "Unknown document"
    for key, label in doc_names.items():
        if key in source.lower():
            doc_label = label
            break

    ref = metadata.get("article_ref") or metadata.get("section_ref")
    if ref:
        return f"{doc_label}, {ref}"
    return doc_label
```

---

### Step 3 — Write the ingestion script

This loads all cleaned documents into ChromaDB. Run it once (or whenever documents change).

```python
# projects/04-aiga/api/rag/ingest.py

import chromadb
from pathlib import Path
from llama_index.core import VectorStoreIndex, Document
from llama_index.core.node_parser import SentenceSplitter
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.embeddings.ollama import OllamaEmbedding
from llama_index.core import Settings
from .metadata import extract_article_reference

DOCS_DIR = Path("source-docs/cleaned")
CHROMA_URL = "http://localhost:8001"
COLLECTION_NAME = "aiga_governance"

# Use the same embedding model as P2 — consistency matters
EMBED_MODEL = "nomic-embed-text"

# Chunk size: 512 tokens with 64 overlap
# Why 512? Long enough to capture a full paragraph (a complete legal obligation),
# short enough that ChromaDB similarity search stays precise.
CHUNK_SIZE = 512
CHUNK_OVERLAP = 64


def build_index(docs_dir: Path = DOCS_DIR) -> VectorStoreIndex:
    """
    Load all .txt files from docs_dir, chunk them, embed them,
    and store in ChromaDB. Returns the index for querying.
    """

    # Configure embedding model (same as P2)
    Settings.embed_model = OllamaEmbedding(model_name=EMBED_MODEL)

    # Connect to ChromaDB
    chroma_client = chromadb.HttpClient(host="localhost", port=8001)
    collection = chroma_client.get_or_create_collection(COLLECTION_NAME)
    vector_store = ChromaVectorStore(chroma_collection=collection)

    # Load and wrap documents
    documents = []
    for txt_file in sorted(docs_dir.glob("*.txt")):
        content = txt_file.read_text(encoding="utf-8")
        doc = Document(
            text=content,
            metadata={
                "source_file": txt_file.name,
                "source_doc": txt_file.stem,
            }
        )
        documents.append(doc)
        print(f"Loaded: {txt_file.name} ({len(content):,} chars)")

    print(f"\nLoaded {len(documents)} documents. Chunking and embedding...")

    # Chunk and embed — this is the same SentenceSplitter from P2
    splitter = SentenceSplitter(chunk_size=CHUNK_SIZE, chunk_overlap=CHUNK_OVERLAP)

    # Build the index — LlamaIndex handles chunking + embedding + storage
    index = VectorStoreIndex.from_documents(
        documents,
        vector_store=vector_store,
        transformations=[splitter],
        show_progress=True,
    )

    print(f"\nDone. Collection '{COLLECTION_NAME}' ready in ChromaDB.")
    return index


if __name__ == "__main__":
    build_index()
```

Run the ingestion:

```bash
cd projects/04-aiga
python -m api.rag.ingest
```

You will see progress output as each document is chunked and embedded. For the full EU AI Act (~200,000 chars), this takes about 2–3 minutes on first run.

---

### Step 4 — Write the query engine

```python
# projects/04-aiga/api/rag/query.py

import chromadb
from dataclasses import dataclass
from typing import List, Optional
from llama_index.core import VectorStoreIndex
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.embeddings.ollama import OllamaEmbedding
from llama_index.llms.ollama import Ollama
from llama_index.core import Settings, PromptTemplate
from .metadata import format_citation

CHROMA_URL = "http://localhost:8001"
COLLECTION_NAME = "aiga_governance"
TOP_K = 5  # retrieve the 5 most relevant chunks

# The system prompt — tells the LLM to always cite its sources
CITATION_PROMPT = PromptTemplate(
    """You are an AI governance expert assistant.
Answer the question using ONLY the provided context from official governance documents.

Rules:
1. Every claim must be supported by a specific quote from the context.
2. Always cite the exact document, article, and section for each point you make.
3. If you cannot find the answer in the context, say "I could not find information
   about this in the provided governance documents."
4. Do not invent or paraphrase without citation. Legal accuracy matters.

Context from governance documents:
---------------------
{context_str}
---------------------

Question: {query_str}

Answer (with citations):"""
)


@dataclass
class Source:
    document: str       # e.g. "EU AI Act, Article 6"
    quote: str          # short excerpt from the source
    score: float        # similarity score (0-1, higher = more relevant)


@dataclass
class QueryResult:
    answer: str
    sources: List[Source]
    risk_level: Optional[str] = None  # filled in by risk classification chain (P4-T3)


def load_index() -> VectorStoreIndex:
    """Connect to the existing ChromaDB collection and return the index."""
    Settings.embed_model = OllamaEmbedding(model_name="nomic-embed-text")
    Settings.llm = Ollama(model="llama3", request_timeout=120.0)

    chroma_client = chromadb.HttpClient(host="localhost", port=8001)
    collection = chroma_client.get_or_create_collection(COLLECTION_NAME)
    vector_store = ChromaVectorStore(chroma_collection=collection)

    return VectorStoreIndex.from_vector_store(vector_store)


def query_governance(question: str, index: VectorStoreIndex) -> QueryResult:
    """
    Ask a question about governance documents.
    Returns an answer with citations.
    """

    # Create query engine with citation prompt and top-k retrieval
    query_engine = index.as_query_engine(
        text_qa_template=CITATION_PROMPT,
        similarity_top_k=TOP_K,
        response_mode="compact",
    )

    # Run the query
    response = query_engine.query(question)

    # Extract source citations from retrieved nodes
    sources = []
    for node in response.source_nodes:
        metadata = node.node.metadata
        citation = format_citation(metadata)
        quote = node.node.text[:200].replace('\n', ' ').strip()  # first 200 chars as quote
        sources.append(Source(
            document=citation,
            quote=f'"{quote}..."',
            score=round(node.score, 3) if node.score else 0.0,
        ))

    return QueryResult(
        answer=str(response),
        sources=sources,
    )
```

---

### Step 5 — Test the query engine

Create a quick test to confirm everything works:

```python
# projects/04-aiga/test_rag.py

from api.rag.query import load_index, query_governance

def main():
    print("Loading index from ChromaDB...")
    index = load_index()

    test_questions = [
        "What does the EU AI Act say about hiring algorithms?",
        "What are the four functions in the NIST AI Risk Management Framework?",
        "What is the definition of a high-risk AI system?",
    ]

    for question in test_questions:
        print(f"\n{'='*60}")
        print(f"Q: {question}")
        print(f"{'='*60}")
        result = query_governance(question, index)
        print(f"\nA: {result.answer}")
        print(f"\nSources:")
        for source in result.sources:
            print(f"  • {source.document} (score: {source.score})")
            print(f"    {source.quote}")

if __name__ == "__main__":
    main()
```

```bash
python test_rag.py
```

Good output looks like:

```
Q: What does the EU AI Act say about hiring algorithms?
============================================================

A: Hiring algorithms are classified as high-risk AI systems under the EU AI Act.
   Specifically, Article 6 and Annex III, paragraph 4 cover AI systems used
   in employment contexts...

Sources:
  • EU AI Act, Article 6 (score: 0.91)
    "...high-risk AI systems referred to in Annex III shall be..."
  • EU AI Act, Annex III (score: 0.88)
    "...AI systems intended to be used for recruitment or selection of
     natural persons, in particular for advertising vacancies..."
```

Bad output (investigate if you see this):

```
A: The EU AI Act has various provisions about employment...
   [no citations]

Sources:
  (none)
```

---

### Step 6 — Compare with P2 (skill compounding exercise)

Open your P2 RAG code alongside this file. Fill in the table:

| What | In P2 | In P4 |
|------|-------|-------|
| Documents | Your personal files (YAML, JSON, markdown) | EU AI Act, NIST, ISO |
| Chunk size | You chose this in P2-T4 | 512 tokens — same reasoning |
| Embedding model | nomic-embed-text | nomic-embed-text (identical) |
| ChromaDB collection | `personal_rag` | `aiga_governance` |
| LLM prompt | "Answer from my files" | "Answer with legal citations" |
| Source metadata | filename + line number | document name + article number |
| Response format | Free text + file citations | Structured + article citations |

The core engine is identical. You changed the domain, not the architecture. Write this observation in your build log.

---

## Visual overview

```
source-docs/cleaned/                 ChromaDB
  eu-ai-act-2024.txt                 collection: aiga_governance
  nist-ai-rmf-1.0.txt    ingest.py   ┌────────────────────────────────┐
  iso-42001-overview.txt ──────────► │  chunk vectors + metadata       │
  anthropic-model-card.txt           │  [0.2, 0.9, ...] Article 6     │
  ...                                │  [0.7, 0.3, ...] MAP 5.1       │
                                     │  [0.1, 0.8, ...] Clause 6.1    │
                                     └────────────────┬───────────────┘
                                                      │
  Question: "What does the EU AI Act                  │ similarity search
  say about facial recognition?"                      │ (top 5 chunks)
                  │                                   │
                  ▼                                   ▼
            embed question ──────────────► retrieve relevant chunks
                                                      │
                                                      ▼
                                         Ollama llama3
                                         "Answer only from these
                                          chunks, cite everything"
                                                      │
                                                      ▼
                                         answer + source citations
```

---

## Learning checkpoint

After the test runs, ask yourself:
- Does every answer include a source citation?
- Does the cited article actually exist in the document you downloaded?
- Can you open the `.txt` file and find the quoted text?

If the answer to any of these is "no", your chunking or metadata extraction needs adjustment. This is normal — iterate.

---

## Done when

- [ ] `python -m api.rag.ingest` runs without errors and populates ChromaDB
- [ ] `python test_rag.py` returns answers with source citations for all 3 test questions
- [ ] Every answer includes at least one citation with document name + article/section
- [ ] Citations can be verified by opening the source `.txt` file

---

## Next step

→ [P4-T3: Build EU AI Act risk classification prompt chain](p4-t3-risk-classification.md)
