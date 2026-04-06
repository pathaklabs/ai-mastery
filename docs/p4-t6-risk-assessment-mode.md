# P4-T6: Add Use Case Risk Assessment Mode

> **Goal:** Add a guided form that walks users through describing their AI system step by step, then runs the risk classification chain and shows a compliance checklist.

**Part of:** [P4-E1: AIGA](p4-e1-aiga.md)
**Week:** 7
**Labels:** `task`, `p4-aiga`

---

## What you are doing

Policy Q&A mode (P4-T5) answers questions. Risk Assessment mode does something more powerful: it takes someone from "I have an idea for an AI system" to "here is your compliance checklist" without them needing to know anything about the EU AI Act.

Instead of a free-text chat box, you will build a guided multi-step form:
1. Describe your AI system (what it does)
2. Who does it affect?
3. What decisions does it influence?
4. Submit → get risk level + required actions

This is the feature that makes AIGA worth sharing with non-engineers. A CTO can fill in the form in 2 minutes and hand the result to their compliance team.

---

## Why this step matters

The risk classification chain you built in P4-T3 is powerful, but it requires the user to describe their system in one go — and they often do not know what information matters. The guided form collects the right information in the right order. The system then combines those inputs into a well-structured description before sending it to the classifier.

---

## Prerequisites

- [ ] P4-T3 completed — risk classification chain returns structured results
- [ ] P4-T4 completed — chat interface is working
- [ ] P4-T5 completed — preset questions mode is working

---

## Step-by-step instructions

### Step 1 — Design the form flow

Draw this flow before building. There are 4 steps:

```
Step 1: What does your AI system do?
  ┌─────────────────────────────────────────┐
  │ Describe your AI system in plain        │
  │ English. What does it do?               │
  │                                         │
  │ [text area — 2-3 sentences]             │
  └─────────────────────────────────────────┘
  Example: "An algorithm that reads resumes
  and ranks candidates for job openings"
                    │
                    ▼

Step 2: Who does it affect?
  ┌─────────────────────────────────────────┐
  │ Who are the people affected by this     │
  │ system's outputs?                       │
  │                                         │
  │ (select all that apply)                 │
  │ [ ] Job applicants / employees          │
  │ [ ] Customers / consumers               │
  │ [ ] Students / children                 │
  │ [ ] Patients / healthcare users         │
  │ [ ] Members of the public               │
  │ [ ] No direct impact on individuals     │
  └─────────────────────────────────────────┘
                    │
                    ▼

Step 3: What decisions does it influence?
  ┌─────────────────────────────────────────┐
  │ What type of decisions does this system │
  │ make or inform?                         │
  │                                         │
  │ (select all that apply)                 │
  │ [ ] Employment / hiring / promotion     │
  │ [ ] Credit / loans / insurance          │
  │ [ ] Healthcare / medical diagnosis      │
  │ [ ] Law enforcement / crime prediction  │
  │ [ ] Education / training evaluation     │
  │ [ ] Critical infrastructure             │
  │ [ ] General recommendations only        │
  └─────────────────────────────────────────┘
                    │
                    ▼

Step 4: (optional) Any additional context?
  ┌─────────────────────────────────────────┐
  │ Where is the system deployed?           │
  │ (e.g. "used within the EU", "B2B only") │
  │ [text input — optional]                 │
  └─────────────────────────────────────────┘
                    │
                    ▼
              [Assess Risk]
                    │
                    ▼
  ┌─────────────────────────────────────────┐
  │ Results                                 │
  │                                         │
  │ Risk Level:  [HIGH RISK]                │
  │                                         │
  │ Reasoning: This system falls under      │
  │ Annex III, paragraph 4 because...       │
  │                                         │
  │ EU AI Act Articles: 6, Annex III §4     │
  │                                         │
  │ Required actions:                       │
  │  1. Conduct conformity assessment       │
  │  2. Register in EU AI database          │
  │  3. Implement human oversight           │
  │                                         │
  │ Documentation required:                 │
  │  - Technical documentation (Art. 11)    │
  │  - Risk management records (Art. 9)     │
  │                                         │
  │ Penalty for non-compliance:             │
  │  Up to €30M or 6% global revenue        │
  └─────────────────────────────────────────┘
```

---

### Step 2 — Build the form state model

