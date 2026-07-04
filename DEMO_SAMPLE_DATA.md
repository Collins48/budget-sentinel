# Demo sample data — live walkthrough script

This is the exact data to type into the UI during the demo to take a fraud case from **zero → detected → AI audit report → real email alert**, plus how to add an expenditure to an existing project. Every number here was verified against the running system before writing this doc — this scenario reliably scores **95.95/100, "high" severity**.

## Accounts for the demo

| Email | Password | Role | Ministry |
|---|---|---|---|
| `kiplimocollins855@gmail.com` | `ChangeMe123456!` | Admin | All ministries |
| `limokcollins@gmail.com` | `ChangeMe123456!` | Auditor | Ministry of Water and Sanitation |

Both are real addresses — alerts triggered during the demo will actually arrive in these inboxes.

---

## Step 1 — Log in

Go to `http://localhost:4000/users/log_in`, log in as `kiplimocollins855@gmail.com` (Admin) so you can create projects/expenditures and run the scan.

---

## Step 2 — Create the project (`/projects` → New Project)

| Field | Value |
|---|---|
| Name | `Kigali-Huye Highway Rehabilitation (Demo)` |
| Sector | `Infrastructure` |
| Ministry | `Ministry of Infrastructure` |
| Approved Budget | `80000000` |
| Market Benchmark | `80000000` |
| Completion Rate (%) | `0` |

This is the setup for a **ghost project** scenario: a project that officially has made **zero progress**.

---

## Step 3 — Add the expenditure (project page → Add Expenditure)

| Field | Value |
|---|---|
| Contractor | `Horizon Construction Ltd` |
| Amount | `72000000` |
| Milestone | `Phase 1 - Earthworks` |
| Paid On | today's date |

You've just recorded a payment of **72,000,000** — 90% of the entire approved budget — against a project that reports **0% completion**. That's the story to narrate live: "the books say nothing has been built, but 90% of the money is already gone."

---

## Step 4 — Run Detection Scan (dashboard `/`)

Click **Run Detection Scan**. Narrate while it runs: the data goes to the Python AI service, the Isolation Forest model flags the payment as a statistical outlier, and the rule engine classifies it specifically as a **ghost project** (full payment, zero reported completion).

Verified result for this exact data: **risk score ≈ 96/100, severity High** — which crosses the 70-point high-risk threshold, so it will automatically:
1. Get a Claude-written (or fallback-templated) audit report attached.
2. Trigger a real email alert.

---

## Step 5 — Show the anomaly (`/anomalies`)

Click into the new anomaly. Show:
- **Detection Details** — fraud type `ghost_project`, contractor, amount, explanation: *"Full payment was disbursed against a project reporting zero completion."*
- **AI-Generated Audit Report** — summary / severity assessment / recommended actions.
- **Audit Review** — set status to `under_review` with a note, to show the workflow isn't just detection, it's an actual case you can work and close out.

---

## Step 6 — Show the alert (`/alerts`)

Because this project is under **Ministry of Infrastructure**, and the only admin account (`kiplimocollins855@gmail.com`) has no ministry restriction, the alert is dispatched to the admin. Show the row: **Sent**, linked back to the anomaly.

> Note: `limokcollins@gmail.com` is scoped to **Ministry of Water and Sanitation**, not Infrastructure — they will *not* receive this specific alert. That's the ministry-scoping feature working correctly, and is worth narrating explicitly: "an auditor only gets paged for anomalies in their own ministry."

---

## Step 7 — Show the real email

Check `kiplimocollins855@gmail.com`'s inbox. Subject: `[BudgetSentinel] High-risk anomaly detected: ghost project`. This is the actual proof point — not a screenshot, a real email that really arrived, with the audit report content in the body.

---

## Optional bonus scenario — Duplicate Payment (quick, but only "Medium" severity — won't email)

If you have extra time and want to show a second fraud type without leaving the same project flow, add a *second* expenditure to **any existing project** with the exact same contractor and milestone as one already recorded, then run the scan again. This verified at **risk score ~60/100, severity Medium** — it will show up on `/anomalies` as a `duplicate_payment` finding, but **will not** cross the high-risk threshold or send an email. Use it to show the system catches more than one fraud pattern, but be clear it's a lower-severity example, not a second emailed alert.

---

## Cleanup after the demo (optional)

If you want to remove the demo project afterward so the dataset returns to its original seeded state, delete it from `/projects/:id` (Edit → Delete) as the admin — this cascades to its expenditure, anomaly, audit report, and alert automatically.
