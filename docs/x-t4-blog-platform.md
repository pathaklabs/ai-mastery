# X-T4: Set Up Medium or Personal Blog

> **Goal:** Pick one blog platform, create an account (or repo), and publish a single test post — so you have a real place to publish your long-form learning.

**Part of:** [X-E1: Content System Setup](x-e1-content-system.md)
**Week:** 1
**Labels:** `task`, `content`

---

## What you are doing

You are choosing one blog platform and publishing your first post on it. The post does not have to be good — it just has to exist. The purpose of this task is to eliminate the setup friction before you are in the middle of a project and thinking about writing.

By the end of this task you will have a live URL where your writing lives. Every blog post you write for the next 14 weeks goes here.

---

## Why this matters

LinkedIn posts drive engagement but disappear in 24 hours. Blog posts are searchable forever. A developer who Googles "how to build a RAG system" in 2027 could find your post from this program. One good blog post can bring more traffic than dozens of LinkedIn posts. Setting up the platform now means you write the first real post during a project — not during setup.

---

## Prerequisites

Before starting this task, make sure:
- [ ] You have decided on a public name or handle (e.g. `shailesh-pathak`, `PathakLabs`)
- [ ] You have 30-45 minutes to set up the platform and write a short first post

---

## Step-by-step instructions

### Step 1 — Pick your platform

Compare the three main options:

| Platform | Setup time | Best audience | SEO | Your control |
|---|---|---|---|---|
| **Medium** | 5 minutes | General / business | Medium | Low |
| **Dev.to** | 5 minutes | Developers | Good | Low |
| **Personal site** | 2-4 hours | Anyone | Best | Full |

**Recommendation for Week 1:** Start with **Dev.to** or **Medium**. Both take under 5 minutes to set up and let you start writing immediately. You can always move to a personal site later.

> **If you already have a personal site:** skip straight to Step 3. Just make sure there is a blog section where you can publish posts.

---

### Step 2 — Create your account

#### Option A: Dev.to

1. Go to [dev.to](https://dev.to)
2. Click **Create account**
3. Sign in with GitHub (fastest — no new password needed)
4. Go to **Settings** → fill in your name, bio, and a profile photo
5. Set your username to something consistent with your GitHub handle

#### Option B: Medium

1. Go to [medium.com](https://medium.com)
2. Click **Get started**
3. Sign in with Google or create an email account
4. Go to your profile → **Edit profile** → fill in your name and bio
5. Consider creating a **Publication** called "PathakLabs" for a cleaner URL

---

### Step 3 — Configure your profile

Wherever you set up, fill in these fields before publishing anything:

```
Name:        Shailesh Pathak
Bio:         Building 6 AI projects in 14 weeks — documenting everything.
             AI Engineer | PathakLabs | Build in public
Website:     [your GitHub or personal site]
Photo:       A real headshot (not a logo — people connect with faces)
```

A complete profile builds trust with readers who find your posts via search.

---

### Step 4 — Write and publish your first post

This post does not need to be polished. Its purpose is to verify that you can publish and to introduce yourself to anyone who finds your blog.

**Title:** `I'm building 6 AI projects in 14 weeks — here's what I'm doing`

**Content to include (bullet form is fine):**

- Who you are and what you do
- What this 14-week program is (briefly)
- The 6 projects you will build (one line each)
- Why you are doing it publicly
- An invitation: "Follow along — I'll post after every project"

**Keep it under 300 words for this first post.** The goal is just to hit publish.

---

### Step 5 — Save your blog URL

Once published, copy your blog URL and add it to your main `README.md`:

```bash
# Open the README and add a line like:
# Blog: https://dev.to/shaileshpathak
```

Also add it to your `CLAUDE.md` under `## Project Context` so Claude knows about it.

---

### Step 6 — Set up your blog-drafts folder workflow

Every blog post you write will follow this path:

```
Build session ends
       │
       ▼
Fill build log (10 min)  ← X-T1
       │
       ▼
Draft in content/blog-drafts/  ← write here first
       │
       ▼
Edit and polish
       │
       ▼
Copy-paste into blog platform and publish
       │
       ▼
Save the published URL in the draft file
```

Create a naming convention for your drafts now:

```bash
# Example file names:
content/blog-drafts/2026-04-20-p1-promptos-what-i-learned.md
content/blog-drafts/2026-05-04-p2-rag-brain-chunking-strategies.md
```

---

## Visual overview

```
Week 1                         Week 2-14
──────                         ─────────
Set up blog platform           Build sessions
        │                            │
        ▼                            ▼
First test post live          Fill build log
        │                            │
        ▼                            ▼
Blog URL saved                Draft blog post locally
                                     │
                                     ▼
                              Publish on platform
                                     │
                                     ▼
                              Share URL on LinkedIn
```

---

## Learning checkpoint

> Write your answer to this question BEFORE moving on: Why does publishing in public — even imperfect writing — make you a better engineer?

Write your answer in your build log.

---

## Done when

- [ ] Blog platform chosen and account created
- [ ] Profile is complete (name, bio, photo)
- [ ] First post published with a live URL
- [ ] Blog URL is saved in your `README.md`
- [ ] You understand the draft-to-publish workflow

---

## Next step

-> After this task, continue with [X-T5: Create master CLAUDE.md template](x-t5-claude-md-template.md)
