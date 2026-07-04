# BudgetSentinel — User Journey & Feature Guide

This is the single reference for navigating BudgetSentinel end to end: what each role can do, every screen in the system, and how the platform fulfills the six objectives in `BudgetSentinel_Proposal.md`.

BudgetSentinel monitors government project expenditures, runs machine-learning anomaly detection against them, generates AI audit reports for high-risk findings, and routes real alerts to the right people — scoped by ministry, gated by role.

---

## 1. Getting in

There is no public sign-up. Every real account is provisioned by an admin **inviting** a person by email — the admin never sets or sees that person's password.

**Invite flow:**

1. Admin opens `/admin/users` → **Invite Account** → enters the person's email, role (Admin / Auditor / Oversight Officer), and ministry (left blank for admins, who see everything).
2. BudgetSentinel creates the account in an `invited` state — no password, not yet usable — and emails the recipient a secure, single-use, 14-day link.
3. The recipient opens the link (`/users/invite/:token`), which shows them the exact role and ministry they're being onboarded into, then sets their own password.
4. Setting the password activates (`confirmed_at`) and the account flips from `invited` to `active`. The token is consumed and cannot be reused.
5. If the link expires or the email never arrives, the admin clicks **Resend invite** next to that account on `/admin/users` — this invalidates the old token and sends a fresh one.

`/admin/users` always shows each account's status (**Invited** / **Active**) and who invited them, so admins can see at a glance who hasn't onboarded yet.

For this demo environment, seeded accounts are pre-activated with a known password (`ChangeMe123456!`) so you can log in immediately without running the invite flow first:

| Account | Role | Ministry |
|---|---|---|
| `admin@budgetsentinel.local` | Admin | All (unrestricted) |
| `auditor.mininfra@budgetsentinel.local` | Auditor | Ministry of Infrastructure |
| `oversight.mininfra@budgetsentinel.local` | Oversight Officer | Ministry of Infrastructure |
| `auditor.mineduc@budgetsentinel.local` | Auditor | Ministry of Education |
| `oversight.mineduc@budgetsentinel.local` | Oversight Officer | Ministry of Education |
| `auditor.minisante@budgetsentinel.local` | Auditor | Ministry of Health |
| `oversight.minisante@budgetsentinel.local` | Oversight Officer | Ministry of Health |
| `auditor.miniwasa@budgetsentinel.local` | Auditor | Ministry of Water and Sanitation |
| `oversight.miniwasa@budgetsentinel.local` | Oversight Officer | Ministry of Water and Sanitation |
| `auditor.minenergy@budgetsentinel.local` | Auditor | Ministry of Energy |
| `oversight.minenergy@budgetsentinel.local` | Oversight Officer | Ministry of Energy |

Log in at `/users/log_in`. Visiting any page while logged out redirects you there automatically.

---

## 2. Roles, at a glance

| Capability | Admin | Auditor | Oversight Officer |
|---|---|---|---|
| See all ministries | ✅ | ❌ (own ministry only) | ❌ (own ministry only) |
| View dashboard, projects, anomalies, alerts | ✅ | ✅ | ✅ |
| Create / edit / delete projects & expenditures | ✅ | ✅ | ❌ view-only |
| Run a detection scan | ✅ | ✅ | ❌ |
| Action anomalies (status, notes) | ✅ | ✅ | ❌ view-only |
| Retry a failed alert | ✅ | ✅ | ❌ view-only |
| Create user accounts (`/admin/users`) | ✅ | ❌ | ❌ |

An **oversight officer** is the read-only accountability layer the proposal describes: they see exactly what's happening in their ministry, in real time, without being able to alter the record.

An **auditor** is the operational role: they maintain project/expenditure data, trigger scans, and work anomalies through to resolution.

An **admin** runs the platform: every ministry, plus user provisioning.

---

## 3. The Dashboard (`/`)

The first thing everyone sees after logging in. It is the real-time situational overview Phoenix LiveView is built for — it updates live via PubSub the moment a scan finds something, with no page refresh.

