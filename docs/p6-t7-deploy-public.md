# P6-T7: Deploy the Dashboard to shailesh-pathak.com

> **Goal:** Get the dashboard live on a public URL so that anyone in the world can see your 5 AI projects running.

**Part of:** [P6-US2: Public Portfolio](p6-us2-public-portfolio.md)
**Week:** 13
**Labels:** `task`, `p6-dashboard`

---

## What you are doing

You are deploying two things:

1. **The React dashboard** (frontend) — a static website that can be hosted anywhere for free
2. **The FastAPI metrics API** (backend) — a server process that needs to run somewhere continuously

You have several options depending on whether you have a VPS or prefer cloud services. This task covers all of them so you can pick what fits your setup.

---

## Why this step matters

"Most powerful thing you can show a potential employer, client, or collaborator."

A repository link says: "I wrote some code."

A live dashboard link says: "I built 5 real systems and they are running right now."

When someone opens your dashboard and sees live timestamps and real metric counts, the conversation changes. You are not asking them to imagine what you built — you are showing them.

---

## Prerequisites

- [ ] [P6-T4: React Dashboard](p6-t4-react-dashboard.md) — working locally
- [ ] [P6-T5: Cost Charts](p6-t5-cost-charts.md) — working locally
- [ ] [P6-T6: Content Tracker](p6-t6-content-tracker.md) — working locally
- [ ] All 5 projects sending events to the metrics API
- [ ] A domain or subdomain to deploy to (shailesh-pathak.com or labs.shailesh-pathak.com)

---

## Architecture of what you are deploying

```
Internet
   │
   ├──► shailesh-pathak.com/labs  ──► React build (static files)
   │         (Vercel / Netlify / your server)
   │
   └──► api.shailesh-pathak.com  ──► FastAPI metrics API
              (Fly.io / Railway / your homelab + Cloudflare Tunnel)
                      │
                      └──► PostgreSQL database


Security:
  Public can read:   GET /projects, GET /costs/*, GET /health
  Only you can write: POST /events  (requires x-api-key header)
```

---

## Step-by-step instructions

### Part A — Deploy the FastAPI backend

Choose one option. Option 1 is best if you already have a homelab.

---

#### Option 1 — Your homelab with Cloudflare Tunnel (recommended if you have a homelab)

This keeps everything on your hardware and costs nothing extra. Cloudflare Tunnel gives it a public HTTPS URL without opening ports in your router.

**Step 1 — Make sure the API runs reliably**

Create a systemd service or a podman compose entry so the API starts on boot:

```yaml
# docker-compose.yml or podman-compose.yml
version: "3.8"
services:
  metrics-api:
    build: ./projects/06-dashboard/api
    restart: always
    ports:
      - "8006:8006"
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/pathaklabs_metrics
      METRICS_API_KEY: your-secret-key
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: pathaklabs_metrics
      POSTGRES_PASSWORD: password
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

**Step 2 — Install cloudflared**

```bash
# On your homelab (Debian/Ubuntu):
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
  | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] \
  https://pkg.cloudflare.com/cloudflared any main" \
  | sudo tee /etc/apt/sources.list.d/cloudflared.list

sudo apt update && sudo apt install cloudflared
```

**Step 3 — Authenticate and create a tunnel**

```bash
cloudflared tunnel login
cloudflared tunnel create pathaklabs-api
```

**Step 4 — Configure the tunnel**

Create `/etc/cloudflared/config.yml`:

```yaml
tunnel: pathaklabs-api
credentials-file: /root/.cloudflared/<your-tunnel-id>.json

ingress:
  - hostname: api.shailesh-pathak.com
    service: http://localhost:8006
  - service: http_status:404
```

**Step 5 — Create the DNS record**

In the Cloudflare dashboard:
- Add a CNAME record: `api` → `<tunnel-id>.cfargotunnel.com`

**Step 6 — Start the tunnel as a service**

```bash
cloudflared service install
systemctl start cloudflared
systemctl enable cloudflared
```

Your API is now live at `https://api.shailesh-pathak.com`. Test it:

```bash
curl https://api.shailesh-pathak.com/health
# {"status": "ok", "service": "pathaklabs-metrics-api"}
```

---

#### Option 2 — Fly.io (free tier, no server needed)

Fly.io runs your Docker container in the cloud. Free tier is enough for this API.

**Step 1 — Install the Fly CLI**

```bash
curl -L https://fly.io/install.sh | sh
fly auth login
```

**Step 2 — Create a Dockerfile in the api folder**

```dockerfile
# projects/06-dashboard/api/Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Step 3 — Launch on Fly**

```bash
cd projects/06-dashboard/api
fly launch --name pathaklabs-metrics-api --region ams
```

Fly will detect the Dockerfile and create a `fly.toml` for you. Say yes to defaults.

**Step 4 — Set environment variables**

```bash
fly secrets set METRICS_API_KEY=your-secret-key
fly secrets set DATABASE_URL=postgresql://...   # your Fly Postgres URL
```

**Step 5 — Create a Fly Postgres database**

```bash
fly postgres create --name pathaklabs-db
fly postgres attach pathaklabs-db --app pathaklabs-metrics-api
```

**Step 6 — Deploy**

```bash
fly deploy
```

Your API is now at `https://pathaklabs-metrics-api.fly.dev`. Add a custom domain in the Fly dashboard to get `api.shailesh-pathak.com`.

---

#### Option 3 — Railway (simplest, free tier available)

Railway is the easiest option for beginners.

