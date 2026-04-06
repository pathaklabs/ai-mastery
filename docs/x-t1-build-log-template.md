# X-T1: Create BUILD_LOG_TEMPLATE.md

> **Goal:** Create a reusable session diary template so you capture what you built, what broke, and what you learned — within 10 minutes of every session.

**Part of:** [X-E1: Content System Setup](x-e1-content-system.md)
**Week:** 1
**Labels:** `task`, `content`

---

## What you are doing

You are creating a single markdown file called `BUILD_LOG_TEMPLATE.md` inside a `content/` folder. Every time you finish a coding session, you copy this template, fill it in, and save it as a new file with the date. Think of it like a lab notebook — scientists fill one in after every experiment, and so will you.

The template has six short sections. None of them should take more than a couple of minutes to fill out.

---

## Why this matters

Memory fades fast. The specific error you hit, the workaround you discovered, the thing that surprised you — those details disappear within hours. A build log locks them in. Over 14 weeks, your build logs become the raw material for your LinkedIn posts, blog articles, and proof of growth. Without logs, you cannot write content and you cannot track progress.

---

## Prerequisites

Before starting this task, make sure:
- [ ] You have the `ai-mastery` repository cloned on your machine
- [ ] You can open a terminal in the project root folder
- [ ] [X-T2: Content folder structure](x-t2-content-folders.md) is complete (the `content/` folder must exist first)

> **Note:** X-T2 and X-T1 can technically be done in the same sitting. If you have not done X-T2 yet, do it first — it takes 2 minutes.

---

## Step-by-step instructions

### Step 1 — Open a terminal in your project root

Open your terminal application and navigate to the `ai-mastery` folder:

```bash
cd ~/GitHub/ai-mastery
```

Confirm you are in the right place by running:

```bash
ls
```

You should see folders like `docs/`, `content/`, and files like `README.md`.

---

### Step 2 — Create the template file

Run this command to create the file:

```bash
touch content/BUILD_LOG_TEMPLATE.md
```

Now open it in your editor. If you use VS Code:

```bash
code content/BUILD_LOG_TEMPLATE.md
```

---

### Step 3 — Paste in the template content

Copy and paste the following into `content/BUILD_LOG_TEMPLATE.md` exactly as written:

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

Save the file.

---

### Step 4 — Understand what each section is for

Here is what to write in each section so you never stare at a blank page:

| Section | Write... | Example |
|---|---|---|
| **What I tried** | Every approach you attempted | "Tried using LangChain's RetrievalQA chain" |
| **What broke** | Error messages, wrong outputs, dead ends | "Got a 422 validation error from FastAPI" |
| **What I learned** | Facts, concepts, or patterns you now understand | "Learned that Pydantic validates on assignment by default" |
| **What surprised me** | Anything unexpected — good or bad | "The model hallucinated a function name that doesn't exist" |
| **Next session plan** | First thing you will do in the next session | "Fix the embedding dimension mismatch in ChromaDB" |

---

### Step 5 — Use the template for the first time (right now)

Do not wait. Fill in a build log for this session — setting up the content system IS a session.

Copy the template to a new file:

```bash
cp content/BUILD_LOG_TEMPLATE.md content/build-logs/2026-04-06-setup.md
```

Replace `2026-04-06` with today's date. Open the new file and fill it in. Even two bullet points per section is enough.

---

## Visual overview

```
ai-mastery/
└── content/
    ├── BUILD_LOG_TEMPLATE.md   ← the blank template (never edit this)
    └── build-logs/
        ├── 2026-04-06-setup.md     ← session 1 (copy of template, filled in)
        ├── 2026-04-07-p1-start.md  ← session 2
        └── 2026-04-10-p1-rag.md    ← session 3
        ...

Each session = one new file. The template stays clean.
```

---

## Learning checkpoint

> Write your answer to this question BEFORE moving on: What was the last thing you built or learned in a side project that you have already forgotten the details of? How would a build log have helped?

Write your answer in your first build log under "What I learned."

---

## Done when

- [ ] `content/BUILD_LOG_TEMPLATE.md` exists and contains all six sections
- [ ] `content/build-logs/` folder exists (created in X-T2)
- [ ] You have created at least one real build log file by copying the template and filling it in

---

## Next step

-> After this task, continue with [X-T2: Set up content folder structure](x-t2-content-folders.md) (if not done yet), then [X-T3: Create LinkedIn post template](x-t3-linkedin-template.md)
