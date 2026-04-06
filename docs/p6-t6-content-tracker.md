# P6-T6: Add the Content Publishing Tracker

> **Goal:** Add a panel to the dashboard showing your publishing progress across all 6 projects — build logs, LinkedIn posts, blog posts, and Instagram carousels.

**Part of:** [P6-US2: Public Portfolio](p6-us2-public-portfolio.md)
**Week:** 12
**Labels:** `task`, `p6-dashboard`

---

## What you are doing

You are adding a fourth panel to the dashboard: a content tracker. It is a simple grid showing which pieces of content you have published for each project.

This tracker does two things:
1. It holds you accountable to the content system you set up in Week 1
2. It shows visitors that you documented the entire build process — not just the code

---

## Why this step matters

Most developers build things and never talk about them. The content tracker on a public dashboard is a visual commitment that you build *and* communicate.

When a potential client or employer sees that you have published 12 build logs, 6 LinkedIn posts, 3 blog posts, and 2 Instagram carousels — all linked to specific projects — it shows a level of discipline that is rare and valuable.

---

## Prerequisites

- [ ] [P6-T4: React Dashboard](p6-t4-react-dashboard.md) is running
- [ ] You have published at least some content for Projects 1–5 (even if incomplete)

---

## Step-by-step instructions

### Step 1 — Decide how to store content status

The content tracker can be stored two ways:

**Option A — Static JSON file (recommended to start)**

A simple JSON file that you update manually each time you publish something. No database needed.

**Option B — Database table** (add later if you want it live on the dashboard)

A `content_items` table you insert rows into.

Start with Option A. It is the fastest to build and easiest to maintain.

### Step 2 — Create the content data file

Create `projects/06-dashboard/dashboard/src/data/content.json`:

```json
{
  "projects": [
    {
      "id": "p1",
      "name": "P1 — PromptOS",
      "build_logs": [
        { "title": "Week 1: FastAPI setup", "url": "", "published": true },
        { "title": "Week 2: Multi-model testing", "url": "", "published": true },
        { "title": "Week 3: Scoring system", "url": "", "published": false }
      ],
      "linkedin_posts": [
        { "title": "PromptOS launch post", "url": "", "published": true }
      ],
      "blog_posts": [
        { "title": "How I built a prompt management system", "url": "", "published": false }
      ],
      "instagram_carousels": [
        { "title": "Prompt engineering tips", "url": "", "published": false }
      ]
    },
    {
      "id": "p2",
      "name": "P2 — RAG Brain",
      "build_logs": [
        { "title": "Week 4: LlamaIndex setup", "url": "", "published": true },
        { "title": "Week 5: HA YAML loader", "url": "", "published": true },
        { "title": "Week 6: Hallucination detection", "url": "", "published": false }
      ],
      "linkedin_posts": [
        { "title": "RAG Brain post", "url": "", "published": false }
      ],
      "blog_posts": [
        { "title": "Building a personal RAG system", "url": "", "published": false }
      ],
      "instagram_carousels": []
    },
    {
      "id": "p3",
      "name": "P3 — Pipeline",
      "build_logs": [
        { "title": "Week 6: Agent pipeline intro", "url": "", "published": false }
      ],
      "linkedin_posts": [],
      "blog_posts": [],
      "instagram_carousels": []
    },
    {
      "id": "p4",
      "name": "P4 — AIGA",
      "build_logs": [],
      "linkedin_posts": [],
      "blog_posts": [],
      "instagram_carousels": []
    },
    {
      "id": "p5",
      "name": "P5 — PR Review Bot",
      "build_logs": [],
      "linkedin_posts": [],
      "blog_posts": [],
      "instagram_carousels": []
    },
    {
      "id": "p6",
      "name": "P6 — Dashboard",
      "build_logs": [],
      "linkedin_posts": [],
      "blog_posts": [
        { "title": "14 weeks, 6 AI projects: the capstone", "url": "", "published": false }
      ],
      "instagram_carousels": [
        { "title": "Live dashboard walkthrough reel", "url": "", "published": false }
      ]
    }
  ]
}
```

Update the `published` and `url` fields as you publish things.

### Step 3 — Build the ContentTracker component

Create `src/components/ContentTracker.tsx`:

