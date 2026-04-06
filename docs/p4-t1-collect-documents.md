# P4-T1: Collect and Clean Governance Source Documents

> **Goal:** Download the public governance documents that AIGA will be built on, clean them so the RAG system can read them reliably, and create sample AI policy templates.

**Part of:** [P4-US1: Governance RAG System](p4-us1-governance-rag.md)
**Week:** 5
**Labels:** `task`, `p4-aiga`

---

## What you are doing

You are downloading the source documents that AIGA will search over. Think of this as loading the books into a library before anyone can ask questions.

The EU AI Act, NIST AI RMF, and ISO 42001 are real legal and standards documents — they are long, full of footnotes, and have headers and footers on every page. Those extra elements confuse the RAG chunker. This task is about getting clean, well-structured text files the system can actually use.

No code yet. This is research and preparation work — but it is the foundation everything else depends on.

---

## Why this step matters

Garbage in, garbage out. If your source documents are poorly formatted:
- The chunker will split text in the middle of important sentences
- Citations will point to the wrong place
- The AI will hallucinate because it cannot find the relevant section

Spending an hour cleaning documents now saves you days of debugging wrong answers later.

---

## Prerequisites

- [ ] `projects/04-aiga/source-docs/` directory created
- [ ] A PDF viewer installed (to inspect documents before cleaning)
- [ ] Python installed with `pdfminer.six` or `pypdf` (`pip install pypdf pdfminer.six`)

---

## Step-by-step instructions

### Step 1 — Create the directory structure

```bash
mkdir -p projects/04-aiga/source-docs/raw
mkdir -p projects/04-aiga/source-docs/cleaned
mkdir -p projects/04-aiga/source-docs/sample
mkdir -p projects/04-aiga/source-docs/templates
```

Your folder layout should look like this:

```
projects/04-aiga/
  source-docs/
    raw/          ← original PDFs go here, untouched
    cleaned/      ← cleaned .txt files go here
    sample/       ← a small subset that ships with the repo
    templates/    ← your fictional AI policy templates
```

---

### Step 2 — Download the source documents

#### EU AI Act

1. Go to: `https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689`
2. Click "PDF" to download the official full text
3. Save as `projects/04-aiga/source-docs/raw/eu-ai-act-2024.pdf`

The EU AI Act is the core regulation. It is 144 pages. The key sections to know:

```
EU AI Act structure (simplified):
  ├── Title I: General Provisions (definitions)
  ├── Title II: Prohibited AI Practices (Article 5)
  ├── Title III: High-Risk AI Systems
  │     ├── Chapter 1: Classification (Article 6)
  │     ├── Chapter 2: Requirements (Articles 8-15)
  │     └── Annex III: List of high-risk use cases
  ├── Title IV: Transparency Obligations
  └── Title X: Penalties
```

#### NIST AI Risk Management Framework

1. Go to: `https://airc.nist.gov/RMF/1`
2. Download the PDF version
3. Save as `projects/04-aiga/source-docs/raw/nist-ai-rmf-1.0.pdf`

NIST AI RMF organises AI risk management into four functions:

```
NIST AI RMF structure:
  ├── GOVERN  ← policies, accountability, culture
  ├── MAP     ← identify context and risks
  ├── MEASURE ← quantify and analyse risks
  └── MANAGE  ← prioritise and treat risks
```

#### ISO 42001

ISO 42001 is not fully free, but the publicly available overview and scope are sufficient for AIGA. Download what is publicly available:

1. Go to: `https://www.iso.org/standard/81230.html`
2. Download the free preview/scope document
3. Save as `projects/04-aiga/source-docs/raw/iso-42001-overview.pdf`

For a more complete picture, search for "ISO 42001 overview PDF" — several organisations have published detailed summaries under open licences.

#### Model Cards

1. Anthropic model card: `https://www.anthropic.com/model-card`
   - Save the page as PDF or copy the text
   - Save as `projects/04-aiga/source-docs/raw/anthropic-model-card.pdf`

2. OpenAI GPT-4 system card: `https://openai.com/research/gpt-4-system-card`
   - Save as `projects/04-aiga/source-docs/raw/openai-gpt4-system-card.pdf`

---

### Step 3 — Extract and clean the text

Run this Python script to extract clean text from each PDF:

