# P4-T3: Build EU AI Act Risk Classification Prompt Chain

> **Goal:** Build a multi-step prompt chain that takes a plain-English description of an AI system and returns its EU AI Act risk level, the reasoning, the relevant articles, required compliance actions, and documentation needed.

**Part of:** [P4-E1: AIGA](p4-e1-aiga.md)
**Week:** 6
**Labels:** `task`, `p4-aiga`

---

## What you are doing

The EU AI Act sorts every AI system into one of four risk buckets. This task builds the engine that looks at a description of an AI system (e.g. "a tool that screens job applications") and automatically classifies it into the right bucket — then tells you exactly what you need to do about it.

This is a "prompt chain" — instead of asking one big question, you break the problem into two focused steps:
1. Classify the risk level
2. Get the specific obligations for that risk level

You will design the chain on paper (or in a diagram) before you write any code. This is a professional habit: plan before building.

---

## Background: The 4 EU AI Act risk levels

Before writing code, you must understand what you are classifying. Here is the EU AI Act risk model:

```
UNACCEPTABLE RISK — Banned outright
┌────────────────────────────────────────────────────────────┐
│ These AI systems cannot be deployed in the EU at all.      │
│                                                            │
│ Examples:                                                  │
│  • Social credit scoring by governments                    │
│  • Real-time biometric surveillance in public spaces       │
│    (with narrow exceptions for law enforcement)            │
│  • Subliminal manipulation techniques                      │
│  • Exploiting vulnerabilities of specific groups           │
│                                                            │
│ Legal basis: EU AI Act, Article 5                          │
└────────────────────────────────────────────────────────────┘

HIGH RISK — Regulated, must comply
┌────────────────────────────────────────────────────────────┐
│ These can be deployed, but only with strict safeguards.    │
│                                                            │
│ Examples (from Annex III):                                 │
│  • Hiring / recruitment algorithms                         │
│  • Credit scoring systems                                  │
│  • Medical diagnostic AI                                   │
│  • AI used in education (exam scoring)                     │
│  • Biometric identification systems                        │
│  • AI in critical infrastructure (energy, water, traffic)  │
│  • Law enforcement AI                                      │
│  • Border control AI                                       │
│                                                            │
│ Requirements: conformity assessment, technical docs,       │
│ human oversight, EU database registration, transparency    │
│                                                            │
│ Legal basis: EU AI Act, Articles 6-51, Annex III           │
└────────────────────────────────────────────────────────────┘

LIMITED RISK — Transparency requirements only
┌────────────────────────────────────────────────────────────┐
│ These have lighter requirements — mainly: tell people      │
│ they are talking to AI.                                    │
│                                                            │
│ Examples:                                                  │
│  • Customer service chatbots                               │
│  • AI content generation tools                             │
│  • Deepfake generators (must label output as AI-made)      │
│                                                            │
│ Requirement: disclose that the system is an AI             │
│                                                            │
│ Legal basis: EU AI Act, Article 50                         │
└────────────────────────────────────────────────────────────┘

MINIMAL RISK — No requirements
┌────────────────────────────────────────────────────────────┐
│ No compliance obligations. Deploy freely.                  │
│                                                            │
│ Examples:                                                  │
│  • Spam filters                                            │
│  • AI in video games                                       │
│  • AI-powered playlists                                    │
│  • Recommendation engines for entertainment               │
│                                                            │
│ Legal basis: EU AI Act recitals (implicitly not covered)   │
└────────────────────────────────────────────────────────────┘
```

---

## Why this step matters

Without a risk classifier, AIGA can only answer free-form questions. With a risk classifier, AIGA can take someone from "I have this AI system idea" to "here is your compliance checklist" in under 30 seconds. That is the product value that makes this worth sharing.

---

## Prerequisites

- [ ] P4-T2 completed — the RAG pipeline is working and can return citations
- [ ] Ollama running with `llama3` model
- [ ] Python `pydantic` installed: `pip install pydantic`

---

## Step-by-step instructions

### Step 1 — Draw the chain before building it

Draw this on paper or a whiteboard before touching code. Here is the design:

```
User input: plain-English description of the AI system
  │
  ▼
┌──────────────────────────────────────────────────────────────┐
│  STEP 1 of chain: RISK LEVEL CLASSIFICATION                  │
│                                                              │
│  Prompt: "You are an EU AI Act expert. Given this system     │
│  description, classify it. Return JSON with:                 │
│    - risk_level (one of 4 levels)                            │
│    - reasoning (why you chose this level)                    │
│    - relevant_articles (which articles apply)"               │
│                                                              │
│  LLM reads: system description + EU AI Act chunks from RAG   │
│  LLM outputs: { risk_level, reasoning, relevant_articles }   │
└──────────────────────────┬───────────────────────────────────┘
                           │ risk_level + relevant_articles
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  STEP 2 of chain: COMPLIANCE OBLIGATIONS LOOKUP              │
│                                                              │
│  Prompt: "The system is HIGH_RISK. Articles 6 and Annex III  │
│  apply. What are the specific compliance obligations?"       │
│                                                              │
│  LLM reads: risk level + articles + EU AI Act chunks from RAG│
│  LLM outputs: { compliance_obligations, documentation_       │
│               required, human_oversight_required,            │
│               timeline, penalty_if_non_compliant }           │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
Final output:
  {
    "risk_level": "HIGH_RISK",
    "reasoning": "...",
    "relevant_articles": ["Article 6", "Annex III, paragraph 4"],
    "compliance_obligations": ["Conduct conformity assessment", ...],
    "documentation_required": ["Technical documentation", ...],
    "human_oversight_required": true,
    "timeline": "Before deployment",
    "penalty_if_non_compliant": "Up to €30 million or 6% of global revenue"
  }
```

---

### Step 2 — Define the output schemas (Pydantic)

Strong types make chains reliable. Define what each step must return.

```python
# projects/04-aiga/api/rag/risk_schema.py

from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum


class RiskLevel(str, Enum):
    UNACCEPTABLE_RISK = "UNACCEPTABLE_RISK"
    HIGH_RISK = "HIGH_RISK"
    LIMITED_RISK = "LIMITED_RISK"
    MINIMAL_RISK = "MINIMAL_RISK"


class RiskClassificationStep1(BaseModel):
    """Output of the first step in the chain — classification only."""
    risk_level: RiskLevel
    reasoning: str = Field(description="Why this risk level was chosen, referencing specific articles")
    relevant_articles: List[str] = Field(description="List of EU AI Act articles that apply")
    confidence: str = Field(description="HIGH, MEDIUM, or LOW — how confident is the classification")


class ComplianceObligations(BaseModel):
    """Output of the second step in the chain — what you must do."""
    compliance_obligations: List[str] = Field(
        description="List of actions required before/after deployment"
    )
    documentation_required: List[str] = Field(
        description="Documents that must be created and maintained"
    )
    human_oversight_required: bool
    timeline: str = Field(description="When these obligations must be met")
    penalty_if_non_compliant: Optional[str] = Field(
        description="Maximum penalty under the EU AI Act"
    )


class RiskAssessmentResult(BaseModel):
    """The final combined output returned to the user."""
    system_description: str
    risk_level: RiskLevel
    reasoning: str
    relevant_articles: List[str]
    compliance_obligations: List[str]
    documentation_required: List[str]
    human_oversight_required: bool
    timeline: str
    penalty_if_non_compliant: Optional[str]
    confidence: str

    def risk_badge(self) -> str:
        """Return a text badge for display in the UI."""
        badges = {
            RiskLevel.UNACCEPTABLE_RISK: "[BANNED]",
            RiskLevel.HIGH_RISK: "[HIGH RISK]",
            RiskLevel.LIMITED_RISK: "[LIMITED RISK]",
            RiskLevel.MINIMAL_RISK: "[MINIMAL RISK]",
        }
        return badges[self.risk_level]
```

---

### Step 3 — Build the risk classification chain