- **Stat row**: Monitored Projects, Anomalies (recent), High-Risk Open (high-severity anomalies still `open`/`under_review` — drops automatically as auditors resolve them), Failed Alerts.
- **Run Detection Scan** button (admin/auditor only) — kicks off the full pipeline: pulls every visible project + expenditure, sends it to the Python AI microservice, persists results, generates audit reports for high-risk findings, and dispatches alerts. The button shows "Scanning…" until `PubSub` broadcasts completion.
- **Project Budget Health** — top 6 projects with a budget-utilization bar.
- **Recent Anomalies** — last 10 detected, with risk badge and fraud type.
- **Recent Alerts** — last 5 dispatched alerts, with a link to the full Alerts Center.

Everything on this page is scoped: an oversight officer only ever sees their own ministry's numbers.

---

## 4. Projects (`/projects`)

The system of record for government projects and their expenditures.

- **List** (`/projects`): every visible project, sector, ministry, approved budget, completion %, and a budget-utilization bar. Admins/auditors get a **New Project** button.
- **New / Edit** (`/projects/new`, `/projects/:id/edit`): modal form — name, sector, ministry, approved budget, market benchmark, completion rate. Read-only for oversight officers (the route redirects them back with a flash if they try).
- **Show** (`/projects/:id`): full project detail, ministry, budget stats, and the expenditure ledger.
  - **Add Expenditure** / **Edit** / **Delete** per row (admin/auditor only) — contractor, amount, milestone, date paid. This is the raw data the anomaly model analyzes.
  - **Edit** / **Delete** the project itself (admin/auditor only, with a confirmation prompt on delete).

This satisfies objective 1 — ingesting and tracking expenditure data against approved budgets and milestones.

---

## 5. Anomalies (`/anomalies`)

Every anomaly the Isolation Forest model has ever flagged, with filter tabs: **All / Open / Under Review / Resolved / Dismissed**.

- **List**: project, fraud type (budget overrun, duplicate payment, ghost project, inflated contract, premature payment), risk badge, status pill, whether an AI audit report exists, and when it was detected.
- **Show** (`/anomalies/:id`):
  - **Detection Details** — project, fraud type, contractor, amount, explanation.
  - **AI-Generated Audit Report** — the Claude-generated summary, severity assessment, and recommended corrective action for high-risk anomalies.
  - **Audit Review** — the status workflow. Admins/auditors set status (`open → under_review → resolved/dismissed`) and attach resolution notes; the system records who reviewed it and when. This is what turns a static fraud-detection log into an actual audit workflow — an anomaly isn't "handled" until someone closes it out.
  - **Alert Dispatch History** — who was alerted about this specific anomaly and whether it sent successfully.

This satisfies objectives 2, 3, and 6 — ML-based fraud detection, AI-generated audit reports, and a record you can evaluate against known fraud scenarios.

---

## 6. Alerts Center (`/alerts`)

The feature this build closes the gap on: alerts are no longer just a row buried in an anomaly page — they're a first-class, ministry-scoped screen.

- **Filter tabs**: All / Sent / Failed / Pending.
- **Table**: recipient, project (linked to the anomaly), fraud type, status badge, dispatched-at timestamp.
- **Retry** (admin/auditor only): if an alert failed to send (e.g. SMTP was down), retry it in place — no need to re-run the whole scan.

**Who actually gets alerted, and why it's real:** when a scan finds a high-risk anomaly, BudgetSentinel looks up every **admin** account plus every **auditor/oversight officer assigned to that project's ministry** and emails each of them — not a static hardcoded list. Add a new oversight officer to a ministry via `/admin/users`, and they start receiving that ministry's alerts on the very next scan.

This satisfies objective 5 — automated alerts to designated oversight officers on high-risk detection, and is the proposal's `alerts` table made visible and operable.

---

## 7. User Management (`/admin/users` — admin only)

