# P4-T5: Add Policy Q&A Mode

> **Goal:** Add a set of preset governance questions users can click instead of type — making AIGA immediately useful to people who do not know what to ask.

**Part of:** [P4-E1: AIGA](p4-e1-aiga.md)
**Week:** 7
**Labels:** `task`, `p4-aiga`

---

## What you are doing

The chat interface from P4-T4 is great for people who already know what they want to ask. Policy Q&A mode is for everyone else — the engineering manager who just heard about the EU AI Act in a meeting, the developer who wants to quickly check one thing, the compliance person who does not know where to start.

You will add a panel of clickable preset questions. Clicking a question fires it into the chat, exactly as if the user had typed it themselves.

The key design principle: **preset questions are config, not code.** They live in a JSON file so you can update them without touching any TypeScript.

---

## Why this step matters

Most users do not know what question to ask. The preset questions lower the barrier to entry. They also demonstrate the capability of the system immediately — someone can click a question and see a real answer in 30 seconds, without having to formulate their own question first.

This is a product pattern called "progressive disclosure" — you give users a starting point, then let them explore from there.

---

## Prerequisites

- [ ] P4-T4 completed — chat interface is working and returning cited answers
- [ ] The React frontend is running at `http://localhost:3000`

---

## Step-by-step instructions

### Step 1 — Create the preset questions config file

Store preset questions in a JSON file, not in TypeScript code. This means anyone can update the questions by editing the config — no code change needed.

```json
// projects/04-aiga/frontend/src/config/preset-questions.json

{
  "categories": [
    {
      "label": "EU AI Act basics",
      "questions": [
        "What is the EU AI Act and who does it apply to?",
        "What is the difference between High Risk and Limited Risk AI systems?",
        "What does the EU AI Act say about facial recognition in public spaces?",
        "When does the EU AI Act come into force and what are the key dates?"
      ]
    },
    {
      "label": "High-Risk AI systems",
      "questions": [
        "What documentation do I need for a High-Risk AI system?",
        "What does the EU AI Act require for a hiring algorithm?",
        "Does a medical AI diagnostic tool need EU AI Act compliance?",
        "What is a conformity assessment and when is it required?",
        "What does 'human oversight' mean under the EU AI Act?"
      ]
    },
    {
      "label": "NIST AI RMF",
      "questions": [
        "What are the four functions of the NIST AI Risk Management Framework?",
        "How does NIST AI RMF define 'trustworthy AI'?",
        "What is the GOVERN function in NIST AI RMF?",
        "How do NIST AI RMF and EU AI Act work together?"
      ]
    },
    {
      "label": "Practical compliance",
      "questions": [
        "What are the penalties for violating the EU AI Act?",
        "Do I need to register my AI system in a database?",
        "What is required if I am a provider vs a deployer of an AI system?",
        "Does the EU AI Act apply to AI systems built outside the EU?"
      ]
    }
  ]
}
```

---

### Step 2 — Build the PresetQuestions component

```typescript
// projects/04-aiga/frontend/src/components/PresetQuestions.tsx

import React, { useState } from 'react';
import presetQuestions from '../config/preset-questions.json';

interface PresetQuestionsProps {
  onSelect: (question: string) => void;
}

export function PresetQuestions({ onSelect }: PresetQuestionsProps) {
  const [activeCategory, setActiveCategory] = useState(0);

  return (
    <div style={{ marginBottom: '24px' }}>
      <p style={{ color: '#666', fontSize: '14px', marginBottom: '8px' }}>
        Quick questions — click to ask:
      </p>

      {/* Category tabs */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '12px', flexWrap: 'wrap' }}>
        {presetQuestions.categories.map((cat, i) => (
          <button
            key={i}
            onClick={() => setActiveCategory(i)}
            style={{
              padding: '6px 14px',
              borderRadius: '20px',
              border: '1px solid',
              borderColor: i === activeCategory ? '#2563EB' : '#ccc',
              backgroundColor: i === activeCategory ? '#2563EB' : 'transparent',
              color: i === activeCategory ? '#fff' : '#555',
              cursor: 'pointer',
              fontSize: '13px',
              fontWeight: i === activeCategory ? 'bold' : 'normal',
            }}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* Questions for active category */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
        {presetQuestions.categories[activeCategory].questions.map((q, i) => (
          <button
            key={i}
            onClick={() => onSelect(q)}
            style={{
              textAlign: 'left',
              padding: '10px 14px',
              borderRadius: '6px',
              border: '1px solid #E5E7EB',
              backgroundColor: '#fff',
              cursor: 'pointer',
              fontSize: '14px',
              color: '#1E3A5F',
              transition: 'background-color 0.1s',
            }}
            onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#EFF6FF')}
            onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#fff')}
          >
            {q}
          </button>
        ))}
      </div>
    </div>
  );
}
```

