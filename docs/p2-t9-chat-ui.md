# P2-T9: Build Simple Chat UI

> **Goal:** Build a browser-based chat interface that sends questions to your RAG API, shows answers, and displays source citations below each answer — so you can actually use the system you built.

**Part of:** [P2-US1: Personal RAG System](p2-us1-personal-rag.md)
**Week:** 5
**Labels:** `task`, `p2-rag`

---

## What you are doing

Your API is working. Now you need a way to use it without typing `curl` commands. You will build a simple single-page HTML interface that:

- Shows a chat-style conversation
- Displays source citations as collapsible sections below each answer
- Keeps a query history in the sidebar so you can refer back to previous questions

This is intentionally simple — one HTML file, no build step, no framework. It runs entirely in your browser and talks to the FastAPI endpoint you built in P2-T8.

---

## Why this step matters

A working UI makes the system real. It also exposes usability issues you cannot see from API responses alone: Is the answer too long? Are the sources confusing? Does "I don't know" look clear? You will discover these things only by using it.

---

## Prerequisites

- [ ] [P2-T8](p2-t8-query-endpoint.md) complete — `POST /query` endpoint working
- [ ] API running at `http://localhost:8000` (or your homelab IP)

---

## Step-by-step instructions

### Step 1 — Create the chat UI file

Create `~/projects/rag-brain/static/index.html`:

```bash
mkdir -p ~/projects/rag-brain/static
```

