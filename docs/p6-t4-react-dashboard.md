# P6-T4: Build the React Dashboard with Project Health Cards

> **Goal:** Build a React dashboard that shows a health card for each of the 5 projects, with a status indicator, key metric, and 7-day sparkline.

**Part of:** [P6-US1: Unified Metrics](p6-us1-unified-metrics.md)
**Week:** 11–12
**Labels:** `task`, `p6-dashboard`

---

## What you are doing

You are building the frontend of the dashboard. This is a React application that calls your metrics API and displays the data in a clean, readable layout.

If you have not built much React before, do not worry. This task breaks it into small pieces and gives you the complete component code. You are assembling known building blocks, not inventing anything new.

By the end of this task, you will have a working dashboard at `http://localhost:3000` showing live data from all 5 projects.

---

## Why this step matters

The metrics API is invisible — it just stores data. This task makes all of that data visible. For the first time, you will be able to look at one page and see the state of every system you have built.

This is also the layer that makes the project shareable. You cannot send someone a link to a PostgreSQL database. You can send them a link to a dashboard.

---

## Prerequisites

- [ ] [P6-T2: Metrics API](p6-t2-metrics-api.md) is running and has real data
- [ ] [P6-T3: Cost Tracking](p6-t3-cost-tracking.md) is working
- [ ] Node.js 20+ installed (`node --version`)
- [ ] Basic familiarity with the concept of components and props in React (not required, but helpful)

---

## Step-by-step instructions

### Step 1 — Create the React project

```bash
cd projects/06-dashboard
npx create-react-app dashboard --template typescript
cd dashboard
```

If you prefer Vite (faster, lighter):

```bash
npm create vite@latest dashboard -- --template react-ts
cd dashboard
npm install
```

### Step 2 — Install dependencies

```bash
npm install recharts axios date-fns
```

| Package | What it does |
|---------|-------------|
| `recharts` | Simple chart library for React — sparklines, bar charts, pie charts |
| `axios` | Makes HTTP calls to your metrics API |
| `date-fns` | Format dates nicely |

### Step 3 — Set up the environment

Create `.env` in the `dashboard/` folder:

```bash
REACT_APP_API_URL=http://localhost:8006
```

(If using Vite, use `VITE_API_URL` instead.)

### Step 4 — Understand the component structure

```
src/
  App.tsx                  ← root component, fetches all data
  components/
    ProjectCard.tsx        ← one card per project
    Sparkline.tsx          ← 7-day activity chart
    StatusBadge.tsx        ← 🟢 Live / 🟡 Idle / 🔴 Down
    CostPanel.tsx          ← today's cost and budget bar
  api/
    metrics.ts             ← all API calls in one place
  types/
    index.ts               ← TypeScript types
```

### Step 5 — Write the types

Create `src/types/index.ts`:

```typescript
export type ProjectStatus = "live" | "idle" | "down";

export interface ProjectSummary {
  project: string;
  total_events: number;
  last_seen: string | null;        // ISO timestamp
  time_since_last_event: string;   // e.g. "00:02:34"
}

export interface SparklinePoint {
  date: string;
  event_count: number;
}

export interface CostSummary {
  today: Record<string, number>;   // project -> USD
  today_total_usd: number;
  month_total_usd: number;
  projected_month_usd: number;
  budget_usd: number;
}

export const PROJECT_LABELS: Record<string, string> = {
  "promptos":  "PromptOS",
  "rag-brain": "RAG Brain",
  "pipeline":  "Pipeline",
  "aiga":      "AIGA",
  "pr-review": "PR Review",
};

export const PROJECT_GITHUB: Record<string, string> = {
  "promptos":  "https://github.com/PathakLabs/promptos",
  "rag-brain": "https://github.com/PathakLabs/rag-brain",
  "pipeline":  "https://github.com/PathakLabs/pipeline",
  "aiga":      "https://github.com/PathakLabs/aiga",
  "pr-review": "https://github.com/PathakLabs/pr-review-bot",
};
```

### Step 6 — Write the API layer

