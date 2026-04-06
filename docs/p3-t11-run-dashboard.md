# P3-T11: Build Pipeline Run Summary Dashboard

> **Goal:** Build a simple dashboard that shows how the pipeline is performing across runs — articles found, filter rates, validation scores, and posts sent.

**Part of:** [P3-E1: 5-Agent Research Pipeline in n8n](p3-e1-agent-pipeline.md)
**Week:** 8
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are building a read-only dashboard that queries the `pipeline_logs` table you created in P3-T10 and displays a summary of recent pipeline runs.

You have two options for building this dashboard — choose based on what tools you have available:

**Option A (Simpler):** An n8n workflow that runs a SQL query and sends a formatted summary to Telegram on demand.

**Option B (Visual):** A basic HTML page on your homelab that queries MariaDB and displays results in a table.

Both options produce the same data. Start with Option A.

---

## Why this step matters

```
Without a dashboard:
  "Did the pipeline work yesterday? Let me check n8n logs..."
  *5 minutes of clicking*
  "I think it worked? Not sure why only 1 article passed Validator."

With a dashboard:
  You open one page or send one Telegram command.
  You see:
  - Run 1: 50 articles → 30 filtered → 8 validated → 1 post sent ✓
  - Run 2: 47 articles → 28 filtered → 6 validated → 1 post sent ✓
  - Run 3: 51 articles → 30 filtered → 0 validated → 0 posts    ✗
  "Run 3 failed at Validator. Average score was 4.2. Something changed."
```

A dashboard turns raw log data into actionable insight in seconds.

---

## Prerequisites

- [ ] [P3-T10](p3-t10-quality-logging.md) complete — `pipeline_logs` table populated with at least 2–3 runs
- [ ] MariaDB accessible from n8n

---

## Step-by-step instructions

### Step 1 — Design what the dashboard shows

Your dashboard should answer these questions at a glance:

1. **Run history:** Last N runs — when did they run, did they succeed?
2. **Funnel view:** For each run, how many articles entered and exited each agent?
3. **Per-agent success rate:** Which agent fails most often across all runs?
4. **Posts sent to Telegram:** How many posts have been generated total?

---

### Step 2 — Write the SQL queries

**Query 1: Last 10 runs summary**
```sql
SELECT
  run_id,
  MIN(timestamp) AS run_started,
  MAX(CASE WHEN agent_name = 'Search'      THEN output_count END) AS articles_found,
  MAX(CASE WHEN agent_name = 'Pre-filter'  THEN output_count END) AS passed_filter,
  MAX(CASE WHEN agent_name = 'Validator'   THEN output_count END) AS passed_validation,
  MAX(CASE WHEN agent_name = 'Synthesizer' THEN output_count END) AS posts_sent,
  SUM(CASE WHEN failed = 1 THEN 1 ELSE 0 END) AS agent_failures,
  MAX(topic) AS topic
FROM pipeline_logs
GROUP BY run_id
ORDER BY run_started DESC
LIMIT 10;
```

**Query 2: Per-agent success rate (all time)**
```sql
SELECT
  agent_name,
  COUNT(*) AS total_runs,
  SUM(CASE WHEN failed = 1 THEN 1 ELSE 0 END) AS failures,
  ROUND(100.0 * SUM(CASE WHEN failed = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS success_rate_pct,
  ROUND(AVG(quality_score), 2) AS avg_quality_score
FROM pipeline_logs
GROUP BY agent_name
ORDER BY
  FIELD(agent_name, 'Planner', 'Search', 'Pre-filter', 'Validator', 'Extractor', 'Synthesizer');
```

**Query 3: Funnel view for latest run**
```sql
SELECT
  agent_name,
  input_count,
  output_count,
  quality_score,
  failed,
  timestamp
FROM pipeline_logs
WHERE run_id = (
  SELECT run_id FROM pipeline_logs ORDER BY timestamp DESC LIMIT 1
)
ORDER BY timestamp ASC;
```

---

### Step 3 — Option A: Telegram report workflow

