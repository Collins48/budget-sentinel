# AI Microservice REST Contract

Base URL: `http://localhost:5000` (configurable via `AI_SERVICE_URL` on the Elixir side, `FLASK_PORT` on the Python side). All endpoints are under `/api/v1`. The service has no authentication of its own — it is expected to sit on a private network reachable only by the Elixir web service.

## `GET /api/v1/health`

Liveness check for container orchestration.

```json
{ "status": "ok" }
```

## `POST /api/v1/anomalies/detect`

Runs the trained Isolation Forest + rule-based risk scoring over a batch of expenditures.

**Request body**
```json
{
  "projects": [
    {
      "id": "1",
      "sector": "infrastructure",
      "approved_budget": 500000.0,
      "completion_rate": 40.0,
      "market_benchmark": 480000.0
    }
  ],
  "expenditures": [
    {
      "id": "17",
      "project_id": "1",
      "contractor": "Kivu Builders Ltd",
      "amount": 60000.0,
      "milestone": "foundation",
      "date": "2024-03-01"
    }
  ]
}
```

`market_benchmark` is optional; if omitted, `approved_budget` is used as the benchmark.

**Response** — only anomalous expenditures are returned, sorted by `risk_score` descending:
```json
{
  "anomalies": [
    {
      "expenditure_id": "17",
      "project_id": "1",
      "fraud_type": "premature_payment",
      "risk_score": 78.4,
      "severity": "high",
      "anomaly_score": 0.81,
      "explanation": "Payment amount far exceeds the project's reported completion percentage."
    }
  ]
}
```

`fraud_type` is one of: `budget_overrun`, `duplicate_payment`, `ghost_project`, `inflated_contract`, `premature_payment`, `unclassified_anomaly` (statistically anomalous but not matching a known rule). `severity` is derived from `risk_score`: `>=70` high, `>=40` medium, otherwise low.

**Errors**: `400` with `{"error": "..."}" when projects/expenditures are missing required fields or an expenditure references an unknown project.

## `POST /api/v1/audit-reports/generate`

Generates a structured audit report for a single anomaly via the Claude API.

**Request body**
```json
{
  "anomaly": {
    "fraud_type": "ghost_project",
    "risk_score": 85.0,
    "severity": "high",
    "explanation": "Full payment was disbursed against a project reporting zero completion."
  },
  "project": { "id": "1", "sector": "infrastructure", "approved_budget": 500000.0, "completion_rate": 0.0 },
  "expenditure": { "id": "17", "project_id": "1", "contractor": "Kivu Builders Ltd", "amount": 200000.0, "milestone": "handover", "date": "2024-03-01" }
}
```

**Response**
```json
{
  "summary": "...",
  "severity_assessment": "...",
  "recommended_actions": "..."
}
```

If `ANTHROPIC_API_KEY` is not configured, this endpoint returns a deterministic, template-based report instead of failing — useful for local development and grading without API credentials.