```typescript
// projects/04-aiga/frontend/src/types/risk-assessment.ts

export type AffectedGroup =
  | 'job_applicants'
  | 'customers'
  | 'students_children'
  | 'patients'
  | 'general_public'
  | 'no_direct_impact';

export type DecisionType =
  | 'employment'
  | 'credit'
  | 'healthcare'
  | 'law_enforcement'
  | 'education'
  | 'critical_infrastructure'
  | 'general_recommendations';

export interface RiskAssessmentForm {
  systemDescription: string;
  affectedGroups: AffectedGroup[];
  decisionTypes: DecisionType[];
  additionalContext: string;
}

export interface RiskAssessmentResult {
  risk_level: string;
  reasoning: string;
  relevant_articles: string[];
  compliance_obligations: string[];
  documentation_required: string[];
  human_oversight_required: boolean;
  timeline: string;
  penalty_if_non_compliant: string | null;
  confidence: string;
}
```

---

### Step 3 — Build the form component

```typescript
// projects/04-aiga/frontend/src/components/RiskAssessmentForm.tsx

import React, { useState } from 'react';
import axios from 'axios';
import type { RiskAssessmentForm, RiskAssessmentResult } from '../types/risk-assessment';

const API_URL = 'http://localhost:8000/api/query';

const AFFECTED_GROUP_LABELS = {
  job_applicants:   'Job applicants / employees',
  customers:        'Customers / consumers',
  students_children:'Students / children',
  patients:         'Patients / healthcare users',
  general_public:   'Members of the general public',
  no_direct_impact: 'No direct impact on individuals',
};

const DECISION_TYPE_LABELS = {
  employment:              'Employment / hiring / promotion',
  credit:                  'Credit / loans / insurance',
  healthcare:              'Healthcare / medical diagnosis',
  law_enforcement:         'Law enforcement / crime prediction',
  education:               'Education / training evaluation',
  critical_infrastructure: 'Critical infrastructure (energy, water, transport)',
  general_recommendations: 'General recommendations only (no high-stakes decisions)',
};

const RISK_BADGE_STYLES: Record<string, React.CSSProperties> = {
  UNACCEPTABLE_RISK: { backgroundColor: '#7B0000', color: '#fff' },
  HIGH_RISK:         { backgroundColor: '#C0392B', color: '#fff' },
  LIMITED_RISK:      { backgroundColor: '#E67E22', color: '#fff' },
  MINIMAL_RISK:      { backgroundColor: '#27AE60', color: '#fff' },
};

function buildSystemDescription(form: RiskAssessmentForm): string {
  /**
   * Combine the form inputs into a single rich description
   * for the risk classification chain.
   *
   * This structured description helps the LLM classify accurately
   * because it includes the key signals: who is affected, what decisions.
   */
  const groups = form.affectedGroups
    .map(g => AFFECTED_GROUP_LABELS[g])
    .join(', ');

  const decisions = form.decisionTypes
    .map(d => DECISION_TYPE_LABELS[d])
    .join(', ');

  let description = form.systemDescription;

  if (groups) {
    description += ` This system affects: ${groups}.`;
  }
  if (decisions) {
    description += ` It influences decisions related to: ${decisions}.`;
  }
  if (form.additionalContext) {
    description += ` Additional context: ${form.additionalContext}.`;
  }

  return description;
}

export function RiskAssessmentFormComponent() {
  const [step, setStep] = useState(1);
  const [form, setForm] = useState<RiskAssessmentForm>({
    systemDescription: '',
    affectedGroups: [],
    decisionTypes: [],
    additionalContext: '',
  });
  const [result, setResult] = useState<RiskAssessmentResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const toggleGroup = (group: any) => {
    setForm(f => ({
      ...f,
      affectedGroups: f.affectedGroups.includes(group)
        ? f.affectedGroups.filter(g => g !== group)
        : [...f.affectedGroups, group],
    }));
  };

  const toggleDecision = (decision: any) => {
    setForm(f => ({
      ...f,
      decisionTypes: f.decisionTypes.includes(decision)
        ? f.decisionTypes.filter(d => d !== decision)
        : [...f.decisionTypes, decision],
    }));
  };

  const submit = async () => {
    const description = buildSystemDescription(form);
    setLoading(true);
    setError('');

    try {
      const res = await axios.post(API_URL, {
        question: description,
        mode: 'risk-assessment',
      });
      setResult(res.data);
      setStep(5); // Jump to results step
    } catch {
      setError('Risk assessment failed. Is the API running?');
    } finally {
      setLoading(false);
    }
  };

  const badgeStyle = result
    ? RISK_BADGE_STYLES[result.risk_level] || {}
    : {};

  return (
    <div style={{ maxWidth: '700px', margin: '0 auto', padding: '24px', fontFamily: 'system-ui' }}>
      <h2>Risk Assessment</h2>
      <p style={{ color: '#666' }}>
        Describe your AI system and get an EU AI Act risk classification with a compliance checklist.
      </p>

      {/* Progress indicator */}
      {step < 5 && (
        <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
          {[1,2,3,4].map(s => (
            <div key={s} style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              backgroundColor: s <= step ? '#2563EB' : '#ddd',
            }} />
          ))}
          <span style={{ fontSize: '13px', color: '#666', marginLeft: '4px' }}>
            Step {step} of 4
          </span>
        </div>
      )}

      {/* Step 1: System description */}
      {step === 1 && (
        <div>
          <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '8px' }}>
            What does your AI system do?
          </label>
          <p style={{ color: '#666', fontSize: '14px' }}>
            Describe it in 2–3 sentences in plain English. No technical jargon needed.
          </p>
          <textarea
            value={form.systemDescription}
            onChange={e => setForm(f => ({ ...f, systemDescription: e.target.value }))}
            placeholder="e.g. An algorithm that reads job applications and ranks candidates by fit score, which our recruiters use to decide who to interview."
            rows={4}
            style={{ width: '100%', padding: '12px', fontSize: '15px', borderRadius: '6px', border: '1px solid #ccc' }}
          />
          <button
            onClick={() => setStep(2)}
            disabled={!form.systemDescription.trim()}
            style={{ marginTop: '16px', padding: '10px 24px', backgroundColor: '#2563EB', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer' }}
          >
            Next →
          </button>
        </div>
      )}

      {/* Step 2: Affected groups */}
      {step === 2 && (
        <div>
          <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '8px' }}>
            Who does this system affect?
          </label>
          <p style={{ color: '#666', fontSize: '14px' }}>Select all that apply.</p>
          {Object.entries(AFFECTED_GROUP_LABELS).map(([key, label]) => (
            <label key={key} style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={form.affectedGroups.includes(key as any)}
                onChange={() => toggleGroup(key)}
              />
              {label}
            </label>
          ))}
          <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
            <button onClick={() => setStep(1)} style={{ padding: '10px 16px', border: '1px solid #ccc', borderRadius: '6px', cursor: 'pointer' }}>← Back</button>
            <button onClick={() => setStep(3)} style={{ padding: '10px 24px', backgroundColor: '#2563EB', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer' }}>Next →</button>
          </div>
        </div>
      )}

      {/* Step 3: Decision types */}
      {step === 3 && (
        <div>
          <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '8px' }}>
            What decisions does it influence?
          </label>
          <p style={{ color: '#666', fontSize: '14px' }}>Select all that apply.</p>
          {Object.entries(DECISION_TYPE_LABELS).map(([key, label]) => (
            <label key={key} style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={form.decisionTypes.includes(key as any)}
                onChange={() => toggleDecision(key)}
              />
              {label}
            </label>
          ))}
          <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
            <button onClick={() => setStep(2)} style={{ padding: '10px 16px', border: '1px solid #ccc', borderRadius: '6px', cursor: 'pointer' }}>← Back</button>
            <button onClick={() => setStep(4)} style={{ padding: '10px 24px', backgroundColor: '#2563EB', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer' }}>Next →</button>
          </div>
        </div>
      )}

      {/* Step 4: Additional context */}
      {step === 4 && (
        <div>
          <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '8px' }}>
            Any additional context? (optional)
          </label>
          <p style={{ color: '#666', fontSize: '14px' }}>
            E.g. "Used within the EU", "B2B tool not used with consumers", "Fully automated with no human review"
          </p>
          <textarea
            value={form.additionalContext}
            onChange={e => setForm(f => ({ ...f, additionalContext: e.target.value }))}
            placeholder="Optional — leave blank if nothing to add"
            rows={3}
            style={{ width: '100%', padding: '12px', fontSize: '15px', borderRadius: '6px', border: '1px solid #ccc' }}
          />
          {error && <p style={{ color: '#C0392B' }}>{error}</p>}
          <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
            <button onClick={() => setStep(3)} style={{ padding: '10px 16px', border: '1px solid #ccc', borderRadius: '6px', cursor: 'pointer' }}>← Back</button>
            <button
              onClick={submit}
              disabled={loading}
              style={{ padding: '10px 24px', backgroundColor: loading ? '#aaa' : '#2563EB', color: '#fff', border: 'none', borderRadius: '6px', cursor: loading ? 'wait' : 'pointer', fontWeight: 'bold' }}
            >
              {loading ? 'Assessing...' : 'Assess Risk'}
            </button>
          </div>
        </div>
      )}

      {/* Step 5: Results */}
      {step === 5 && result && (
        <div style={{ border: '1px solid #e0e0e0', borderRadius: '8px', padding: '24px' }}>
          <h3 style={{ marginTop: 0 }}>Risk Assessment Result</h3>

          <div style={{ marginBottom: '16px' }}>
            <strong>Risk Level: </strong>
            <span style={{
              ...badgeStyle,
              padding: '4px 12px',
              borderRadius: '4px',
              fontWeight: 'bold',
            }}>
              {result.risk_level.replace(/_/g, ' ')}
            </span>
            <span style={{ marginLeft: '8px', color: '#666', fontSize: '14px' }}>
              Confidence: {result.confidence}
            </span>
          </div>

          <p><strong>Reasoning:</strong> {result.reasoning}</p>
          <p><strong>EU AI Act articles:</strong> {result.relevant_articles.join(', ')}</p>

          <div>
            <strong>Required actions:</strong>
            <ol>
              {result.compliance_obligations.map((ob, i) => (
                <li key={i} style={{ marginBottom: '4px' }}>{ob}</li>
              ))}
            </ol>
          </div>

          <div>
            <strong>Documentation required:</strong>
            <ul>
              {result.documentation_required.map((doc, i) => (
                <li key={i} style={{ marginBottom: '4px' }}>{doc}</li>
              ))}
            </ul>
          </div>

          {result.human_oversight_required !== null && (
            <p><strong>Human oversight required:</strong> {result.human_oversight_required ? 'Yes' : 'No'}</p>
          )}
          {result.penalty_if_non_compliant && (
            <p><strong>Penalty for non-compliance:</strong> {result.penalty_if_non_compliant}</p>
          )}

          <button
            onClick={() => { setStep(1); setResult(null); setForm({ systemDescription: '', affectedGroups: [], decisionTypes: [], additionalContext: '' }); }}
            style={{ marginTop: '16px', padding: '10px 16px', border: '1px solid #ccc', borderRadius: '6px', cursor: 'pointer' }}
          >
            Start over
          </button>
        </div>
      )}
    </div>
  );
}
```