Create a **new n8n workflow** called `Pipeline Dashboard — Telegram Report`.

**Trigger:** Manual Trigger (or Schedule it to run every morning at 8am)

**Node sequence:**

1. **Manual Trigger** or **Schedule Trigger**

2. **MariaDB node: Run History**
   - Execute the "Last 10 runs" query above
   - Name: `Query: Last 10 Runs`

3. **MariaDB node: Agent Success Rates**
   - Execute the "Per-agent success rate" query above
   - Name: `Query: Agent Success Rates`

4. **Code node: Format Dashboard Text**
   ```javascript
   // Get data from both previous queries
   const runs = $('Query: Last 10 Runs').all().map(i => i.json);
   const agents = $('Query: Agent Success Rates').all().map(i => i.json);

   // Format run history table
   const runLines = runs.map(run => {
     const status = run.agent_failures > 0 ? '✗' : '✓';
     const date = new Date(run.run_started).toLocaleDateString('en-GB');
     return `${status} ${date} | ${run.topic?.substring(0, 20) || 'n/a'} | Found: ${run.articles_found || 0} | Passed filter: ${run.passed_filter || 0} | Validated: ${run.passed_validation || 0} | Posts: ${run.posts_sent || 0}`;
   });

   // Format agent success rate table
   const agentLines = agents.map(agent => {
     return `${agent.agent_name}: ${agent.success_rate_pct}% success (${agent.total_runs} runs) | Avg quality: ${agent.avg_quality_score || 'n/a'}`;
   });

   // Build the full report
   const report = [
     '📊 *Pipeline Dashboard*',
     `_Generated: ${new Date().toLocaleString()}_`,
     '',
     '*Recent Runs (last 10):*',
     '```',
     'Status | Date       | Topic               | Found | Filter | Valid | Posts',
     '-------|------------|---------------------|-------|--------|-------|------',
     ...runLines,
     '```',
     '',
     '*Agent Success Rates (all time):*',
     ...agentLines
   ].join('\n');

   return [{ json: { report } }];
   ```

5. **Telegram node: Send Dashboard**
   - Message: `{{ $json.report }}`
   - Parse Mode: `Markdown`

---

### Step 4 — Option B: Simple HTML dashboard (optional)

If you want a visual browser-based dashboard, create a file on your homelab at `/var/www/pipeline-dashboard/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Pipeline Dashboard</title>
  <style>
    body { font-family: monospace; background: #111; color: #eee; padding: 2rem; }
    h1 { color: #7df; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
    th, td { border: 1px solid #444; padding: 0.5rem 1rem; text-align: left; }
    th { background: #222; color: #7df; }
    tr:nth-child(even) { background: #1a1a1a; }
    .ok { color: #4f4; }
    .fail { color: #f44; }
    .metric { font-size: 2rem; font-weight: bold; color: #7df; }
    .metric-label { font-size: 0.9rem; color: #888; }
  </style>
</head>
<body>
  <h1>AI Research Pipeline Dashboard</h1>
  <p id="updated">Loading...</p>

  <h2>Summary (all time)</h2>
  <div id="summary"></div>

  <h2>Recent Runs</h2>
  <table id="runs-table">
    <thead>
      <tr>
        <th>Status</th>
        <th>Date</th>
        <th>Topic</th>
        <th>Articles Found</th>
        <th>Passed Filter</th>
        <th>Validated</th>
        <th>Posts Sent</th>
      </tr>
    </thead>
    <tbody id="runs-body">Loading...</tbody>
  </table>

  <h2>Agent Success Rates</h2>
  <table id="agents-table">
    <thead>
      <tr>
        <th>Agent</th>
        <th>Success Rate</th>
        <th>Total Runs</th>
        <th>Avg Quality Score</th>
      </tr>
    </thead>
    <tbody id="agents-body">Loading...</tbody>
  </table>

  <script>
    // This assumes you have a simple API endpoint that queries MariaDB
    // Replace with your actual API URL
    const API_BASE = 'http://your-homelab-ip:3000/api';

    async function loadDashboard() {
      try {
        const [runs, agents] = await Promise.all([
          fetch(`${API_BASE}/pipeline-runs`).then(r => r.json()),
          fetch(`${API_BASE}/agent-stats`).then(r => r.json())
        ]);

        renderRuns(runs);
        renderAgents(agents);
        document.getElementById('updated').textContent =
          `Last updated: ${new Date().toLocaleString()}`;
      } catch (e) {
        document.getElementById('updated').textContent =
          `Error loading dashboard: ${e.message}`;
      }
    }

    function renderRuns(runs) {
      const tbody = document.getElementById('runs-body');
      tbody.innerHTML = runs.map(run => `
        <tr>
          <td class="${run.agent_failures > 0 ? 'fail' : 'ok'}">
            ${run.agent_failures > 0 ? '✗ Failed' : '✓ OK'}
          </td>
          <td>${new Date(run.run_started).toLocaleDateString()}</td>
          <td>${run.topic || 'n/a'}</td>
          <td>${run.articles_found || 0}</td>
          <td>${run.passed_filter || 0}</td>
          <td>${run.passed_validation || 0}</td>
          <td>${run.posts_sent || 0}</td>
        </tr>
      `).join('');
    }

    function renderAgents(agents) {
      const tbody = document.getElementById('agents-body');
      tbody.innerHTML = agents.map(agent => `
        <tr>
          <td>${agent.agent_name}</td>
          <td class="${agent.success_rate_pct < 80 ? 'fail' : 'ok'}">
            ${agent.success_rate_pct}%
          </td>
          <td>${agent.total_runs}</td>
          <td>${agent.avg_quality_score || 'n/a'}</td>
        </tr>
      `).join('');
    }

    loadDashboard();
    setInterval(loadDashboard, 60000); // Refresh every minute
  </script>
</body>
</html>
```

---

## What to look for in the dashboard

**Normal funnel ratios (reference targets):**

```
Articles found:     50  (100%)
After Pre-filter:   30  (60%)   ← below 40% = Pre-filter too strict
After Validator:     8  (27%)   ← below 10% = topic too niche or Validator too strict
Posts drafted:       1
```

**Warning signs:**
- Pre-filter output < 40% of Search output → filter rules may be too aggressive
- Validator output < 10% of Pre-filter output → topic may be too niche, or Gemini scoring too harshly
- Validator `avg_quality_score` dropping week over week → content quality declining for your topic
- Any agent at < 90% success rate → investigate that agent's failure logs

---

## Visual overview

```
pipeline_logs (MariaDB)
       │
       │ SQL queries
       ▼
┌──────────────────────────────────────────────┐
│  Dashboard (Telegram report or HTML page)     │
│                                               │
│  Run History:                                 │
│  ✓ 06 Apr | AI healthcare | 50→30→8→1 post   │
│  ✓ 05 Apr | AI agents     | 47→28→6→1 post   │
│  ✗ 04 Apr | AI robotics   | 51→30→0→0 posts  │
│    ↑ Validator failure on 04 Apr!             │
│                                               │
│  Agent Success Rates:                         │
│  Planner:    100% (10 runs)                   │
│  Search:     100% (10 runs)                   │
│  Pre-filter:  90% (10 runs)                   │
│  Validator:   90% (10 runs)                   │
│  Extractor:  100% (10 runs)                   │
│  Synthesizer: 90% (10 runs)                   │
└──────────────────────────────────────────────┘
```

---

## Done when

- [ ] SQL queries tested and returning correct data from `pipeline_logs`
- [ ] Telegram report workflow runs and delivers formatted summary
- [ ] Dashboard shows last 10 runs with funnel metrics
- [ ] Dashboard shows per-agent success rates
- [ ] At least 3 pipeline runs exist in logs to make the dashboard meaningful

---

## Next step

→ [P3-T12: Write Agent Failure Runbook](p3-t12-failure-runbook.md)
