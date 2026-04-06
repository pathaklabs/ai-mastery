# P1-T9: Add Scoring UI to Comparison View

> **Goal:** Add a scoring panel below each model output column — with sliders for each dimension and a text annotation field — that saves scores to the API on submit.

**Part of:** [P1-US3: Output Scoring](p1-us3-output-scoring.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 3
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are extending the comparison view from P1-T7. Below each model output column, you will add a rating panel: four sliders (one per dimension), a text field for notes, and a "Save score" button. When saved, the scores are posted to `POST /scores` and a confirmation is shown.

---

## Why this step matters

The scoring UI is how data gets into the system. Without it, the aggregate scores and dashboard have nothing to show. The act of scoring also forces you to articulate why an output is good or bad — which builds the prompt engineering intuition this project is designed to develop.

---

## Prerequisites

- [ ] P1-T8 is complete — `POST /scores` and `GET /scores/aggregate` work
- [ ] P1-T7 is complete — comparison view renders model result columns
- [ ] The comparison view shows at least one model's output after running a prompt

---

## Step-by-step instructions

### Step 1 — Add the score API call to the API client

Add to `frontend/src/api.js`:

```javascript
export const createScore = (scoreData) =>
  api.post('/scores', scoreData).then(r => r.data);

export const getAggregateScores = (promptVersionId) =>
  api.get('/scores/aggregate', {
    params: { prompt_version_id: promptVersionId }
  }).then(r => r.data);
```

---

### Step 2 — Build the RatingSlider component

A simple 1–5 slider with a label. Create `frontend/src/components/RatingSlider.jsx`:

```jsx
const LABELS = {
  1: 'Poor',
  2: 'Fair',
  3: 'OK',
  4: 'Good',
  5: 'Excellent',
};

export function RatingSlider({ label, value, onChange }) {
  return (
    <div style={{ marginBottom: '10px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
        <span style={{ fontSize: '12px', color: '#aaa' }}>{label}</span>
        <span style={{ fontSize: '12px', color: '#e0e0e0' }}>
          {value} — {LABELS[value]}
        </span>
      </div>
      <input
        type="range"
        min={1}
        max={5}
        step={1}
        value={value}
        onChange={e => onChange(Number(e.target.value))}
        style={{ width: '100%', accentColor: '#2563eb' }}
      />
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#555' }}>
        <span>1</span>
        <span>2</span>
        <span>3</span>
        <span>4</span>
        <span>5</span>
      </div>
    </div>
  );
}
```

---

### Step 3 — Build the ScoringPanel component

Create `frontend/src/components/ScoringPanel.jsx`:

```jsx
import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createScore } from '../api';
import { RatingSlider } from './RatingSlider';

const DEFAULT_RATINGS = {
  accuracy: 3,
  format: 3,
  tone: 3,
  completeness: 3,
};

const DIMENSION_DESCRIPTIONS = {
  accuracy: 'Is the information factually correct?',
  format: 'Is the structure/format right for the task?',
  tone: 'Does the voice match what you needed?',
  completeness: 'Did it fully answer the question?',
};

export function ScoringPanel({ promptVersionId, model }) {
  const queryClient = useQueryClient();
  const [ratings, setRatings] = useState({ ...DEFAULT_RATINGS });
  const [annotation, setAnnotation] = useState('');
  const [saved, setSaved] = useState(false);

  const saveMutation = useMutation({
    mutationFn: createScore,
    onSuccess: () => {
      setSaved(true);
      setAnnotation('');
      // Invalidate aggregate scores so the dashboard reflects the new score
      queryClient.invalidateQueries(['aggregate-scores']);
      // Reset saved state after 3 seconds
      setTimeout(() => setSaved(false), 3000);
    },
  });

  const handleSubmit = () => {
    if (!promptVersionId) {
      alert('Run a saved prompt version first to enable scoring.');
      return;
    }
    saveMutation.mutate({
      prompt_version_id: promptVersionId,
      model,
      ...ratings,
      annotation: annotation || null,
    });
  };

  const updateRating = (dimension) => (value) => {
    setRatings(prev => ({ ...prev, [dimension]: value }));
  };

  return (
    <div style={{
      marginTop: '12px',
      padding: '14px',
      background: '#111',
      border: '1px solid #2a2a2a',
      borderRadius: '8px',
    }}>
      <div style={{
        fontSize: '12px',
        fontWeight: 'bold',
        color: '#888',
        marginBottom: '12px',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
      }}>
        Rate this output
      </div>

      {Object.entries(DIMENSION_DESCRIPTIONS).map(([dimension, description]) => (
        <div key={dimension} title={description}>
          <RatingSlider
            label={dimension.charAt(0).toUpperCase() + dimension.slice(1)}
            value={ratings[dimension]}
            onChange={updateRating(dimension)}
          />
        </div>
      ))}

      <textarea
        placeholder="Notes (optional) — what made this good or bad?"
        value={annotation}
        onChange={e => setAnnotation(e.target.value)}
        rows={2}
        style={{
          width: '100%',
          padding: '8px',
          marginTop: '8px',
          marginBottom: '10px',
          fontSize: '12px',
          background: '#1a1a1a',
          border: '1px solid #333',
          borderRadius: '4px',
          color: '#e0e0e0',
          resize: 'vertical',
        }}
      />

      <button
        onClick={handleSubmit}
        disabled={saveMutation.isPending || !promptVersionId}
        style={{
          width: '100%',
          padding: '8px',
          fontSize: '13px',
          background: saved ? '#1a3a1a' : '#1e3a5f',
          color: saved ? '#4caf50' : '#4a9eff',
          border: `1px solid ${saved ? '#4caf50' : '#2563eb'}`,
          borderRadius: '6px',
          cursor: promptVersionId ? 'pointer' : 'not-allowed',
        }}
      >
        {saveMutation.isPending ? 'Saving...' : saved ? 'Score saved!' : 'Save score'}
      </button>

      {!promptVersionId && (
        <p style={{ fontSize: '11px', color: '#555', marginTop: '6px', textAlign: 'center' }}>
          Run a saved prompt version to enable scoring
        </p>
      )}

      {saveMutation.isError && (
        <p style={{ fontSize: '11px', color: '#ff6b6b', marginTop: '6px' }}>
          Failed to save score. Check the API.
        </p>
      )}
    </div>
  );
}
```

---

### Step 4 — Add ScoringPanel to ModelResultColumn

Update `frontend/src/components/ModelResultColumn.jsx` to accept `promptVersionId` and render the panel:

```jsx
import { ScoringPanel } from './ScoringPanel';

export function ModelResultColumn({ result, isLoading, promptVersionId }) {
  const isError = result?.error;

  return (
    <div style={{
      flex: 1,
      border: '1px solid #333',
      borderRadius: '8px',
      padding: '16px',
      minWidth: '300px',
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

      {/* Scoring panel — only show after output loads */}
      {!isLoading && !isError && result?.output && (
        <ScoringPanel
          promptVersionId={promptVersionId}
          model={result.model}
        />
      )}
    </div>
  );
}
```

---

### Step 5 — Pass promptVersionId from ComparisonView

Update `frontend/src/components/ComparisonView.jsx` to track the prompt version that was run, and pass it down:

```jsx
// Add to ComparisonView state:
const [lastRunVersionId, setLastRunVersionId] = useState(null);

// When running from a saved prompt version, capture the version ID.
// Update the runMutation call:
const handleRun = () => {
  // If a prompt version was selected (not ad-hoc), track its ID for scoring
  const versionId = prompt?.versions?.[prompt.versions.length - 1]?.id || null;
  setLastRunVersionId(versionId);
  runMutation.mutate();
};

// In the results rendering, pass promptVersionId to each column:
results.map(result => (
  <ModelResultColumn
    key={result.model}
    result={result}
    isLoading={false}
    promptVersionId={lastRunVersionId}
  />
))
```

---

## Visual overview

```
Model output column (after running)
┌─────────────────────────────────────────────────┐
│ claude-sonnet-4-6                               │
│ 812ms · 104 tokens · $0.0005                    │
│ ─────────────────────────────────────────────── │
│ Async/await is Python's way of writing...       │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ RATE THIS OUTPUT                            │ │
│ │                                             │ │
│ │ Accuracy          3 — OK                   │ │
│ │ [────────●────────────]                     │ │
│ │                                             │ │
│ │ Format            4 — Good                 │ │
│ │ [──────────────●──────]                     │ │
│ │                                             │ │
│ │ Tone              5 — Excellent             │ │
│ │ [────────────────────●]                     │ │
│ │                                             │ │
│ │ Completeness      4 — Good                 │ │
│ │ [──────────────●──────]                     │ │
│ │                                             │ │
│ │ [Notes: used a great analogy...           ] │ │
│ │                                             │ │
│ │ [       Save score       ]                  │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

On "Save score":
  POST /scores
  { prompt_version_id: 1, model: "claude-sonnet-4-6",
    accuracy: 3, format: 4, tone: 5, completeness: 4,
    annotation: "used a great analogy..." }
```

---

## Done when

- [ ] Each model output column shows a scoring panel after output loads
- [ ] All four dimension sliders (1–5) work independently
- [ ] Optional annotation text field works
- [ ] "Save score" posts to `POST /scores` and shows confirmation ("Score saved!")
- [ ] If no prompt version is selected (ad-hoc prompt body), scoring is disabled with a message
- [ ] Error from the API shows a readable message (not a silent failure)

---

## Next step

→ After this, do [P1-T10: Build Prompt Performance Dashboard](p1-t10-performance-dashboard.md)
