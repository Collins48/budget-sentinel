# BudgetSentinel — Complete Project Walkthrough

This document takes a contributor or reviewer through the entire system end to end: what it does, why it was built, every screen, how the AI and ML components function under the hood, and the full pipeline from raw expenditure data to a real email alert landing in an inbox.

**System is live at: http://localhost:4000**

---

## 1. What this system is and why it exists

BudgetSentinel is a government expenditure monitoring and fraud detection platform built for public accountability in Rwanda and East Africa. The core problem it solves:

Government projects publish budgets and procurement records, but no intelligent system watches whether actual spending aligns with those budgets in real time. Auditors work reactively — reviewing records long after irregularities occur. By then, funds are gone.

BudgetSentinel changes this to **proactive monitoring**: every payment is scored automatically as it's recorded, high-risk fraud patterns are flagged immediately, an AI writes a structured audit report explaining what was detected and recommending corrective action, and designated oversight officers receive a real email alert — all triggered by a single button click.

---

## 2. Accounts and how to log in

**URL:** http://localhost:4000/users/log_in

There is no public sign-up. Every account is provisioned by an admin using the invite flow — the admin sends an emailed invitation, the recipient sets their own password via a secure link. No admin ever sets or sees a user's password.

### Active accounts

| Email | Password | Role | Access |
|---|---|---|---|
| `kiplimocollins855@gmail.com` | `BudgetSentinel2026!` | Admin | All ministries — full write access, user management, runs scans |
| `limokcollins@gmail.com` | `BudgetSentinel2026!` | Auditor | Ministry of Water and Sanitation only — create/edit projects and expenditures, run scans, action anomalies |

### Role differences to demonstrate

Log in as **Admin** (`kiplimocollins855`) first — you see all 50 projects across all 5 ministries, all anomalies, and the **User Accounts** link in the nav. Then log out and log in as **Auditor** (`limokcollins`) — you only see projects and anomalies belonging to the Ministry of Water and Sanitation. The dashboard numbers, project list, anomaly list, and alerts all filter automatically to that ministry. No code changes between sessions — it's the same data, same scan, scoped differently based on who is logged in.

---

## 3. Dashboard (`/`)

The first thing every user sees after login. Built with **Phoenix LiveView** — it updates automatically when a scan completes, with no page refresh and no JavaScript written by hand.

**What the stat row shows:**
- **Monitored Projects** — total projects visible to this user (50 for admin, fewer for ministry-scoped roles).
- **Anomalies (recent)** — last 10 flagged.
- **High-Risk Open** — anomalies scored ≥70/100 that haven't been resolved or dismissed yet. This number drops in real time as auditors work through cases.
- **Failed Alerts** — alert emails that couldn't be delivered (SMTP down, bad address). Retryable from the Alerts Center.

**Run Detection Scan button** (admin/auditor only) — this is the core action. Explain to your visitor: clicking this kicks off the full pipeline:
1. Every project and expenditure is sent to the Python AI microservice.
2. The Isolation Forest model scores each payment for statistical abnormality.
3. A rule engine classifies the fraud type.
4. High-risk findings get a Claude-generated audit report.
5. Email alerts go to every admin and every person assigned to that project's ministry.
6. The dashboard updates live.

The button shows **Scanning…** during the run and returns to normal when complete.

---

## 4. Projects (`/projects`)

The system of record for government projects and their individual expenditure payments.

**List view:** 50 pre-loaded projects across sectors (infrastructure, education, health, water, energy) and ministries. Each row shows the project name, sector, and a **budget utilization bar** — a visual measure of how much of the approved budget has been spent.

**Project detail (`/projects/:id`):** Full breakdown — approved budget, total spent, completion rate, and the full ledger of individual expenditure records (contractor, amount, milestone, date paid). This is the raw data the AI model analyzes.

**Adding an expenditure (admin/auditor only):** Click **Add Expenditure**. Every payment recorded here feeds the next detection scan.

---

## 5. The live demo scenario — triggering a real fraud detection

This is the walkthrough's centrepiece. Doing it live proves the full pipeline works, rather than just describing it.

### Step 1 — Create a new project (logged in as admin or auditor)

Go to `/projects` → **New Project** and enter:

| Field | Value |
|---|---|
| Name | `Kigali-Huye Highway Rehabilitation` |
| Sector | `Infrastructure` |
| Ministry | `Ministry of Infrastructure` |
| Approved Budget | `80000000` |
| Market Benchmark | `80000000` |
| Completion Rate (%) | `0` |

Narrate: *"This project has been approved for 80 million RWF and officially reports zero percent completion — nothing has been built."*

### Step 2 — Add the fraudulent expenditure

Open the project you just created → **Add Expenditure**:

| Field | Value |
|---|---|
| Contractor | `Horizon Construction Ltd` |
| Amount | `72000000` |
| Milestone | `Phase 1 - Earthworks` |
| Paid On | today's date |