1. Go to railway.app → New Project → Deploy from GitHub
2. Select your ai-mastery repository
3. Set the root directory to `projects/06-dashboard/api`
4. Add environment variables: `METRICS_API_KEY`, `DATABASE_URL`
5. Add a PostgreSQL plugin: click "+ New" → "Database" → "PostgreSQL"
6. Railway auto-detects the `requirements.txt` and deploys

Your API URL will be `https://your-project.up.railway.app`. Connect a custom domain in the Railway settings.

---

### Part B — Deploy the React dashboard

This is the frontend (static files). It is simpler to deploy than the backend.

---

#### Option 1 — Vercel (recommended, free)

**Step 1 — Update the API URL**

In `projects/06-dashboard/dashboard/.env.production`:

```bash
REACT_APP_API_URL=https://api.shailesh-pathak.com
```

**Step 2 — Build the project**

```bash
cd projects/06-dashboard/dashboard
npm run build
```

**Step 3 — Deploy to Vercel**

```bash
npm install -g vercel
vercel login
vercel --prod
```

When prompted:
- Set up and deploy: yes
- Project name: `pathaklabs-dashboard`
- Directory: `./build` (the output folder)

**Step 4 — Add your custom domain**

In the Vercel dashboard:
- Go to your project → Domains
- Add `labs.shailesh-pathak.com` or `dashboard.shailesh-pathak.com`
- Vercel will tell you what DNS record to add

---

#### Option 2 — Netlify (also free)

```bash
npm install -g netlify-cli
netlify login
cd projects/06-dashboard/dashboard
npm run build
netlify deploy --prod --dir=build
```

Add a custom domain in the Netlify dashboard: Site settings → Domain management.

---

#### Option 3 — Your own server (nginx)

If you have an existing VPS or homelab server running nginx:

```bash
# Build the React app
npm run build

# Copy to your server
scp -r build/* user@your-server:/var/www/html/labs/

# Create nginx config
sudo nano /etc/nginx/sites-available/labs.shailesh-pathak.com
```

Nginx config:

```nginx
server {
    listen 80;
    server_name labs.shailesh-pathak.com;

    root /var/www/html/labs;
    index index.html;

    # React Router — serve index.html for all paths
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable it and get an SSL certificate:

```bash
sudo ln -s /etc/nginx/sites-available/labs.shailesh-pathak.com \
           /etc/nginx/sites-enabled/
sudo certbot --nginx -d labs.shailesh-pathak.com
sudo systemctl reload nginx
```

---

### Part C — Final checks after deployment

Work through this checklist after both frontend and backend are deployed:

```bash
# 1. API health check
curl https://api.shailesh-pathak.com/health
# Expected: {"status": "ok"}

# 2. Send a test event from your local machine
curl -X POST https://api.shailesh-pathak.com/events \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-key" \
  -d '{"project": "promptos", "event_type": "prompt_run", "value": 1, "metadata": {}}'
# Expected: {"status": "ok", ...}

# 3. Check the event appeared
curl https://api.shailesh-pathak.com/projects
# Expected: list of projects with event counts

# 4. Open the dashboard in a browser
# Expected: all 5 project cards visible with live data

# 5. Test on mobile — open the URL on your phone
# Expected: readable without zooming
```

### Part D — Update each project's environment variables

Now that the API has a public URL, update the `.env` in each of your 5 projects:

```bash
# In each project's .env:
METRICS_URL=https://api.shailesh-pathak.com
METRICS_API_KEY=your-secret-key
```

Redeploy or restart each project after the change.

---

## Visual overview

```
Your laptop                      Cloud / Homelab
────────────                     ───────────────

Dashboard code    npm run build
                  ──────────────► /build folder
                                       │
                  Vercel/Netlify/nginx  │
                  ◄─────────────────── │
                         │
                         │ serves
                         ▼
               labs.shailesh-pathak.com   ← visitors see this
                         │
                         │ calls
                         ▼
               api.shailesh-pathak.com    ← metrics API
                         │
                         │ reads/writes
                         ▼
                    PostgreSQL


5 projects ──► POST api.shailesh-pathak.com/events  (write, needs API key)
Dashboard  ──► GET  api.shailesh-pathak.com/projects (read, public)
```

---

## Learning checkpoint

**Why separate the frontend and backend?**

The React dashboard is just HTML, CSS, and JavaScript files. Once built, they do not need a running server — any file host (Vercel, Netlify, nginx) can serve them.

The FastAPI backend needs a running Python process. It does database queries and has state.

By separating them, you can:
- Update the dashboard UI without touching the API
- Scale or move the API without changing the frontend URL
- Keep the frontend free (Vercel/Netlify) while paying only for backend compute

This separation is called a "decoupled" or "Jamstack" architecture. It is standard in modern web development.

---

## Done when

- [ ] FastAPI metrics API is accessible at a public HTTPS URL
- [ ] React dashboard is accessible at a public HTTPS URL
- [ ] A stranger can open the dashboard URL and see live data
- [ ] POST /events is blocked without a valid API key (test with a wrong key)
- [ ] All 5 projects have their `METRICS_URL` updated to the public API URL
- [ ] The dashboard URL is added to your LinkedIn profile and portfolio site

---

## Next step

→ [P6-C2: LinkedIn Series](p6-c2-linkedin-series.md) — now that the dashboard is live, start the 6-post retrospective series.
→ [P6-C1: Capstone Blog](p6-c1-capstone-blog.md) — write the 14-week retrospective (your most important piece of content).
