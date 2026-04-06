# X-E1: Content System Setup

> **Epic goal:** Set up the system you will use to document your learning and publish it — starting on Day 1, running for the entire 14 weeks.

**Week:** 1 (then ongoing forever)
**Labels:** `epic`, `content`

---

## Why this matters

You are building 6 real AI projects. If you don't document and publish as you go, you end up with 6 projects and 0 audience.

The content system turns every build session into:
- a build log (for you)
- a LinkedIn post (for your network)
- a blog post (for Google search)
- an Instagram carousel (for visual learners)

```
You build something
        │
        ▼
  Fill build log (10 min)
        │
        ▼
  Draft LinkedIn post
        │
        ▼
  Expand into blog
        │
        ▼
  Condense into Instagram
```

---

## What you will create

| Task | File | Purpose |
|------|------|---------|
| X-T1 | `content/BUILD_LOG_TEMPLATE.md` | Your personal session diary |
| X-T2 | Folder structure | Organised home for all content |
| X-T3 | `content/linkedin/POST_TEMPLATE.md` | Repeatable LinkedIn format |
| X-T4 | Blog platform | Where your long-form lives |

---

## Step-by-step instructions

### Step 1 — Create the content folder structure

Open your terminal in the `ai-mastery` project folder and run:

```bash
mkdir -p content/build-logs
mkdir -p content/blog-drafts
mkdir -p content/linkedin
mkdir -p content/instagram
```

Your folder will look like this:

```
ai-mastery/
└── content/
    ├── build-logs/       ← one file per session
    ├── blog-drafts/      ← blog posts before publishing
    ├── linkedin/         ← LinkedIn post drafts
    └── instagram/        ← carousel slide notes
```

---

### Step 2 — Create BUILD_LOG_TEMPLATE.md

Create the file `content/BUILD_LOG_TEMPLATE.md` with this content:

```markdown
# Build Log — [Date]

**Project:** [e.g. P1 PromptOS]
**Session duration:** [e.g. 2 hours]

## What I tried
-

## What broke
-

## What I learned
-

## What surprised me
-

## Next session plan
-
```

**Rule:** Fill this within 10 minutes of ending every single session. No exceptions.

> **Why 10 minutes?** After 30 minutes your brain starts to lose the details. The friction and confusion you felt — that is the most valuable content. Capture it while it is fresh.

---

### Step 3 — Create LinkedIn POST_TEMPLATE.md

Create the file `content/linkedin/POST_TEMPLATE.md`:

```markdown
# LinkedIn Post — [Topic] — [Date]

## Hook (1-2 lines)
Make someone stop scrolling. Use: a surprising fact, a failure, or a bold claim.

## The Problem (2-3 lines)
What was broken or confusing before?

## What I Tried (bullets)
- Attempt 1
- Attempt 2

## What Actually Worked
One clear answer.

## The Insight (1 punchy line)
The thing you wish someone had told you before you started.

## CTA (question to drive comments)
Ask the reader something. Gets comments. Gets reach.

## Hashtags
#AIEngineering #BuildInPublic #PathakLabs
```

---

### Step 4 — Set up your blog

Choose one. Set it up now. You can always move later — just pick something:

| Option | Effort | Best for |
|--------|--------|---------|
| Medium | Very low | Getting started fast |
| Dev.to | Low | Developer audience |
| Personal site (shailesh-pathak.com) | Medium | Portfolio, SEO |

Create an account. Write one test post ("Hello, I'm starting a 14-week AI build challenge"). Publish it. That is X-T4 done.

---

## Content publishing schedule

Use this table to track what you have published per project:

| Project | Build Logs | LinkedIn | Blog | Instagram |
|---------|-----------|----------|------|-----------|
| P1 | 3 logs | 1 post | 1 post | 1 carousel |
| P2 | 3 logs | 1 post | 1 post | 1 carousel |
| P3 | 5 logs | 1 post | 1 post | 1 carousel |
| P4 | — | 1 post | 1 post | 1 carousel |
| P5 | — | 1 post | 1 post | — |
| P6 | — | 6 posts | 1 post | 1 reel |

---

## Done when

- [ ] `content/` folder structure created
- [ ] `BUILD_LOG_TEMPLATE.md` exists and you have used it once
- [ ] `linkedin/POST_TEMPLATE.md` exists
- [ ] Blog platform set up and first post published
