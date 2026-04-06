# P3-T2: Set Up API Keys in n8n

> **Goal:** Add credentials for Tavily, Gemini, Claude, and DeepSeek to n8n so all agents can use them securely.

**Part of:** [P3-US1: Document and Design the Full Pipeline](p3-us1-pipeline-architecture.md)
**Week:** 4
**Labels:** `task`, `p3-pipeline`

---

## What you are doing

You are adding API keys to n8n's credential store. This is n8n's secure vault — once you save a key here, your workflow nodes can use it by name without ever seeing the raw key value.

**n8n concept:** Credentials are stored encrypted. When a node uses a credential, n8n injects the value at runtime. You never paste keys into node configuration fields.

```
┌─────────────────────────────────────────────────┐
│  n8n Credentials Store (encrypted)               │
│                                                  │
│  "Tavily API"   → api_key: ●●●●●●●●●●●●●●●●●  │
│  "Gemini API"   → api_key: ●●●●●●●●●●●●●●●●●  │
│  "Claude API"   → api_key: ●●●●●●●●●●●●●●●●●  │
│  "DeepSeek API" → api_key: ●●●●●●●●●●●●●●●●●  │
└─────────────────────────────────────────────────┘
          │
          │ referenced by name in nodes
          ▼
  [HTTP Request node] → uses "Tavily API" credential
  [Message a Model]   → uses "Claude API" credential
```

---

## Why this step matters

Without credentials, none of your agents can make API calls. You need all four services:

| Service | Used by agent | What it does |
|---------|--------------|--------------|
| Tavily | Search | Web search API — finds real articles |
| Gemini | Validator | Scores articles for credibility/relevance |
| Claude | Synthesizer | Writes the final LinkedIn post |
| DeepSeek | Optional fallback | Cheaper alternative for extraction tasks |

---

## Prerequisites

- [ ] n8n is running on your homelab and accessible in your browser
- [ ] You have accounts on all four platforms listed below
- [ ] You have [P3-T1](p3-t1-agent-contracts.md) complete (contracts written)

---

## Step-by-step instructions

### Step 1 — Get your API keys

Get a key from each of these services. Keep each key in a temporary text file (you will delete this after pasting into n8n).

**Tavily** — Web search API
- URL: [tavily.com](https://tavily.com)
- Sign up → Dashboard → API Keys → Create New Key
- Key looks like: `tvly-xxxxxxxxxxxxxxxxxxxxxxxx`
- Free tier: 1,000 searches/month

**Gemini** — Google's LLM
- URL: [aistudio.google.com](https://aistudio.google.com)
- Sign in with Google → Get API Key → Create API key in new project
- Key looks like: `AIzaSy...`
- Free tier: generous for development use

**Claude (Anthropic)** — Used for Synthesizer
- URL: [console.anthropic.com](https://console.anthropic.com)
- Sign up → API Keys → Create Key
- Key looks like: `sk-ant-...`
- Requires adding credit card (pay-as-you-go)

**DeepSeek** — Cheap LLM, OpenAI-compatible
- URL: [platform.deepseek.com](https://platform.deepseek.com)
- Sign up → API Keys → Create new API key
- Key looks like: `sk-...`
- Very cheap: ~$0.14 per million tokens

---

### Step 2 — Add Tavily credential to n8n

Tavily uses HTTP Header authentication (you pass the key as a request header).

1. In n8n, click **Settings** (gear icon, bottom left)
2. Click **Credentials**
3. Click **Add credential** (top right)
4. Search for: `Header Auth`
5. Fill in:
   - **Name:** `Tavily API`
   - **Name (header name):** `Authorization`
   - **Value:** `Bearer tvly-your-key-here`
6. Click **Save**

```
Settings → Credentials → Add credential → Header Auth

  Credential name:  Tavily API
  Header Name:      Authorization
  Header Value:     Bearer tvly-xxxxxxxxxxxxxxxxxxxxxxxx
```

---

### Step 3 — Add Gemini credential to n8n

1. In Credentials, click **Add credential**
2. Search for: `Google Gemini`
   - If not found, search for `Google AI` or use `Header Auth`
3. Fill in:
   - **Name:** `Gemini API`
   - **API Key:** paste your Gemini key
4. Click **Save**

If n8n does not have a native Gemini credential type, use Header Auth:
```
  Credential name:  Gemini API
  Header Name:      x-goog-api-key
  Header Value:     AIzaSy-your-key-here
```

---

### Step 4 — Add Claude credential to n8n

1. In Credentials, click **Add credential**
2. Search for: `Anthropic`
3. Fill in:
   - **Name:** `Claude API`
   - **API Key:** paste your Anthropic key
4. Click **Save**

n8n has a native Anthropic credential type. Use it.

---

### Step 5 — Add DeepSeek credential to n8n

DeepSeek uses the OpenAI API format, so use the OpenAI credential type with a custom base URL.

1. In Credentials, click **Add credential**
2. Search for: `OpenAI`
3. Fill in:
   - **Name:** `DeepSeek API`
   - **API Key:** paste your DeepSeek key
   - **Base URL:** `https://api.deepseek.com`
4. Click **Save**

---

### Step 6 — Verify all credentials are saved

Go to **Settings → Credentials** and confirm you see all four:

```
┌──────────────────────────────────────────┐
│  n8n Credentials                          │
│                                           │
│  ✓ Tavily API          Header Auth        │
│  ✓ Gemini API          Google AI / Header │
│  ✓ Claude API          Anthropic          │
│  ✓ DeepSeek API        OpenAI             │
└──────────────────────────────────────────┘
```

---

### Step 7 — Test each credential (optional but recommended)

For Tavily, create a quick test:
1. Create a new workflow (temporary)
2. Add an **HTTP Request** node
3. Set URL to `https://api.tavily.com/search`
4. Set Method to `POST`
5. Under Authentication, select **Header Auth** → choose `Tavily API`
6. Add body: `{"query": "test", "max_results": 1}`
7. Run node — you should get a search result back

Delete this test workflow when done.

---

## Visual overview

```
You                  API Providers
│                         │
│  Get keys from:         │
│  - tavily.com           │
│  - aistudio.google.com  │
│  - console.anthropic.com│
│  - platform.deepseek.com│
│                         │
▼                         ▼
┌─────────────────────────────────┐
│  n8n → Settings → Credentials   │
│                                 │
│  [Add] Tavily API               │
│  [Add] Gemini API               │
│  [Add] Claude API               │
│  [Add] DeepSeek API             │
└─────────────────────────────────┘
         │
         │ Referenced safely in nodes
         ▼
   Pipeline nodes use credentials
   without ever exposing raw keys
```

---

## Security note

Never:
- Paste API keys directly into a node's URL or body field
- Commit API keys to git
- Share screenshots that show API keys

n8n's credential store encrypts keys at rest. Using it is the right way.

---

## Done when

- [ ] Tavily API credential saved in n8n
- [ ] Gemini API credential saved in n8n
- [ ] Claude API credential saved in n8n
- [ ] DeepSeek API credential saved in n8n
- [ ] At least one credential tested with a real API call
- [ ] No raw API keys pasted anywhere in workflow nodes

---

## Next step

→ [P3-T3: Create n8n Workflow Skeleton](p3-t3-workflow-skeleton.md)