```python
# projects/04-aiga/api/rag/risk_classifier.py

import json
import re
from llama_index.core import VectorStoreIndex
from llama_index.llms.ollama import Ollama
from llama_index.core import Settings
from .risk_schema import RiskClassificationStep1, ComplianceObligations, RiskAssessmentResult, RiskLevel
from .query import load_index, query_governance

# ---- Prompt templates ----

STEP1_PROMPT = """You are an EU AI Act compliance expert.

A user has described their AI system as follows:
"{system_description}"

Based on the EU AI Act, classify this AI system into one of these four risk levels:
- UNACCEPTABLE_RISK: Systems banned outright (Article 5)
- HIGH_RISK: Systems requiring conformity assessment and registration (Article 6 + Annex III)
- LIMITED_RISK: Systems with transparency obligations only (Article 50)
- MINIMAL_RISK: Systems with no specific EU AI Act obligations

Reference material from the EU AI Act:
{context}

Return your answer as valid JSON only. No explanation outside the JSON.
Format:
{{
  "risk_level": "HIGH_RISK",
  "reasoning": "This system falls under Annex III, paragraph 4 because...",
  "relevant_articles": ["Article 6", "Annex III, paragraph 4"],
  "confidence": "HIGH"
}}"""


STEP2_PROMPT = """You are an EU AI Act compliance expert.

An AI system has been classified as: {risk_level}
Relevant articles: {relevant_articles}
System description: "{system_description}"

Reference material:
{context}

What are the specific compliance obligations for this system?

Return valid JSON only:
{{
  "compliance_obligations": [
    "Conduct a conformity assessment before deployment",
    "Register the system in the EU AI database"
  ],
  "documentation_required": [
    "Technical documentation (Article 11)",
    "Risk management records (Article 9)"
  ],
  "human_oversight_required": true,
  "timeline": "Before placing the system on the market",
  "penalty_if_non_compliant": "Up to €30 million or 6% of annual global turnover"
}}"""


# ---- The chain itself ----

def classify_risk(
    system_description: str,
    index: VectorStoreIndex,
    llm: Ollama = None,
) -> RiskAssessmentResult:
    """
    Run the two-step risk classification chain.

    Step 1: Classify risk level
    Step 2: Get compliance obligations
    Returns a fully structured RiskAssessmentResult.
    """

    if llm is None:
        llm = Ollama(model="llama3", request_timeout=120.0)

    # -- STEP 1: Classify the risk level --

    # Get relevant context from RAG (search for risk classification articles)
    classification_query = (
        f"EU AI Act risk classification for: {system_description}. "
        f"Article 5 prohibited AI. Article 6 high risk. Annex III list."
    )
    rag_result = query_governance(classification_query, index)

    # Build context string from retrieved chunks
    context_step1 = "\n\n".join([
        f"[{s.document}]\n{s.quote}" for s in rag_result.sources
    ])

    step1_prompt_filled = STEP1_PROMPT.format(
        system_description=system_description,
        context=context_step1,
    )

    step1_response = llm.complete(step1_prompt_filled)
    step1_json = _extract_json(str(step1_response))
    step1_data = RiskClassificationStep1(**step1_json)

    # -- STEP 2: Get compliance obligations --

    # Search for the specific obligations for this risk level
    obligations_query = (
        f"EU AI Act compliance obligations for {step1_data.risk_level}. "
        f"{' '.join(step1_data.relevant_articles)}. "
        f"Documentation required. Human oversight. Conformity assessment."
    )
    rag_obligations = query_governance(obligations_query, index)
    context_step2 = "\n\n".join([
        f"[{s.document}]\n{s.quote}" for s in rag_obligations.sources
    ])

    step2_prompt_filled = STEP2_PROMPT.format(
        risk_level=step1_data.risk_level,
        relevant_articles=", ".join(step1_data.relevant_articles),
        system_description=system_description,
        context=context_step2,
    )

    step2_response = llm.complete(step2_prompt_filled)
    step2_json = _extract_json(str(step2_response))
    step2_data = ComplianceObligations(**step2_json)

    # -- Combine results --
    return RiskAssessmentResult(
        system_description=system_description,
        risk_level=step1_data.risk_level,
        reasoning=step1_data.reasoning,
        relevant_articles=step1_data.relevant_articles,
        compliance_obligations=step2_data.compliance_obligations,
        documentation_required=step2_data.documentation_required,
        human_oversight_required=step2_data.human_oversight_required,
        timeline=step2_data.timeline,
        penalty_if_non_compliant=step2_data.penalty_if_non_compliant,
        confidence=step1_data.confidence,
    )


def _extract_json(text: str) -> dict:
    """Extract the first JSON object from LLM output text."""
    # LLMs sometimes add text before/after the JSON — find the JSON block
    match = re.search(r'\{.*\}', text, re.DOTALL)
    if not match:
        raise ValueError(f"No JSON found in LLM response: {text[:200]}")
    return json.loads(match.group(0))
```

---

### Step 4 — Test the chain with real examples