Create `src/api/metrics.ts`:

```typescript
import axios from "axios";

const BASE = process.env.REACT_APP_API_URL ?? "http://localhost:8006";
const api  = axios.create({ baseURL: BASE });

export async function fetchProjects() {
  const res = await api.get("/projects");
  return res.data;
}

export async function fetchSparkline(project: string, days = 7) {
  const res = await api.get(`/projects/${project}/sparkline`, {
    params: { days },
  });
  return res.data;
}

export async function fetchCostSummary() {
  const res = await api.get("/costs/summary");
  return res.data;
}
```

### Step 7 — Build the StatusBadge component

Create `src/components/StatusBadge.tsx`:

```typescript
import React from "react";
import { ProjectStatus } from "../types";

interface Props {
  status: ProjectStatus;
}

// Status is determined by how long since the last event:
//   < 24 hours  → live (green)
//   24-72 hours → idle (yellow)
//   > 72 hours  → down (red)
export function getStatus(lastSeen: string | null): ProjectStatus {
  if (!lastSeen) return "down";
  const hours = (Date.now() - new Date(lastSeen).getTime()) / (1000 * 60 * 60);
  if (hours < 24) return "live";
  if (hours < 72) return "idle";
  return "down";
}

const labels: Record<ProjectStatus, string> = {
  live: "Live",
  idle: "Idle",
  down: "Down",
};

const colours: Record<ProjectStatus, string> = {
  live: "#22c55e",   // green
  idle: "#eab308",   // yellow
  down: "#ef4444",   // red
};

export function StatusBadge({ status }: Props) {
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: "6px",
        fontSize: "13px",
        fontWeight: 600,
        color: colours[status],
      }}
    >
      <span
        style={{
          width: 10,
          height: 10,
          borderRadius: "50%",
          background: colours[status],
          display: "inline-block",
        }}
      />
      {labels[status]}
    </span>
  );
}
```

### Step 8 — Build the Sparkline component

Create `src/components/Sparkline.tsx`:

