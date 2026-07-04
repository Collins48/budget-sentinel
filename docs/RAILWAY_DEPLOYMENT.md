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

## Step 7 — Seed the database with demo data

The migrations ran automatically at startup (Step 5), but the demo dataset (50 projects, 200 expenditures, ministries) still needs to be loaded. Run this once using the Railway CLI:

**Install Railway CLI (if you don't have it):**
```bash
npm install -g @railway/cli
```

**Log in:**
```bash
railway login
```

**Link to your project:**
```bash
railway link
```
Select your BudgetSentinel project and the `web` service when prompted.

**Run the seeds:**
```bash
railway run bin/budget_sentinel eval "Code.eval_file(\"priv/repo/seeds.exs\")"
```

> This seeds ministries, 50 projects, 200 expenditure records, and demo admin accounts. It is idempotent — safe to run more than once.

**After seeding, create your own admin account** (the seed admin uses a placeholder email — replace it with a real one):
```bash
railway run bin/budget_sentinel eval "
  alias BudgetSentinel.Accounts
  {:ok, _} = Accounts.create_user_by_admin(%{
    'email' => 'kiplimocollins855@gmail.com',
    'password' => 'BudgetSentinel2026!',
    'role' => 'admin'
  })
"
```

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
| `PHX_HOST` | Yes | Your Railway public domain (no `https://`) |
| `PHX_SCHEME` | Yes | `https` |
| `PHX_URL_PORT` | Yes | `443` |
| `AI_SERVICE_URL` | Yes | `http://ai-service.railway.internal:5000` |
| `SMTP_RELAY` | Yes | `smtp.gmail.com` |
| `SMTP_USERNAME` | Yes | Your Gmail address |
| `SMTP_PASSWORD` | Yes | Your Gmail app password |
| `HIGH_RISK_THRESHOLD` | No | `70.0` (default — anomalies above this score trigger alerts) |

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

**The app redirects to log in on every page**
→ `DATABASE_URL` is wrong or the migrations have not run. Check the web service logs in the Railway dashboard.

**Run Detection Scan hangs indefinitely**
→ `AI_SERVICE_URL` is pointing to the wrong address. Confirm the ai-service private domain matches exactly. Go to ai-service → Settings → Networking → Private Domain and copy the exact value.

**Emails not arriving**
→ Check `SMTP_USERNAME` / `SMTP_PASSWORD` are set correctly. Gmail app passwords must have no spaces. Verify the alert shows `Sent` on `/alerts` — if it shows `Failed`, the SMTP credentials are wrong.

**Build fails for the web service**
→ The Elixir compiler needs the source files. Confirm `Root Directory` is set to `web` in the Railway service settings, not the repo root.

**Invite links in emails point to `https://localhost`**
→ `PHX_HOST` is not set or is still blank. Set it to your Railway public domain and redeploy.