```typescript
import React, { useState } from "react";
import contentData from "../data/content.json";

interface ContentItem {
  title: string;
  url: string;
  published: boolean;
}

interface Project {
  id: string;
  name: string;
  build_logs: ContentItem[];
  linkedin_posts: ContentItem[];
  blog_posts: ContentItem[];
  instagram_carousels: ContentItem[];
}

const COLUMNS: { key: keyof Omit<Project, "id" | "name">; label: string }[] = [
  { key: "build_logs",          label: "Build Logs" },
  { key: "linkedin_posts",      label: "LinkedIn" },
  { key: "blog_posts",          label: "Blog" },
  { key: "instagram_carousels", label: "Instagram" },
];

function ItemDot({ item }: { item: ContentItem }) {
  const [hover, setHover] = useState(false);

  return (
    <a
      href={item.url || undefined}
      target={item.url ? "_blank" : undefined}
      rel="noreferrer"
      title={item.title}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        display: "inline-block",
        width: 12,
        height: 12,
        borderRadius: "50%",
        background: item.published ? "#22c55e" : "#1e293b",
        border: `2px solid ${item.published ? "#22c55e" : "#334155"}`,
        cursor: item.url ? "pointer" : "default",
        textDecoration: "none",
        transition: "transform 0.15s",
        transform: hover ? "scale(1.3)" : "scale(1)",
        marginRight: 4,
      }}
    />
  );
}

function countPublished(items: ContentItem[]): number {
  return items.filter((i) => i.published).length;
}

export function ContentTracker() {
  const projects: Project[] = contentData.projects;

  // Calculate totals
  const totalPublished = projects.reduce((sum, p) => {
    return sum + COLUMNS.reduce((s, col) => {
      return s + countPublished(p[col.key] as ContentItem[]);
    }, 0);
  }, 0);

  const totalItems = projects.reduce((sum, p) => {
    return sum + COLUMNS.reduce((s, col) => {
      return s + (p[col.key] as ContentItem[]).length;
    }, 0);
  }, 0);

  return (
    <div
      style={{
        background: "#1e1e2e",
        borderRadius: 12,
        padding: "20px 24px",
        border: "1px solid #333",
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
        <h2 style={{ fontSize: 15, fontWeight: 600, margin: 0, color: "#f1f5f9" }}>
          Content Published
        </h2>
        <span style={{ fontSize: 12, color: "#64748b" }}>
          {totalPublished} / {totalItems} pieces
        </span>
      </div>

      {/* Table */}
      <div style={{ overflowX: "auto" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
          <thead>
            <tr>
              <th style={{ textAlign: "left", color: "#64748b", fontWeight: 500, paddingBottom: 10, paddingRight: 16 }}>
                Project
              </th>
              {COLUMNS.map((col) => (
                <th
                  key={col.key}
                  style={{ textAlign: "left", color: "#64748b", fontWeight: 500, paddingBottom: 10, paddingRight: 16 }}
                >
                  {col.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {projects.map((project) => (
              <tr key={project.id}>
                <td
                  style={{
                    paddingBottom: 12,
                    paddingRight: 16,
                    color: "#94a3b8",
                    fontWeight: 500,
                    whiteSpace: "nowrap",
                  }}
                >
                  {project.name}
                </td>
                {COLUMNS.map((col) => {
                  const items = project[col.key] as ContentItem[];
                  return (
                    <td key={col.key} style={{ paddingBottom: 12, paddingRight: 16 }}>
                      {items.length === 0 ? (
                        <span style={{ color: "#334155", fontSize: 11 }}>—</span>
                      ) : (
                        <div style={{ display: "flex", flexWrap: "wrap", gap: 2 }}>
                          {items.map((item, i) => (
                            <ItemDot key={i} item={item} />
                          ))}
                        </div>
                      )}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Legend */}
      <div style={{ marginTop: 12, fontSize: 11, color: "#475569", display: "flex", gap: 16 }}>
        <span>
          <span style={{ display: "inline-block", width: 10, height: 10, borderRadius: "50%", background: "#22c55e", marginRight: 4 }} />
          Published
        </span>
        <span>
          <span style={{ display: "inline-block", width: 10, height: 10, borderRadius: "50%", background: "#1e293b", border: "2px solid #334155", marginRight: 4 }} />
          Not yet
        </span>
        <span>Hover a dot to see the title. Click if it has a link.</span>
      </div>
    </div>
  );
}
```

### Step 4 — Add the ContentTracker to the dashboard

In `src/App.tsx`, import and add the tracker below the cost summary bar:

```typescript
import { ContentTracker } from "./components/ContentTracker";

// Add after the cost summary bar in the overview tab:
{tab === "overview" && (
  <>
    {/* ... existing project cards and cost bar ... */}
    <ContentTracker />
  </>
)}
```

### Step 5 — Update the tracker as you publish

Every time you publish a piece of content, open `src/data/content.json` and update it:

```json
{ "title": "PromptOS launch post", "url": "https://linkedin.com/...", "published": true }
```

This is intentionally manual. You publish something → you update the file → you commit. The act of updating it is a small celebration of the work.

### Step 6 — Optional: add total counts to the header

If you want summary numbers in the dashboard header:

```typescript
// Above the project cards in App.tsx
const totalLogs     = contentData.projects.reduce((s, p) => s + p.build_logs.filter(i => i.published).length, 0);
const totalLinkedIn = contentData.projects.reduce((s, p) => s + p.linkedin_posts.filter(i => i.published).length, 0);
const totalBlogs    = contentData.projects.reduce((s, p) => s + p.blog_posts.filter(i => i.published).length, 0);

// Render:
<p style={{ color: "#64748b", fontSize: 12 }}>
  {totalLogs} build logs · {totalLinkedIn} LinkedIn posts · {totalBlogs} blog posts
</p>
```

---

## Visual overview

```
CONTENT TRACKER PANEL
─────────────────────

  Project       Build Logs    LinkedIn    Blog    Instagram
  ──────────────────────────────────────────────────────────
  P1 PromptOS   ● ● ○         ●           ○       ○
  P2 RAG Brain  ● ● ○         ○           ○       —
  P3 Pipeline   ○             —           —       —
  P4 AIGA       —             ○           ○       —
  P5 PR Review  —             ○           ○       —
  P6 Dashboard  —             ○           ○       ○

  ● = published   ○ = not yet   — = not applicable

  Hover any dot to see the title.
  Click a dot (if it has a URL) to open the published piece.
```

---

## Learning checkpoint

**Why keep this in a JSON file instead of a database?**

Content publishing is a manual action. You write something, you publish it, then you record it. A JSON file is fast to update and visible in your git history — every commit where you change a dot from `false` to `true` is a moment of progress.

If you want to make this dynamic later (pull real LinkedIn post metrics, blog view counts, etc.) you can migrate to a database table. But for now, simple is better.

---

## Done when

- [ ] `src/data/content.json` exists with all 6 projects listed
- [ ] ContentTracker component renders in the dashboard
- [ ] All published content is marked `true` with a URL where available
- [ ] Legend is visible and dots are hoverable
- [ ] The tracker is visible on the overview tab

---

## Next step

→ [P6-T7: Deploy Publicly](p6-t7-deploy-public.md) — get everything live on shailesh-pathak.com.
