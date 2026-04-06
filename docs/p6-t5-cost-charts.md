# P6-T5: Add Cost Breakdown Charts

> **Goal:** Add a dedicated costs page to the dashboard with three charts — daily spend per project, model usage breakdown, and monthly total with projection.

**Part of:** [P6-US1: Unified Metrics](p6-us1-unified-metrics.md)
**Week:** 12
**Labels:** `task`, `p6-dashboard`

---

## What you are doing

The health cards from P6-T4 show today's cost in a single number. This task builds a proper costs page with three charts that help you understand your spending over time.

You will use Recharts (already installed in P6-T4) to build:
1. A stacked bar chart — daily spend broken down by project
2. A pie chart — which AI models are being called most
3. A summary panel — month to date with a projected total and budget bar

---

## Why this step matters

Costs are one of the most interesting things to publish about. Your audience on LinkedIn and in blog posts wants to know: "How much does running 5 AI projects actually cost?" The charts give you an honest, visual answer.

They also give you control. When you see one project's bar getting taller than the others, you know to investigate before the bill arrives.

---

## Prerequisites

- [ ] [P6-T4: React Dashboard](p6-t4-react-dashboard.md) is complete and the dashboard runs locally
- [ ] The metrics API has at least a few days of `api_cost` events

---

## Step-by-step instructions

### Step 1 — Add a costs API endpoint for the chart data

Add this endpoint to the metrics API `main.py`. It returns the shape of data that Recharts expects for a stacked bar chart:

```python
@app.get("/costs/chart-data")
async def get_cost_chart_data(days: int = 14):
    """
    Return daily costs per project in a format ready for a stacked bar chart.

    Each item in the array is one day:
    {
      "date": "2026-04-06",
      "promptos": 0.23,
      "rag-brain": 0.08,
      "pipeline": 0.04,
      "aiga": 0.12,
      "pr-review": 0.34
    }
    """
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT
                DATE(timestamp)  AS date,
                project,
                SUM(value)       AS cost_usd
            FROM metric_events
            WHERE event_type = 'api_cost'
              AND timestamp >= NOW() - INTERVAL '1 day' * $1
            GROUP BY DATE(timestamp), project
            ORDER BY date ASC
            """,
            days
        )

    # Pivot: one object per date, one key per project
    from collections import defaultdict
    result = defaultdict(dict)

    for row in rows:
        date_str = str(row["date"])
        result[date_str][row["project"]] = float(row["cost_usd"])

    return [
        {"date": date, **costs}
        for date, costs in sorted(result.items())
    ]


@app.get("/costs/model-breakdown")
async def get_model_breakdown(days: int = 30):
    """
    Return model usage breakdown for the pie chart.
    Groups by the 'model' field in metadata.
    """
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT
                metadata->>'model'   AS model,
                COUNT(*)             AS event_count,
                SUM(value)           AS total_cost_usd
            FROM metric_events
            WHERE event_type = 'api_cost'
              AND timestamp >= NOW() - INTERVAL '1 day' * $1
            GROUP BY metadata->>'model'
            ORDER BY total_cost_usd DESC
            """,
            days
        )

    total = sum(float(r["total_cost_usd"]) for r in rows)
    return [
        {
            "model": r["model"] or "unknown",
            "cost_usd": float(r["total_cost_usd"]),
            "percentage": round(float(r["total_cost_usd"]) / total * 100, 1) if total else 0,
        }
        for r in rows
    ]
```

### Step 2 — Add the API calls to the frontend

Add to `src/api/metrics.ts`:

```typescript
export async function fetchCostChartData(days = 14) {
  const res = await api.get("/costs/chart-data", { params: { days } });
  return res.data;
}

export async function fetchModelBreakdown(days = 30) {
  const res = await api.get("/costs/model-breakdown", { params: { days } });
  return res.data;
}
```

### Step 3 — Build the stacked bar chart

Create `src/components/DailyCostChart.tsx`:

