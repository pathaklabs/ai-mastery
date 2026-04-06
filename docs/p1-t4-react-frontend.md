# P1-T4: Build React Frontend — Prompt List and Editor

> **Goal:** Build a React app with two views: a searchable prompt list and a prompt editor with version history sidebar.

**Part of:** [P1-US1: Prompt Storage](p1-us1-prompt-storage.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 2
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are building the browser-facing part of PromptOS. Two screens: a list view where you can search and filter your prompts, and an editor view where you can write a prompt, see its version history, and create new versions. The React app calls the FastAPI backend you built in P1-T1 through P1-T3.

---

## Why this step matters

A UI turns your API into a usable tool. Without it, you can only test with curl or the Swagger docs. The version history sidebar is the visual proof that versioning works — you can see all your previous prompt texts in a timeline.

---

## Prerequisites

- [ ] P1-T3 is complete — all five API endpoints work and return correct JSON
- [ ] Node.js 18+ installed (`node --version`)
- [ ] API is running on `http://localhost:8000`

---

## Step-by-step instructions

### Step 1 — (Recommended) Try v0.dev for initial scaffolding

Before writing code by hand, try this AI tool approach:

1. Go to [v0.dev](https://v0.dev)
2. Paste this prompt:

```
Build a React component for a prompt library app.

Layout: two-panel. Left panel is a list of prompts. Right panel is an editor.

Left panel:
- Text search input at the top (filters list by title)
- Tag filter dropdown
- List of prompt items — each shows: title, tag badges, model target, and version count

Right panel:
- Title input field
- Model target dropdown (options: claude-sonnet-4-6, llama3, qwen3, mistral)
- Tags input (comma separated)
- Large textarea for the prompt body
- Version history sidebar on the right edge showing v1, v2, v3... with dates
- "Save new version" button
- "Create new prompt" button

Style: clean, dark mode, developer tool aesthetic. Use Tailwind CSS.
```

3. Copy the generated code.
4. In your build log: write what v0 got right, what it got wrong, and what you had to change.

---

### Step 2 — Create the React project with Vite

```bash
cd projects/01-promptos
npm create vite@latest frontend -- --template react
cd frontend
npm install
```

Install a few helpers:

```bash
npm install axios @tanstack/react-query
```

- `axios` — cleaner HTTP client than raw `fetch`
- `@tanstack/react-query` — manages loading/error states and caching for API calls

---

### Step 3 — Set up the API client

Create `frontend/src/api.js`:

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Prompts
export const getPrompts = (search, tag) =>
  api.get('/prompts', { params: { search, tag } }).then(r => r.data);

export const getPrompt = (id) =>
  api.get(`/prompts/${id}`).then(r => r.data);

export const createPrompt = (data) =>
  api.post('/prompts', data).then(r => r.data);

export const createVersion = (id, data) =>
  api.post(`/prompts/${id}/versions`, data).then(r => r.data);

export const diffVersions = (id, v1, v2) =>
  api.get(`/prompts/${id}/versions/${v1}/diff/${v2}`).then(r => r.data);
```

---

### Step 4 — Set up React Query in main.jsx

Replace `frontend/src/main.jsx` with:

```jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App';
import './index.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 30_000,  // cache for 30 seconds
    },
  },
});

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>
);
```

---

### Step 5 — Build the PromptList component

Create `frontend/src/components/PromptList.jsx`:

```jsx
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getPrompts } from '../api';

