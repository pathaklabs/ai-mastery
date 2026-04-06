# P4-C1: Blog — How I Built an Open-Source AI Governance Assistant

> **Goal:** Write the highest-impact blog post of the entire 6-project program. Target audience: engineering managers, CTOs, and compliance leads in European tech who need to understand the EU AI Act.

**Part of:** [P4-US3: Publish AIGA](p4-us3-content-publish.md)
**Week:** 8
**Labels:** `task`, `p4-aiga`, `content`

---

## What you are doing

This is not a technical tutorial. It is a story about building something useful to solve a real problem — told to an audience of technical leaders who are under real regulatory pressure from the EU AI Act.

The blog post must do three things:
1. Explain the EU AI Act in plain English (so they feel you understand their problem)
2. Show how AIGA solves it (with real output — not mock data)
3. Give them a link to try it themselves

---

## Why this post is the highest-impact in the program

The EU AI Act affects every tech company operating in Europe. That is not a niche — it is the largest tech regulatory event since GDPR. Engineering managers and CTOs are actively looking for practical information and tools.

A blog post that:
- Explains a complex law clearly (credibility signal)
- Shows a working open-source tool (proof of skill)
- Invites them to try it (acquisition)

...will be shared by people who found it genuinely useful. That sharing is worth more than any amount of ads.

---

## Prerequisites

- [ ] AIGA is working and deployed
- [ ] At least 3 screenshots of the UI taken (from P4-T4)
- [ ] One real risk classification result ready to paste in (run `test_risk_classifier.py`)
- [ ] GitHub repo is public

---

## Step-by-step instructions

### Step 1 — Run your best risk classification example

Before writing a word, generate the output you will use in the blog. This should be a real example that is immediately relatable to engineering managers.

Good candidates:
- Hiring algorithm (almost every tech company uses one)
- Credit scoring (fintech readers)
- Customer service chatbot (universal)

Run this:

```bash
cd projects/04-aiga
python -c "
from api.rag.query import load_index
from api.rag.risk_classifier import classify_risk

index = load_index()
result = classify_risk(
    'An AI system that automatically screens job applications and ranks '
    'candidates based on their resume and video interview performance, '
    'which our HR team uses to decide who to invite to a live interview.',
    index
)
print('Risk level:', result.risk_level)
print('Reasoning:', result.reasoning)
print('Articles:', result.relevant_articles)
print()
print('Obligations:')
for ob in result.compliance_obligations:
    print(f'  - {ob}')
print()
print('Documentation required:')
for doc in result.documentation_required:
    print(f'  - {doc}')
"
```

Save the full output. This is the centrepiece of the blog post.

---

### Step 2 — Write the blog post

Here is the complete outline with draft copy for each section. Fill in your real output where indicated.

---

**Headline:**
> How I Built an Open-Source AI Governance Assistant (and Why Every Tech Team Needs One)

**Subheading:**
> The EU AI Act is 144 pages of dense legal text. I built an AI that reads it so you do not have to — and open-sourced it.

---

**Section 1: The problem (200 words)**

Draft:

> In August 2024, the EU AI Act became law. If your company builds or deploys AI systems in Europe, this law applies to you.
>
> The problem: the Act is 144 pages of legal text. It classifies AI systems into four risk tiers, each with different compliance obligations. Miss the right classification for your system and you are looking at fines of up to €30 million or 6% of global annual revenue.
>
> I asked a dozen engineering managers what they knew about the EU AI Act. The answers were mostly some version of: "I know it exists" and "our legal team is looking at it." Nobody actually knew which of their AI systems were High Risk. Nobody knew which of those required conformity assessments before deployment.
>
> This is the gap AIGA is built to close.

---

**Section 2: What the EU AI Act actually says (300 words)**

Explain the four risk levels in plain English. Use the table format below.

> Before describing how AIGA works, you need to understand the framework it is built on.
>
> The EU AI Act classifies every AI system into one of four risk levels:

| Risk Level | What it means | Examples | What you must do |
|------------|--------------|---------|-----------------|
| Unacceptable | Banned. Cannot be deployed in the EU. | Social credit scoring, real-time biometric surveillance in public spaces | Nothing — you cannot build these |
| High Risk | Permitted, but with strict requirements before deployment | Hiring algorithms, credit scoring, medical diagnosis AI, education scoring | Conformity assessment, EU database registration, human oversight, technical docs |
| Limited Risk | Permitted with transparency requirements | Customer service chatbots, deepfake generators | Disclose to users that they are interacting with AI |
| Minimal Risk | No obligations | Spam filters, AI in games, music recommendations | Nothing required |

> The law came into force in stages. The prohibition on Unacceptable Risk systems applied from February 2025. Requirements for High-Risk systems apply from August 2026.
>
> The critical question for any engineering team: **which risk level does our AI system fall into?** That question requires reading Annex III of the Act — a 7-page list of use cases that qualify as High Risk.

---

**Section 3: Introducing AIGA (200 words + screenshot)**

> This is the problem AIGA solves. It is an open-source RAG (Retrieval-Augmented Generation) assistant that has read the EU AI Act, NIST AI RMF, and ISO 42001 — and can answer questions about them in plain English, always citing the exact article.
>
> Here is what it looks like in practice:
>
> [INSERT SCREENSHOT: the chat interface with a cited answer]
>
> Every answer includes the exact article and a short quote from the source text. "The EU AI Act says X" without a citation is not accepted — AIGA always tells you where it came from.

---

**Section 4: The risk classification feature (400 words — the centrepiece)**

> The most useful feature is the risk classifier. You describe your AI system in plain English. AIGA runs a two-step prompt chain — first classifying the risk level, then looking up the specific compliance obligations — and returns a structured result.
>
> Here is a real example. I described a hiring algorithm like this:
>
> > "An AI system that automatically screens job applications and ranks candidates based on their resume and video interview performance, which our HR team uses to decide who to invite to a live interview."
>
> AIGA returned this:

```json
{
  "risk_level": "HIGH_RISK",
  "confidence": "HIGH",
  "reasoning": "This system falls under EU AI Act Article 6 and Annex III,
    paragraph 4, which explicitly lists AI systems 'intended to be used for
    recruitment or selection of natural persons, in particular for advertising
    vacancies, screening or filtering applications' as High-Risk AI systems.",
  "relevant_articles": [
    "Article 6 — Classification of high-risk AI systems",
    "Annex III, paragraph 4 — AI systems in employment context"
  ],
  "compliance_obligations": [
    "Conduct a conformity assessment before deployment (Article 43)",
    "Register the system in the EU AI database before deployment (Article 71)",
    "Implement a human oversight mechanism (Article 14)",
    "Maintain technical documentation for 10 years after deployment (Article 11)",
    "Provide transparency information to affected job applicants (Article 13)"
  ],
  "documentation_required": [
    "Technical documentation — model type, training data, performance metrics",
    "Risk management records — updated throughout system lifecycle",
    "Logs of system operation (Article 12)",
    "Conformity assessment report (Article 43)"
  ],
  "human_oversight_required": true,
  "timeline": "All requirements must be met before placing the system on the market",
  "penalty_if_non_compliant": "Up to €30 million or 6% of annual global turnover"
}
```

> That output was generated in about 12 seconds on my homelab. No cloud APIs — it runs entirely locally using Ollama and ChromaDB.
>
> [INSERT SCREENSHOT: the risk assessment UI showing this result]

---

**Section 5: How AIGA works (300 words + architecture diagram)**

> For the technically curious, here is the architecture.

```
Source documents                     ChromaDB
  EU AI Act (144 pages)              (vector store)
  NIST AI RMF (60 pages)   ingest    ┌──────────────────────┐
  ISO 42001 overview       ────────► │  chunk embeddings    │
  Model cards                        │  + article metadata  │
                                     └──────────┬───────────┘
                                                │
  User question                                 │ similarity search
       │                                        │ (top 5 chunks)
       ▼                                        ▼
  Embed question ──────────────────► retrieve relevant chunks
                                                │
                                                ▼
                                    Ollama llama3 (local)
                                    "Answer citing sources"
                                                │
                                                ▼
                                    Answer + cited articles
```