---

### Step 3 — Integrate into ChatInterface

Update `ChatInterface.tsx` to include the preset questions panel.

Find the section just before the input textarea and add:

```typescript
// In ChatInterface.tsx, add this import at the top:
import { PresetQuestions } from './PresetQuestions';

// Add this handler function in the component:
const handlePresetSelect = (preset: string) => {
  setQuestion(preset);
  // Auto-submit the preset question
  // (We set the question state, then fire the ask function)
  // Note: because setState is async, pass the value directly to ask
  askWithQuestion(preset);
};

// Rename your existing ask() to accept an optional parameter:
const askWithQuestion = async (q?: string) => {
  const questionToAsk = q ?? question;
  if (!questionToAsk.trim()) return;
  setLoading(true);
  setError('');
  setResponse(null);
  // ... rest of the ask logic, replacing `question` with `questionToAsk`
};

// In the JSX, add the PresetQuestions component above the textarea:
<PresetQuestions onSelect={handlePresetSelect} />
```

The updated layout:

```
┌─────────────────────────────────────────────────────────────────┐
│ AIGA                                                            │
│ AI Governance Assistant                                         │
│                                                                 │
│ Quick questions — click to ask:                                 │
│ [EU AI Act basics] [High-Risk AI] [NIST AI RMF] [Compliance]   │
│                                                                 │
│ > What is the EU AI Act and who does it apply to?               │
│ > What is the difference between High Risk and Limited Risk?    │
│ > What does the EU AI Act say about facial recognition?         │
│ > When does the EU AI Act come into force?                      │
│                                                                 │
│ ┌────────────────────────────────────────────────────┐  [Ask]  │
│ │ Or type your own question...                       │         │
│ └────────────────────────────────────────────────────┘         │
│                                                                 │
│ (answer appears here)                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

### Step 4 — Add a backend endpoint for preset questions (optional but useful)

This endpoint lets you fetch the preset questions from the API so the config lives in one place (the backend) rather than being duplicated in the frontend.

```python
# In projects/04-aiga/api/main.py, add:

import json
from pathlib import Path

PRESET_QUESTIONS_FILE = Path(__file__).parent.parent / "config" / "preset-questions.json"

@app.get("/api/preset-questions")
def get_preset_questions():
    """Return the preset questions config for the UI."""
    if PRESET_QUESTIONS_FILE.exists():
        return json.loads(PRESET_QUESTIONS_FILE.read_text())
    return {"categories": []}
```

Move the `preset-questions.json` to `projects/04-aiga/config/preset-questions.json` so it is served from the API — then fetch it in the frontend instead of importing it directly.

---

## Visual overview

```
preset-questions.json (config file)
  │
  │  "categories": [
  │    { "label": "EU AI Act basics",
  │      "questions": ["What is...", "What does...", ...] },
  │    { "label": "High-Risk AI",
  │      "questions": ["What documentation...", ...] },
  │    ...
  │  ]
  │
  ▼
PresetQuestions component
  │  renders category tabs + question buttons
  │  onClick → calls onSelect(question)
  │
  ▼
ChatInterface.onSelect handler
  │  sets question state
  │  fires askWithQuestion(preset)
  │
  ▼
POST /api/query
  │  { "question": preset, "mode": "chat" }
  │
  ▼
RAG pipeline → answer + citations
  │
  ▼
Answer rendered in chat UI
```

---

## Learning checkpoint

After this is working, notice the design pattern you have used:

- The preset questions are data, not code
- Adding a new question = editing a JSON file
- Adding a new category = editing a JSON file
- No TypeScript changes needed

This is the "open/closed principle" in practice: the system is open for extension (new questions) but closed for modification (you do not need to change the code). Write this in your build log.

---

## Done when

- [ ] `preset-questions.json` config file created with at least 3 categories and 4+ questions each
- [ ] `PresetQuestions` component renders in the UI
- [ ] Clicking a preset question fires it into the chat and shows a response
- [ ] Category tabs work — clicking a tab shows the questions for that category
- [ ] Adding a new question to the JSON file adds it to the UI without any code change

---

## Next step

→ [P4-T6: Add use case risk assessment mode](p4-t6-risk-assessment-mode.md)
