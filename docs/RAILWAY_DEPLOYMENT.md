# Deploying BudgetSentinel on Railway

This guide walks through deploying all three services (PostgreSQL, Python AI microservice, Elixir Phoenix web) to Railway from the GitHub repository. Follow each section in order — the services depend on each other and must be set up in the sequence below.

**Estimated time:** 20–30 minutes

---

## Prerequisites

- GitHub repository pushed and accessible (e.g. `https://github.com/dorcss/budget-sentinel`)
- A Railway account — sign up free at **railway.app** using your GitHub account
- Your Gmail app password for email delivery (already configured in `.env`)

---

## Step 1 — Create a Railway project

1. Log in to **railway.app**
2. Click **New Project**
3. Select **Empty Project**
4. Give it a name: `BudgetSentinel`

You will add all three services into this one project. Services within the same project can talk to each other over Railway's private internal network.

---

## Step 2 — Add PostgreSQL (managed database)

1. Inside your project, click **+ Add Service**
2. Select **Database → PostgreSQL**
3. Railway creates a managed PostgreSQL instance automatically
4. Click on the new PostgreSQL service → **Variables** tab
5. Copy the value of **DATABASE_URL** — you will paste it into the web service later

> Railway's managed PostgreSQL is persistent and does not expire. It is automatically backed up.

---

## Step 3 — Deploy the AI microservice

1. Click **+ Add Service** → **GitHub Repo**
2. Select the `budget-sentinel` repository
3. Railway will detect it and begin configuring — **stop it before it deploys**:
   - Click **Settings** on the new service
   - Set **Root Directory** to: `ai_service`
   - Set **Watch Paths** to: `ai_service/**`
   - The Dockerfile is at `ai_service/Dockerfile` — Railway finds it automatically from the root directory