Narrate: *"Someone just processed a 72 million RWF payment — 90 percent of the entire approved budget — against a project reporting zero percent completion. In a manual audit environment, this might sit unnoticed for months. BudgetSentinel will catch it in seconds."*

### Step 3 — Run Detection Scan

Go to the dashboard (`/`) and click **Run Detection Scan**.

While it runs, explain what's happening in the background:
- Phoenix sends all 50 projects and 200+ expenditure records to the Python microservice.
- The Isolation Forest model scores every payment by how statistically isolated its feature combination is — cumulative budget utilization, payment-as-fraction-of-budget, gap between payment percentage and completion rate, duplicate-payment count, contract-to-benchmark ratio, and the zero-completion flag.
- The zero-completion full-payment flag fires for this expenditure: completion rate is 0, yet 90% of the budget is being paid.
- The rule engine classifies it as **ghost project** with rule strength ~97/100.
- Combined risk score: **~96/100, severity HIGH**.

This crosses the high-risk threshold (70/100), which triggers two things: a Claude-generated audit report, and a real email alert.

### Step 4 — Show the anomaly (`/anomalies`)

The new anomaly appears at the top of the list (most recent, highest risk). Click into it.

**Detection Details section:**
- Fraud type: `ghost_project`
- Risk score: ~96/100
- Explanation: *"Full payment was disbursed against a project reporting zero completion."*

**AI-Generated Audit Report section:** Three structured paragraphs — Summary (what happened), Severity Assessment (risk quantification), Recommended Actions (what an oversight body should do). This was generated by Claude using the anomaly's fraud type, risk score, contractor, amount, and project context as the prompt. Without an API key configured, a deterministic template based on the same data is used instead — the structure is identical.

**Audit Review section (admin/auditor only):** Change the status from `open` to `under_review` and add a note. Narrate: *"This is what turns detection into an actual audit workflow — not just a log entry, but a case with a status, a responsible reviewer, and an audit trail of who acted on it and when."*

### Step 5 — Show the alert (`/alerts`)

Go to the Alerts Center. The new row shows:
- **Recipient**: `kiplimocollins855@gmail.com` (admin, receives all ministry alerts)
- **Project**: linked back to the anomaly
- **Status**: `Sent`
- **Dispatched At**: timestamp

Narrate: *"The system determined who needed to know about this — every admin, plus every auditor and oversight officer assigned to that project's ministry — and emailed each of them directly."*

### Step 6 — Show the real email

Open `kiplimocollins855@gmail.com`'s inbox. The email will have arrived with subject:

> [BudgetSentinel] High-risk anomaly detected: ghost project

The body contains the fraud type, risk score, and the full three-section audit report. This is not a demo screenshot — it is a real email that left the server via Gmail SMTP.

---

## 6. Anomalies Center (`/anomalies`)

Every anomaly the system has ever flagged, across all scans. Five fraud types the model detects:

| Fraud Type | What it means |
|---|---|
| **Ghost Project** | Full payment against a project with zero reported completion |
| **Premature Payment** | Payment amount far exceeds the project's reported completion percentage |
| **Budget Overrun** | Cumulative spending has exceeded the approved project budget |
| **Inflated Contract** | Payment is significantly above the market benchmark for this project type |
| **Duplicate Payment** | The same contractor was paid more than once for the same milestone |

Filter tabs (All / Open / Under Review / Resolved / Dismissed) reflect the live audit workflow. High-Risk Open on the dashboard counts anomalies in the `open` or `under_review` state — it drops in real time as auditors resolve or dismiss cases.

---

## 7. Alerts Center (`/alerts`)

A first-class view of every email dispatch, not buried inside individual anomaly pages.

- **Filter tabs**: All / Sent / Failed / Pending.
- **Retry button** (admin/auditor, on failed rows): re-sends just that one recipient without re-running the entire scan.
- **Ministry scoping**: auditors and oversight officers only see alerts for their own ministry's projects.

**Who receives alerts is computed live from the users table** — not a static config list. Add a new oversight officer to a ministry today, and they start receiving that ministry's alerts on the very next scan. No code change, no redeploy.

---

## 8. Invite-based user onboarding (`/admin/users` — admin only)

No public registration. The admin invites users by email — the system sends a secure, single-use, 14-day link. The recipient sets their own password by clicking it.

**Steps to demonstrate:**
1. `/admin/users` → **Invite Account** → enter an email, select role (Admin / Auditor / Oversight Officer) and ministry (leave blank for admins).
2. Click **Send Invitation**.
3. The recipient gets a branded HTML email with their role and ministry baked in, and a button: *Accept Invitation & Set Password*.
4. Clicking that link opens `/users/invite/:token` — the accept page, which shows as clean (no app nav, no authenticated shell) regardless of who else might be logged in on that browser.
5. After setting a password, the account activates. The token is invalidated — the same link won't work twice.
6. Back on `/admin/users`, the account now shows **Active** (was **Invited** before). The **Resend invite** button disappears.

