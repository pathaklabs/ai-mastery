# P1-T10: Build Prompt Performance Dashboard

> **Goal:** Build a dashboard view showing top-performing prompt versions, model win rates, and score trends over time.

**Part of:** [P1-US3: Output Scoring](p1-us3-output-scoring.md) → [P1-E1: Build PromptOS](p1-e1-promptos.md)
**Week:** 3
**Labels:** `task`, `p1-promptos`

---

## What you are doing

You are building the final view of PromptOS: a dashboard that reads all the scores you have saved and presents them as three charts. Top-performing prompt versions (by average overall score), model win rate (which model wins most head-to-head comparisons), and a score trend over time (are your prompts getting better across the program?).

---

## Why this step matters

This is your first AI evaluation system. The dashboard answers a question that every AI engineer faces: given a set of outputs, how do you know which is actually better? Your scoring rubric is the answer. The data you collect across all six projects in this program will tell you whether your prompt engineering skills are improving.

---

## Prerequisites

- [ ] P1-T9 is complete — scores are being saved via the UI
- [ ] You have scored at least 5–10 model outputs (the dashboard is not meaningful with 0–1 data points)
- [ ] `GET /scores/aggregate` returns data

---

## Step-by-step instructions

### Step 1 — Add a dashboard data endpoint to the API

The existing `/scores/aggregate` endpoint handles aggregates per version+model. Add a new endpoint to the scores router that returns data formatted for the dashboard.

Add to `api/scores.py`:

```python
from sqlalchemy import and_

@router.get("/dashboard")
async def dashboard_data(db: AsyncSession = Depends(get_db)):
    """
    Return three datasets for the performance dashboard:
    1. top_versions: top 10 prompt versions by average overall score
    2. model_win_rates: which model has the highest average score per comparison
    3. score_trend: average overall score grouped by day
    """

    # ── 1. Top prompt versions ────────────────────────────────────────────────
    top_versions_query = (
        select(
            OutputScore.prompt_version_id,
            PromptVersion.version_num,
            Prompt.title,
            func.avg(
                (OutputScore.accuracy + OutputScore.format +
                 OutputScore.tone + OutputScore.completeness) / 4.0
            ).label("avg_overall"),
            func.count(OutputScore.id).label("score_count"),
        )
        .join(PromptVersion, OutputScore.prompt_version_id == PromptVersion.id)
        .join(Prompt, PromptVersion.prompt_id == Prompt.id)
        .group_by(OutputScore.prompt_version_id, PromptVersion.version_num, Prompt.title)
        .order_by(func.avg(
            (OutputScore.accuracy + OutputScore.format +
             OutputScore.tone + OutputScore.completeness) / 4.0
        ).desc())
        .limit(10)
    )
    top_versions_result = await db.execute(top_versions_query)
    top_versions = [
        {
            "prompt_version_id": row.prompt_version_id,
            "version_num": row.version_num,
            "title": row.title,
            "avg_overall": round(float(row.avg_overall), 2),
            "score_count": row.score_count,
        }
        for row in top_versions_result
    ]

    # ── 2. Model win rates ────────────────────────────────────────────────────
    model_avg_query = (
        select(
            OutputScore.model,
            func.avg(
                (OutputScore.accuracy + OutputScore.format +
                 OutputScore.tone + OutputScore.completeness) / 4.0
            ).label("avg_overall"),
            func.count(OutputScore.id).label("score_count"),
        )
        .group_by(OutputScore.model)
        .order_by(func.avg(
            (OutputScore.accuracy + OutputScore.format +
             OutputScore.tone + OutputScore.completeness) / 4.0
        ).desc())
    )
    model_result = await db.execute(model_avg_query)
    model_win_rates = [
        {
            "model": row.model,
            "avg_overall": round(float(row.avg_overall), 2),
            "score_count": row.score_count,
        }
        for row in model_result
    ]

    # ── 3. Score trend over time (by day) ─────────────────────────────────────
    trend_query = (
        select(
            func.date(OutputScore.created_at).label("date"),
            func.avg(
                (OutputScore.accuracy + OutputScore.format +
                 OutputScore.tone + OutputScore.completeness) / 4.0
            ).label("avg_overall"),
            func.count(OutputScore.id).label("score_count"),
        )
        .group_by(func.date(OutputScore.created_at))
        .order_by(func.date(OutputScore.created_at))
    )
    trend_result = await db.execute(trend_query)
    score_trend = [
        {
            "date": str(row.date),
            "avg_overall": round(float(row.avg_overall), 2),
            "score_count": row.score_count,
        }
        for row in trend_result
    ]

    return {
        "top_versions": top_versions,
        "model_win_rates": model_win_rates,
        "score_trend": score_trend,
    }
```