- **List**: every account, role, ministry, status (**Invited** / **Active**), who invited them, and date created.
- **Invite Account**: email, role, and ministry (left blank for admins, who see everything). No password field — the admin sends an invitation, the recipient sets their own password by accepting it.
- **Resend invite**: shown next to any account still in `Invited` status — invalidates the old link and sends a new one. Useful if the email bounced, was missed, or the 14-day link expired.

This is how you onboard a real auditor or oversight officer for a new ministry, or add a second admin — by inviting their real email address into a specific role and ministry, not by handing them a password.

---

## 7a. My Profile (`/users/profile` — every authenticated user)

A read-only view of your own account: email, role, ministry scope, what your role is permitted to do, account status, who invited you, and your member-since date. Linked from the account menu in the header next to **Settings**. Email and password changes still happen at `/users/settings`.

---

## 8. A full operational walkthrough

1. **Admin** logs in, invites a ministry's auditor and oversight-officer by email (`/admin/users` → Invite Account), assigning each a role and that ministry.
2. **Auditor**/**oversight officer** receives the invite email, opens the link, and sets their own password — the account activates and they land on `/users/log_in`.
3. **Auditor** logs in, adds a project for their ministry (`/projects/new`) and records its expenditures as payments go out (`/projects/:id` → Add Expenditure).
4. **Auditor** (or admin) clicks **Run Detection Scan** on the dashboard. The pipeline:
   - Sends every project + expenditure to the Python AI microservice.
   - The Isolation Forest model scores each expenditure and classifies fraud type/severity.
   - High-risk findings get a Claude-generated audit report attached.
   - Alerts are dispatched to every admin and to that project's ministry's auditors/oversight officers.
   - The dashboard updates live — no refresh — via PubSub.
5. **Oversight officer** for that ministry sees the new anomaly on their (ministry-scoped) dashboard and in their inbox/Alerts Center.
6. **Auditor** opens the anomaly, reads the AI audit report, investigates, and sets its status to `under_review` with a note, then later to `resolved` or `dismissed` once it's been actioned.
7. The dashboard's **High-Risk Open** count drops, reflecting that the case is closed — not just detected.

---

## 9. Proposal objectives → where they live

| # | Objective | Implementation |
|---|---|---|
| 1 | Ingest and track expenditure data against approved budgets/milestones | `/projects`, `/projects/:id` (project + expenditure CRUD), `Procurement` context |
| 2 | ML-based anomaly detection (fraud, duplicates, inflated contracts, spikes) | Python `ai_service` — `IsolationForest` model, `/anomalies` |
| 3 | LLM-generated, context-aware audit reports with corrective actions | Claude API integration in `ai_service`, shown on `/anomalies/:id` |
| 4 | Real-time LiveView dashboard, no manual refresh | `/` — Phoenix LiveView + PubSub broadcasts on scan completion |
| 5 | Automated alerts to designated oversight officers on high-risk detection | `/alerts` — ministry-routed `Notifications.Dispatcher`, real `users` table recipients |
| 6 | Evaluate detection accuracy against known embedded fraud scenarios | Seed dataset embeds 10 fraud scenarios across 5 types; `/anomalies` history is the evaluation record |

---

## Notes for running this for real

- **Email delivery**: alerts and invitations are dispatched through Swoosh. In this environment it uses the `Local` adapter (captured in-memory, not actually sent) unless `SMTP_RELAY` is set as an env var on the `web` service — set that plus `SMTP_USERNAME`/`SMTP_PASSWORD` to have invitations and alerts actually land in inboxes.
- **Bootstrap admin password**: change `admin@budgetsentinel.local`'s password via `/users/settings` immediately in any real deployment — `ChangeMe123456!` is a seed default, not a production credential. Every other real account should be created via **Invite Account**, never by sharing a password.
- **Invite link expiry**: invitation links are valid for 14 days; an admin can always issue a fresh one with **Resend invite** on `/admin/users`.
