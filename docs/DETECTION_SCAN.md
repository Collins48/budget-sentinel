# What "Run Detection Scan" does in the background

This is a step-by-step trace of everything that happens, in order, from the moment an admin or auditor clicks **Run Detection Scan** on the dashboard (`/`) to the moment the UI settles back to its idle state. Every step links to the actual code, not a simplified description of it.

---

## 0. Who can trigger it, and what it scans

- Gated by `User.can_manage?/1` — only `admin` and `auditor` roles see the button; oversight officers don't ([dashboard_live.ex:64](../web/lib/budget_sentinel_web/live/dashboard_live.ex#L64)).
- The scan is **not scoped to the clicking user's ministry**. It always loads every project and every expenditure in the system ([analysis_pipeline.ex:16-17](../web/lib/budget_sentinel/intelligence/analysis_pipeline.ex#L16-L17)). Ministry scoping happens later, only at the alert-recipient stage (step 6) — the detection model itself sees the whole dataset, because fraud patterns like duplicate payments can span ministries.

---

## Step 1 — Click fires a background task, not a request/response

[`dashboard_live.ex:17-26`](../web/lib/budget_sentinel_web/live/dashboard_live.ex#L17-L26)

```elixir
def handle_event("run_scan", _params, socket) do
  if User.can_manage?(socket.assigns.current_user) do
    Task.Supervisor.start_child(BudgetSentinel.TaskSupervisor, fn ->
      AnalysisPipeline.run_detection_scan()
    end)
    {:noreply, assign(socket, scanning: true)}
  ...
```

The pipeline runs on its own supervised process, completely detached from the LiveView socket that triggered it. This matters for two reasons:

- The button flips to "Scanning…" instantly — the click handler returns in microseconds, it doesn't wait for the scan.
- If the scan crashes, it crashes its own task; it can't take down the user's LiveView session. `Task.Supervisor` (started in the application tree) restarts/cleans up the child, it doesn't restart the scan itself — a crash just means no completion broadcast ever fires, and the button stays on "Scanning…" until the page is reloaded. There's no built-in retry or timeout watchdog on the overall pipeline (see [Failure modes](#failure-modes) below).

---

## Step 2 — Load and serialize the entire dataset

[`analysis_pipeline.ex:16-20`](../web/lib/budget_sentinel/intelligence/analysis_pipeline.ex#L16-L20)

```elixir
projects = Procurement.list_projects()
expenditures = Procurement.list_expenditures()
project_payloads = Enum.map(projects, &project_payload/1)
expenditure_payloads = Enum.map(expenditures, &expenditure_payload/1)
```

Every project and expenditure is pulled from Postgres in full (no pagination, no date filtering) and converted into plain maps — id, sector, approved budget, completion rate, market benchmark for projects; id, project_id, contractor, amount, milestone, paid-on date for expenditures. This is the entire payload the ML model will see. At the seeded demo scale (50 projects / ~200 expenditures) this is instant; it is **not** designed to paginate or stream for a much larger real dataset.

---

## Step 3 — One HTTP round-trip to the Python AI service

[`http_ai_client.ex:10-16`](../web/lib/budget_sentinel/intelligence/http_ai_client.ex#L10-L16) → `POST {AI_SERVICE_URL}/api/v1/anomalies/detect`, 15-second timeout, via `Req`.

Inside the Flask service, for **every** expenditure (not just new ones — the whole dataset is re-scored on every scan):

1. **Feature engineering** — 6 numbers per expenditure: cumulative budget-utilization ratio, this-payment-as-fraction-of-budget, gap between payment% and reported completion%, prior-payment count for the same contractor+milestone, ratio to market benchmark, and a zero-completion-but-paid flag.
2. **Isolation Forest** scores how statistically isolated that feature vector is versus the rest of the dataset (unsupervised — no labels, no Claude).
3. **Rule-based classification** on the same 6 features assigns a fraud type (duplicate payment / ghost project / premature payment / inflated contract / budget overrun) and a "rule strength."
4. **Combined risk score** = `50% Isolation Forest anomaly score + 50% rule strength`, 0–100. Severity is just a threshold (`≥70` high, `≥40` medium, else low).
5. Expenditures that come out classified `"normal"` are dropped entirely — only actual anomalies are returned in the response.

This step is a single synchronous HTTP call from Elixir's point of view — Elixir blocks (inside the background task, not the UI) until the AI service responds or the 15s timeout fires.

---

## Step 4 — Persist each anomaly, broadcasting as it goes

[`analysis_pipeline.ex:22-26`](../web/lib/budget_sentinel/intelligence/analysis_pipeline.ex#L22-L26) and [`analysis_pipeline.ex:30-52`](../web/lib/budget_sentinel/intelligence/analysis_pipeline.ex#L30-L52)

For each anomaly the AI service returned:

```elixir
case Audit.record_anomaly(attrs) do
  {:ok, anomaly} ->
    broadcast({:anomaly_detected, anomaly})
    [Audit.get_anomaly!(anomaly.id)]
  {:error, _changeset} -> []
end
```

Each successful insert immediately broadcasts `{:anomaly_detected, anomaly}` over Phoenix PubSub on the `"anomalies:lobby"` topic — **before** the loop moves to the next anomaly. This is why, during a scan, anomalies appear on the dashboard one at a time rather than all at once when the scan finishes. Every browser tab subscribed to that topic (every connected dashboard, from any logged-in user) receives the same broadcast simultaneously — this is a global event bus, not a per-user channel.

Anomalies that fail to insert (changeset error) are silently dropped from the result list — there's no surfaced error to the user for a single bad row.

---

## Step 5 — High-risk anomalies get a second AI call: a Claude-written audit report

[`analysis_pipeline.ex:54-66`](../web/lib/budget_sentinel/intelligence/analysis_pipeline.ex#L54-L66)

```elixir
defp handle_high_risk(%Anomaly{} = anomaly) do
  if Audit.high_risk?(anomaly) do
    project = Procurement.get_project!(anomaly.project_id)
    expenditure = ...
    with {:ok, report_body} <- ai_client().generate_report(...),
         {:ok, report} <- Audit.attach_report(anomaly, report_body) do
      broadcast({:report_generated, anomaly.id, report})
      Notifications.Dispatcher.dispatch(anomaly, report, project)
    end
  end
end
```

`Audit.high_risk?/1` checks the anomaly's risk score against `:high_risk_threshold` (config default `70.0`). For each one that qualifies:

1. A **second**, separate HTTP call goes to `/api/v1/audit-reports/generate` with the anomaly, project, and expenditure context.
2. On the Python side, if `ANTHROPIC_API_KEY` is configured, this prompts Claude (system prompt: "You are a public financial audit analyst…") and parses the SUMMARY / SEVERITY ASSESSMENT / RECOMMENDED ACTIONS sections out of the response. If no API key is set, it returns a deterministic templated report built from the same data instead — the pipeline doesn't know or care which one it got, the shape of the response is identical either way.
3. The report is saved via `Audit.attach_report/2` and broadcast as `{:report_generated, anomaly.id, report}`.
4. **Only then** does alert dispatch happen (step 6) — low/medium-severity anomalies never reach `Notifications.Dispatcher` at all; they're recorded but nobody is emailed about them.

If the AI call or the report insert fails, the `with` simply doesn't match and **silently skips both the report and the alert dispatch** for that anomaly — no error surfaces, no retry. The anomaly itself is still saved from step 4.

---

## Step 6 — Alert dispatch: real, ministry-scoped emails

[`dispatcher.ex:14-29`](../web/lib/budget_sentinel/notifications/dispatcher.ex#L14-L29)

```elixir
def dispatch(anomaly, report, project) do
  recipients = Accounts.list_alert_recipients(project.ministry_id)
  Enum.each(recipients, fn recipient ->
    email = AlertEmail.high_risk_alert(anomaly, report, recipient)
    try do
      case Mailer.deliver(email) do
        {:ok, _} -> Audit.log_alert(anomaly, recipient, "sent")
        {:error, _} -> Audit.log_alert(anomaly, recipient, "failed")
      end
    rescue
      _ -> Audit.log_alert(anomaly, recipient, "failed")
    end
  end)
end
```

`Accounts.list_alert_recipients/1` is a live query, not a hardcoded list: every `admin` account (all ministries) **plus** every `auditor`/`oversight_officer` whose `ministry_id` matches the anomaly's project. This is the same query whether the recipient was a seeded account or an account that accepted an invite five minutes ago — adding a new oversight officer to a ministry makes them eligible for that ministry's very next scan, no code change needed.

Each recipient gets their **own** email and their **own** `Alert` row, sent one at a time, sequentially (not concurrently) — for a project with 5 eligible recipients, that's 5 separate `Mailer.deliver/1` calls inside this one `Enum.each`. A delivery failure (SMTP down, bad address, anything raising) is caught per-recipient by the `try/rescue` and logged as `"failed"` rather than aborting the rest of the loop — one bad address can't block alerts to everyone else. Failed alerts show up on `/alerts` with a **Retry** button, which re-invokes `Dispatcher.retry/1` for just that one row.

---

## Step 7 — Scan completes, UI settles

[`analysis_pipeline.ex:25`](../web/lib/budget_sentinel/intelligence/analysis_pipeline.ex#L25) broadcasts `{:scan_completed, count}` once every anomaly has been processed (persisted, possibly reported, possibly alerted).

[`dashboard_live.ex:30-31`](../web/lib/budget_sentinel_web/live/dashboard_live.ex#L30-L31):

```elixir
def handle_info({:scan_completed, _count}, socket) do
  {:noreply, assign_dashboard_data(socket, scanning: false)}
end
```

This flips the button back from "Scanning…" to "Run Detection Scan" and re-queries the dashboard's stats (project list, anomaly list, high-risk-open count, failed-alert count) fresh from the database — for **every** connected dashboard, not just the one that clicked the button, since the broadcast is global.

---

## Sequence at a glance

```
Browser click ──▶ DashboardLive.handle_event("run_scan")
                       │
                       ▼ (spawned Task, detached from socket)
                  AnalysisPipeline.run_detection_scan()
                       │
                       ├─▶ Procurement.list_projects/list_expenditures (Postgres read)
                       │
                       ├─▶ HTTP POST ai_service:5000/api/v1/anomalies/detect
                       │      (Isolation Forest + rule classification, no Claude)
                       │
                       ├─▶ for each anomaly: Audit.record_anomaly
                       │      └─▶ PubSub broadcast {:anomaly_detected, anomaly}  ──▶ every dashboard updates live
                       │
                       ├─▶ for each HIGH-RISK anomaly:
                       │      ├─▶ HTTP POST ai_service:5000/api/v1/audit-reports/generate (Claude, or fallback template)
                       │      ├─▶ Audit.attach_report
                       │      │      └─▶ PubSub broadcast {:report_generated, ...}
                       │      └─▶ Notifications.Dispatcher.dispatch
                       │             └─▶ for each ministry-scoped recipient: Swoosh email + Audit.log_alert("sent"/"failed")
                       │
                       └─▶ PubSub broadcast {:scan_completed, count} ──▶ every dashboard exits "Scanning…"
```

---

## Failure modes

| What fails | What actually happens |
|---|---|
| AI service unreachable / times out (>15s) | `run_detection_scan/0` returns `{:error, reason}` from the `with`. **No `{:scan_completed, ...}` is ever broadcast** — the button stays stuck on "Scanning…" for that session until the page is reloaded. No anomalies are persisted for this run. |
| AI service returns malformed/unexpected JSON | Same as above — `{:error, {:unexpected_response, body}}`, scan silently halts before persisting anything. |
| One anomaly's insert fails (changeset error) | That anomaly is dropped; the loop continues with the rest. No error shown to the user. |
| Claude API call fails for a high-risk anomaly | The `with` in `handle_high_risk/1` doesn't match; no report is attached and **no alert is dispatched** for that anomaly. The anomaly itself remains saved from step 4, just without a report. |
| No `ANTHROPIC_API_KEY` configured | Not a failure — the Python service deterministically returns a templated report instead of calling Claude. The pipeline behaves identically either way. |
| Email delivery fails for one recipient | Caught per-recipient; logged as a `"failed"` `Alert` row; every other recipient still gets their email. Retryable from `/alerts`. |
| Browser tab open during a scan that started before it connected | `connected?(socket)` subscribes to the PubSub topic on mount ([dashboard_live.ex:9-10](../web/lib/budget_sentinel_web/live/dashboard_live.ex#L9-L10)), so a tab opened mid-scan only sees broadcasts from that point forward — it won't show "Scanning…" for a scan it didn't see start, and won't retroactively render anomalies detected before it connected (those just appear via the normal `assign_dashboard_data` query on next mount/refresh). |

---

## Things worth knowing for a real deployment

- **No rate limiting / concurrency guard**: nothing stops two admins from clicking "Run Detection Scan" at the same time, or one admin double-clicking before the button disables. Two scans would run concurrently, each independently re-scoring the whole dataset and potentially double-inserting overlapping anomalies.
- **Full re-scan every time**: there's no "only score new expenditures since last scan" — every expenditure is sent and re-scored on every run. Fine at demo scale; would need incremental scoping for a large, continuously-growing dataset.
- **No scan history/audit trail of the scan itself**: individual anomalies and alerts are recorded, but there's no `scans` table recording who ran a scan, when, or how many anomalies it found in aggregate — that's reconstructable from anomaly `detected_at` timestamps clustering together, but isn't an explicit record.