Add the missing imports at the top of `api/scores.py`:

```python
from models.prompt import OutputScore, PromptVersion, Prompt
```

---

### Step 2 — Add the dashboard API call to the frontend

Add to `frontend/src/api.js`:

```javascript
export const getDashboardData = () =>
  api.get('/scores/dashboard').then(r => r.data);
```

---

### Step 3 — Install a lightweight chart library

```bash
cd frontend
npm install recharts
```

Recharts is simple, React-native, and does not require D3 knowledge.

---

### Step 4 — Build the TopVersionsChart component

Create `frontend/src/components/dashboard/TopVersionsChart.jsx`:

```jsx
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Cell,
  ResponsiveContainer,
} from 'recharts';

export function TopVersionsChart({ data }) {
  if (!data || data.length === 0) {
    return (
      <div style={{ padding: '24px', color: '#555', textAlign: 'center' }}>
        No scores yet. Run prompts and score them to see top performers.
      </div>
    );
  }

  const chartData = data.map(d => ({
    name: `${d.title} v${d.version_num}`,
    score: d.avg_overall,
    count: d.score_count,
  }));

  return (
    <div>
      <h3 style={{ marginBottom: '16px', fontSize: '14px', color: '#aaa' }}>
        Top Prompt Versions (by avg overall score)
      </h3>
      <ResponsiveContainer width="100%" height={250}>
        <BarChart data={chartData} layout="vertical" margin={{ left: 20, right: 20 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" />
          <XAxis type="number" domain={[0, 5]} tick={{ fill: '#888', fontSize: 12 }} />
          <YAxis
            type="category"
            dataKey="name"
            width={180}
            tick={{ fill: '#888', fontSize: 11 }}
          />
          <Tooltip
            contentStyle={{ background: '#1a1a1a', border: '1px solid #333' }}
            formatter={(value, name) => [`${value}/5`, 'Avg score']}
          />
          <Bar dataKey="score" fill="#2563eb" radius={[0, 4, 4, 0]}>
            {chartData.map((entry, index) => (
              <Cell
                key={index}
                fill={entry.score >= 4 ? '#22c55e' : entry.score >= 3 ? '#2563eb' : '#ef4444'}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
```

---

### Step 5 — Build the ModelWinRateChart component

Create `frontend/src/components/dashboard/ModelWinRateChart.jsx`:

```jsx
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

export function ModelWinRateChart({ data }) {
  if (!data || data.length === 0) {
    return (
      <div style={{ padding: '24px', color: '#555', textAlign: 'center' }}>
        No model scores yet.
      </div>
    );
  }

  return (
    <div>
      <h3 style={{ marginBottom: '16px', fontSize: '14px', color: '#aaa' }}>
        Model Average Scores
      </h3>
      <ResponsiveContainer width="100%" height={200}>
        <BarChart data={data} margin={{ left: 20, right: 20 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" />
          <XAxis dataKey="model" tick={{ fill: '#888', fontSize: 11 }} />
          <YAxis domain={[0, 5]} tick={{ fill: '#888', fontSize: 12 }} />
          <Tooltip
            contentStyle={{ background: '#1a1a1a', border: '1px solid #333' }}
            formatter={(value) => [`${value}/5`, 'Avg overall']}
          />
          <Bar dataKey="avg_overall" fill="#7c3aed" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
      <div style={{ marginTop: '12px' }}>
        {data.map(m => (
          <div key={m.model} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: '#888', marginBottom: '4px' }}>
            <span>{m.model}</span>
            <span>{m.avg_overall}/5 ({m.score_count} scores)</span>
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

### Step 6 — Build the ScoreTrendChart component

Create `frontend/src/components/dashboard/ScoreTrendChart.jsx`:

```jsx
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

