# X-US: Cross-Cutting Setup — Week 1 Overview

> **User story goal:** By the end of Week 1, you have two systems running in parallel: a content system that turns every build session into publishable writing, and an AI briefing habit that makes every Claude Code session precise and targeted.

**Covers tasks:** X-T1, X-T2, X-T3, X-T4, X-T5
**Week:** 1
**Labels:** `user-story`, `content`, `learning`

---

## What "cross-cutting" means

Most of the work in this program is project-specific — P1, P2, P3, and so on. The X-series is different. These tasks cut across all six projects. They are infrastructure for how you work, not what you build.

You do these tasks once, in Week 1. Then you use the habits and tools they set up for the entire 14 weeks.

---

## The two systems you are building

Week 1 sets up exactly two systems:

```
┌─────────────────────────────────────────────────────────────────┐
│  SYSTEM 1: Content System (X-E1)                                │
│                                                                  │
│  Purpose: Turn every build session into content you can publish  │
│                                                                  │
│  X-T2 ── Create folder structure     content/build-logs/        │
│  X-T1 ── Build log template          content/blog-drafts/       │
│  X-T3 ── LinkedIn post template      content/linkedin/          │
│  X-T4 ── Blog platform live          content/instagram/         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  SYSTEM 2: CLAUDE.md Habit (X-E2)                               │
│                                                                  │
│  Purpose: Make every AI-assisted session precise and targeted    │
│                                                                  │
│  X-T5 ── Master CLAUDE.md template   CLAUDE.md (root)           │
│           Per-project copies          projects/XX/CLAUDE.md     │
└─────────────────────────────────────────────────────────────────┘
```

---

## How all five tasks connect

Here is the dependency order — do them in this sequence:

```
X-T2  ←  Start here. Creates the folders everything else lives in.
  │
  ▼
X-T1  ←  Creates the build log template inside content/build-logs/
  │
  ▼
X-T3  ←  Creates the LinkedIn template inside content/linkedin/
  │
  ▼
X-T4  ←  Sets up a live blog platform (external, not in the repo)
  │
  ▼
X-T5  ←  Creates the CLAUDE.md master template in the repo root
```

X-T2 must come first because X-T1 and X-T3 depend on the folders existing. X-T5 is independent of the content system and can be done in any order, but it fits naturally at the end as the final piece of Week 1 setup.

---

## What the end state looks like

When all five tasks are done, your repo looks like this:

```
ai-mastery/
├── CLAUDE.md                           ← X-T5: master AI briefing file
├── README.md
├── docs/
│   ├── x-e1-content-system.md
│   ├── x-e2-claude-md-template.md
│   ├── x-t1-build-log-template.md
│   ├── x-t2-content-folders.md
│   ├── x-t3-linkedin-template.md
│   ├── x-t4-blog-platform.md
│   ├── x-t5-claude-md-template.md
│   └── x-us-cross-cutting.md
└── content/
    ├── BUILD_LOG_TEMPLATE.md           ← X-T1: your session diary template
    ├── build-logs/
    │   └── 2026-04-06-setup.md         ← your first real build log
    ├── blog-drafts/                    ← X-T2: folder for blog posts
    ├── linkedin/
    │   └── POST_TEMPLATE.md            ← X-T3: LinkedIn post template
    └── instagram/                      ← X-T2: folder for carousel content

And externally:
  ✓ Blog live at https://dev.to/[yourhandle]  ← X-T4
  ✓ First post published
```

---

## Why you do all of this in Week 1

You do this in Week 1, before any project work, for three reasons:

**1. Front-load the friction.**
Setting up systems mid-project is painful. Doing it before the pressure of a deadline means you actually do it properly. By Week 2, you just use the systems.

**2. Capture from day one.**
Your Week 1 confusion is valuable content. People who are just starting out want to read about setting up an AI engineering program — not just the finished projects. If you start the build log in Week 3, you have lost the most relatable material.

**3. The CLAUDE.md habit requires practice.**
Writing a good CLAUDE.md is a skill. Your first one will be mediocre. By the time you write the one for P3, you will know exactly what to put in it. Starting in Week 1 gives you reps before the projects get complex.

---

## The weekly loop these systems enable

Once set up, the systems run on a loop every session for all 14 weeks:

```
┌──────────────────────────────────────────────────────────────┐
│  BEFORE the session                                          │
│                                                              │
│  1. Open projects/XX/CLAUDE.md                               │
│  2. Update "Current Task" to today's goal                    │
│  3. Open Claude Code                                         │
└──────────────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│  DURING the session                                          │
│                                                              │
│  Build. Debug. Learn. Note surprising things mentally.       │
└──────────────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│  AFTER the session (10 minutes — no exceptions)              │
│                                                              │
│  1. Copy BUILD_LOG_TEMPLATE.md to a new dated file           │
│  2. Fill in all six sections while memory is fresh           │
│  3. Draft a LinkedIn post outline (not the full post yet)    │
└──────────────────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│  END OF PROJECT (every 2-3 weeks)                            │
│                                                              │
│  1. Expand a build log into a full blog post draft           │
│  2. Polish the LinkedIn post draft and publish               │
│  3. Publish the blog post                                    │
│  4. Update CLAUDE.md with final architecture decisions       │
└──────────────────────────────────────────────────────────────┘
```

---

## What goes wrong if you skip these tasks

| Skipped task | What happens later |
|---|---|
| X-T1 (build log) | You have no raw material for content. You forget what you built. Your blog posts are vague. |
| X-T2 (folders) | Your content files are scattered. You can't find anything after Week 3. |
| X-T3 (LinkedIn template) | You stare at a blank page. Posts never get written. You stay invisible. |
| X-T4 (blog) | Your long-form writing has nowhere to live. You skip writing entirely. |
| X-T5 (CLAUDE.md) | Your AI sessions are generic and slow. You answer the same context questions every session. |

None of these are dramatic individual failures. Together, they add up to finishing 6 projects with no audience, no documentation, and no evidence of growth.

---

## Done when

- [ ] `content/` folder structure exists with all four subfolders (X-T2)
- [ ] `content/BUILD_LOG_TEMPLATE.md` exists and you have filled in at least one log (X-T1)
- [ ] `content/linkedin/POST_TEMPLATE.md` exists and you have one draft post (X-T3)
- [ ] Blog platform set up with first post published and URL saved (X-T4)
- [ ] `CLAUDE.md` exists in repo root with every section filled in (X-T5)
- [ ] You have used CLAUDE.md in at least one Claude Code session and noted the difference

---

## Next step

-> With all X-series setup complete, move to the first project: [P1-E1: PromptOS](p1-e1-promptos.md)