**Resend invite** — visible next to any still-Invited account. Invalidates the old link and sends a fresh one.

---

## 9. Profile and Settings

**Profile (`/users/profile`)** — every logged-in user can see their own email, role, ministry scope, what their role is permitted to do, account status, who invited them, and their member-since date. Accessible from the header account menu.

**Settings (`/users/settings`)** — change your own email or password. Email changes use a verification link sent to the new address before the change takes effect. Password changes require the current password and invalidate all other active sessions.

---

## 10. How the AI components work

There are two distinct AI layers, both in the Python microservice (`ai_service/`):

### Layer 1 — Isolation Forest (no LLM, pure ML)

Runs on every scan, against every expenditure in the database. Unsupervised — no labelled training data needed. Each expenditure is converted to 6 numeric features, scored by how statistically isolated that feature combination is, then classified against five rule-based fraud patterns. The final risk score blends the ML anomaly score (50%) and the rule-based classification strength (50%), normalized to 0–100.

The model was trained offline on the seeded Rwanda expenditure dataset (50 projects, ~200 expenditures, 10 embedded fraud scenarios) via `ai_service/scripts/train_model.py`. It is loaded into memory at service startup and does not retrain on live data.

### Layer 2 — Claude audit report (LLM, high-risk only)

Only fires for anomalies scoring ≥70. The Python service sends a structured prompt to Claude (`claude-sonnet-4-6`) with the fraud type, risk score, project details, and payment details. Claude responds with three labelled sections — SUMMARY, SEVERITY ASSESSMENT, RECOMMENDED ACTIONS — which are parsed out and stored as an `audit_report` row linked to that anomaly.

If `ANTHROPIC_API_KEY` is not set, a deterministic template built from the same data is used instead. The dashboard, anomaly detail, and alert email all work identically either way.

---

## 11. Architecture in one diagram

```
Browser (LiveView, auto-updates) ─── http://localhost:4000
              │
              │ button click → Phoenix spawns background Task
              ▼
    AnalysisPipeline.run_detection_scan()
              │
              ├─ Procurement.list_projects/list_expenditures  (Postgres)
              │
              ├─ HTTP POST :5000/api/v1/anomalies/detect
              │      └─ Isolation Forest + rule classification (Python)
              │
              ├─ Audit.record_anomaly  ──► PubSub broadcast → dashboard updates live
              │
              └─ for each HIGH-RISK anomaly:
                     ├─ HTTP POST :5000/api/v1/audit-reports/generate  (Claude API)
                     ├─ Audit.attach_report
                     └─ Notifications.Dispatcher.dispatch
                            └─ Accounts.list_alert_recipients (live DB query)
                                   └─ Swoosh SMTP → Gmail → real inbox
```

---

## 12. Technology stack

| Component | Technology | Purpose |
|---|---|---|
| Web service | Elixir / Phoenix | Real-time web, routing, database, email |
| Real-time UI | Phoenix LiveView + PubSub | Dashboard updates without page refresh |
| Database | PostgreSQL via Ecto | All persistence |
| Email delivery | Swoosh + Gmail SMTP | Real alert and invite delivery |
| AI microservice | Python / Flask | Isolation Forest + Claude integration |
| ML anomaly detection | scikit-learn IsolationForest | Unsupervised fraud scoring |
| Audit report generation | Anthropic Claude API | Structured, context-aware audit text |
| Containerisation | Docker Compose | Single command startup |

---

## 13. Running the system

Everything runs via Docker Compose from the project root:

```bash
docker compose up -d          # start all services
docker compose logs web -f    # watch logs
docker compose down           # stop everything
```

All three services must be healthy before the system works:
- `postgres` — database, port 5433 on the host
- `ai_service` — Python Flask + Isolation Forest, port 5000
- `web` — Phoenix release, port 4000

After any code change, rebuild and redeploy with:

```bash
docker compose build web
docker compose up -d web
```

---

## 14. Further reading

| Document | What it covers |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Microservice split, bounded contexts, ports-and-adapters pattern |
| [docs/DETECTION_SCAN.md](docs/DETECTION_SCAN.md) | Step-by-step trace of what "Run Detection Scan" does in the background |
| [docs/ALERTS.md](docs/ALERTS.md) | How alert dispatch, ministry scoping, SMTP, and retry work |
| [docs/FRAUD_PATTERNS.md](docs/FRAUD_PATTERNS.md) | The five fraud types the model detects and how each is scored |
| [docs/DATABASE.md](docs/DATABASE.md) | Full schema — every table and its purpose |
| [docs/API.md](docs/API.md) | Python microservice API reference |
| [BudgetSentinel_User_Journey.md](BudgetSentinel_User_Journey.md) | Every screen and role capability from a user's perspective |
| [DEMO_SAMPLE_DATA.md](DEMO_SAMPLE_DATA.md) | Exact field values to enter live during a demo |
