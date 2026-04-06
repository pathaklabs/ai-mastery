# X-T2: Set Up Content Folder Structure

> **Goal:** Create four folders inside `content/` that will organise every piece of writing, every post draft, and every build log for the next 14 weeks.

**Part of:** [X-E1: Content System Setup](x-e1-content-system.md)
**Week:** 1
**Labels:** `task`, `content`

---

## What you are doing

You are creating a simple folder structure inside your `ai-mastery` project. Think of it like setting up filing cabinets before you start a big project — one drawer for session notes, one for blog drafts, one for LinkedIn posts, one for Instagram content. You do this once in Week 1 and it stays useful for all 14 weeks.

The four folders are: `build-logs`, `blog-drafts`, `linkedin`, and `instagram`. Each one has a clear purpose and maps to a specific type of content you will produce.

---

## Why this matters

When content has no home, it ends up scattered — in random notes apps, in your Downloads folder, in a browser tab you forgot to close. A consistent folder structure means you always know where to look and where to save. It also makes it easy to count what you have published and what is still a draft.

---

## Prerequisites

Before starting this task, make sure:
- [ ] You have the `ai-mastery` repository cloned on your machine
- [ ] You can open a terminal and navigate to the project root

---

## Step-by-step instructions

### Step 1 — Open a terminal in your project root

```bash
cd ~/GitHub/ai-mastery
```

Verify you are in the right folder:

```bash
pwd
```

The output should end with `/ai-mastery`.

---

### Step 2 — Create all four folders in one command

Run the following commands one after the other (or all at once — both work):

```bash
mkdir -p content/build-logs
mkdir -p content/blog-drafts
mkdir -p content/linkedin
mkdir -p content/instagram
```

> **What does `-p` mean?** The `-p` flag tells `mkdir` to create any parent folders that do not exist yet. So if `content/` does not exist, it will be created automatically along with the subfolder. This prevents an error.

---

### Step 3 — Verify the folders were created

Run:

```bash
ls content/
```

You should see:

```
blog-drafts    build-logs    instagram    linkedin
```

If you see all four — you are done.

---

### Step 4 — Add a .gitkeep file to each folder (optional but recommended)

Git does not track empty folders. If you want these folders to appear when someone else clones your repo (or when you clone it fresh), add an empty `.gitkeep` file to each:

```bash
touch content/build-logs/.gitkeep
touch content/blog-drafts/.gitkeep
touch content/linkedin/.gitkeep
touch content/instagram/.gitkeep
```

> **What is .gitkeep?** It is a convention — just an empty file with a name that signals "this folder should exist." It has no special meaning to git or any tool; it is just a placeholder.

---

## Visual overview

```
ai-mastery/
└── content/
    │
    ├── build-logs/         ← one .md file per session
    │   └── .gitkeep
    │
    ├── blog-drafts/        ← blog posts before publishing
    │   └── .gitkeep
    │
    ├── linkedin/           ← LinkedIn post drafts
    │   └── .gitkeep
    │
    └── instagram/          ← carousel slide notes and scripts
        └── .gitkeep

Every project will generate files in these folders.
By Week 14 you will have dozens of files here.
```

---

## Learning checkpoint

> Write your answer to this question BEFORE moving on: What are the four types of content you will produce from each build session, and where does each one live?

Write the answer in your build log for this session.

---

## Done when

- [ ] `content/build-logs/` folder exists
- [ ] `content/blog-drafts/` folder exists
- [ ] `content/linkedin/` folder exists
- [ ] `content/instagram/` folder exists
- [ ] Running `ls content/` shows all four folders

---

## Next step

-> After this task, continue with [X-T1: Create BUILD_LOG_TEMPLATE.md](x-t1-build-log-template.md)