```python
# projects/04-aiga/scripts/clean_docs.py

import re
from pathlib import Path
import pypdf

RAW_DIR = Path("source-docs/raw")
CLEAN_DIR = Path("source-docs/cleaned")
CLEAN_DIR.mkdir(exist_ok=True)

def clean_text(raw_text: str) -> str:
    """Remove common PDF artifacts that confuse the RAG chunker."""

    # Remove page numbers (e.g. "- 12 -" or just "12" on its own line)
    text = re.sub(r'^\s*[-–]?\s*\d+\s*[-–]?\s*$', '', raw_text, flags=re.MULTILINE)

    # Remove running headers/footers (short lines with "Official Journal" or "EUR-Lex")
    text = re.sub(r'^.*(Official Journal|EUR-Lex|EN L \d+|NIST|Regulation \(EU\)).*$',
                  '', text, flags=re.MULTILINE | re.IGNORECASE)

    # Collapse multiple blank lines into one
    text = re.sub(r'\n{3,}', '\n\n', text)

    # Fix hyphenated line breaks (common in PDFs: "regu-\nlation" → "regulation")
    text = re.sub(r'(\w)-\n(\w)', r'\1\2', text)

    return text.strip()

def extract_pdf(pdf_path: Path, output_path: Path):
    reader = pypdf.PdfReader(str(pdf_path))
    all_text = []

    for page_num, page in enumerate(reader.pages, start=1):
        page_text = page.extract_text() or ""
        all_text.append(f"\n\n--- Page {page_num} ---\n\n{page_text}")

    raw = "\n".join(all_text)
    cleaned = clean_text(raw)

    output_path.write_text(cleaned, encoding="utf-8")
    print(f"Cleaned: {pdf_path.name} → {output_path.name} ({len(cleaned):,} characters)")

# Process all PDFs
for pdf_file in RAW_DIR.glob("*.pdf"):
    output_file = CLEAN_DIR / (pdf_file.stem + ".txt")
    extract_pdf(pdf_file, output_file)

print("Done. Check source-docs/cleaned/ for output files.")
```

Run it:

```bash
cd projects/04-aiga
python scripts/clean_docs.py
```

---

### Step 4 — Inspect the cleaned files

Open each `.txt` file and check:

```
Things to look for:
  ✓ Article numbers are intact (e.g. "Article 6" appears on its own line)
  ✓ No garbled text from tables (tables in PDFs often extract badly)
  ✓ No repeated headers every 40 lines
  ✓ Sentences are complete (not cut off mid-word)
```

If articles are missing or text looks garbled, you may need to clean more aggressively. Add additional `re.sub()` patterns to `clean_text()` for any artifacts you spot.

---

### Step 5 — Create sample documents for the repo

The repo will ship with a small set of sample documents so that anyone who clones it can run AIGA immediately without downloading the full PDFs. Create trimmed versions:

```python
# projects/04-aiga/scripts/create_samples.py
# Take the first 50,000 characters of each cleaned document as a sample

from pathlib import Path

CLEAN_DIR = Path("source-docs/cleaned")
SAMPLE_DIR = Path("source-docs/sample")
SAMPLE_DIR.mkdir(exist_ok=True)

SAMPLE_SIZE = 50_000  # characters — enough for meaningful demo queries

for txt_file in CLEAN_DIR.glob("*.txt"):
    content = txt_file.read_text(encoding="utf-8")
    sample = content[:SAMPLE_SIZE]
    sample_path = SAMPLE_DIR / txt_file.name
    sample_path.write_text(sample, encoding="utf-8")
    print(f"Sample created: {sample_path.name} ({len(sample):,} chars)")
```

---

### Step 6 — Create AI policy templates

Create 2–3 fictional company AI policy templates. These serve two purposes:
1. They make AIGA more useful (people can ask "does my policy cover X?")
2. They are example content for demos

Save these in `source-docs/templates/`:

**`source-docs/templates/company-ai-policy-template.md`**