---

### Step 4 — Add a mode toggle to the app

The app now has two modes: Chat and Risk Assessment. Add a simple toggle.

```typescript
// In App.tsx:
import { useState } from 'react';
import { ChatInterface } from './components/ChatInterface';
import { RiskAssessmentFormComponent } from './components/RiskAssessmentForm';

function App() {
  const [mode, setMode] = useState<'chat' | 'risk-assessment'>('chat');

  return (
    <div>
      <nav style={{ display: 'flex', gap: '16px', padding: '16px 24px', borderBottom: '1px solid #eee' }}>
        <button
          onClick={() => setMode('chat')}
          style={{ fontWeight: mode === 'chat' ? 'bold' : 'normal', background: 'none', border: 'none', cursor: 'pointer', fontSize: '15px', color: mode === 'chat' ? '#2563EB' : '#555' }}
        >
          Policy Q&A
        </button>
        <button
          onClick={() => setMode('risk-assessment')}
          style={{ fontWeight: mode === 'risk-assessment' ? 'bold' : 'normal', background: 'none', border: 'none', cursor: 'pointer', fontSize: '15px', color: mode === 'risk-assessment' ? '#2563EB' : '#555' }}
        >
          Risk Assessment
        </button>
      </nav>
      {mode === 'chat' ? <ChatInterface /> : <RiskAssessmentFormComponent />}
    </div>
  );
}
```

