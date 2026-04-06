# P2-US4: Content — Publish P2 Learnings

> **Goal:** Turn everything you learned building the RAG system into public content: build logs, a LinkedIn post, a technical blog post, and an Instagram carousel.

**Part of:** [P2-E1: RAG Brain](p2-e1-rag-brain.md)
**Week:** 6
**Labels:** `user-story`, `p2-rag`, `content`

---

## The story

> As someone building in public, I want to document and share what I learned building a local RAG system — including the parts that broke — so that other developers can learn from my real experience, not a polished tutorial.

---

## Why this matters

The technical work is half of this program. The other half is building an audience that knows you can do this work. Publishing in public:

- Cements your own understanding (teaching forces clarity)
- Creates artifacts that show your skills (recruiters read blog posts)
- Helps the next person who tries to build a local RAG system

The rule: **write about failures too**. A post titled "I built a RAG system and it worked perfectly" is boring. "I built a RAG system and broke it 5 different ways" is worth reading.

---

## Content tasks in this story

| Task | Output | Format |
|------|--------|--------|
| [P2-C1](#p2-c1-build-logs) | 3 build logs during P2 | Markdown (private or public) |
| [P2-C2](#p2-c2-linkedin-post) | LinkedIn post | LinkedIn |
| [P2-C3](p2-c3-blog-rag-system.md) | Full technical blog post | Blog (dev.to, personal site, Hashnode) |
| [P2-C4](#p2-c4-instagram-carousel) | Instagram carousel | Instagram / image slides |

---

## P2-C1: Build Logs

Write 3 build logs using the build log template during weeks 3–6. Write them DURING the work, not after.

**When to write each:**

| Log | When | Topic |
|-----|------|-------|
| Build Log 1 | End of Week 3 | Setting up the stack + first ingestion |
| Build Log 2 | End of Week 4 | Chunking experiment results + embedding model |
| Build Log 3 | End of Week 5 or 6 | Search, reranking, UI, and hallucination rate |

**What to include in each log:**

```
## What I built this week
[2-3 sentences, concrete. "I built X that does Y."]

## What I learned
[What surprised you. Be specific.]

## What broke
[What did not work on the first try. What the error was. How you fixed it.]

## Numbers
[Chunking experiment scores, hallucination detection rate, query latency]

## What I am doing next
[1-2 sentence plan for next week]
```

---

## P2-C2: LinkedIn Post

**Title concept:** "RAG explained from someone who broke it 5 times"

**Hook options (pick one):**
- "I spent 4 weeks building a RAG system. Here is what nobody tells you about chunking."
- "My AI couldn't find my own Home Assistant automations. Here's what I had to fix."
- "I asked my homelab AI 'which workflow sends Telegram alerts?' It said 'I don't know' for 2 weeks. Here's how I fixed it."

**Structure:**

```
[Hook — 1-2 sentences]

What I built:
- Local RAG system over my own homelab files
- HA YAML, n8n workflows, markdown notes
- Runs entirely on my homelab. No cloud API.

3 things I didn't expect:
1. Chunking matters more than the LLM model
   (Strategy C beat Strategy A by X points in my experiment)
2. Vector similarity ≠ relevance
   (Added reranking and immediately improved recall)
3. Hallucinations are measurable
   (My system flags X% of answers as unsupported)

If you're building a RAG system, test your chunking strategy
before you touch the LLM. I promise it matters more.

→ Full write-up in bio link.

#RAG #AIEngineering #HomeAutomation #BuildInPublic #LocalAI #Homelab
```

**Format tips:**
- Keep it to under 300 words
- Add line breaks liberally (LinkedIn wraps everything)
- Include a screenshot of the chat UI with a real answer + sources visible
- Post on a Tuesday or Wednesday morning

---

## P2-C4: Instagram Carousel

**Title:** "What is RAG? (I built one on my homelab)"

**Slide structure:**

```
Slide 1 (Cover):
  "I built an AI that answers questions
   from MY OWN files.
   Here's what RAG is (real example)"
  [screenshot of chat UI]

Slide 2:
  "Without RAG:"
  You: "Which automation controls my hallway light?"
  AI: "I don't have access to your files."

  "With RAG:"
  You: "Which automation controls my hallway light?"
  AI: "The Hallway Motion Light automation..."
       Source: automations.yaml ✓

Slide 3:
  "How it works:"
  1. Your files → chunks → numbers (embeddings)
  2. Question → numbers
  3. Find similar numbers → relevant chunks
  4. Feed chunks to AI → answer with citations

  [simple diagram]

Slide 4:
  "The part nobody talks about:"
  Chunking strategy = 70% of retrieval quality

  Strategy A: 4/10 correct
  Strategy B: 7/10 correct
  Strategy C: 9/10 correct

  (same documents, same AI, different split)

Slide 5:
  "I also added hallucination detection:"
  After every answer, a second AI call asks:
  "Is this answer supported by the sources?"

  My system flags X% of answers as possibly wrong.
  That's my RAG quality baseline.

Slide 6 (CTA):
  "Full build log + blog post in bio.
   All local. No cloud API.
   Running on my homelab."
  [photo of homelab if you have one]
```

**Visual style tips:**
- Dark background (matches your homelab / terminal aesthetic)
- Code snippet screenshots for the technical slides
- Real numbers from your experiment (not placeholders)

---

## Done when

- [ ] P2-C1: 3 build logs written (one per "wave" of work)
- [ ] P2-C2: LinkedIn post published — includes your chunking experiment score and hallucination rate
- [ ] P2-C3: Blog post published — see [p2-c3-blog-rag-system.md](p2-c3-blog-rag-system.md)
- [ ] P2-C4: Instagram carousel posted — 6 slides, real screenshots
- [ ] All content links saved somewhere (blog URL, LinkedIn post URL)

---

## Start here

→ Write [Build Log 1](../x-t1-build-log-template.md) at the end of Week 3
→ Write [P2-C3 blog post](p2-c3-blog-rag-system.md) at the end of Week 6
