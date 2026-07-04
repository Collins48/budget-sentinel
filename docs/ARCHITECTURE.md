# Architecture

BudgetSentinel is split into two independently deployable services that communicate over plain HTTP/JSON. Neither service shares a database — the Elixir service owns all persistence, the Python service is purely computational.

```
 ┌──────────────┐      HTTPS       ┌────────────────────┐      HTTP/JSON      ┌─────────────────────┐
 │ Browser      │ ───────────────▶ │ Elixir / Phoenix    │ ──────────────────▶ │ Python / Flask        │
 │ (LiveView UI)│ ◀─PubSub/socket─ │ web service          │ ◀──────────────────  │ AI microservice        │
 └──────────────┘                  └────────────────────┘                      └─────────────────────┘
                                            │                                            │
                                            ▼                                            ▼
                                     PostgreSQL (Ecto)                          Anthropic Claude API
```

## Why two services

The web layer (real-time dashboard, persistence, email alerts) and the AI layer (Isolation Forest inference, Claude prompting) have very different scaling and deployment needs. Keeping them separate lets the ML/AI service be redeployed, retrained, or scaled independently of the user-facing web tier, and keeps Python ML dependencies out of the BEAM runtime entirely.

## Elixir / Phoenix service (`web/`)

Organized as Phoenix **bounded contexts** plus a **ports-and-adapters** boundary for the only external dependency that matters architecturally — the AI service:

- `BudgetSentinel.Procurement` — projects and expenditures (the system of record).
- `BudgetSentinel.Audit` — anomalies, AI-generated audit reports, and alert dispatch history.
- `BudgetSentinel.Intelligence` — the **port** (`AIClientBehaviour`), the **adapter** (`HttpAIClient`), and the **orchestrator** (`AnalysisPipeline`) that ties detection, persistence, reporting, and alerting together for a single scan.
- `BudgetSentinel.Notifications` — Swoosh mailer, email template, and the dispatch policy (which anomalies trigger an email, and to whom).

Because the web layer only ever talks to `AIClientBehaviour`, tests substitute `BudgetSentinel.IntelligenceTest.MockAIClient` and never make a real network call — this is what makes `mix test` deterministic and fast.

The dashboard is **Phoenix LiveView**: a "Run Detection Scan" button kicks off `AnalysisPipeline.run_detection_scan/0` in a supervised `Task`, and `Phoenix.PubSub` broadcasts (`anomalies:lobby` topic) push every new anomaly and audit report to all connected browsers without a page refresh or any hand-written JavaScript.

## Python / Flask AI microservice (`ai_service/`)

A small layered application:

- `app/domain` — plain dataclasses (`ProjectContext`, `ExpenditureRecord`, `AnomalyResult`) with no framework dependencies.
- `app/ml` — feature engineering, the Isolation Forest wrapper, and joblib model persistence.
- `app/services` — `AnomalyDetectionService` (orchestrates ML + rule-based fraud typing into a risk score) and `AuditReportService` (Claude API client with a deterministic fallback when no API key is configured).
- `app/api` — Flask blueprint + request validation, the only layer that knows about HTTP.

The service is **stateless**: every request carries the full project/expenditure context it needs, and nothing is written to disk except the trained model artifact produced by `scripts/train_model.py`.

## Data flow for one detection scan

1. A user clicks **Run Detection Scan** on the LiveView dashboard.
2. `AnalysisPipeline` loads all projects/expenditures from Postgres via `Procurement`, serializes them to JSON-friendly maps, and calls `AIClientBehaviour.detect_anomalies/2`.
3. `HttpAIClient` POSTs to `ai_service`'s `/api/v1/anomalies/detect`. The Flask service builds features, scores them with the trained Isolation Forest, classifies each anomaly against the five known fraud patterns, and returns risk-scored results.
4. `AnalysisPipeline` persists each anomaly via `Audit.record_anomaly/1` and broadcasts `{:anomaly_detected, anomaly}` over PubSub — the dashboard updates immediately.
5. For anomalies at or above the high-risk threshold, `AnalysisPipeline` calls `/api/v1/audit-reports/generate` (Claude API), stores the result via `Audit.attach_report/2`, and hands off to `Notifications.Dispatcher`, which emails designated oversight officers and logs an `Alert` record.

## Design patterns used and why

| Pattern | Where | Why |
|---|---|---|
| Bounded contexts | `Procurement`, `Audit`, `Notifications` | Keeps persistence/query logic out of LiveViews; each context owns its schemas. |
| Ports & adapters | `AIClientBehaviour` / `HttpAIClient` | The web service never depends on HTTP details directly — swappable, mockable. |
| Orchestrator/pipeline | `AnalysisPipeline` | Single place that sequences detect → persist → report → alert → broadcast. |
| Factory | `app/__init__.create_app()` | Standard Flask pattern; lets tests build an app with a stubbed model. |
| Strategy (rule-based + ML) | `app/services/risk_scoring.py` | Combines an unsupervised anomaly score with explicit fraud-type rules, instead of relying on either alone. |