Create `~/projects/rag-brain/static/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>RAG Brain — PathakLabs</title>
  <style>
    /* ─── Reset and base ───────────────────────────────────────────────── */
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #0f1117;
      color: #e0e0e0;
      height: 100vh;
      display: flex;
      overflow: hidden;
    }

    /* ─── Sidebar (query history) ──────────────────────────────────────── */
    #sidebar {
      width: 260px;
      min-width: 260px;
      background: #1a1d27;
      border-right: 1px solid #2a2d3a;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    #sidebar-header {
      padding: 20px 16px 12px;
      font-size: 13px;
      font-weight: 600;
      color: #7c7f93;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 1px solid #2a2d3a;
    }
    #history-list {
      flex: 1;
      overflow-y: auto;
      padding: 8px;
    }
    .history-item {
      padding: 10px 12px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 13px;
      color: #9ea3b8;
      line-height: 1.4;
      border: 1px solid transparent;
      margin-bottom: 4px;
      transition: background 0.15s;
    }
    .history-item:hover {
      background: #22263a;
      color: #c9cde0;
    }
    .history-item.active {
      background: #1e3a5f;
      color: #60a5fa;
      border-color: #1d4ed8;
    }
    #sidebar-footer {
      padding: 12px 16px;
      border-top: 1px solid #2a2d3a;
      font-size: 11px;
      color: #3a3d50;
    }

    /* ─── Main content ─────────────────────────────────────────────────── */
    #main {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    /* Header */
    #header {
      padding: 16px 24px;
      border-bottom: 1px solid #2a2d3a;
      display: flex;
      align-items: center;
      gap: 12px;
      background: #13161f;
    }
    #header h1 {
      font-size: 18px;
      font-weight: 600;
      color: #60a5fa;
    }
    #header .subtitle {
      font-size: 13px;
      color: #4a4d60;
      margin-left: auto;
    }

    /* Chat area */
    #chat-area {
      flex: 1;
      overflow-y: auto;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }

    /* Empty state */
    #empty-state {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
      color: #3a3d50;
    }
    #empty-state .icon { font-size: 40px; }
    #empty-state .label { font-size: 16px; color: #4a4d60; }
    #example-questions { display: flex; flex-direction: column; gap: 8px; }
    .example-q {
      padding: 10px 16px;
      background: #1a1d27;
      border: 1px solid #2a2d3a;
      border-radius: 8px;
      font-size: 13px;
      color: #6a6d80;
      cursor: pointer;
      transition: border-color 0.15s, color 0.15s;
    }
    .example-q:hover {
      border-color: #3b5998;
      color: #9ea3b8;
    }

    /* Message bubbles */
    .message {
      display: flex;
      flex-direction: column;
      gap: 8px;
      max-width: 780px;
    }
    .message.user { align-self: flex-end; align-items: flex-end; }
    .message.assistant { align-self: flex-start; }

    .bubble {
      padding: 12px 16px;
      border-radius: 10px;
      line-height: 1.6;
      font-size: 14px;
    }
    .user .bubble {
      background: #1e3a5f;
      color: #c0d8f8;
      border: 1px solid #1d4ed8;
    }
    .assistant .bubble {
      background: #1a1d27;
      color: #d0d3e8;
      border: 1px solid #2a2d3a;
    }

    /* Sources section */
    .sources-section {
      margin-top: 4px;
    }
    .sources-toggle {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      cursor: pointer;
      font-size: 12px;
      color: #4a90d9;
      padding: 4px 8px;
      border-radius: 4px;
      border: 1px solid #1d4ed8;
      background: transparent;
      transition: background 0.15s;
    }
    .sources-toggle:hover { background: #1a2d4a; }
    .sources-toggle .arrow { transition: transform 0.2s; display: inline-block; }
    .sources-toggle.open .arrow { transform: rotate(90deg); }

    .sources-list {
      display: none;
      flex-direction: column;
      gap: 8px;
      margin-top: 8px;
    }
    .sources-list.open { display: flex; }

    .source-card {
      background: #13161f;
      border: 1px solid #2a2d3a;
      border-radius: 6px;
      padding: 10px 14px;
      font-size: 12px;
    }
    .source-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 6px;
    }
    .source-file {
      color: #60a5fa;
      font-weight: 500;
      font-family: monospace;
    }
    .source-score {
      color: #4a4d60;
      font-size: 11px;
    }
    .source-score.high { color: #22c55e; }
    .source-score.medium { color: #eab308; }
    .source-score.low { color: #ef4444; }
    .source-excerpt {
      color: #5a5d70;
      line-height: 1.5;
      white-space: pre-wrap;
      font-family: monospace;
      font-size: 11px;
    }

    /* Loading indicator */
    .loading {
      display: flex;
      align-items: center;
      gap: 8px;
      color: #4a4d60;
      font-size: 13px;
    }
    .dots span {
      display: inline-block;
      width: 5px;
      height: 5px;
      border-radius: 50%;
      background: #4a4d60;
      animation: bounce 1.2s ease infinite;
    }
    .dots span:nth-child(2) { animation-delay: 0.2s; }
    .dots span:nth-child(3) { animation-delay: 0.4s; }
    @keyframes bounce {
      0%, 80%, 100% { transform: translateY(0); }
      40% { transform: translateY(-6px); }
    }

    /* Input area */
    #input-area {
      padding: 16px 24px;
      border-top: 1px solid #2a2d3a;
      background: #13161f;
      display: flex;
      gap: 10px;
      align-items: flex-end;
    }
    #question-input {
      flex: 1;
      background: #1a1d27;
      border: 1px solid #2a2d3a;
      border-radius: 8px;
      padding: 12px 16px;
      color: #e0e0e0;
      font-size: 14px;
      resize: none;
      min-height: 48px;
      max-height: 200px;
      outline: none;
      line-height: 1.5;
      transition: border-color 0.15s;
    }
    #question-input:focus { border-color: #3b5998; }
    #question-input::placeholder { color: #3a3d50; }
    #ask-btn {
      background: #1d4ed8;
      color: white;
      border: none;
      border-radius: 8px;
      padding: 12px 20px;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: background 0.15s;
      white-space: nowrap;
    }
    #ask-btn:hover:not(:disabled) { background: #2563eb; }
    #ask-btn:disabled { opacity: 0.4; cursor: not-allowed; }
    #input-hint {
      font-size: 11px;
      color: #2a2d3a;
      padding: 0 24px 8px;
      background: #13161f;
    }
  </style>
</head>
<body>

<!-- ─── Sidebar ──────────────────────────────────────────────────────────── -->
<div id="sidebar">
  <div id="sidebar-header">Query History</div>
  <div id="history-list">
    <div style="padding: 16px 12px; font-size: 12px; color: #2a2d3a;">
      Your questions will appear here.
    </div>
  </div>
  <div id="sidebar-footer">RAG Brain v1.0 · PathakLabs</div>
</div>

<!-- ─── Main ─────────────────────────────────────────────────────────────── -->
<div id="main">
  <div id="header">
    <h1>RAG Brain</h1>
    <span class="subtitle">Fully local · Your files only</span>
  </div>

  <div id="chat-area">
    <div id="empty-state">
      <div class="icon">🧠</div>
      <div class="label">Ask anything about your homelab files</div>
      <div id="example-questions">
        <div class="example-q" onclick="fillQuestion(this)">Which automation turns on the hallway light?</div>
        <div class="example-q" onclick="fillQuestion(this)">Which n8n workflow sends Telegram alerts?</div>
        <div class="example-q" onclick="fillQuestion(this)">What entities does the morning coffee automation use?</div>
      </div>
    </div>
  </div>

  <div id="input-hint">Press Enter to ask · Shift+Enter for new line</div>
  <div id="input-area">
    <textarea
      id="question-input"
      placeholder="Ask a question about your Home Assistant automations, n8n workflows, or notes..."
      rows="1"
    ></textarea>
    <button id="ask-btn" onclick="sendQuestion()">Ask</button>
  </div>
</div>

<script>
  // ─── Configuration ─────────────────────────────────────────────────────────
  const API_URL = "http://localhost:8000";  // change to your homelab IP if needed
  // ───────────────────────────────────────────────────────────────────────────

  let queryHistory = [];
  let isLoading = false;

  // Auto-resize textarea
  const textarea = document.getElementById("question-input");
  textarea.addEventListener("input", () => {
    textarea.style.height = "auto";
    textarea.style.height = Math.min(textarea.scrollHeight, 200) + "px";
  });

  // Enter to submit, Shift+Enter for new line
  textarea.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendQuestion();
    }
  });

  function fillQuestion(el) {
    textarea.value = el.textContent;
    textarea.focus();
  }

  function scoreClass(score) {
    if (score >= 0.8) return "high";
    if (score >= 0.6) return "medium";
    return "low";
  }

  function addToHistory(question) {
    queryHistory.unshift(question);
    const list = document.getElementById("history-list");

    // Clear default text on first question
    if (queryHistory.length === 1) {
      list.innerHTML = "";
    }

    const item = document.createElement("div");
    item.className = "history-item";
    item.textContent = question.length > 60 ? question.slice(0, 60) + "..." : question;
    item.title = question;
    item.onclick = () => {
      textarea.value = question;
      textarea.focus();
    };

    list.prepend(item);
  }

  function renderMessage(role, content, sources) {
    const chatArea = document.getElementById("chat-area");

    // Remove empty state on first message
    const emptyState = document.getElementById("empty-state");
    if (emptyState) emptyState.remove();

    const messageEl = document.createElement("div");
    messageEl.className = `message ${role}`;

    const bubble = document.createElement("div");
    bubble.className = "bubble";
    bubble.textContent = content;
    messageEl.appendChild(bubble);

    // Add sources section for assistant messages
    if (role === "assistant" && sources && sources.length > 0) {
      const sourcesSection = document.createElement("div");
      sourcesSection.className = "sources-section";

      const toggle = document.createElement("button");
      toggle.className = "sources-toggle";
      toggle.innerHTML = `<span class="arrow">▶</span> ${sources.length} source${sources.length > 1 ? "s" : ""}`;
      toggle.onclick = () => {
        toggle.classList.toggle("open");
        sourcesList.classList.toggle("open");
      };
      sourcesSection.appendChild(toggle);

      const sourcesList = document.createElement("div");
      sourcesList.className = "sources-list";

      sources.forEach(src => {
        const card = document.createElement("div");
        card.className = "source-card";
        const scoreDisplay = (src.score * 100).toFixed(0) + "%";
        card.innerHTML = `
          <div class="source-header">
            <span class="source-file">${src.file}</span>
            <span class="source-score ${scoreClass(src.score)}">relevance: ${scoreDisplay}</span>
          </div>
          <div class="source-excerpt">${src.excerpt}</div>
        `;
        sourcesList.appendChild(card);
      });

      sourcesSection.appendChild(sourcesList);
      messageEl.appendChild(sourcesSection);
    }

    chatArea.appendChild(messageEl);
    chatArea.scrollTop = chatArea.scrollHeight;
    return messageEl;
  }

  function showLoading() {
    const chatArea = document.getElementById("chat-area");
    const emptyState = document.getElementById("empty-state");
    if (emptyState) emptyState.remove();

    const loadingEl = document.createElement("div");
    loadingEl.className = "message assistant";
    loadingEl.id = "loading-indicator";
    loadingEl.innerHTML = `
      <div class="loading">
        <div class="dots">
          <span></span><span></span><span></span>
        </div>
        Searching your files...
      </div>
    `;
    chatArea.appendChild(loadingEl);
    chatArea.scrollTop = chatArea.scrollHeight;
  }

  function hideLoading() {
    const el = document.getElementById("loading-indicator");
    if (el) el.remove();
  }

  async function sendQuestion() {
    if (isLoading) return;

    const input = document.getElementById("question-input");
    const question = input.value.trim();
    if (!question) return;

    // Clear input
    input.value = "";
    input.style.height = "auto";

    // Disable button while loading
    const btn = document.getElementById("ask-btn");
    btn.disabled = true;
    isLoading = true;

    // Show user message
    renderMessage("user", question, null);
    addToHistory(question);

    // Show loading indicator
    showLoading();

    try {
      const response = await fetch(`${API_URL}/query`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question, top_k: 5 }),
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      hideLoading();

      renderMessage("assistant", data.answer, data.sources);

    } catch (err) {
      hideLoading();
      const errorMsg = err.message.includes("Failed to fetch")
        ? `Cannot reach the API at ${API_URL}. Is your RAG Brain running?`
        : `Error: ${err.message}`;
      renderMessage("assistant", errorMsg, null);
    }

    btn.disabled = false;
    isLoading = false;
  }
</script>
</body>
</html>
```

