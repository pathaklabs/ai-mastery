# P4-T4: Build Chat Interface with Source Citation

> **Goal:** Build a FastAPI backend and React frontend where users can ask governance questions and see answers with cited articles and a risk level badge.

**Part of:** [P4-E1: AIGA](p4-e1-aiga.md)
**Weeks:** 6–7
**Labels:** `task`, `p4-aiga`

---

## What you are doing

Up to this point, AIGA runs in the terminal. This task gives it a face — a web-based chat interface where anyone can type a question and see a clear, cited answer in their browser.

The interface has two key design decisions baked in:
1. **Citations are always visible** — not hidden in a dropdown, not optional. Every answer shows its sources.
2. **Risk level is a badge** — if the question triggered risk classification, the risk level appears as a coloured badge next to the answer. Colour = severity.

---

## Why this step matters

A terminal-only tool reaches developers. A web UI reaches everyone else — engineering managers, compliance leads, lawyers, founders. The web interface is what makes AIGA shareable and screenshot-able for the blog post.

---

## Prerequisites

- [ ] P4-T2 completed — RAG query engine works and returns citations
- [ ] P4-T3 completed — risk classification chain works
- [ ] `fastapi`, `uvicorn`, `pydantic` installed: `pip install fastapi uvicorn pydantic`
- [ ] Node.js installed for the React frontend

---

## Step-by-step instructions

### Step 1 — Design the API contract

Before writing any code, agree on what the API will return. This contract is what both the backend (FastAPI) and frontend (React) must agree on.

```
POST /api/query
Request body:
  {
    "question": "What does the EU AI Act say about facial recognition?",
    "mode": "chat"        // "chat" or "risk-assessment"
  }

Response:
  {
    "answer": "Facial recognition systems in public spaces...",
    "risk_level": "HIGH_RISK",   // null if not risk-related
    "sources": [
      {
        "document": "EU AI Act, Article 5(1)(d)",
        "quote": "...real-time remote biometric identification systems in publicly accessible spaces...",
        "score": 0.94
      },
      {
        "document": "NIST AI RMF, MAP 5.1",
        "quote": "...likelihood and magnitude of each identified impact...",
        "score": 0.81
      }
    ],
    "compliance_obligations": [],    // populated if risk_level is set
    "processing_time_ms": 1240
  }
```

---

### Step 2 — Build the FastAPI backend

```python
# projects/04-aiga/api/main.py

import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List

from .rag.query import load_index, query_governance, QueryResult
from .rag.risk_classifier import classify_risk

# Global index — loaded once at startup, shared across all requests
_index = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load the ChromaDB index on startup."""
    global _index
    print("Loading governance index from ChromaDB...")
    _index = load_index()
    print("Index ready.")
    yield
    # Cleanup on shutdown (nothing needed for ChromaDB client)


app = FastAPI(
    title="AIGA — AI Governance Assistant",
    description="Ask questions about EU AI Act, NIST AI RMF, and ISO 42001",
    version="0.1.0",
    lifespan=lifespan,
)

# Allow the React frontend (running on port 3000) to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---- Request / Response models ----

class QueryRequest(BaseModel):
    question: str
    mode: str = "chat"  # "chat" or "risk-assessment"


class SourceItem(BaseModel):
    document: str
    quote: str
    score: float


class QueryResponse(BaseModel):
    answer: str
    risk_level: Optional[str] = None
    sources: List[SourceItem]
    compliance_obligations: List[str] = []
    documentation_required: List[str] = []
    human_oversight_required: Optional[bool] = None
    processing_time_ms: int


# ---- Endpoints ----

@app.get("/health")
def health_check():
    return {"status": "ok", "index_loaded": _index is not None}


@app.post("/api/query", response_model=QueryResponse)
def query(req: QueryRequest):
    if _index is None:
        raise HTTPException(status_code=503, detail="Index not loaded yet")

    start = time.monotonic()

    if req.mode == "risk-assessment":
        # Run the full risk classification chain
        result = classify_risk(req.question, _index)
        sources = [
            SourceItem(document=a, quote="", score=1.0)
            for a in result.relevant_articles
        ]
        return QueryResponse(
            answer=result.reasoning,
            risk_level=result.risk_level,
            sources=sources,
            compliance_obligations=result.compliance_obligations,
            documentation_required=result.documentation_required,
            human_oversight_required=result.human_oversight_required,
            processing_time_ms=int((time.monotonic() - start) * 1000),
        )
    else:
        # Standard chat query with citations
        result: QueryResult = query_governance(req.question, _index)
        sources = [
            SourceItem(document=s.document, quote=s.quote, score=s.score)
            for s in result.sources
        ]
        return QueryResponse(
            answer=result.answer,
            risk_level=result.risk_level,
            sources=sources,
            processing_time_ms=int((time.monotonic() - start) * 1000),
        )
```