```markdown
# [Company Name] Artificial Intelligence Use Policy
Version: 1.0 | Last updated: [Date] | Owner: [CTO / Compliance Lead]

## 1. Purpose and Scope

This policy governs the development, procurement, and deployment of artificial
intelligence systems within [Company Name]. It applies to all employees,
contractors, and third-party vendors who build or use AI systems on behalf of
[Company Name].

## 2. Definitions

- **AI System:** Any software that uses machine learning, neural networks,
  or rule-based approaches to generate outputs (recommendations, decisions,
  content) from inputs.
- **High-Risk AI System:** Any AI system that falls under Annex III of the
  EU AI Act, including systems used in hiring, credit scoring, or healthcare.
- **Human Oversight:** A defined process where a human reviews and can override
  any AI-generated decision before it affects a person.

## 3. Prohibited Uses

The following uses of AI are prohibited at [Company Name]:

- Using AI to make final hiring or termination decisions without human review
- Using AI to score, rank, or profile employees without their knowledge
- Deploying AI systems in safety-critical contexts without approved risk assessment
- Using AI-generated content in customer communications without disclosure

## 4. Governance Requirements

### 4.1 Before Deployment
All AI systems must be assessed against:
- EU AI Act risk classification (is this a High-Risk system?)
- Our internal AI Risk Register
- Data protection impact assessment (if personal data is processed)

### 4.2 Documentation Required
For High-Risk AI systems, maintain:
- Technical documentation (model type, training data description, accuracy metrics)
- Risk management records (updated quarterly)
- Incident log (any unexpected outputs or complaints)

### 4.3 Human Oversight
High-Risk systems must have:
- A named human responsible for oversight
- A defined escalation path when the AI output is disputed
- A mechanism for affected persons to request human review

## 5. Vendor Assessment

When procuring third-party AI tools, verify:
- Does the vendor provide a model card or system card?
- Is the system classified as High-Risk under the EU AI Act?
- Does the vendor's data processing agreement cover AI-specific risks?

## 6. Review

This policy is reviewed annually or when relevant regulations change.
```

**`source-docs/templates/ai-system-registration-template.md`**

```markdown
# AI System Registration Form
Use this form to register any new AI system before deployment.

## System Details
- System name:
- System description (plain English, 2-3 sentences):
- Department / team owner:
- Deployment date:

## Risk Classification
- EU AI Act risk level: [ ] Unacceptable  [ ] High  [ ] Limited  [ ] Minimal
- Basis for classification (cite article/annex):
- Does this system process personal data? [ ] Yes  [ ] No
- Does this system make or influence decisions about people? [ ] Yes  [ ] No

## If High Risk — Required Actions
- [ ] Technical documentation completed
- [ ] Conformity assessment completed
- [ ] Human oversight process documented
- [ ] Registered in EU AI database (if required)
- [ ] Named human oversight contact:

## Approval
- Completed by:
- Reviewed by CTO/Compliance Lead:
- Date approved:
```

---

## Visual overview

```
  source-docs/
    │
    ├── raw/                 ← untouched PDFs from official sources
    │     eu-ai-act-2024.pdf
    │     nist-ai-rmf-1.0.pdf
    │     iso-42001-overview.pdf
    │     anthropic-model-card.pdf
    │     openai-gpt4-system-card.pdf
    │
    ├── cleaned/             ← text extracted + headers/footers removed
    │     eu-ai-act-2024.txt      (~200,000 chars)
    │     nist-ai-rmf-1.0.txt     (~100,000 chars)
    │     iso-42001-overview.txt  (~20,000 chars)
    │     anthropic-model-card.txt
    │     openai-gpt4-system-card.txt
    │
    ├── sample/              ← trimmed versions shipped with the repo
    │     (first 50k chars of each cleaned file)
    │
    └── templates/           ← fictional company policy templates
          company-ai-policy-template.md
          ai-system-registration-template.md
```

---

## Learning checkpoint

Before moving on, open `cleaned/eu-ai-act-2024.txt` and find:
- Article 5 (list of prohibited AI practices)
- Article 6 (definition of high-risk AI systems)
- Annex III (the list of high-risk use cases)

You do not need to memorise them. Just know where they are. The RAG system will find them for you later — but it helps to have seen them once.

---

## Done when

- [ ] All 5 documents downloaded to `source-docs/raw/`
- [ ] All 5 documents cleaned and saved to `source-docs/cleaned/`
- [ ] Sample versions created in `source-docs/sample/`
- [ ] At least 2 policy templates created in `source-docs/templates/`
- [ ] You can open each `.txt` file and see clean, readable article text

---

## Next step

→ [P4-T2: Build RAG pipeline over governance documents](p4-t2-governance-rag.md)