---

### Step 2 — Serve the static file from FastAPI

Update `~/projects/rag-brain/main.py` to serve the static folder:

```python
# Add these imports at the top of main.py:
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

# Add these lines after `app = FastAPI(...)`:
# Serve the static folder (HTML, CSS, JS)
static_path = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_path):
    app.mount("/static", StaticFiles(directory=static_path), name="static")

# Add this route:
@app.get("/ui")
def serve_ui():
    """Serve the chat UI."""
    return FileResponse("static/index.html")
```

Install the static files dependency:

```bash
pip install aiofiles
```

Add to `requirements.txt`:

```
aiofiles==23.2.1
```

---

### Step 3 — Start the server and open the UI

```bash
# Start the server (with reload for development)
uvicorn main:app --reload --port 8000
```

Open your browser:

```
http://localhost:8000/ui
```

Or if your API is on your homelab:

```
http://YOUR_HOMELAB_IP:8000/ui
```

---

### Step 4 — Test the UI

1. Type a question and press Enter (or click Ask)
2. Watch the loading indicator appear
3. See the answer appear as an assistant message
4. Click "N sources" to expand the source citations
5. Try clicking the example questions in the empty state

If you see "Cannot reach the API" error: check that `API_URL` in the HTML file matches where your server is running.

---