---

## Visual overview

```
App
 ├── [Policy Q&A] tab ─────────────────► ChatInterface
 │                                         (free text + preset questions)
 │
 └── [Risk Assessment] tab ─────────────► RiskAssessmentFormComponent
                                            Step 1: system description
                                            Step 2: affected groups
                                            Step 3: decision types
                                            Step 4: additional context
                                                 │
                                                 ▼
                                         buildSystemDescription()
                                         combines all 4 steps into
                                         one rich description
                                                 │
                                                 ▼
                                         POST /api/query
                                         { mode: "risk-assessment" }
                                                 │
                                                 ▼
                                         classify_risk() (P4-T3)
                                                 │
                                                 ▼
                                         Results: risk badge +
                                         compliance checklist
```

---

## Done when

- [ ] The app shows a mode toggle between "Policy Q&A" and "Risk Assessment"
- [ ] Risk Assessment form shows all 4 steps in sequence
- [ ] Back button works at each step
- [ ] Submitting a hiring algorithm description returns `HIGH_RISK`
- [ ] Submitting a music recommendation system returns `MINIMAL_RISK`
- [ ] Results show risk badge, reasoning, articles, obligations, and documentation list
- [ ] "Start over" button resets the form to Step 1

---

## Next step

→ [P4-T7: Package as podman compose for open-source deployment](p4-t7-podman-deployment.md)