> The RAG pattern means AIGA cannot make things up — it can only answer from the documents it retrieved. If the EU AI Act does not say something, AIGA tells you it could not find that information in the governance documents.
>
> The risk classification is a two-step prompt chain: step one classifies the risk level, step two looks up the obligations for that level. Two focused steps are more reliable than one complex prompt.
>
> The entire stack runs on podman compose. No cloud required.

---

**Section 6: Try it yourself (100 words)**

> AIGA is fully open source and runs on any machine with Ollama installed.

```bash
git clone https://github.com/PathakLabs/aiga.git
cd aiga
./start.sh
# Open http://localhost:3000
```

> If you find it useful — or if you are using it in your team — I would love to hear about it. GitHub issues and stars help more people find the project.

---

**Section 7: What I learned (200 words)**

> A few things surprised me during this build:
>
> 1. **Legal documents are terrible for RAG.** PDFs export with page headers on every page, tables that extract as garbled text, and footnotes embedded mid-sentence. Cleaning the text was as important as building the RAG pipeline.
>
> 2. **Two-step chains beat one long prompt.** My first version was a single prompt asking for risk level and obligations together. The results were inconsistent. Splitting into two focused prompts doubled the accuracy.
>
> 3. **The EU AI Act is actually readable.** Once you understand the four-level structure, the rest follows logically. The complexity is in the Annex III list of use cases — 13 categories, each with sub-categories. That list is where most compliance questions live.
>
> AIGA is part of a larger 6-project AI engineering program I am documenting publicly at [link]. The full architecture and build logs are there.

---

### Step 3 — Publish checklist

Before hitting publish:

- [ ] Every section has been read aloud (catches awkward sentences)
- [ ] The real risk classification output is in the post (not mock data)
- [ ] At least 2 screenshots in the post
- [ ] Architecture diagram is in the post
- [ ] GitHub repo link appears at least twice
- [ ] Post is under 1,500 words (long enough to be useful, short enough to be read)
- [ ] Title and subheading are set correctly
- [ ] SEO meta description written (use the subheading)
- [ ] Posted to your blog, LinkedIn article, and dev.to

---

## Visual overview

```
Blog post structure:
  ┌────────────────────────────────────────────┐
  │ Headline + subheading                      │ ← hook in 2 lines
  ├────────────────────────────────────────────┤
  │ Section 1: The problem                     │ ← they recognise this
  ├────────────────────────────────────────────┤
  │ Section 2: EU AI Act explained             │ ← table of 4 risk levels
  ├────────────────────────────────────────────┤
  │ Section 3: Introducing AIGA               │ ← screenshot 1
  ├────────────────────────────────────────────┤
  │ Section 4: Risk classification example     │ ← real JSON output + screenshot 2
  ├────────────────────────────────────────────┤
  │ Section 5: How it works                    │ ← architecture diagram
  ├────────────────────────────────────────────┤
  │ Section 6: Try it yourself                 │ ← 3 lines of bash
  ├────────────────────────────────────────────┤
  │ Section 7: What I learned                  │ ← 3 honest observations
  └────────────────────────────────────────────┘
```

---

## Done when

- [ ] Blog post published and URL recorded in `projects/04-aiga/content/links.md`
- [ ] Real risk classification JSON output is in the post (run it yourself, paste the real output)
- [ ] Architecture diagram is in the post (ASCII is fine — copy from this doc)
- [ ] EU AI Act risk level table is in the post
- [ ] GitHub repo URL appears in the post
- [ ] Post shared on LinkedIn, dev.to, and any other platforms you use

---

## Next step

→ [P4-C2: LinkedIn post](p4-c2-linkedin-eu-ai-act.md)