export function PromptList({ onSelect, selectedId }) {
  const [search, setSearch] = useState('');
  const [tag, setTag] = useState('');

  const { data: prompts = [], isLoading, isError } = useQuery({
    queryKey: ['prompts', search, tag],
    queryFn: () => getPrompts(search || undefined, tag || undefined),
  });

  return (
    <div style={{ width: '280px', borderRight: '1px solid #333', padding: '16px' }}>
      <h2 style={{ marginBottom: '12px' }}>Prompts</h2>

      <input
        placeholder="Search by title..."
        value={search}
        onChange={e => setSearch(e.target.value)}
        style={{ width: '100%', marginBottom: '8px', padding: '8px' }}
      />

      <input
        placeholder="Filter by tag..."
        value={tag}
        onChange={e => setTag(e.target.value)}
        style={{ width: '100%', marginBottom: '16px', padding: '8px' }}
      />

      {isLoading && <p>Loading...</p>}
      {isError && <p style={{ color: 'red' }}>Failed to load prompts</p>}

      {prompts.map(p => (
        <div
          key={p.id}
          onClick={() => onSelect(p.id)}
          style={{
            padding: '10px',
            marginBottom: '6px',
            cursor: 'pointer',
            borderRadius: '6px',
            background: selectedId === p.id ? '#2a2a2a' : 'transparent',
            border: '1px solid #333',
          }}
        >
          <strong>{p.title}</strong>
          <div style={{ fontSize: '12px', color: '#888', marginTop: '4px' }}>
            {p.version_count} version{p.version_count !== 1 ? 's' : ''}
            {p.model_target && ` · ${p.model_target}`}
          </div>
          {p.tags && (
            <div style={{ marginTop: '4px' }}>
              {p.tags.split(',').map(t => t.trim()).filter(Boolean).map(t => (
                <span
                  key={t}
                  style={{
                    background: '#3a3a3a',
                    borderRadius: '4px',
                    padding: '2px 6px',
                    fontSize: '11px',
                    marginRight: '4px',
                  }}
                >
                  {t}
                </span>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
```

---

### Step 6 — Build the PromptEditor component

Create `frontend/src/components/PromptEditor.jsx`:

```jsx
import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPrompt, createPrompt, createVersion } from '../api';

const MODEL_OPTIONS = [
  'claude-sonnet-4-6',
  'llama3',
  'qwen3:14b',
  'mistral',
];

export function PromptEditor({ promptId, onCreated }) {
  const queryClient = useQueryClient();
  const [title, setTitle] = useState('');
  const [modelTarget, setModelTarget] = useState('claude-sonnet-4-6');
  const [tags, setTags] = useState('');
  const [body, setBody] = useState('');
  const [note, setNote] = useState('');
  const [selectedVersion, setSelectedVersion] = useState(null);

  // Load prompt if editing an existing one
  const { data: prompt } = useQuery({
    queryKey: ['prompt', promptId],
    queryFn: () => getPrompt(promptId),
    enabled: !!promptId,
  });

  // When prompt loads, populate the form with the latest version
  useEffect(() => {
    if (prompt) {
      setTitle(prompt.title);
      setModelTarget(prompt.model_target || 'claude-sonnet-4-6');
      setTags(prompt.tags || '');
      const latest = prompt.versions[prompt.versions.length - 1];
      if (latest) {
        setBody(latest.body);
        setSelectedVersion(latest.version_num);
      }
    }
  }, [prompt]);

  // Load a specific version into the editor when user clicks it
  const loadVersion = (version) => {
    setBody(version.body);
    setSelectedVersion(version.version_num);
  };

  // Create new prompt mutation
  const createMutation = useMutation({
    mutationFn: createPrompt,
    onSuccess: (newPrompt) => {
      queryClient.invalidateQueries(['prompts']);
      onCreated(newPrompt.id);
    },
  });

  // Create new version mutation
  const versionMutation = useMutation({
    mutationFn: ({ id, data }) => createVersion(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['prompt', promptId]);
      queryClient.invalidateQueries(['prompts']);
      setNote('');
    },
  });

  const handleSave = () => {
    if (!promptId) {
      // Creating a brand new prompt
      createMutation.mutate({ title, model_target: modelTarget, tags, body, note });
    } else {
      // Saving a new version of existing prompt
      versionMutation.mutate({ id: promptId, data: { body, note } });
    }
  };

  const isLoading = createMutation.isPending || versionMutation.isPending;

  return (
    <div style={{ display: 'flex', flex: 1, padding: '16px', gap: '16px' }}>

      {/* Main editor area */}
      <div style={{ flex: 1 }}>
        {!promptId && (
          <>
            <input
              placeholder="Prompt title..."
              value={title}
              onChange={e => setTitle(e.target.value)}
              style={{ width: '100%', padding: '8px', marginBottom: '8px', fontSize: '16px' }}
            />
            <div style={{ display: 'flex', gap: '8px', marginBottom: '8px' }}>
              <select
                value={modelTarget}
                onChange={e => setModelTarget(e.target.value)}
                style={{ padding: '8px' }}
              >
                {MODEL_OPTIONS.map(m => (
                  <option key={m} value={m}>{m}</option>
                ))}
              </select>
              <input
                placeholder="Tags (comma separated)..."
                value={tags}
                onChange={e => setTags(e.target.value)}
                style={{ flex: 1, padding: '8px' }}
              />
            </div>
          </>
        )}

        {promptId && (
          <h3 style={{ marginBottom: '8px' }}>
            {prompt?.title}
            {selectedVersion && (
              <span style={{ fontSize: '14px', color: '#888', marginLeft: '8px' }}>
                (viewing v{selectedVersion})
              </span>
            )}
          </h3>
        )}

        <textarea
          placeholder="Write your prompt here..."
          value={body}
          onChange={e => setBody(e.target.value)}
          rows={16}
          style={{
            width: '100%',
            padding: '12px',
            fontSize: '14px',
            fontFamily: 'monospace',
            resize: 'vertical',
          }}
        />

        <input
          placeholder="Version note (optional — what changed?)..."
          value={note}
          onChange={e => setNote(e.target.value)}
          style={{ width: '100%', padding: '8px', marginTop: '8px', marginBottom: '8px' }}
        />

        <button
          onClick={handleSave}
          disabled={isLoading || !body.trim()}
          style={{ padding: '10px 20px', fontSize: '14px' }}
        >
          {isLoading ? 'Saving...' : promptId ? 'Save as new version' : 'Create prompt'}
        </button>

        {(createMutation.isError || versionMutation.isError) && (
          <p style={{ color: 'red', marginTop: '8px' }}>
            Error saving. Check the API is running.
          </p>
        )}
      </div>

      {/* Version history sidebar */}
      {prompt && prompt.versions.length > 0 && (
        <div style={{ width: '200px', borderLeft: '1px solid #333', paddingLeft: '16px' }}>
          <h4 style={{ marginBottom: '12px' }}>Version history</h4>
          {[...prompt.versions].reverse().map(v => (
            <div
              key={v.id}
              onClick={() => loadVersion(v)}
              style={{
                padding: '8px',
                marginBottom: '6px',
                cursor: 'pointer',
                borderRadius: '4px',
                background: selectedVersion === v.version_num ? '#2a2a2a' : 'transparent',
                border: '1px solid #333',
              }}
            >
              <div><strong>v{v.version_num}</strong></div>
              <div style={{ fontSize: '11px', color: '#888' }}>
                {new Date(v.created_at).toLocaleDateString()}
              </div>
              {v.note && (
                <div style={{ fontSize: '11px', color: '#aaa', marginTop: '4px' }}>
                  {v.note}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

---

### Step 7 — Wire it all together in App.jsx

Replace `frontend/src/App.jsx`:

```jsx
import { useState } from 'react';
import { PromptList } from './components/PromptList';
import { PromptEditor } from './components/PromptEditor';

export default function App() {
  const [selectedPromptId, setSelectedPromptId] = useState(null);

  return (
    <div style={{
      display: 'flex',
      height: '100vh',
      background: '#1a1a1a',
      color: '#e0e0e0',
      fontFamily: 'system-ui, sans-serif',
    }}>

      {/* Left: Prompt list */}
      <PromptList
        onSelect={setSelectedPromptId}
        selectedId={selectedPromptId}
      />

      {/* Right: Editor */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '12px 16px', borderBottom: '1px solid #333', display: 'flex', gap: '8px' }}>
          <h1 style={{ margin: 0, fontSize: '18px' }}>PromptOS</h1>
          <button onClick={() => setSelectedPromptId(null)} style={{ marginLeft: 'auto' }}>
            + New Prompt
          </button>
        </div>

        <PromptEditor
          promptId={selectedPromptId}
          onCreated={(id) => setSelectedPromptId(id)}
        />
      </div>
    </div>
  );
}
```

---

### Step 8 — Run the frontend

```bash
cd frontend
npm run dev
```

Open `http://localhost:5173`. You should see the PromptOS interface.

Test the full flow:
1. Click "+ New Prompt"
2. Fill in title, body, and note
3. Click "Create prompt" — the prompt appears in the left list
4. Click the prompt in the list — the editor loads with the text
5. Change the body text, add a note, click "Save as new version"
6. The version history sidebar now shows v1 and v2
7. Click v1 in the sidebar — the editor loads the old text

---

## Visual overview

```
Browser: http://localhost:5173
┌──────────────────────────────────────────────────────────────────┐
│ PromptOS                                          [+ New Prompt] │
├─────────────────┬────────────────────────────────────────────────┤
│ Prompts         │  Python explainer                (viewing v2)  │
│                 │                                                │
│ [Search...]     │  ┌──────────────────────────────────────────┐  │
│ [Tag filter...] │  │ Explain async/await in Python in exactly │  │
│                 │  │ 3 sentences. Use a real-world analogy.   │  │
│ Python explainer│  │ Write for someone who knows JavaScript.  │  │
│ 2 versions      │  │                                          │  │
│ claude-sonnet   │  └──────────────────────────────────────────┘  │
│                 │                                                │
│ SQL helper      │  [Version note...]               │  v2 today  │
│ 1 version       │                                  │  v1 Apr 4  │
│                 │  [Save as new version]            │            │
└─────────────────┴──────────────────────────────────────────────┘

Data flow:
  React components  ──axios──►  FastAPI (port 8000)  ──SQLAlchemy──►  PostgreSQL
  React Query caches API results and shows loading/error states
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> You tried v0.dev (or another AI scaffolding tool) to generate the initial components. What exactly did it get right? What did it get wrong or miss? What does this tell you about when AI code generation is useful vs. when you need to write the code yourself?

---

## Done when

- [ ] React app runs at `http://localhost:5173` without console errors
- [ ] Can create a new prompt with title, body, and note
- [ ] Prompt appears in the left list immediately after creation
- [ ] Can click a prompt and load it in the editor
- [ ] Can save a new version — version appears in the history sidebar
- [ ] Clicking an old version loads that version's text in the editor
- [ ] Search input filters the prompt list

---

## Next step

→ After this, do [P1-T5: Integrate Claude API with Streaming](p1-t5-claude-api.md)