Start the API:

```bash
cd projects/04-aiga
uvicorn api.main:app --reload --port 8000
```

Test it:

```bash
curl -s -X POST http://localhost:8000/api/query \
  -H "Content-Type: application/json" \
  -d '{"question": "What is a high-risk AI system?", "mode": "chat"}' \
  | python -m json.tool
```

---

### Step 3 — Scaffold the React frontend

```bash
cd projects/04-aiga
npx create-react-app frontend --template typescript
cd frontend
npm install axios
```

---

### Step 4 — Build the chat component

```typescript
// projects/04-aiga/frontend/src/components/ChatInterface.tsx

import React, { useState } from 'react';
import axios from 'axios';

const API_URL = 'http://localhost:8000/api/query';

interface Source {
  document: string;
  quote: string;
  score: number;
}

interface QueryResponse {
  answer: string;
  risk_level: string | null;
  sources: Source[];
  compliance_obligations: string[];
  documentation_required: string[];
  human_oversight_required: boolean | null;
  processing_time_ms: number;
}

// Risk level → badge colour mapping
const RISK_BADGE_STYLES: Record<string, React.CSSProperties> = {
  UNACCEPTABLE_RISK: { backgroundColor: '#7B0000', color: '#fff' },
  HIGH_RISK:         { backgroundColor: '#C0392B', color: '#fff' },
  LIMITED_RISK:      { backgroundColor: '#E67E22', color: '#fff' },
  MINIMAL_RISK:      { backgroundColor: '#27AE60', color: '#fff' },
};

const RISK_BADGE_LABELS: Record<string, string> = {
  UNACCEPTABLE_RISK: 'BANNED',
  HIGH_RISK:         'HIGH RISK',
  LIMITED_RISK:      'LIMITED RISK',
  MINIMAL_RISK:      'MINIMAL RISK',
};

function RiskBadge({ level }: { level: string }) {
  const style = RISK_BADGE_STYLES[level] || {};
  const label = RISK_BADGE_LABELS[level] || level;
  return (
    <span style={{
      ...style,
      padding: '4px 12px',
      borderRadius: '4px',
      fontWeight: 'bold',
      fontSize: '13px',
      marginLeft: '8px',
    }}>
      {label}
    </span>
  );
}

export function ChatInterface() {
  const [question, setQuestion] = useState('');
  const [response, setResponse] = useState<QueryResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const ask = async () => {
    if (!question.trim()) return;
    setLoading(true);
    setError('');
    setResponse(null);

    try {
      const res = await axios.post<QueryResponse>(API_URL, {
        question,
        mode: 'chat',
      });
      setResponse(res.data);
    } catch (err) {
      setError('Failed to get a response. Is the API running?');
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      ask();
    }
  };

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '24px', fontFamily: 'system-ui' }}>
      <h1 style={{ marginBottom: '4px' }}>AIGA</h1>
      <p style={{ color: '#666', marginTop: '0' }}>
        AI Governance Assistant — Ask about EU AI Act, NIST AI RMF, ISO 42001
      </p>

      {/* Input area */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
        <textarea
          value={question}
          onChange={e => setQuestion(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Ask a governance question... e.g. What does the EU AI Act require for a hiring algorithm?"
          rows={3}
          style={{
            flex: 1,
            padding: '12px',
            fontSize: '15px',
            borderRadius: '6px',
            border: '1px solid #ccc',
            resize: 'vertical',
          }}
        />
        <button
          onClick={ask}
          disabled={loading || !question.trim()}
          style={{
            padding: '0 24px',
            backgroundColor: loading ? '#ccc' : '#2563EB',
            color: '#fff',
            border: 'none',
            borderRadius: '6px',
            cursor: loading ? 'wait' : 'pointer',
            fontWeight: 'bold',
            fontSize: '15px',
          }}
        >
          {loading ? 'Asking...' : 'Ask'}
        </button>
      </div>

      {error && (
        <div style={{ color: '#C0392B', marginBottom: '16px' }}>{error}</div>
      )}

      {/* Answer area */}
      {response && (
        <div style={{
          border: '1px solid #e0e0e0',
          borderRadius: '8px',
          padding: '20px',
          backgroundColor: '#FAFAFA',
        }}>
          {/* Risk badge */}
          {response.risk_level && (
            <div style={{ marginBottom: '12px' }}>
              Risk level: <RiskBadge level={response.risk_level} />
            </div>
          )}

          {/* Answer text */}
          <p style={{ fontSize: '16px', lineHeight: '1.6', marginBottom: '20px' }}>
            {response.answer}
          </p>

          {/* Compliance obligations (if any) */}
          {response.compliance_obligations.length > 0 && (
            <div style={{ marginBottom: '20px' }}>
              <strong>Required actions:</strong>
              <ol>
                {response.compliance_obligations.map((ob, i) => (
                  <li key={i} style={{ marginBottom: '4px' }}>{ob}</li>
                ))}
              </ol>
            </div>
          )}

          {/* Sources */}
          <div>
            <strong style={{ display: 'block', marginBottom: '8px' }}>Sources:</strong>
            {response.sources.map((s, i) => (
              <div key={i} style={{
                borderLeft: '3px solid #2563EB',
                paddingLeft: '12px',
                marginBottom: '12px',
              }}>
                <div style={{ fontWeight: 'bold', fontSize: '14px' }}>{s.document}</div>
                {s.quote && (
                  <div style={{ color: '#555', fontSize: '13px', fontStyle: 'italic', marginTop: '4px' }}>
                    {s.quote}
                  </div>
                )}
                {s.score > 0 && (
                  <div style={{ color: '#999', fontSize: '12px', marginTop: '2px' }}>
                    Relevance: {Math.round(s.score * 100)}%
                  </div>
                )}
              </div>
            ))}
          </div>

          <div style={{ color: '#aaa', fontSize: '12px', marginTop: '8px' }}>
            Response time: {response.processing_time_ms}ms
          </div>
        </div>
      )}
    </div>
  );
}
```