```typescript
import React from "react";
import {
  AreaChart,
  Area,
  ResponsiveContainer,
  Tooltip,
} from "recharts";
import { SparklinePoint } from "../types";

interface Props {
  data: SparklinePoint[];
  colour?: string;
}

export function Sparkline({ data, colour = "#6366f1" }: Props) {
  if (data.length === 0) {
    return (
      <div style={{ height: 40, color: "#6b7280", fontSize: 12 }}>
        No data yet
      </div>
    );
  }

  return (
    <div style={{ height: 48 }}>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 4, bottom: 4 }}>
          <defs>
            <linearGradient id={`grad-${colour}`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%"   stopColor={colour} stopOpacity={0.3} />
              <stop offset="95%"  stopColor={colour} stopOpacity={0} />
            </linearGradient>
          </defs>
          <Area
            type="monotone"
            dataKey="event_count"
            stroke={colour}
            strokeWidth={2}
            fill={`url(#grad-${colour})`}
            dot={false}
          />
          <Tooltip
            contentStyle={{ fontSize: 11 }}
            formatter={(v: number) => [`${v} events`, ""]}
            labelFormatter={(label) => label}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
```

### Step 9 — Build the ProjectCard component

Create `src/components/ProjectCard.tsx`:

```typescript
import React, { useEffect, useState } from "react";
import { ProjectSummary, SparklinePoint, PROJECT_LABELS, PROJECT_GITHUB } from "../types";
import { fetchSparkline } from "../api/metrics";
import { StatusBadge, getStatus } from "./StatusBadge";
import { Sparkline } from "./Sparkline";

// One colour per project
const PROJECT_COLOURS: Record<string, string> = {
  "promptos":  "#6366f1",   // indigo
  "rag-brain": "#10b981",   // emerald
  "pipeline":  "#f59e0b",   // amber
  "aiga":      "#3b82f6",   // blue
  "pr-review": "#ec4899",   // pink
};

interface Props {
  summary: ProjectSummary;
  costToday?: number;
}

export function ProjectCard({ summary, costToday }: Props) {
  const [sparkline, setSparkline] = useState<SparklinePoint[]>([]);

  useEffect(() => {
    fetchSparkline(summary.project)
      .then(setSparkline)
      .catch(() => setSparkline([]));
  }, [summary.project]);

  const status  = getStatus(summary.last_seen);
  const colour  = PROJECT_COLOURS[summary.project] ?? "#6366f1";
  const label   = PROJECT_LABELS[summary.project] ?? summary.project;
  const github  = PROJECT_GITHUB[summary.project];

  return (
    <div
      style={{
        background: "#1e1e2e",
        borderRadius: 12,
        border: `1px solid ${colour}33`,
        padding: "18px 20px",
        display: "flex",
        flexDirection: "column",
        gap: 12,
        minWidth: 200,
        flex: 1,
      }}
    >
      {/* Header row */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontWeight: 700, fontSize: 15, color: "#f1f5f9" }}>
          {label}
        </span>
        <StatusBadge status={status} />
      </div>

      {/* Key metric */}
      <div style={{ fontSize: 28, fontWeight: 700, color: colour }}>
        {summary.total_events.toLocaleString()}
      </div>
      <div style={{ fontSize: 12, color: "#94a3b8", marginTop: -8 }}>
        total events
      </div>

      {/* 7-day sparkline */}
      <div>
        <div style={{ fontSize: 11, color: "#64748b", marginBottom: 4 }}>
          Last 7 days
        </div>
        <Sparkline data={sparkline} colour={colour} />
      </div>

      {/* Cost today */}
      {costToday !== undefined && (
        <div style={{ fontSize: 12, color: "#94a3b8" }}>
          Cost today:{" "}
          <span style={{ color: "#f1f5f9", fontWeight: 600 }}>
            ${costToday.toFixed(4)}
          </span>
        </div>
      )}

      {/* GitHub link */}
      {github && (
        <a
          href={github}
          target="_blank"
          rel="noreferrer"
          style={{
            fontSize: 12,
            color: colour,
            textDecoration: "none",
            display: "flex",
            alignItems: "center",
            gap: 4,
          }}
        >
          View on GitHub ↗
        </a>
      )}
    </div>
  );
}
```

### Step 10 — Build the main App component

Replace `src/App.tsx`:

```typescript
import React, { useEffect, useState } from "react";
import { ProjectSummary, CostSummary } from "./types";
import { fetchProjects, fetchCostSummary } from "./api/metrics";
import { ProjectCard } from "./components/ProjectCard";

const PROJECTS = ["promptos", "rag-brain", "pipeline", "aiga", "pr-review"];

