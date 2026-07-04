# BudgetSentinel

Government Public Project Expenditure Tracking and Anomaly Detection System.

A microservice system that monitors government project expenditures against approved budgets and milestones, detects procurement fraud patterns with an Isolation Forest model, generates AI-written audit reports via the Claude API, and pushes real-time alerts to a live dashboard.

Full design rationale: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · [docs/DATABASE.md](docs/DATABASE.md) · [docs/API.md](docs/API.md) · [docs/FRAUD_PATTERNS.md](docs/FRAUD_PATTERNS.md) · [docs/DETECTION_SCAN.md](docs/DETECTION_SCAN.md) · [docs/ALERTS.md](docs/ALERTS.md)

## Services

| Service | Path | Stack |
|---|---|---|
| Web (real-time dashboard, persistence, alerts) | `web/` | Elixir, Phoenix, Phoenix LiveView, Ecto, PostgreSQL, Swoosh |
| AI microservice (anomaly detection, audit reports) | `ai_service/` | Python, Flask, scikit-learn, Anthropic SDK |

## Run with Docker Compose (recommended)

Requires Docker and Docker Compose.

```bash
cp ai_service/.env.example ai_service/.env   # optionally add your ANTHROPIC_API_KEY
docker compose up --build
```

This starts PostgreSQL, the AI microservice (`:5000`), and the Phoenix app (`:4000`). On first run, also seed the database with the simulated Rwanda dataset:

```bash
docker compose exec web bin/budget_sentinel eval "BudgetSentinel.Release.migrate()"
docker compose exec web bin/budget_sentinel eval "Code.eval_file(\"priv/repo/seeds.exs\")"
```

Then open http://localhost:4000.

Without `ANTHROPIC_API_KEY` set, the AI service still runs and detects anomalies — audit report generation falls back to a deterministic template instead of calling Claude.

## Run locally without Docker

### 1. Python AI microservice

```bash
cd ai_service
python -m venv .venv
source .venv/Scripts/activate   # on Windows Git Bash; use .venv/bin/activate on macOS/Linux
pip install -r requirements.txt
cp .env.example .env            # add ANTHROPIC_API_KEY if you have one
python scripts/train_model.py   # trains and saves the Isolation Forest model
python wsgi.py                  # serves on http://localhost:5000
```

Run the test suite:

```bash
pytest tests
```

### 2. Elixir / Phoenix web service

Requires Elixir 1.17+, Erlang/OTP 27+, and a running PostgreSQL instance.

```bash
cd web
mix deps.get
mix ecto.setup       # creates the DB, runs migrations, seeds the simulated dataset
mix phx.server       # serves on http://localhost:4000
```

By default the web service expects the AI microservice at `http://localhost:5000` (override with `AI_SERVICE_URL`).

Run the test suite (uses a mocked AI client — no network calls):

```bash
mix test
```

## Configuration

| Variable | Service | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | ai_service | Enables real Claude-generated audit reports |
| `ANTHROPIC_MODEL` | ai_service | Defaults to `claude-sonnet-4-6` |
| `HIGH_RISK_THRESHOLD` | ai_service / web | Risk score (0–100) above which an anomaly is "high" severity and triggers an alert email |
| `AI_SERVICE_URL` | web | Base URL of the Python AI microservice |
| `OVERSIGHT_OFFICER_EMAILS` | web | Comma-separated list of email recipients for high-risk alerts |
| `DATABASE_URL` | web | PostgreSQL connection string (production) |

## UI design

Two-color brand system: deep navy (`#13294B`) for authority/trust as the primary, warm amber/gold (`#D4A24C`) for attention as the secondary. Risk severity is conveyed through weight and tint of the amber accent rather than a third semantic color, so the whole interface stays visually disciplined while still reading clearly at a glance.

## Note on this implementation

Elixir/Phoenix is hand-written in this repository rather than scaffolded with `mix phx.new`, and could not be compiled/run in the environment that produced it. Read through `web/lib` once before running `mix phx.server` for the first time. The Python AI microservice was built and verified in the same environment (`pytest tests` passes, and `wsgi.py` was smoke-tested end-to-end).