export function ScoreTrendChart({ data }) {
  if (!data || data.length < 2) {
    return (
      <div style={{ padding: '24px', color: '#555', textAlign: 'center' }}>
        Score more outputs across multiple days to see a trend.
      </div>
    );
  }

  return (
    <div>
      <h3 style={{ marginBottom: '16px', fontSize: '14px', color: '#aaa' }}>
        Score Trend Over Time
      </h3>
      <ResponsiveContainer width="100%" height={200}>
        <LineChart data={data} margin={{ left: 20, right: 20 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" />
          <XAxis dataKey="date" tick={{ fill: '#888', fontSize: 11 }} />
          <YAxis domain={[1, 5]} tick={{ fill: '#888', fontSize: 12 }} />
          <Tooltip
            contentStyle={{ background: '#1a1a1a', border: '1px solid #333' }}
            formatter={(value) => [`${value}/5`, 'Avg score']}
          />
          <Line
            type="monotone"
            dataKey="avg_overall"
            stroke="#f59e0b"
            strokeWidth={2}
            dot={{ fill: '#f59e0b', r: 4 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
```

---

### Step 7 — Build the Dashboard page

Create `frontend/src/components/Dashboard.jsx`:

```jsx
import { useQuery } from '@tanstack/react-query';
import { getDashboardData } from '../api';
import { TopVersionsChart } from './dashboard/TopVersionsChart';
import { ModelWinRateChart } from './dashboard/ModelWinRateChart';
import { ScoreTrendChart } from './dashboard/ScoreTrendChart';

export function Dashboard() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['dashboard'],
    queryFn: getDashboardData,
    refetchInterval: 30_000,  // auto-refresh every 30 seconds
  });

  if (isLoading) return <div style={{ padding: '24px', color: '#888' }}>Loading dashboard...</div>;
  if (isError) return <div style={{ padding: '24px', color: '#ff6b6b' }}>Failed to load dashboard data.</div>;

  return (
    <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: '32px' }}>
      <h2 style={{ margin: 0, fontSize: '20px' }}>Prompt Performance Dashboard</h2>

      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '24px',
      }}>
        <div style={{ background: '#111', border: '1px solid #2a2a2a', borderRadius: '8px', padding: '20px' }}>
          <ModelWinRateChart data={data?.model_win_rates} />
        </div>
        <div style={{ background: '#111', border: '1px solid #2a2a2a', borderRadius: '8px', padding: '20px' }}>
          <ScoreTrendChart data={data?.score_trend} />
        </div>
      </div>

      <div style={{ background: '#111', border: '1px solid #2a2a2a', borderRadius: '8px', padding: '20px' }}>
        <TopVersionsChart data={data?.top_versions} />
      </div>
    </div>
  );
}
```

---

### Step 8 — Add Dashboard tab to App.jsx

Add `'dashboard'` to the tabs in `App.jsx`:

```jsx
{['editor', 'compare', 'dashboard'].map(tab => (
  <button key={tab} onClick={() => setActiveTab(tab)} ...>
    {tab}
  </button>
))}

{activeTab === 'dashboard' && <Dashboard />}
```

---

## Visual overview

```
Dashboard tab
┌──────────────────────────────────────────────────────────────────────┐
│ Prompt Performance Dashboard                                         │
│                                                                      │
│ ┌──────────────────────────┐  ┌─────────────────────────────────┐   │
│ │ Model Average Scores     │  │ Score Trend Over Time           │   │
│ │                          │  │                                 │   │
│ │  claude-sonnet │████ 4.2 │  │  5 ──────────────────────       │   │
│ │  llama3        │███  3.8 │  │  4 ──────●───────●──────●       │   │
│ │  qwen3:14b     │███  3.6 │  │  3 ──────────────────────       │   │
│ │                          │  │     Apr4  Apr5  Apr6  Apr7      │   │
│ └──────────────────────────┘  └─────────────────────────────────┘   │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────────┐   │
│ │ Top Prompt Versions (by avg overall score)                     │   │
│ │                                                                │   │
│ │ Python explainer v3    ████████████████████  4.5              │   │
│ │ SQL helper v2          ████████████████      4.0              │   │
│ │ Python explainer v2    ██████████████        3.8              │   │
│ └────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> You have now built a complete AI evaluation system. Look at your own data — even if you only have 5–10 scores.
>
> Answer this in your build log:
> **How do you know if an AI output is actually good?**
>
> Write 3–4 paragraphs. Consider:
> - Is a high score on your rubric the same as the output being "correct"?
> - Who defines what "good" means — you, the user, the task?
> - What would you measure differently if this were a real product used by 10,000 people?
> - Why is this the hardest open problem in AI engineering?
>
> There is no right answer. Your current thinking is what matters. You will revisit this question after Project 6.

---

## Done when

- [ ] `GET /scores/dashboard` returns `top_versions`, `model_win_rates`, and `score_trend` data
- [ ] Dashboard tab is accessible from the main navigation
- [ ] Top Versions chart renders prompt version names and scores as horizontal bars
- [ ] Model Win Rate chart renders all scored models as vertical bars
- [ ] Score Trend chart renders average scores by date as a line graph
- [ ] Empty states show readable messages when there is no data yet
- [ ] Dashboard auto-refreshes without requiring a page reload

---

## Next step

→ Complete [P1-US4: Content — Publish P1 Learnings](p1-us4-content-publish.md)
→ Then start [P2-E1: RAG Brain](p2-e1-rag-brain.md)