4. Rename this service to `ai-service` (click the service name at the top to edit it)
5. Go to **Variables** tab and add:

   | Variable | Value |
   |---|---|
   | `ANTHROPIC_API_KEY` | your Anthropic API key (leave blank if you don't have one — the system will use fallback audit reports) |
   | `FLASK_PORT` | `5000` |

6. Go to **Settings → Networking** — the AI service does **not** need a public domain. It only needs to be reachable internally by the web service. Leave public networking off.

7. Click **Deploy** — Railway builds the Docker image (this trains the Isolation Forest model inside the container, takes 2–3 minutes on first build).

8. Once deployed, go to **Settings → Networking → Private Networking** and note the **private domain** — it will look like `ai-service.railway.internal`. Copy it.

---

## Step 4 — Generate a SECRET_KEY_BASE

The Phoenix web service requires a 64-byte random secret for encrypting sessions and cookies. Run this command on your machine to generate one:

**On Windows (PowerShell):**
```powershell
-join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
```

**On Mac/Linux:**
```bash
openssl rand -hex 64
```

Save the output — you will paste it as `SECRET_KEY_BASE` in the next step.

---

## Step 5 — Deploy the Phoenix web service

> **Before adding variables** — Railway injects a `PORT` environment variable automatically. The Dockerfile exposes port `4000`. These must match, so you must explicitly set `PORT=4000` in Railway's environment variables to prevent a mismatch that causes "Application failed to respond".

1. Click **+ Add Service** → **GitHub Repo**
2. Select the `budget-sentinel` repository again
3. Before it deploys — go to **Settings** and set:
   - **Root Directory**: `web`
   - **Watch Paths**: `web/**`
4. Rename this service to `web`
5. Go to **Settings → Deploy** and set the **Start Command** to:
   ```
   bin/budget_sentinel eval "BudgetSentinel.Release.migrate()" && bin/budget_sentinel start
   ```
   This runs database migrations automatically on every deploy before starting the server.

6. Go to **Variables** tab and add every variable below:

   | Variable | Value |
   |---|---|
   | `DATABASE_URL` | paste the value you copied from the PostgreSQL service in Step 2 |
   | `SECRET_KEY_BASE` | paste the value you generated in Step 4 |
   | `PORT` | `4000` |
   | `PHX_HOST` | leave blank for now — you will fill this in after the first deploy (see Step 6) |
   | `PHX_SCHEME` | `https` |
   | `PHX_URL_PORT` | `443` |
   | `AI_SERVICE_URL` | `http://ai-service.railway.internal:5000` (use the private domain you noted in Step 3) |
   | `SMTP_RELAY` | `smtp.gmail.com` |
   | `SMTP_USERNAME` | `kiplimocollins855@gmail.com` |
   | `SMTP_PASSWORD` | your Gmail app password |
   | `HIGH_RISK_THRESHOLD` | `70.0` |

7. Click **Deploy** — the build takes 3–5 minutes (compiling Elixir + assets).

8. Once deployed, go to **Settings → Networking** → click **Generate Domain**. Railway assigns a public URL like `web-production-xxxx.up.railway.app`.

---

## Step 6 — Set PHX_HOST and redeploy

The invite links and alert email links must contain the correct public URL. Now that you have it:

1. Go to the **web** service → **Variables**
2. Set `PHX_HOST` to your Railway domain **without** `https://` — for example:
   ```
   web-production-xxxx.up.railway.app
   ```
3. Railway will automatically redeploy when you save the variable. Wait for it to complete.

---

## Step 7 — Seed the database

Seeds run **automatically on every startup** via the start command — no manual step needed. The `Release.seed/0` function checks whether the database already has ministries before running, so it is completely safe across multiple redeploys. On first deploy, seeds will run and create the 5 ministries, 50 projects, 200 expenditure records, and demo accounts. On all subsequent deploys it skips seeding automatically.

If you ever need to re-seed a fresh database manually, use the Railway CLI:

**Install Railway CLI (if you don't have it):**
```bash
npm install -g @railway/cli
```

**Log in and link:**
```bash
railway login
railway link
```
Select your BudgetSentinel project and the `web` service when prompted.

**Run seeds manually (only needed if seeding failed):**
```bash
railway exec --service web "/app/bin/budget_sentinel eval \"BudgetSentinel.Release.seed()\""
```

> Note: use `railway exec` (not `railway run`). `railway run` executes commands locally on your machine with Railway env vars injected — it does not run inside the deployed container. `railway exec` runs inside the container where the release binary exists.

---

## Step 8 — Verify the deployment

Open your Railway public URL in a browser (e.g. `https://web-production-xxxx.up.railway.app`).

You should be redirected to `/users/log_in`. Log in with:

| Email | Password |
|---|---|
| `kiplimocollins855@gmail.com` | `BudgetSentinel2026!` |

Check each service works:
- **Dashboard** loads with project stats
- **Projects** shows the 50 seeded projects
- **Run Detection Scan** completes and anomalies appear
- **Alerts** shows dispatched alerts with `Sent` status
- Check `kiplimocollins855@gmail.com` inbox — a real alert email should arrive

---

## Environment variables — quick reference

### ai-service

| Variable | Required | Value |
|---|---|---|
| `ANTHROPIC_API_KEY` | Optional | Your Anthropic key — if absent, fallback audit reports are used |
| `FLASK_PORT` | Yes | `5000` |

### web

| Variable | Required | Value |
|---|---|---|
| `DATABASE_URL` | Yes | From Railway PostgreSQL plugin |
| `SECRET_KEY_BASE` | Yes | 64-byte hex string (generated in Step 4) |
| `PORT` | Yes | `4000` — must match the Dockerfile EXPOSE port |
| `PHX_HOST` | Yes | Your Railway public domain (no `https://`) |
| `PHX_SCHEME` | Yes | `https` |
| `PHX_URL_PORT` | Yes | `443` |
| `AI_SERVICE_URL` | No | `http://ai-service.railway.internal:5000` — defaults to localhost:5000 if not set |
| `SMTP_RELAY` | No | `smtp.gmail.com` — if absent, emails are captured locally |
| `SMTP_USERNAME` | No | Your Gmail address |
| `SMTP_PASSWORD` | No | Your Gmail app password |
| `HIGH_RISK_THRESHOLD` | No | `70.0` (default) |
| `DB_SSL` | No | Set to `false` only if your Postgres host does not support SSL (Railway's managed Postgres always supports it) |

---

## Redeployment (after code changes)

Railway automatically rebuilds and redeploys when you push to the branch it is watching. If you push to the `develop` branch:

1. Railway detects the push
2. Rebuilds the Docker image
3. Runs migrations (`bin/budget_sentinel eval "BudgetSentinel.Release.migrate()"`)
4. Starts the new release

No manual steps needed after the initial setup.

---

## Troubleshooting

**"Application failed to respond" on first visit**
→ Check Railway deploy logs (click the web service → Deployments → the latest deployment → View Logs). The most common causes in order:
1. `PORT` not set to `4000` — Railway routes traffic to port 4000 (from EXPOSE in Dockerfile) but the app is binding to a different port. Fix: add `PORT=4000` to the web service variables.
2. Database SSL mismatch — Railway's managed PostgreSQL requires SSL. If you see a connection error in the logs, the SSL config is failing. The code now enables SSL by default; if it still fails, add `DB_SSL=false` as a temporary test.
3. `DATABASE_URL` is wrong or missing — copy it directly from the PostgreSQL plugin's Variables tab, not from the connection details page.

**`railway run` gives "No such file or directory"**
→ `railway run` executes commands **locally on your machine** with Railway env vars injected — the Elixir release binary only exists inside the deployed Docker container. Use `railway exec` instead:
```bash
railway exec --service web "/app/bin/budget_sentinel eval \"BudgetSentinel.Release.seed()\""
```

**The app redirects to log in on every page after logging in**
→ `SECRET_KEY_BASE` is wrong or changed since the last deployment — all sessions become invalid. Generate a new one and redeploy. Also confirm `PHX_HOST` is set to the correct domain.

**Run Detection Scan hangs indefinitely (button stays "Scanning…")**
→ `AI_SERVICE_URL` is wrong or the ai-service is not running. Go to ai-service in Railway → check it shows healthy. Then confirm the private domain matches exactly what you set in `AI_SERVICE_URL` for the web service.

**Emails not arriving**
→ Check that the alert row on `/alerts` shows `Sent` not `Failed`. If `Failed`, the SMTP credentials are wrong. Gmail app passwords must be 16 characters with no spaces. If `Sent`, check the spam/junk folder.

**Build fails for the web service**
→ Confirm `Root Directory` is set to `web` in Railway service Settings — not the repo root and not `budget-sentinel/web`.

**Invite links in emails point to `https://localhost` or wrong URL**
→ `PHX_HOST` is blank or wrong. Set it to your Railway public domain (without `https://`) and Railway will trigger a redeploy automatically.