```python
# projects/04-aiga/test_risk_classifier.py

from api.rag.query import load_index
from api.rag.risk_classifier import classify_risk

def test_case(description: str, index):
    print(f"\n{'='*65}")
    print(f"System: {description}")
    print('='*65)
    result = classify_risk(description, index)
    print(f"\nRisk level:  {result.risk_badge()} {result.risk_level}")
    print(f"Confidence:  {result.confidence}")
    print(f"\nReasoning:   {result.reasoning}")
    print(f"\nArticles:    {', '.join(result.relevant_articles)}")
    print(f"\nObligations:")
    for i, ob in enumerate(result.compliance_obligations, 1):
        print(f"  {i}. {ob}")
    print(f"\nDocumentation required:")
    for doc in result.documentation_required:
        print(f"  - {doc}")
    print(f"\nHuman oversight required: {result.human_oversight_required}")
    print(f"Timeline: {result.timeline}")
    if result.penalty_if_non_compliant:
        print(f"Penalty: {result.penalty_if_non_compliant}")


index = load_index()

# These 4 cases cover all 4 risk levels
test_case("A tool that automatically screens and ranks job applications", index)
test_case("A chatbot on our website that answers customer questions", index)
test_case("An AI playlist recommendation engine for a music app", index)
test_case("A system that scores citizens on social trustworthiness for government benefits", index)
```

Expected output pattern:

```
System: A tool that automatically screens and ranks job applications
=================================================================
Risk level:  [HIGH RISK] HIGH_RISK
Confidence:  HIGH

Reasoning:   This system falls under Annex III, paragraph 4, which lists
             "AI systems intended to be used for recruitment or selection of
             natural persons" as High-Risk systems...

Articles:    Article 6, Annex III paragraph 4

Obligations:
  1. Conduct conformity assessment before deployment
  2. Register system in EU AI database
  3. Implement human oversight mechanism
  4. Maintain technical documentation

Documentation required:
  - Technical documentation (Article 11)
  - Risk management records (Article 9)
  - Logs of system operation (Article 12)

Human oversight required: True
Timeline: Before placing the system on the market or putting into service
Penalty: Up to €30 million or 6% of annual global turnover
```

---

## Visual overview

```
User: "An AI that screens job applications"
                │
                ▼
    ┌───────────────────────────┐
    │  STEP 1: Classify         │
    │                           │
    │  RAG search:              │
    │  "Article 5, Article 6,   │
    │   Annex III risk levels"  │
    │           │               │
    │           ▼               │
    │  Ollama llama3            │
    │  → JSON response          │
    │  { risk_level: HIGH_RISK, │
    │    articles: [Art.6,      │
    │               Annex III]} │
    └──────────┬────────────────┘
               │ risk_level + articles
               ▼
    ┌───────────────────────────┐
    │  STEP 2: Obligations      │
    │                           │
    │  RAG search:              │
    │  "HIGH_RISK obligations   │
    │   Article 6 Annex III     │
    │   conformity assessment"  │
    │           │               │
    │           ▼               │
    │  Ollama llama3            │
    │  → JSON response          │
    │  { obligations: [...],    │
    │    documentation: [...],  │
    │    human_oversight: true }│
    └──────────┬────────────────┘
               │
               ▼
    Combined RiskAssessmentResult
    (all fields in one structured object)
```

---

## Learning checkpoint

After the tests pass, think about:

1. Why two steps instead of one big prompt?
   - Step 1 focuses on classification only. Fewer decisions = higher accuracy.
   - Step 2 can look up the RIGHT obligations because it already knows the risk level.
   - One combined prompt tends to mix up the reasoning.

2. Why use Pydantic models?
   - The LLM might return slightly different JSON each time.
   - Pydantic validates and normalises the structure.
   - If the LLM returns an invalid risk level string, Pydantic raises an error immediately.

3. Why does the chain call RAG twice?
   - Step 1 needs articles about risk classification.
   - Step 2 needs articles about compliance obligations.
   - These are in different parts of the EU AI Act — two separate searches are more precise than one.

---

## Done when

- [ ] `test_risk_classifier.py` returns structured JSON for all 4 test cases
- [ ] Hiring algorithm → `HIGH_RISK`
- [ ] Customer chatbot → `LIMITED_RISK`
- [ ] Music playlist → `MINIMAL_RISK`
- [ ] Social credit scoring → `UNACCEPTABLE_RISK`
- [ ] Every result includes at least 2 compliance obligations
- [ ] Every result cites at least one EU AI Act article

---

## Next step

→ [P4-T4: Build chat interface with source citation](p4-t4-chat-interface.md)
