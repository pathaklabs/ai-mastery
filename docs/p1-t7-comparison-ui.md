# P1-T7: Build Side-by-Side Model Comparison UI

> **Goal:** Build a React view that sends a prompt to multiple models simultaneously and shows the outputs in parallel columns with token counts, latency, and cost.

**Part of:** [P1-US2: Multi-Model Testing](p1-us2-multi-model-testing.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 2
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are building the "Run" screen in PromptOS. The user picks a saved prompt (or writes one from scratch), selects which models to run, clicks "Run on all models," and sees the outputs appear side by side as they come in. Each column shows the model output, token count, latency, and cost estimate.

---

## Why this step matters

This is the feature that makes PromptOS actually useful for prompt engineering. Seeing two model outputs next to each other — with objective metrics — turns "which model is better?" from a feeling into observable data.

---

## Prerequisites

- [ ] P1-T5 and P1-T6 are complete — `POST /run` works with both Claude and Ollama
- [ ] `GET /run/models` returns available models
- [ ] The React app from P1-T4 is running at `http://localhost:5173`

---

## Step-by-step instructions

### Step 1 — Add the run API call to the API client

Add to `frontend/src/api.js`:

```javascript
export const runPrompt = (body, models, promptVersionId = null) =>
  api.post('/run', {
    body: body || undefined,
    prompt_version_id: promptVersionId || undefined,
    models,
  }).then(r => r.data);

export const getAvailableModels = () =>
  api.get('/run/models').then(r => r.data);
```

---

### Step 2 — Build the ModelSelector component

Create `frontend/src/components/ModelSelector.jsx`:

```jsx
import { useQuery } from '@tanstack/react-query';
import { getAvailableModels } from '../api';

export function ModelSelector({ selected, onChange }) {
  const { data: available, isLoading } = useQuery({
    queryKey: ['models'],
    queryFn: getAvailableModels,
  });

  if (isLoading) return <p>Loading models...</p>;

  const allModels = [
    ...(available?.claude || []),
    ...(available?.ollama || []),
  ];

  const toggle = (model) => {
    if (selected.includes(model)) {
      onChange(selected.filter(m => m !== model));
    } else {
      onChange([...selected, model]);
    }
  };

  return (
    <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '12px' }}>
      <span style={{ color: '#888', alignSelf: 'center', fontSize: '13px' }}>Run on:</span>
      {allModels.map(model => (
        <button
          key={model}
          onClick={() => toggle(model)}
          style={{
            padding: '4px 10px',
            fontSize: '12px',
            borderRadius: '20px',
            border: '1px solid',
            borderColor: selected.includes(model) ? '#4a9eff' : '#444',
            background: selected.includes(model) ? '#1a3a5c' : 'transparent',
            color: selected.includes(model) ? '#4a9eff' : '#888',
            cursor: 'pointer',
          }}
        >
          {model}
        </button>
      ))}
      {available?.ollama_error && (
        <span style={{ color: '#ff6b6b', fontSize: '12px', alignSelf: 'center' }}>
          Ollama offline
        </span>
      )}
    </div>
  );
}
```

---

### Step 3 — Build the ModelResultColumn component

Create `frontend/src/components/ModelResultColumn.jsx`:

```jsx
export function ModelResultColumn({ result, isLoading }) {
  const isError = result?.error;

  return (
    <div style={{
      flex: 1,
      border: '1px solid #333',
      borderRadius: '8px',
      padding: '16px',
      minWidth: '280px',
      display: 'flex',
      flexDirection: 'column',
      gap: '12px',
    }}>
      {/* Model header */}
      <div style={{ borderBottom: '1px solid #333', paddingBottom: '8px' }}>
        <strong style={{ fontSize: '14px' }}>{result?.model || 'Loading...'}</strong>
        {result && !isLoading && (
          <div style={{ display: 'flex', gap: '12px', marginTop: '4px', fontSize: '12px', color: '#888' }}>
            <span>{result.latency_ms}ms</span>
            {result.input_tokens && (
              <span>{result.input_tokens + result.output_tokens} tokens</span>
            )}
            {result.cost_usd != null && (
              <span>${result.cost_usd.toFixed(4)}</span>
            )}
          </div>
        )}
      </div>

      {/* Output body */}
      {isLoading && (
        <div style={{ color: '#888', fontStyle: 'italic' }}>Running...</div>
      )}

      {!isLoading && isError && (
        <div style={{
          background: '#2a1a1a',
          border: '1px solid #5a2020',
          borderRadius: '4px',
          padding: '12px',
          color: '#ff6b6b',
          fontSize: '13px',
        }}>
          Error: {result.error}
        </div>
      )}

      {!isLoading && !isError && result?.output && (
        <div style={{
          whiteSpace: 'pre-wrap',
          fontFamily: 'system-ui, sans-serif',
          fontSize: '14px',
          lineHeight: '1.6',
          color: '#e0e0e0',
        }}>
          {result.output}
        </div>
      )}
    </div>
  );
}
```

---

### Step 4 — Build the ComparisonView component

Create `frontend/src/components/ComparisonView.jsx`:

```jsx
import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { runPrompt } from '../api';
import { ModelSelector } from './ModelSelector';
import { ModelResultColumn } from './ModelResultColumn';

const DEFAULT_MODELS = ['claude-sonnet-4-6'];

export function ComparisonView({ prompt }) {
  const [selectedModels, setSelectedModels] = useState(DEFAULT_MODELS);
  const [promptBody, setPromptBody] = useState(
    prompt?.versions?.[prompt.versions.length - 1]?.body || ''
  );

  const runMutation = useMutation({
    mutationFn: () => runPrompt(promptBody, selectedModels),
  });

  const results = runMutation.data?.results || [];
  const isLoading = runMutation.isPending;

  return (
    <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>

      {/* Prompt textarea */}
      <div>
        <label style={{ fontSize: '13px', color: '#888', display: 'block', marginBottom: '6px' }}>
          Prompt
        </label>
        <textarea
          value={promptBody}
          onChange={e => setPromptBody(e.target.value)}
          rows={6}
          style={{
            width: '100%',
            padding: '12px',
            fontFamily: 'monospace',
            fontSize: '13px',
            background: '#1a1a1a',
            border: '1px solid #333',
            borderRadius: '6px',
            color: '#e0e0e0',
            resize: 'vertical',
          }}
          placeholder="Write your prompt here, or select one from the list..."
        />
      </div>

      {/* Model selector + Run button */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px', flexWrap: 'wrap' }}>
        <ModelSelector selected={selectedModels} onChange={setSelectedModels} />
        <button
          onClick={() => runMutation.mutate()}
          disabled={isLoading || !promptBody.trim() || selectedModels.length === 0}
          style={{
            padding: '8px 20px',
            background: '#2563eb',
            color: 'white',
            border: 'none',
            borderRadius: '6px',
            fontSize: '14px',
            cursor: isLoading ? 'wait' : 'pointer',
          }}
        >
          {isLoading ? 'Running...' : `Run on ${selectedModels.length} model${selectedModels.length !== 1 ? 's' : ''}`}
        </button>
      </div>

      {/* Results columns */}
      {(isLoading || results.length > 0) && (
        <div>
          <div style={{ fontSize: '13px', color: '#888', marginBottom: '8px' }}>Results</div>
          <div style={{ display: 'flex', gap: '12px', overflowX: 'auto' }}>
            {isLoading
              ? selectedModels.map(model => (
                  <ModelResultColumn
                    key={model}
                    result={{ model }}
                    isLoading={true}
                  />
                ))
              : results.map(result => (
                  <ModelResultColumn
                    key={result.model}
                    result={result}
                    isLoading={false}
                  />
                ))
            }
          </div>
        </div>
      )}

      {runMutation.isError && (
        <p style={{ color: '#ff6b6b' }}>
          Failed to run: check that the API is running and at least one model is selected.
        </p>
      )}
    </div>
  );
}
```

---

### Step 5 — Add a navigation tab to switch between Editor and Compare

Update `frontend/src/App.jsx` to add a tab bar:

```jsx
import { useState } from 'react';
import { PromptList } from './components/PromptList';
import { PromptEditor } from './components/PromptEditor';
import { ComparisonView } from './components/ComparisonView';
import { useQuery } from '@tanstack/react-query';
import { getPrompt } from './api';

export default function App() {
  const [selectedPromptId, setSelectedPromptId] = useState(null);
  const [activeTab, setActiveTab] = useState('editor'); // 'editor' | 'compare'

  const { data: selectedPrompt } = useQuery({
    queryKey: ['prompt', selectedPromptId],
    queryFn: () => getPrompt(selectedPromptId),
    enabled: !!selectedPromptId,
  });

  return (
    <div style={{
      display: 'flex',
      height: '100vh',
      background: '#1a1a1a',
      color: '#e0e0e0',
      fontFamily: 'system-ui, sans-serif',
    }}>
      <PromptList
        onSelect={(id) => { setSelectedPromptId(id); setActiveTab('editor'); }}
        selectedId={selectedPromptId}
      />

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Header */}
        <div style={{ padding: '12px 16px', borderBottom: '1px solid #333', display: 'flex', alignItems: 'center', gap: '16px' }}>
          <h1 style={{ margin: 0, fontSize: '18px' }}>PromptOS</h1>
          {/* Tabs */}
          <div style={{ display: 'flex', gap: '4px' }}>
            {['editor', 'compare'].map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                style={{
                  padding: '6px 14px',
                  fontSize: '13px',
                  borderRadius: '6px',
                  border: 'none',
                  background: activeTab === tab ? '#2a2a2a' : 'transparent',
                  color: activeTab === tab ? '#e0e0e0' : '#888',
                  cursor: 'pointer',
                  textTransform: 'capitalize',
                }}
              >
                {tab}
              </button>
            ))}
          </div>
          <button
            onClick={() => { setSelectedPromptId(null); setActiveTab('editor'); }}
            style={{ marginLeft: 'auto', padding: '6px 14px', fontSize: '13px' }}
          >
            + New Prompt
          </button>
        </div>

        {/* Tab content */}
        <div style={{ flex: 1, overflow: 'auto' }}>
          {activeTab === 'editor' && (
            <PromptEditor
              promptId={selectedPromptId}
              onCreated={(id) => setSelectedPromptId(id)}
            />
          )}
          {activeTab === 'compare' && (
            <ComparisonView prompt={selectedPrompt} />
          )}
        </div>
      </div>
    </div>
  );
}
```

---

## Visual overview

```
PromptOS — Compare tab
┌─────────────────────────────────────────────────────────────────────┐
│ Prompt                                                              │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Explain async/await in Python in 3 sentences for a beginner.   │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Run on: [claude-sonnet-4-6 ✓] [llama3 ✓] [qwen3:14b]              │
│ [Run on 2 models]                                                   │
│                                                                     │
│ Results                                                             │
│ ┌───────────────────────────┐  ┌───────────────────────────────┐   │
│ │ claude-sonnet-4-6         │  │ llama3                        │   │
│ │ 812ms · 104 tokens ·$0.00 │  │ 4230ms · 97 tokens            │   │
│ │ ─────────────────────     │  │ ────────────────────────────   │   │
│ │ Async/await is Python's   │  │ In Python, the async keyword  │   │
│ │ way of writing code that  │  │ marks a function as...        │   │
│ │ can pause and resume...   │  │                               │   │
│ └───────────────────────────┘  └───────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘

Data flow:
  [Run on 2 models] click
        │
        ▼
  POST /run { models: ["claude-sonnet-4-6", "llama3"] }
        │
        ▼  asyncio.gather() in FastAPI
  Claude API ──────────────────────► ModelResult
  Ollama homelab ──────────────────► ModelResult
        │
        ▼
  RunResponse: [ claudeResult, llamaResult ]
        │
        ▼
  React renders two ModelResultColumn components
```

---

## Done when

- [ ] Compare tab is accessible from the main navigation
- [ ] Model selector shows all available Claude and Ollama models
- [ ] Clicking "Run on N models" sends a request and shows loading state in each column
- [ ] Results appear in parallel columns with model name, output, latency, tokens, and cost
- [ ] Error state (e.g., Ollama timeout) shows a readable message in that column only — other columns still show results
- [ ] Prompt body can be typed freely or is pre-populated from a selected saved prompt

---

## Next step

→ After this, do [P1-T8: Build Scoring Data Model and API](p1-t8-scoring-model.md)
