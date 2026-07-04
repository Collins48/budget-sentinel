# How anomaly-detection alerts work

This documents the alert/notification system end to end: what triggers an alert, who receives it, how delivery is tracked, and how to verify it's actually working. For how the detection scan that triggers all of this works, see [DETECTION_SCAN.md](DETECTION_SCAN.md).

---

## 1. What triggers an alert

Not every anomaly sends an email — only **high-risk** ones.

[`audit.ex` — `high_risk?/1`](../web/lib/budget_sentinel/audit.ex#L173-L176):

```elixir
def high_risk?(%Anomaly{risk_score: risk_score}) do
  threshold = Application.get_env(:budget_sentinel, :high_risk_threshold, 70.0)
  Decimal.compare(risk_score, Decimal.from_float(threshold * 1.0)) != :lt
end
```

Default threshold is **70 / 100** (configurable via the `:high_risk_threshold` app env, see `config.exs`). Anomalies scored below that are still recorded and visible on `/anomalies`, but nobody is emailed about them — they're left for an auditor to find during routine review rather than paged about immediately.

This check happens inside [`AnalysisPipeline.handle_high_risk/1`](../web/lib/budget_sentinel/intelligence/analysis_pipeline.ex#L54-L66), called once per anomaly right after it's persisted during a detection scan. A low/medium anomaly never reaches the alert code at all.

---

## 2. Who receives it — ministry-scoped, computed live

[`accounts.ex` — `list_alert_recipients/1`](../web/lib/budget_sentinel/accounts.ex):

```elixir
def list_alert_recipients(ministry_id) do
  User
  |> where([u], u.role == "admin" or u.ministry_id == ^ministry_id)
  |> select([u], u.email)
  |> Repo.all()
end
```

This is a **live query against the `users` table**, not a hardcoded list or a static config value:

- Every `admin` account, regardless of ministry (admins see everything).
- Every `auditor` or `oversight_officer` whose `ministry_id` matches the **anomaly's project's ministry** — not the ministry of whoever ran the scan.

Practical effect: invite a new oversight officer into a ministry today via `/admin/users`, and the moment they accept the invite, they're in this query's result set for that ministry's *next* scan — no redeploy, no config change. Conversely, an auditor for a different ministry never sees or gets emailed about anomalies outside their scope.

---

## 3. Building and sending the email

[`Notifications.Dispatcher.dispatch/3`](../web/lib/budget_sentinel/notifications/dispatcher.ex#L14-L29):

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

Key behaviors:

- **One email per recipient**, sent sequentially in a loop — a project with 5 eligible recipients means 5 separate SMTP transactions, not one email with 5 `To:` addresses.
- **One `Alert` database row per recipient**, logged immediately after each send attempt — this is what populates `/alerts`.
- **Failure isolation**: the `try/rescue` means a crash or SMTP error for one recipient (bad address, connection drop) is caught and logged as `"failed"` without aborting the loop — every other recipient still gets their attempt.
- The email itself ([`AlertEmail.high_risk_alert/3`](../web/lib/budget_sentinel/notifications/alert_email.ex)) is a plain-text message: subject `[BudgetSentinel] High-risk anomaly detected: <fraud type>`, body containing the fraud type, risk score, and the three sections of the attached audit report (summary / severity assessment / recommended actions — either Claude-written or the deterministic fallback, see [DETECTION_SCAN.md](DETECTION_SCAN.md#step-5--high-risk-anomalies-get-a-second-ai-call-a-claude-written-audit-report)).

---

## 4. Where it's visible: the Alerts Center (`/alerts`)

[`AlertLive.Index`](../web/lib/budget_sentinel_web/live/alert_live/index.ex):

- **Filter tabs**: All / Sent / Failed / Pending — backed by the `status` column on the `alerts` table.
- **Ministry-scoped list**: `Audit.list_alerts/2` shows admins every alert; auditors/oversight officers only see alerts tied to their own ministry's projects (same scoping pattern as recipient selection).
- **Retry** (admin/auditor only): visible only on rows with `status == "failed"`. Clicking it calls `Notifications.Dispatcher.retry/1`, which re-sends to that *one* recipient using the anomaly's already-attached audit report, and flips that row's status to `"sent"` or leaves it `"failed"` again — without re-running the whole scan or re-emailing anyone else.

---

## 5. Email delivery configuration — what actually sends the email

The mailer adapter is environment-driven, configured in [`config/runtime.exs`](../web/config/runtime.exs):

| Environment | Adapter | What actually happens |
|---|---|---|
| No `SMTP_RELAY` set | `Swoosh.Adapters.Local` | Email is built and "delivered" successfully from the app's point of view (`Audit.log_alert(..., "sent")` still fires), but it only goes into an **in-memory mailbox inside the running container** — nothing leaves the server. Useful for tests and for confirming the alert *logic* fired without needing real credentials, but invisible to an actual inbox. |
| `SMTP_RELAY`, `SMTP_USERNAME`, `SMTP_PASSWORD` set | `Swoosh.Adapters.SMTP` (via `gen_smtp`) | A real SMTP connection is made on port 587 (configurable via `SMTP_PORT`) with STARTTLS (`tls: :always`) and auth. `tls_options: [verify: :verify_none]` is set to tolerate test SMTP providers (like Ethereal) whose certificate chain isn't in every CA bundle — for a production provider with a properly chained cert this is harmless but not required. |

**This determines whether `"sent"` in the `alerts` table means "actually left the building" or "captured in memory and discarded on container restart."** The status column can't distinguish these — `Audit.log_alert` only knows whether the configured adapter's `deliver/1` call itself returned `{:ok, _}` or `{:error, _}`, and the Local adapter always returns `{:ok, _}`.

`docker-compose.yml` passes these through from a `.env` file (not committed — see `.env.example`) so real credentials never touch source control.

---

## 6. How to verify alerts are really being delivered (not just logged)

Because `"sent"` in the UI doesn't distinguish Local from real SMTP, verifying actual delivery requires checking the configured provider directly:

1. Confirm the active adapter: `Application.get_env(:budget_sentinel, BudgetSentinel.Notifications.Mailer)` should show `Swoosh.Adapters.SMTP` with your relay, not `Swoosh.Adapters.Local`.
2. Trigger a real high-risk anomaly alert — either run a full detection scan, or call `Notifications.Dispatcher.dispatch/3` directly for an existing anomaly (same function the pipeline uses, so this is not a separate code path).
3. Check the `/alerts` page for the expected recipient(s) with `"Sent"` status.
4. Check the **actual mail provider** — your real inbox for a provider like Gmail, or the provider's web viewer for a test service like Ethereal (`https://ethereal.email/login` with the configured `SMTP_USERNAME`/`SMTP_PASSWORD`) — and confirm the message subject/body match what `AlertEmail.high_risk_alert/3` builds.

A `"sent"` row with no corresponding message in the provider almost always means the adapter is still `Local` (no `SMTP_RELAY` configured) rather than an application bug.

---

## 7. Failure modes specific to alerting

| Scenario | Behavior |
|---|---|
| SMTP relay unreachable / auth fails | `Mailer.deliver/1` returns `{:error, reason}` (or raises, caught by `rescue`) → `Audit.log_alert(anomaly, recipient, "failed")`. Visible on `/alerts` with a **Retry** button. The anomaly and its report are still saved regardless. |
| `list_alert_recipients/1` returns an empty list (no admin, no ministry staff assigned yet) | `Enum.each` simply does nothing — zero alerts, zero rows logged, no error. A high-risk anomaly can exist with no alert history at all if a ministry has no provisioned staff yet. |
| Anomaly has no attached audit report when `Retry` is clicked | [`Dispatcher.retry/1`](../web/lib/budget_sentinel/notifications/dispatcher.ex#L32-L51) checks `anomaly.audit_report` first — if `nil`, it marks the alert `"failed"` again without attempting to send, rather than emailing a report-less message. |
| TLS certificate not trusted by the container's CA bundle (common with test SMTP providers) | Surfaces as `{:retries_exceeded, {:temporary_failure, ..., :tls_failed}}` from `gen_smtp`. Fixed generally via `tls_options: [verify: :verify_none]`; for production, use a provider with a standard trusted certificate instead of disabling verification. |