### Step 5 — Fix CORS if needed

If you are accessing the UI from a different origin than the API, you may need to enable CORS:

```python
# Add to main.py:
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your homelab IP
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## Visual overview

```
Browser (http://homelab-ip:8000/ui)
┌─────────────────────────────────────────────────────────────────┐
│  RAG Brain                              Fully local · Your files │
├─────────────────────┬───────────────────────────────────────────┤
│  Query History      │                                           │
│  ─────────────────  │   You:  Which automation controls         │
│  ▸ Which automation │          the hallway light?               │
│    controls hall... │                                           │
│                     │   AI:   The "Hallway Motion Light"        │
│  ▸ Which workflow   │         automation turns on               │
│    sends Telegram.. │         light.hallway when motion is      │
│                     │         detected after sunset...           │
│                     │                                           │
│                     │         ▶ 2 sources                        │
│                     │           (click to expand)               │
│                     │         ┌──────────────────────────────┐  │
│                     │         │ automations.yaml  93%        │  │
│                     │         │ Automation: Hallway Motion..  │  │
│                     │         └──────────────────────────────┘  │
│                     │                                           │
│                     │   [ Ask about your homelab...    ] [Ask]  │
└─────────────────────┴───────────────────────────────────────────┘
```

---

## Learning checkpoint

> Write your answer to this question in your build log BEFORE moving on:
>
> **"After using the UI for 10 minutes, what did you learn about your system that you did not know from reading API responses? Did any answers surprise you? Were the source citations helpful for verifying correctness?"**

---

## Done when

- [ ] `static/index.html` created
- [ ] FastAPI serves `/ui` route
- [ ] Browser opens UI at `http://localhost:8000/ui` without errors
- [ ] Asking a question shows user bubble + assistant bubble + source toggle
- [ ] Expanding sources shows filename and excerpt for each source
- [ ] Query history sidebar updates with each question
- [ ] Example questions are clickable and fill the input field
- [ ] "Cannot reach API" shows a clear error message
- [ ] Learning checkpoint answered in build log

---

## Next step

→ [P2-T10: Add hallucination detection eval loop](p2-t10-hallucination-detection.md)