```typescript
// projects/04-aiga/frontend/src/App.tsx
import { ChatInterface } from './components/ChatInterface';

function App() {
  return <ChatInterface />;
}

export default App;
```

Start the frontend:

```bash
cd projects/04-aiga/frontend
npm start
```

Open: `http://localhost:3000`

---

## Visual overview

```
http://localhost:3000
┌─────────────────────────────────────────────────────────────────┐
│ AIGA                                                            │
│ AI Governance Assistant — Ask about EU AI Act, NIST, ISO 42001 │
│                                                                 │
│ ┌─────────────────────────────────────────────────────┐  [Ask] │
│ │ What does the EU AI Act say about facial            │        │
│ │ recognition in workplaces?                          │        │
│ └─────────────────────────────────────────────────────┘        │
│                                                                 │
│ Risk level: [HIGH RISK]                                         │
│                                                                 │
│ Emotion recognition systems in workplaces are classified as     │
│ High Risk AI systems under Article 6 and Annex III...           │
│                                                                 │
│ Sources:                                                        │
│ │ EU AI Act, Article 6, Annex III                               │
│ │ "...biometric categorisation systems used in the context      │
│ │  of employment..."                             Relevance: 94% │
│                                                                 │
│ │ NIST AI RMF, MAP 5.1                                          │
│ │ "...context-specific risk assessment for impacted groups..."  │
│ │                                                 Relevance: 81%│
│                                                                 │
│                                          Response time: 1240ms │
└─────────────────────────────────────────────────────────────────┘
```

---

## Learning checkpoint

After building this, take a screenshot of a real answer with sources. You will use this screenshot in:
- The blog post (P4-C1)
- The GitHub README (P4-C4)
- The LinkedIn post (P4-C2)

Good screenshot criteria:
- The question is visible
- The answer is visible
- At least one source citation is visible
- If a risk badge appears, it is visible

Take 3–4 screenshots with different questions. Keep them in `projects/04-aiga/screenshots/`.

---

## Done when

- [ ] `uvicorn api.main:app --reload` starts without errors
- [ ] `curl` to `POST /api/query` returns a JSON response with `answer` and `sources`
- [ ] React frontend loads at `http://localhost:3000`
- [ ] Submitting a question shows the answer with source citations
- [ ] Risk level badge appears for questions about specific AI system types
- [ ] Screenshots taken and saved to `projects/04-aiga/screenshots/`

---

## Next step

→ [P4-T5: Add policy Q&A mode](p4-t5-policy-qa-mode.md)
