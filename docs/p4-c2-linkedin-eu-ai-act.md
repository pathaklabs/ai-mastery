# P4-C2: LinkedIn — The EU AI Act is 144 pages. I Built an AI to Navigate It.

> **Goal:** Write a LinkedIn post that hooks with the EU AI Act angle, shows one real risk classification output, and drives traffic to the blog post and repo.

**Part of:** [P4-US3: Publish AIGA](p4-us3-content-publish.md)
**Week:** 8
**Labels:** `task`, `p4-aiga`, `content`

---

## What you are doing

Write and publish one LinkedIn post about AIGA. LinkedIn rewards posts that get engagement in the first hour — that means the hook must work immediately. Engineering managers and tech leads should stop scrolling at the first line.

The formula for this post:
1. Hook: a contrast that creates tension
2. Context: the real problem (EU AI Act compliance)
3. What you built: one clear sentence
4. The output: paste real risk classification result
5. Call to action: blog link + GitHub link

---

## Why LinkedIn for this one

AIGA's target audience is engineering managers, CTOs, and compliance leads. That audience is on LinkedIn. They are not on Twitter/X looking for dev content. The EU AI Act hook gives you a reason to be in their feed that is not self-promotional — it is genuinely useful information.

---

## Prerequisites

- [ ] Blog post (P4-C1) is live — you will link to it
- [ ] GitHub repo (P4-C4) is public
- [ ] Real risk classification output saved from P4-T3 testing

---

## Step-by-step instructions

### Step 1 — Run the risk classification for the post

The post must show real output. Run the same example you used in the blog:

```bash
cd projects/04-aiga
python -c "
from api.rag.query import load_index
from api.rag.risk_classifier import classify_risk

index = load_index()
result = classify_risk(
    'An AI system that screens job applications and ranks candidates.',
    index
)
print(f'Risk level: {result.risk_level}')
print(f'Reasoning: {result.reasoning[:200]}')
for ob in result.compliance_obligations[:3]:
    print(f'  Required: {ob}')
"
```

Take a screenshot of the AIGA UI showing this same result. You will attach it to the post.

---

### Step 2 — Write the post using this template

Copy and customise this draft. Do not change the structure — the structure is tested. Do change the specific details to match your real output.

---

**Draft LinkedIn post:**

```
The EU AI Act is 144 pages. Most engineering teams have not read it.

I have not read all of it either. But I built an AI that did.

AIGA is an open-source AI governance assistant I shipped this week.
You describe your AI system in plain English. It tells you:
- Which EU AI Act risk level you fall into
- Which articles apply
- Exactly what you must do before you can legally deploy

Here is a real example — I described a hiring algorithm:

"An AI that screens job applications and ranks candidates for interview."

AIGA returned:

  Risk level: HIGH RISK
  Articles: Article 6, Annex III paragraph 4
  
  Required before deployment:
  → Conduct conformity assessment (Article 43)
  → Register in the EU AI database (Article 71)
  → Implement human oversight (Article 14)
  → Maintain technical documentation for 10 years (Article 11)
  
  Penalty for non-compliance: up to €30 million or 6% of global turnover

That result took 12 seconds. On my homelab. No cloud API.

The stack: Python + LlamaIndex + ChromaDB + FastAPI + React.
Runs fully locally via podman compose.

If you are an engineering manager wondering what the EU AI Act means for
your team, this tool is for you.

Full write-up (how I built it, the architecture, what I learned):
[blog post URL]

GitHub repo (5-minute setup):
[github repo URL]

— — —

If this is useful, share it with a CTO or engineering manager who needs to
understand the EU AI Act. That is the whole point of building in public.

#euaiact #aigengineer #aigovernance #opensource #buildinpublic
```

---

### Step 3 — Format for LinkedIn

LinkedIn has quirks. Follow these rules:

**Line breaks:** LinkedIn ignores single line breaks. Use two line breaks (a blank line) between every paragraph. The draft above already does this.

**Character limit:** 3,000 characters. The draft is approximately 1,600 characters — comfortably within limit.

**The first line is everything:** LinkedIn shows only the first 1–2 lines before "see more." The first line of the draft is the hook. Do not change it.

**Hashtags:** Put them at the very end, after a `— — —` separator. LinkedIn's algorithm uses them but readers should not have to see a wall of hashtags mid-post.

**Image or no image:** Attach a screenshot of the AIGA UI showing the risk classification result. Posts with images get significantly more reach on LinkedIn. Use the screenshot from P4-T4.

---

### Step 4 — Post timing

Post at one of these times (these have the highest engagement rates for B2B/tech content on LinkedIn):
- Tuesday–Thursday, 8–9am (your local time)
- Tuesday–Thursday, 12–1pm

Avoid posting on Mondays (people are catching up) or Fridays (people are wrapping up).

---

### Step 5 — Engage in the first hour

After posting, spend 30 minutes engaging:
- Reply to every comment within the first hour (LinkedIn's algorithm rewards quick replies)
- Like reactions from people you recognise
- If someone asks a technical question, answer it thoroughly — this becomes a thread and increases reach

---

## Visual overview

```
LinkedIn post anatomy:

Line 1-2 (the hook — only this shows before "see more"):
  "The EU AI Act is 144 pages. Most engineering teams have not read it."

Line 3-5 (context):
  "I built AIGA — an open-source assistant that reads it for you."

The example (the proof):
  Input: "An AI that screens job applications..."
  Output: RISK LEVEL: HIGH RISK + obligations list

CTA (the ask):
  Blog link + GitHub link

Hashtags:
  #euaiact #aigengineer #aigovernance #opensource #buildinpublic

Attached image:
  Screenshot of the AIGA risk assessment UI
```

---

## Variations (if you want to test different hooks)

**Variation A (problem-first hook):**
```
Your hiring algorithm might be illegal in the EU starting August 2026.

That sounds alarmist. But the EU AI Act classifies hiring algorithms
as HIGH RISK systems — which means conformity assessment, EU database
registration, and human oversight before deployment.

Most teams have no idea this applies to them.

I built AIGA to change that. [...]
```

**Variation B (builder hook):**
```
Week 6 of building in public: I shipped AIGA.

Open-source AI governance assistant. RAG over the EU AI Act,
NIST AI RMF, and ISO 42001. Ask questions, get cited answers.
Classify your AI system's risk level in under a minute.

Here is the most interesting example I found while testing: [...]
```

Try different hooks and note which one gets more reach. This is a real experiment — your audience will tell you what resonates.

---

## Done when

- [ ] Post written and ready to copy into LinkedIn
- [ ] Screenshot of AIGA UI ready to attach
- [ ] Blog post URL and GitHub URL confirmed (tested, working)
- [ ] Post published at an optimal time (Tue–Thu, morning or midday)
- [ ] First-hour replies done

---

## Next step

→ [P4-C4: Publish GitHub repo with strong README](p4-c4-publish-repo.md)