export default function App() {
  const [projects, setProjects]   = useState<ProjectSummary[]>([]);
  const [costs, setCosts]         = useState<CostSummary | null>(null);
  const [lastUpdated, setUpdated] = useState<Date>(new Date());
  const [loading, setLoading]     = useState(true);

  async function loadData() {
    try {
      const [projectData, costData] = await Promise.all([
        fetchProjects(),
        fetchCostSummary(),
      ]);
      setProjects(projectData);
      setCosts(costData);
      setUpdated(new Date());
    } catch (err) {
      console.error("Failed to load dashboard data", err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
    // Refresh every 5 minutes
    const timer = setInterval(loadData, 5 * 60 * 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div
      style={{
        minHeight: "100vh",
        background: "#0f0f1a",
        color: "#f1f5f9",
        fontFamily: "'Inter', 'Segoe UI', sans-serif",
        padding: "32px 24px",
        maxWidth: 1200,
        margin: "0 auto",
      }}
    >
      {/* Header */}
      <div style={{ marginBottom: 32 }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>
          PathakLabs AI Dashboard
        </h1>
        <p style={{ color: "#64748b", margin: "6px 0 0", fontSize: 13 }}>
          5 live AI projects · Built in 14 weeks ·{" "}
          Last updated: {lastUpdated.toLocaleTimeString()}
        </p>
      </div>

      {loading && (
        <p style={{ color: "#64748b" }}>Loading...</p>
      )}

      {/* Project health cards */}
      <div style={{ display: "flex", gap: 16, flexWrap: "wrap", marginBottom: 32 }}>
        {PROJECTS.map((projectId) => {
          const summary = projects.find((p) => p.project === projectId);
          return summary ? (
            <ProjectCard
              key={projectId}
              summary={summary}
              costToday={costs?.today?.[projectId]}
            />
          ) : (
            <div
              key={projectId}
              style={{
                background: "#1e1e2e",
                borderRadius: 12,
                border: "1px solid #333",
                padding: "18px 20px",
                flex: 1,
                minWidth: 200,
                color: "#64748b",
                fontSize: 13,
              }}
            >
              {projectId} — no data yet
            </div>
          );
        })}
      </div>

      {/* Cost summary bar */}
      {costs && (
        <div
          style={{
            background: "#1e1e2e",
            borderRadius: 12,
            border: "1px solid #333",
            padding: "20px 24px",
            display: "flex",
            gap: 40,
            flexWrap: "wrap",
          }}
        >
          <div>
            <div style={{ fontSize: 12, color: "#64748b" }}>Today</div>
            <div style={{ fontSize: 22, fontWeight: 700 }}>
              ${costs.today_total_usd.toFixed(4)}
            </div>
          </div>
          <div>
            <div style={{ fontSize: 12, color: "#64748b" }}>This month</div>
            <div style={{ fontSize: 22, fontWeight: 700 }}>
              ${costs.month_total_usd.toFixed(2)}
            </div>
          </div>
          <div>
            <div style={{ fontSize: 12, color: "#64748b" }}>Projected</div>
            <div style={{ fontSize: 22, fontWeight: 700 }}>
              ${costs.projected_month_usd.toFixed(2)}
            </div>
          </div>
          <div>
            <div style={{ fontSize: 12, color: "#64748b" }}>Budget</div>
            <div style={{ fontSize: 22, fontWeight: 700 }}>
              ${costs.budget_usd.toFixed(2)}/mo
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

### Step 11 — Run the dashboard

```bash
npm start
```

Open `http://localhost:3000`. You should see the health cards loading data from your metrics API.

---

## Visual overview

```
App (fetches all data every 5 minutes)
│
├── ProjectCard (×5 — one per project)
│   ├── StatusBadge  ← "Live" / "Idle" / "Down"  based on last_seen
│   ├── Key metric   ← total event count
│   ├── Sparkline    ← 7-day activity area chart
│   ├── Cost today   ← from CostSummary.today[project]
│   └── GitHub link
│
└── Cost summary bar
    ├── Today total
    ├── Month total
    ├── Projected month
    └── Budget
```

**Status indicator logic:**

```
last_seen < 24 hours ago  →  ● Live   (green)
last_seen 24–72 hours ago →  ● Idle   (yellow)
last_seen > 72 hours ago  →  ● Down   (red)
no data at all            →  ● Down   (red)
```

---

## Learning checkpoint

**Why does the sparkline use event count, not the raw data?**

The sparkline shows how active each project is day by day. Plotting the raw events would produce a meaningless scatter. Aggregating to a daily count and plotting those counts gives a readable activity trend — rising means more usage, flat means the project ran but at steady volume, zero means it did not run.

**Why refresh every 5 minutes?**

The dashboard is a monitoring tool, not a real-time feed. 5-minute refresh is frequent enough to catch problems quickly without hammering the API.

---

## Done when

- [ ] `npm start` runs without errors
- [ ] All 5 project cards appear at `http://localhost:3000`
- [ ] Each card shows a status indicator based on real data
- [ ] Sparkline charts show data (may be flat if projects have not run much yet)
- [ ] Cost summary bar shows today's total
- [ ] Dashboard refreshes automatically every 5 minutes

---

## Next step

→ [P6-T5: Cost Charts](p6-t5-cost-charts.md) — add a dedicated cost breakdown page with stacked bar and pie charts.