```typescript
import React from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";

interface Props {
  data: Record<string, number | string>[];
}

const COLOURS: Record<string, string> = {
  "promptos":  "#6366f1",
  "rag-brain": "#10b981",
  "pipeline":  "#f59e0b",
  "aiga":      "#3b82f6",
  "pr-review": "#ec4899",
};

const PROJECTS = ["promptos", "rag-brain", "pipeline", "aiga", "pr-review"];

export function DailyCostChart({ data }: Props) {
  return (
    <div style={{ background: "#1e1e2e", borderRadius: 12, padding: "20px 24px", border: "1px solid #333" }}>
      <h2 style={{ fontSize: 15, fontWeight: 600, margin: "0 0 16px", color: "#f1f5f9" }}>
        Daily API Cost — Last 14 Days
      </h2>
      <ResponsiveContainer width="100%" height={240}>
        <BarChart data={data} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
          <XAxis
            dataKey="date"
            tick={{ fontSize: 11, fill: "#64748b" }}
            tickFormatter={(d) => d.slice(5)}  // show MM-DD only
          />
          <YAxis
            tick={{ fontSize: 11, fill: "#64748b" }}
            tickFormatter={(v) => `$${v.toFixed(2)}`}
          />
          <Tooltip
            contentStyle={{ background: "#0f0f1a", border: "1px solid #333", fontSize: 12 }}
            formatter={(v: number) => [`$${v.toFixed(4)}`, ""]}
          />
          <Legend
            wrapperStyle={{ fontSize: 12, color: "#94a3b8", paddingTop: 12 }}
          />
          {PROJECTS.map((project) => (
            <Bar
              key={project}
              dataKey={project}
              stackId="costs"
              fill={COLOURS[project]}
              name={project}
            />
          ))}
        </BarChart>
      </ResponsiveContainer>
      <p style={{ fontSize: 11, color: "#475569", marginTop: 12 }}>
        Alert threshold: $0.54/project/day (≈ €0.50). Each colour = one project.
      </p>
    </div>
  );
}
```

### Step 4 — Build the model usage pie chart

Create `src/components/ModelPieChart.tsx`:

```typescript
import React from "react";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";

interface ModelEntry {
  model: string;
  cost_usd: number;
  percentage: number;
}

interface Props {
  data: ModelEntry[];
}

// Assign colours to common model names
const MODEL_COLOURS: Record<string, string> = {
  "claude-sonnet-4-6": "#6366f1",
  "claude-haiku":      "#a855f7",
  "gemini-pro":        "#3b82f6",
  "llama3":            "#10b981",
  "deepseek-coder":    "#f59e0b",
  "unknown":           "#64748b",
};

function getColour(model: string): string {
  return MODEL_COLOURS[model] ?? "#94a3b8";
}

export function ModelPieChart({ data }: Props) {
  return (
    <div style={{ background: "#1e1e2e", borderRadius: 12, padding: "20px 24px", border: "1px solid #333" }}>
      <h2 style={{ fontSize: 15, fontWeight: 600, margin: "0 0 16px", color: "#f1f5f9" }}>
        Model Usage — Last 30 Days
      </h2>
      <ResponsiveContainer width="100%" height={220}>
        <PieChart>
          <Pie
            data={data}
            dataKey="cost_usd"
            nameKey="model"
            cx="50%"
            cy="50%"
            outerRadius={80}
            label={({ model, percentage }) => `${model.split("-")[0]}: ${percentage}%`}
            labelLine={false}
          >
            {data.map((entry) => (
              <Cell key={entry.model} fill={getColour(entry.model)} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{ background: "#0f0f1a", border: "1px solid #333", fontSize: 12 }}
            formatter={(v: number) => [`$${v.toFixed(4)}`, "Cost"]}
          />
          <Legend wrapperStyle={{ fontSize: 12, color: "#94a3b8" }} />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}
```

### Step 5 — Build the monthly projection panel

Create `src/components/MonthlyProjection.tsx`:

```typescript
import React from "react";
import { CostSummary } from "../types";

interface Props {
  costs: CostSummary;
}

export function MonthlyProjection({ costs }: Props) {
  const spentPct    = Math.min((costs.month_total_usd / costs.budget_usd) * 100, 100);
  const projectedPct = Math.min((costs.projected_month_usd / costs.budget_usd) * 100, 100);
  const remaining   = Math.max(costs.budget_usd - costs.month_total_usd, 0);

  const barColour = spentPct > 85 ? "#ef4444" : spentPct > 65 ? "#eab308" : "#22c55e";

  return (
    <div style={{ background: "#1e1e2e", borderRadius: 12, padding: "20px 24px", border: "1px solid #333" }}>
      <h2 style={{ fontSize: 15, fontWeight: 600, margin: "0 0 16px", color: "#f1f5f9" }}>
        Monthly Budget
      </h2>

      <div style={{ display: "flex", gap: 32, flexWrap: "wrap", marginBottom: 20 }}>
        <Stat label="Spent this month" value={`$${costs.month_total_usd.toFixed(2)}`} />
        <Stat label="Projected total"  value={`$${costs.projected_month_usd.toFixed(2)}`} />
        <Stat label="Budget"           value={`$${costs.budget_usd.toFixed(2)}/mo`} />
        <Stat label="Remaining"        value={`$${remaining.toFixed(2)}`} colour={remaining < 5 ? "#ef4444" : "#22c55e"} />
      </div>

      {/* Budget progress bar */}
      <div style={{ background: "#0f0f1a", borderRadius: 6, height: 12, overflow: "hidden", marginBottom: 6 }}>
        <div
          style={{
            height: "100%",
            width: `${spentPct}%`,
            background: barColour,
            borderRadius: 6,
            transition: "width 0.5s ease",
          }}
        />
      </div>
      <div style={{ fontSize: 11, color: "#64748b" }}>
        {spentPct.toFixed(0)}% of budget used · Projected: {projectedPct.toFixed(0)}%
      </div>
    </div>
  );
}

function Stat({
  label,
  value,
  colour = "#f1f5f9",
}: {
  label: string;
  value: string;
  colour?: string;
}) {
  return (
    <div>
      <div style={{ fontSize: 11, color: "#64748b" }}>{label}</div>
      <div style={{ fontSize: 20, fontWeight: 700, color: colour }}>{value}</div>
    </div>
  );
}
```

### Step 6 — Add a Costs page to App.tsx

Update `src/App.tsx` to add a simple tab navigation:

```typescript
// Add at the top of App.tsx state:
const [tab, setTab] = useState<"overview" | "costs">("overview");

// Add state and effect for cost chart data:
const [chartData, setChartData]       = useState([]);
const [modelData, setModelData]       = useState([]);

// In loadData(), add:
const [chartRes, modelRes] = await Promise.all([
  fetchCostChartData(),
  fetchModelBreakdown(),
]);
setChartData(chartRes);
setModelData(modelRes);

// Add tab buttons in the header:
<div style={{ display: "flex", gap: 8, marginTop: 16 }}>
  {(["overview", "costs"] as const).map((t) => (
    <button
      key={t}
      onClick={() => setTab(t)}
      style={{
        padding: "6px 16px",
        borderRadius: 6,
        border: "none",
        background: tab === t ? "#6366f1" : "#1e1e2e",
        color: "#f1f5f9",
        cursor: "pointer",
        fontSize: 13,
        fontWeight: tab === t ? 600 : 400,
      }}
    >
      {t === "overview" ? "Overview" : "Costs"}
    </button>
  ))}
</div>

// Then conditionally render:
{tab === "costs" && costs && (
  <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
    <MonthlyProjection costs={costs} />
    <DailyCostChart data={chartData} />
    <ModelPieChart data={modelData} />
  </div>
)}
```

---

## Visual overview

```
COSTS PAGE
──────────

  Monthly Budget Panel
  ┌───────────────────────────────────────┐
  │ Spent: $12.40   Projected: $21.80    │
  │ Budget: $16.20   Remaining: $3.80    │
  │ ████████████████░░░░░░░░░░░░  76%   │
  └───────────────────────────────────────┘

  Daily Cost Chart (stacked bar)
  ┌───────────────────────────────────────┐
  │ $0.60│                               │
  │ $0.40│          ████                 │
  │ $0.20│    ████  ████  ████           │
  │ $0.00└───────────────────────────── │
  │       Apr 1  2   3   4   5   6  ...  │
  │                                       │
  │ ■ promptos ■ rag-brain ■ pipeline... │
  └───────────────────────────────────────┘

  Model Usage Pie
  ┌───────────────────────────────────────┐
  │         claude: 45%                   │
  │      ┌──────┐  gemini: 28%            │
  │      │  pie │  llama3: 22%            │
  │      └──────┘  deepseek: 5%           │
  └───────────────────────────────────────┘
```

---

## Learning checkpoint

**What is a stacked bar chart good for?**

A stacked bar chart shows both the individual parts and the total in one view. Each bar's height = total cost that day. Each colour segment = one project's contribution. You can see at a glance which projects are the most expensive and whether your total is growing.

A regular grouped bar chart would also work, but with 5 projects it gets crowded. Stacked keeps it clean.

---

## Done when

- [ ] Costs tab is visible in the dashboard navigation
- [ ] Daily cost stacked bar chart shows real data
- [ ] Model usage pie chart shows which models are being called
- [ ] Monthly projection panel shows remaining budget
- [ ] All three charts update when the dashboard refreshes

---

## Next step

→ [P6-T6: Content Tracker](p6-t6-content-tracker.md) — add the publishing progress panel.
